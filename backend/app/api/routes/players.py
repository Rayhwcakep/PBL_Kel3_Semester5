"""Endpoint daftar dan detail pemain."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from app.schemas.player import PlayerDetailOut, PlayerOut, PlayersResponse
from app.schemas.scouting import PlayerFilter
from app.services.model_registry import get_registry

router = APIRouter(prefix="/players", tags=["players"])


@router.get("", response_model=PlayersResponse, summary="Daftar pemain (dengan filter)")
def list_players(
    archetype: str | None = Query(None, description="Kode arketipe, mis. 'ST'."),
    league: str | None = Query(None, description="Cocokkan sebagian nama liga."),
    max_age: int | None = Query(None, ge=15, le=45),
    min_age: int | None = Query(None, ge=15, le=45),
    max_value_eur: float | None = Query(None, ge=0),
    search: str | None = Query(None, description="Cari sebagian nama pemain atau klub."),
    offset: int = Query(0, ge=0),
    limit: int | None = Query(None, ge=1, le=500),
) -> PlayersResponse:
    registry = get_registry()
    metadata = registry.metadata
    if metadata is None:
        raise HTTPException(status_code=503, detail="Metadata model belum dimuat.")

    if archetype is not None and archetype not in metadata.archetypes:
        raise HTTPException(
            status_code=400,
            detail=f"Arketipe '{archetype}' tidak dikenal. Pilihan: {sorted(metadata.archetypes)}",
        )

    items = registry.players
    if archetype:
        items = [player for player in items if player["archetype"] == archetype]
    if league:
        needle = league.lower()
        items = [player for player in items if needle in (player.get("league") or "").lower()]
    if max_age is not None:
        items = [player for player in items if (player.get("age") or 0) <= max_age]
    if min_age is not None:
        items = [player for player in items if (player.get("age") or 0) >= min_age]
    if max_value_eur is not None:
        items = [
            player
            for player in items
            if player.get("market_value_eur") is not None
            and player["market_value_eur"] <= max_value_eur
        ]
    if search:
        needle = search.lower()
        items = [
            player
            for player in items
            if needle in player["name"].lower() or needle in (player.get("club") or "").lower()
        ]

    total = len(items)
    page = items[offset : offset + limit if limit is not None else None]
    return PlayersResponse(
        total=total,
        count=len(page),
        offset=offset,
        limit=limit,
        players=[PlayerOut(**player) for player in page],
    )


@router.get("/{player_id}", response_model=PlayerDetailOut, summary="Detail satu pemain")
def get_player(player_id: str) -> PlayerDetailOut:
    registry = get_registry()
    player = registry.find_player(player_id)
    if player is None:
        raise HTTPException(status_code=404, detail=f"Pemain '{player_id}' tidak ditemukan.")

    model = registry.model_for(player)
    value = model.value
    return PlayerDetailOut(
        **player,
        reliability=value.reliability if value else None,
        r2_test=round(value.r2_test, 3) if value else None,
        base_value_eur=round(value.base_value_eur) if value else None,
    )


def filter_from_query(**kwargs) -> PlayerFilter:
    """Bantu pengujian: ubah query string menjadi `PlayerFilter`."""
    return PlayerFilter(**kwargs)
