"""Endpoint kesehatan dan info model."""

from fastapi import APIRouter

from app.core.config import get_settings
from app.services.model_registry import get_registry

router = APIRouter(tags=["health"])


@router.get("/health", summary="Cek status layanan")
def health() -> dict:
    registry = get_registry()
    settings = get_settings()
    return {
        "status": "ok" if registry.ready else "degraded",
        "app": settings.app_name,
        "version": settings.app_version,
        "players_loaded": len(registry.players),
        "archetypes_loaded": len(registry.archetypes),
        "model_ready": registry.knn_ready,
        "shap_ready": registry.shap_ready,
        "errors": registry.load_errors,
    }
