"""Endpoint pencarian: kriteria statistik, taktik, dan pemain mirip."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from app.schemas.scouting import (
    NeighborReasonOut,
    PlayerFilter,
    ScoutRequest,
    ScoutResponse,
    ScoutingResultOut,
    SimilarPlayerOut,
    SimilarResponse,
    TacticScoutRequest,
)
from app.services import knn_service, tactic_service
from app.services.model_registry import get_registry

router = APIRouter(tags=["scout"])


def _filter(request) -> PlayerFilter:
    return PlayerFilter(
        max_age=getattr(request, "max_age", None),
        min_age=getattr(request, "min_age", None),
        max_value_eur=getattr(request, "max_value_eur", None),
        league=getattr(request, "league", None),
        exclude_id=getattr(request, "exclude_id", None),
    )


@router.post("/scout", response_model=ScoutResponse, summary="Cari pemain dengan target statistik")
def scout(request: ScoutRequest) -> ScoutResponse:
    registry = get_registry()
    if registry.metadata is None:
        raise HTTPException(status_code=503, detail="Metadata model belum dimuat.")
    if request.archetype not in registry.archetypes:
        raise HTTPException(
            status_code=400,
            detail=f"Arketipe '{request.archetype}' tidak dikenal. Pilihan: {sorted(registry.archetypes)}",
        )

    try:
        payload = knn_service.search_by_criteria(
            registry, request.archetype, request.criteria, _filter(request), request.top_k
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    return ScoutResponse(
        archetype=payload["archetype"],
        tactic=None,
        k=payload["k"],
        target=payload["target"],
        target_percentiles=payload["target_percentiles"],
        results=[ScoutingResultOut(**result) for result in payload["results"]],
    )


@router.post("/scout/tactic", response_model=ScoutResponse, summary="Cari pemain sesuai taktik")
def scout_by_tactic(request: TacticScoutRequest) -> ScoutResponse:
    registry = get_registry()
    if registry.metadata is None:
        raise HTTPException(status_code=503, detail="Metadata model belum dimuat.")
    if request.archetype not in registry.archetypes:
        raise HTTPException(
            status_code=400,
            detail=f"Arketipe '{request.archetype}' tidak dikenal. Pilihan: {sorted(registry.archetypes)}",
        )

    try:
        payload = tactic_service.search_by_tactic(
            registry,
            request.archetype,
            request.tactic,
            request.sliders,
            _filter(request),
            request.top_k,
            explain=request.explain,
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    return ScoutResponse(
        archetype=payload["archetype"],
        tactic=payload["tactic"],
        k=payload["k"],
        target=payload["target"],
        target_percentiles=payload["target_percentiles"],
        results=[ScoutingResultOut(**result) for result in payload["results"]],
    )


@router.get(
    "/players/{player_id}/similar",
    response_model=SimilarResponse,
    summary="Pemain paling mirip beserta alasannya",
)
def similar_players(
    player_id: str,
    limit: int = Query(10, ge=1, le=50),
    max_age: int | None = Query(None, ge=15, le=45),
    min_age: int | None = Query(None, ge=15, le=45),
    max_value_eur: float | None = Query(None, ge=0),
    league: str | None = Query(None),
) -> SimilarResponse:
    registry = get_registry()
    player = registry.find_player(player_id)
    if player is None:
        raise HTTPException(status_code=404, detail=f"Pemain '{player_id}' tidak ditemukan.")

    model = registry.model_for(player)
    request = PlayerFilter(
        max_age=max_age,
        min_age=min_age,
        max_value_eur=max_value_eur,
        league=league,
        exclude_id=str(player["id"]),
    )
    found = knn_service.neighbors(registry, model, int(player["id"]), limit, request)

    metadata = registry.metadata
    index = model.row(int(player["id"]))
    neighbors: list[SimilarPlayerOut] = []
    best_uid = None
    for uid, distance, rank in found:
        if best_uid is None:
            best_uid = uid
        neighbors.append(
            SimilarPlayerOut(
                player=registry.by_id[uid],
                similarity=model.similarity(distance),
                distance=distance,
                rank=rank,
                closer_than_pct=round(100.0 * (1.0 - rank / max(model.n - 1, 1)), 1),
            )
        )

    similar_because: list[NeighborReasonOut] = []
    different_because: list[NeighborReasonOut] = []
    if best_uid is not None:
        from app.services.distance import contributions

        neighbor_index = model.row(best_uid)
        table = contributions(model, model.z[index], model.z[neighbor_index])
        neighbor = registry.by_id[best_uid]
        rows = []
        for position, feature in enumerate(model.features):
            rows.append(
                NeighborReasonOut(
                    feature=feature,
                    label=metadata.label(feature),
                    a=float(player["stats"].get(feature, 0.0)),
                    b=float(neighbor["stats"].get(feature, 0.0)),
                    pct_a=float(player["percentiles"].get(feature, 50.0)),
                    pct_b=float(neighbor["percentiles"].get(feature, 50.0)),
                    contribution=float(table["contrib"][position]),
                    share=float(table["share"][position]),
                )
            )
        rows.sort(key=lambda row: row.share)
        similar_because = rows[:3]
        different_because = list(reversed(rows[-3:]))

    return SimilarResponse(
        player=player,
        same_archetype=True,
        neighbors=neighbors,
        similar_because=similar_because,
        different_because=different_because,
    )
