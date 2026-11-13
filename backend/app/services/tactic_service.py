"""Pencarian berbasis taktik: preset atau slider persentil.

Alur (sama dengan notebook, Langkah 12):

1. Preset/slider -> profil target dalam **persentil**.
2. Persentil -> angka per-90 nyata memakai sebaran pemain di arketipe itu.
3. KNN mengukur jarak pemain ke profil target, hanya pada statistik yang
   disebut taktik (`mask`).
4. Atribusi jarak dipecah per statistik -> kalimat "lebih/kurang".
"""

from __future__ import annotations

from typing import Any

import numpy as np

from app.schemas.scouting import PlayerFilter
from app.services.distance import (
    fit_table,
    natural_from_percentile,
    percentile_rank,
    short_reason,
)
from app.services.knn_service import rank
from app.services.model_registry import ModelRegistry


def _preset(registry: ModelRegistry, archetype: str, tactic: str) -> dict[str, Any]:
    presets = registry.metadata.tactics.get(archetype, {})
    if tactic not in presets:
        raise ValueError(
            f"taktik '{tactic}' tidak ada untuk arketipe {archetype}. Pilihan: {sorted(presets)}"
        )
    return presets[tactic]


def target_percentiles(
    registry: ModelRegistry,
    archetype: str,
    tactic: str | None = None,
    sliders: dict[str, float] | None = None,
) -> dict[str, float]:
    """Persentil target per statistik. Default 50 (median arketipe)."""
    features = registry.archetypes[archetype].features
    target = {feature: 50.0 for feature in features}

    if tactic:
        target.update({key: float(value) for key, value in _preset(registry, archetype, tactic)["targets"].items()})
    if sliders:
        target.update({key: float(value) for key, value in sliders.items()})

    unknown = [key for key in target if key not in features]
    if unknown:
        raise ValueError(
            f"statistik {unknown} tidak dipakai arketipe {archetype}. Pilihan: {features}"
        )
    return target


def target_vector(
    registry: ModelRegistry, archetype: str, percentiles: dict[str, float]
) -> np.ndarray:
    """Persentil target -> angka per-90 nyata (kuantil sebaran arketipe)."""
    model = registry.archetypes[archetype]
    return np.asarray(
        [
            natural_from_percentile(model.stats[:, index], percentiles[feature])
            for index, feature in enumerate(model.features)
        ],
        dtype=float,
    )


def mask_vector(
    registry: ModelRegistry,
    archetype: str,
    tactic: str | None = None,
    sliders: dict[str, float] | None = None,
) -> np.ndarray:
    """0/1 per statistik: hanya statistik yang disebut taktik yang menarik jarak."""
    features = registry.archetypes[archetype].features
    specified: set[str] = set()
    if tactic:
        specified |= set(_preset(registry, archetype, tactic)["targets"])
    if sliders:
        specified |= set(sliders)

    mask = np.asarray([1.0 if feature in specified else 0.0 for feature in features], dtype=float)
    return mask if mask.sum() > 0 else np.ones(len(features), dtype=float)


def search_by_tactic(
    registry: ModelRegistry,
    archetype: str,
    tactic: str | None,
    sliders: dict[str, float] | None,
    request: PlayerFilter,
    top_k: int,
    explain: bool = True,
) -> dict[str, Any]:
    """Cari pemain yang paling dekat dengan profil taktik."""
    model = registry.archetypes[archetype]
    metadata = registry.metadata

    pct_target = target_percentiles(registry, archetype, tactic, sliders)
    target_stats = target_vector(registry, archetype, pct_target)
    mask = mask_vector(registry, archetype, tactic, sliders)

    picked = rank(registry, model, target_stats, request, top_k)

    results: list[dict[str, Any]] = []
    for position, (uid, distance) in enumerate(picked, start=1):
        player = registry.by_id[uid]
        player_stats = np.asarray(
            [player["stats"].get(feature, 0.0) for feature in model.features], dtype=float
        )
        pct_player = {
            feature: float(player["percentiles"].get(feature, 50.0))
            for feature in model.features
        }

        why = None
        if explain:
            rows = fit_table(
                model,
                player_stats,
                target_stats,
                pct_player,
                pct_target,
                metadata,
                mask=mask,
            )
            why = short_reason(rows)

        results.append(
            {
                "rank": position,
                "similarity": model.similarity(distance),
                "distance": distance,
                "player": player,
                "why": why,
            }
        )

    return {
        "archetype": archetype,
        "tactic": tactic,
        "k": top_k,
        "target": {
            feature: round(float(target_stats[index]), 4)
            for index, feature in enumerate(model.features)
        },
        "target_percentiles": {key: round(float(value), 1) for key, value in pct_target.items()},
        "results": results,
    }


def fit_report(
    registry: ModelRegistry,
    player_id: str,
    tactic: str | None = None,
    sliders: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Kecocokan satu pemain dengan taktik tertentu (dipakai `/explain`)."""
    player = registry.find_player(player_id)
    if player is None:
        raise KeyError(f"pemain '{player_id}' tidak ditemukan")

    archetype = player["archetype"]
    model = registry.model_for(player)
    metadata = registry.metadata

    pct_target = target_percentiles(registry, archetype, tactic, sliders)
    target_stats = target_vector(registry, archetype, pct_target)
    mask = mask_vector(registry, archetype, tactic, sliders)

    player_stats = np.asarray(
        [player["stats"].get(feature, 0.0) for feature in model.features], dtype=float
    )
    pct_player = {
        feature: float(player["percentiles"].get(feature, 50.0)) for feature in model.features
    }

    rows = fit_table(model, player_stats, target_stats, pct_player, pct_target, metadata, mask=mask)
    distance = float(np.sqrt(sum(row["contrib"] for row in rows)))

    tepat_sasaran = any(row["verdict"] == "sesuai" and row["contrib"] > 0 for row in rows)
    over = [row for row in rows if row["verdict"] == "kelebihan"]
    under = [row for row in rows if row["verdict"] == "kekurangan"]

    return {
        "player": player,
        "tactic": tactic,
        "similarity": model.similarity(distance),
        "tepat_sasaran": tepat_sasaran,
        "rows": rows,
        "over": sorted(over, key=lambda row: row["delta_good"], reverse=True),
        "under": sorted(under, key=lambda row: row["delta_good"]),
        "target_percentiles": pct_target,
    }
