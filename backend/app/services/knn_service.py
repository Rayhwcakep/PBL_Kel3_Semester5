"""Pencarian kandidat dengan KNN.

Tidak ada training saat request: semua pemain searketipe sudah berada di peta
statistik (`ArchetypeModel.z`). Permintaan hanya membentuk vektor target lalu
mengukur jarak.
"""

from __future__ import annotations

from typing import Any

import numpy as np

from app.schemas.scouting import PlayerFilter
from app.services.distance import (
    fit_table,
    percentile_rank,
    short_reason,
    transform_vector,
)
from app.services.model_registry import ArchetypeModel, ModelRegistry


def passes_filter(player: dict[str, Any], request: PlayerFilter) -> bool:
    """Filter murah yang tidak mengubah urutan jarak."""
    age = player.get("age")
    if request.max_age is not None and (age or 0) > request.max_age:
        return False
    if request.min_age is not None and (age or 0) < request.min_age:
        return False

    value = player.get("market_value_eur")
    if request.max_value_eur is not None:
        if value is None or value > request.max_value_eur:
            return False

    if request.league:
        league = (player.get("league") or "").lower()
        if request.league.lower() not in league:
            return False

    if request.exclude_id is not None and str(player.get("id")) == str(request.exclude_id):
        return False
    return True


def rank(
    registry: ModelRegistry,
    model: ArchetypeModel,
    target_stats: np.ndarray,
    request: PlayerFilter,
    top_k: int,
) -> list[tuple[int, float]]:
    """Urutkan pemain searketipe berdasarkan jarak ke vektor target.

    Mengembalikan `(uid, distance)` yang sudah difilter. Ambil lebih banyak
    kandidat dari `top_k` agar filter umur/harga tidak mengosongkan hasil.
    """
    z_target = transform_vector(model, target_stats)
    squared = np.sum((model.z - z_target) ** 2, axis=1)
    order = np.argsort(squared)

    picked: list[tuple[int, float]] = []
    for index in order:
        uid = int(model.uids[index])
        player = registry.by_id.get(uid)
        if player is None:
            continue
        if not passes_filter(player, request):
            continue
        picked.append((uid, float(np.sqrt(max(squared[index], 0.0)))))
        if len(picked) >= top_k:
            break
    return picked


def search_by_criteria(
    registry: ModelRegistry,
    archetype: str,
    criteria: dict[str, float],
    request: PlayerFilter,
    top_k: int,
) -> dict[str, Any]:
    """Pencarian dengan target statistik nyata (per-90).

    Statistik yang tidak diisi memakai median arketipe. Hanya statistik yang
    diisi yang dipakai menilai "lebih/kurang", supaya pemain tidak dihukum
    karena hal yang tidak diminta.
    """
    model = registry.archetypes[archetype]
    metadata = registry.metadata

    unknown = [key for key in criteria if key not in model.features]
    if unknown:
        raise ValueError(
            f"statistik {unknown} tidak dipakai arketipe {archetype}. "
            f"Pilihan: {model.features}"
        )

    target = [
        float(criteria.get(feature, np.median(model.stats[:, index])))
        for index, feature in enumerate(model.features)
    ]
    target_stats = np.asarray(target, dtype=float)

    pct_target = {
        feature: percentile_rank(model.stats[:, index], target[index])
        for index, feature in enumerate(model.features)
    }

    mask = np.asarray(
        [1.0 if feature in criteria else 0.0 for feature in model.features], dtype=float
    )
    if mask.sum() == 0:
        mask = np.ones(len(model.features))

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
        rows = fit_table(
            model,
            player_stats,
            target_stats,
            pct_player,
            pct_target,
            metadata,
            mask=mask,
        )
        results.append(
            {
                "rank": position,
                "similarity": model.similarity(distance),
                "distance": distance,
                "player": player,
                "why": short_reason(rows),
            }
        )

    return {
        "archetype": archetype,
        "tactic": None,
        "k": top_k,
        "target": {
            feature: round(float(target_stats[index]), 4)
            for index, feature in enumerate(model.features)
        },
        "target_percentiles": {
            feature: round(float(value), 1) for feature, value in pct_target.items()
        },
        "results": results,
    }


def neighbors(
    registry: ModelRegistry,
    model: ArchetypeModel,
    uid: int,
    count: int,
    request: PlayerFilter | None = None,
) -> list[tuple[int, float, int]]:
    """Tetangga terdekat dari seorang pemain: `(uid, distance, rank)`."""
    request = request or PlayerFilter()
    index = model.row(uid)
    squared = np.sum((model.z - model.z[index]) ** 2, axis=1)

    picked: list[tuple[int, float, int]] = []
    for neighbor_index in np.argsort(squared):
        neighbor_uid = int(model.uids[neighbor_index])
        if neighbor_uid == uid:
            continue
        player = registry.by_id.get(neighbor_uid)
        if player is None or not passes_filter(player, request):
            continue
        picked.append(
            (
                neighbor_uid,
                float(np.sqrt(max(squared[neighbor_index], 0.0))),
                len(picked) + 1,
            )
        )
        if len(picked) >= count:
            break
    return picked

