"""Endpoint daftar dan detail pemain."""

from fastapi import APIRouter, HTTPException

from app.schemas.player import PlayerOut, PlayersResponse
from app.services.model_registry import get_registry

router = APIRouter(prefix="/players", tags=["players"])


@router.get("", response_model=PlayersResponse, summary="Daftar seluruh pemain")
def list_players() -> PlayersResponse:
    registry = get_registry()
    players = [PlayerOut(**player) for player in registry.players]
    return PlayersResponse(total=len(players), players=players)


@router.get("/{player_id}", response_model=PlayerOut, summary="Detail satu pemain")
def get_player(player_id: str) -> PlayerOut:
    player = get_registry().find_player(player_id)
    if player is None:
        raise HTTPException(status_code=404, detail=f"Pemain '{player_id}' tidak ditemukan.")
    return PlayerOut(**player)
