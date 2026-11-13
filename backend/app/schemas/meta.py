"""Skema balasan untuk endpoint metadata (`/meta/...`)."""

from __future__ import annotations

from pydantic import BaseModel, Field

from app.schemas.player import ArchetypeMeta


class HexagonAxisOut(BaseModel):
    """Satu sumbu grafik heksagon di aplikasi."""

    label: str
    feature: str
    invert: bool = False


class MetadataResponse(BaseModel):
    """Balasan `GET /meta/features`."""

    archetypes: list[ArchetypeMeta]
    context_labels: dict[str, str] = Field(default_factory=dict)
    min_effect: float = Field(0.03, description="Ambang pengaruh SHAP agar disebut bermakna.")
    min_pct_gap: float = Field(10.0, description="Ambang selisih persentil agar disebut beda.")
    hexagon_axes: dict[str, list[HexagonAxisOut]] = Field(default_factory=dict)


class TacticPresetOut(BaseModel):
    key: str
    label: str
    description: str
    targets: dict[str, float] = Field(..., description="Target persentil per statistik (0-100).")


class TacticArchetypeOut(BaseModel):
    archetype: str
    label: str
    presets: list[TacticPresetOut]


class TacticsResponse(BaseModel):
    """Balasan `GET /meta/tactics`."""

    archetypes: list[TacticArchetypeOut]
    value_models: dict[str, dict] = Field(
        default_factory=dict, description="R² dan keandalan model nilai pasar per arketipe."
    )
