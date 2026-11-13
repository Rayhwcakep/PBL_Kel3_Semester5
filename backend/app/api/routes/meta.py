"""Endpoint metadata: statistik per arketipe dan preset taktik."""

from fastapi import APIRouter, HTTPException

from app.schemas.meta import (
    HexagonAxisOut,
    MetadataResponse,
    TacticsResponse,
    TacticArchetypeOut,
    TacticPresetOut,
)
from app.schemas.player import ArchetypeMeta, FeatureMeta
from app.services.model_registry import get_registry

router = APIRouter(prefix="/meta", tags=["meta"])


@router.get("/features", response_model=MetadataResponse, summary="Statistik tiap arketipe")
def features() -> MetadataResponse:
    registry = get_registry()
    metadata = registry.metadata
    if metadata is None:
        raise HTTPException(status_code=503, detail="Metadata model belum dimuat.")

    archetypes: list[ArchetypeMeta] = []
    for key in sorted(metadata.archetypes):
        model = registry.archetypes.get(key)
        archetypes.append(
            ArchetypeMeta(
                key=key,
                label=metadata.archetype_label(key),
                features=[
                    FeatureMeta(
                        key=feature.key,
                        label=feature.label,
                        good_dir=feature.good_dir,
                        invert=feature.invert,
                        weight=feature.weight,
                    )
                    for feature in metadata.features(key)
                ],
                players=model.n if model else 0,
            )
        )

    return MetadataResponse(
        archetypes=archetypes,
        context_labels=metadata.context_labels,
        min_effect=metadata.min_effect,
        min_pct_gap=metadata.min_pct_gap,
        hexagon_axes={
            key: [HexagonAxisOut(**axis) for axis in axes]
            for key, axes in metadata.hexagon_axes.items()
        },
    )


@router.get("/tactics", response_model=TacticsResponse, summary="Preset taktik per arketipe")
def tactics() -> TacticsResponse:
    registry = get_registry()
    metadata = registry.metadata
    if metadata is None:
        raise HTTPException(status_code=503, detail="Metadata model belum dimuat.")

    archetypes: list[TacticArchetypeOut] = []
    for key in sorted(metadata.tactics):
        presets = [
            TacticPresetOut(
                key=name,
                label=preset.get("label", name),
                description=preset.get("desc", ""),
                targets={stat: float(value) for stat, value in preset.get("targets", {}).items()},
            )
            for name, preset in metadata.tactics[key].items()
        ]
        archetypes.append(
            TacticArchetypeOut(
                archetype=key,
                label=metadata.archetype_label(key),
                presets=presets,
            )
        )

    return TacticsResponse(archetypes=archetypes, value_models=metadata.value_model_info)
