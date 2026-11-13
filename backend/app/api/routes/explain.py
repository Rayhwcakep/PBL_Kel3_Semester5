"""Endpoint perbandingan, penjelasan SHAP, dan rekomendasi best-fit."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from app.schemas.scouting import (
    BestFitCandidateOut,
    BestFitResponse,
    CompareRequest,
    CompareResponse,
    CompareRowOut,
    ExplainResponse,
    NeighborReasonOut,
    PlayerFilter,
)
from app.services import best_fit_service, compare_service
from app.services.explain_service import ExplainService
from app.services.model_registry import get_registry

router = APIRouter(tags=["explain"])

_explain_service: ExplainService | None = None


def explain_service() -> ExplainService:
    """Satu instance ExplainService agar explainer SHAP di-cache."""
    global _explain_service
    if _explain_service is None or _explain_service.registry is not get_registry():
        _explain_service = ExplainService(get_registry())
    return _explain_service


def _player(player_id: str):
    player = get_registry().find_player(player_id)
    if player is None:
        raise HTTPException(status_code=404, detail=f"Pemain '{player_id}' tidak ditemukan.")
    return player


@router.post("/compare", response_model=CompareResponse, summary="Bandingkan dua pemain")
def compare(request: CompareRequest) -> CompareResponse:
    registry = get_registry()
    if registry.metadata is None:
        raise HTTPException(status_code=503, detail="Metadata model belum dimuat.")

    payload = compare_service.compare(
        registry,
        explain_service(),
        _player(request.a),
        _player(request.b),
    )
    return CompareResponse(
        a=payload["a"],
        b=payload["b"],
        same_archetype=payload["same_archetype"],
        warning=payload["warning"],
        similarity=payload["similarity"],
        neighbor_rank=payload["neighbor_rank"],
        rows=[CompareRowOut(**row) for row in payload["rows"]],
        a_better=[CompareRowOut(**row) for row in payload["a_better"]],
        b_better=[CompareRowOut(**row) for row in payload["b_better"]],
        raw_only=[CompareRowOut(**row) for row in payload["raw_only"]],
        summary=payload["summary"],
    )


@router.get(
    "/players/{player_id}/explain",
    response_model=ExplainResponse,
    summary="Kelebihan dan kekurangan pemain hasil SHAP",
)
def explain(player_id: str) -> ExplainResponse:
    registry = get_registry()
    if not registry.shap_ready:
        raise HTTPException(status_code=503, detail="Model nilai pasar belum siap.")

    payload = explain_service().detail(_player(player_id))
    return ExplainResponse(**payload)


@router.get(
    "/best-fit/{player_id}",
    response_model=BestFitResponse,
    summary="Rekomendasi pengganti yang menutup kekurangan",
)
def best_fit(
    player_id: str,
    top_k: int = Query(5, ge=1, le=20),
    needs: str | None = Query(
        None,
        description="Daftar statistik yang ingin ditutup, dipisah koma. Kosong = dari kekurangan SHAP.",
    ),
    improve_weight: float = Query(0.5, ge=0.0, le=1.0),
    max_age: int | None = Query(None, ge=15, le=45),
    min_age: int | None = Query(None, ge=15, le=45),
    max_value_eur: float | None = Query(None, ge=0),
    league: str | None = Query(None),
) -> BestFitResponse:
    registry = get_registry()
    if not registry.shap_ready:
        raise HTTPException(status_code=503, detail="Model nilai pasar belum siap.")

    player = _player(player_id)
    wanted = [item.strip() for item in needs.split(",") if item.strip()] if needs else None

    try:
        payload = best_fit_service.best_fit(
            registry,
            explain_service(),
            player,
            PlayerFilter(
                max_age=max_age,
                min_age=min_age,
                max_value_eur=max_value_eur,
                league=league,
                exclude_id=str(player["id"]),
            ),
            top_k,
            needs=wanted,
            improve_weight=improve_weight,
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    return BestFitResponse(
        player=payload["player"],
        needs=payload["needs"],
        keep=payload["keep"],
        candidates=[BestFitCandidateOut(**candidate) for candidate in payload["candidates"]],
    )


@router.get(
    "/players/{player_id}/fit",
    summary="Kecocokan pemain dengan sebuah taktik",
)
def tactic_fit(
    player_id: str,
    tactic: str | None = Query(None, description="Preset taktik, mis. 'wide_creator'."),
    sliders: str | None = Query(
        None, description="Slider manual 'stat=persentil', mis. 'crs_p90=90,ast_p90=80'."
    ),
) -> dict:
    registry = get_registry()
    if registry.metadata is None:
        raise HTTPException(status_code=503, detail="Metadata model belum dimuat.")

    parsed = None
    if sliders:
        parsed = {}
        for item in sliders.split(","):
            if "=" not in item:
                raise HTTPException(
                    status_code=400,
                    detail=f"Slider '{item}' tidak valid. Format: stat=persentil",
                )
            key, value = item.split("=", 1)
            try:
                parsed[key.strip()] = float(value)
            except ValueError as error:
                raise HTTPException(status_code=400, detail=f"Nilai slider '{item}' bukan angka.") from error

    try:
        from app.services import tactic_service

        payload = tactic_service.fit_report(registry, player_id, tactic, parsed)
    except KeyError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    return {
        "player": payload["player"],
        "tactic": payload["tactic"],
        "similarity": payload["similarity"],
        "tepat_sasaran": payload["tepat_sasaran"],
        "target_percentiles": payload["target_percentiles"],
        "rows": payload["rows"],
        "over": [
            {
                "feature": row["feature"],
                "label": row["label"],
                "pct_player": row["pct_player"],
                "pct_target": row["pct_target"],
                "delta_good": row["delta_good"],
            }
            for row in payload["over"]
        ],
        "under": [
            {
                "feature": row["feature"],
                "label": row["label"],
                "pct_player": row["pct_player"],
                "pct_target": row["pct_target"],
                "delta_good": row["delta_good"],
            }
            for row in payload["under"]
        ],
    }
