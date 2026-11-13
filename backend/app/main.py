"""Entry point API Scoutify.

Jalankan di mesin lokal:

    backend/.venv/Scripts/python.exe -m uvicorn app.main:app --reload --app-dir backend

Dokumentasi interaktif: http://127.0.0.1:8000/docs
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import explain, health, meta, players, scout
from app.core.config import get_settings
from app.services.model_registry import get_registry

logger = logging.getLogger("scoutml")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Muat dataset + artefak sekali saat startup, bukan per request."""
    registry = get_registry()
    if registry.load_errors:
        for error in registry.load_errors:
            logger.warning("registry: %s", error)
    if not registry.ready:
        logger.warning(
            "Model belum siap. Jalankan ml/export_artifacts.py lalu "
            "ml/build_backend_artifacts.py."
        )
    else:
        logger.info(
            "Siap: %d pemain, %d arketipe, SHAP=%s",
            len(registry.players),
            len(registry.archetypes),
            registry.shap_ready,
        )
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        summary="Pencarian pemain dengan KNN + penjelasan SHAP",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    for module in (health, meta, players, scout, explain):
        app.include_router(module.router, prefix=settings.api_prefix)

    return app


app = create_app()
