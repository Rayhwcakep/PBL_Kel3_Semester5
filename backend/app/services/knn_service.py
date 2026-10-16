"""Layanan pencarian tetangga terdekat (KNN).

Bila artefak model kamu tersedia (``scaler.joblib`` + ``knn_model.joblib``),
fungsi ini memakainya. Jika belum, dipakai perhitungan cadangan memakai
``numpy`` dengan jarak Euclidean pada skala 0-1.
"""

from __future__ import annotations

from typing import Any

import numpy as np

from app.schemas.scouting import ScoutRequest
from app.services.features import DEFAULT_FEATURE_VALUE
from app.services.model_registry import ModelRegistry, get_registry


def _query_vector(request: ScoutRequest, feature_names: list[str]) -> np.ndarray:
    return np.array(
        [[float(request.criteria.get(name, DEFAULT_FEATURE_VALUE)) for name in feature_names]],
        dtype=float,
    )


def _player_matrix(registry: ModelRegistry) -> np.ndarray:
    return np.array(
        [
            [float(player["stats"].get(name, DEFAULT_FEATURE_VALUE)) for name in registry.feature_names]
            for player in registry.players
        ],
        dtype=float,
    )


def _passes_filter(player: dict[str, Any], request: ScoutRequest) -> bool:
    if request.position and player["position"] != request.position:
        return False
    if request.max_age is not None and player["age"] > request.max_age:
        return False
    return True


def search(request: ScoutRequest, registry: ModelRegistry | None = None) -> tuple[list[dict[str, Any]], float]:
    """Mencari `top_k` pemain paling mirip dengan kriteria.

    Mengembalikan ``(results, base_value)`` di mana `results` adalah daftar
    dict siap dimasukkan ke ``ScoutingResultOut``.
    """
    registry = registry or get_registry()
    if not registry.players:
        return [], 0.0

    feature_names = registry.feature_names
    matrix = _player_matrix(registry)
    query = _query_vector(request, feature_names)

    if registry.ml_ready:
        pairs = _rank_with_model(registry, matrix, query, request)
    else:
        pairs = _rank_with_numpy(matrix, query)

    filtered = [
        (index, distance)
        for index, distance in pairs
        if _passes_filter(registry.players[index], request)
    ][: request.top_k]

    if not filtered:
        return [], 0.0

    similarities = [1.0 / (1.0 + max(distance, 0.0)) for _, distance in filtered]
    base_value = float(np.mean(similarities))

    results: list[dict[str, Any]] = []
    for rank, (index, distance) in enumerate(filtered, start=1):
        results.append(
            {
                "rank": rank,
                "similarity": float(1.0 / (1.0 + max(distance, 0.0))),
                "distance": float(distance),
                "player": registry.players[index],
            }
        )
    return results, base_value


def _rank_with_model(
    registry: ModelRegistry,
    matrix: np.ndarray,
    query: np.ndarray,
    request: ScoutRequest,
) -> list[tuple[int, float]]:
    """Memakai model KNN milikmu (dengan scaler bila ada)."""
    scaler = registry.scaler
    if scaler is not None:
        scaled_matrix = scaler.transform(matrix)
        scaled_query = scaler.transform(query)
    else:
        scaled_matrix = matrix
        scaled_query = query

    total = len(registry.players)
    # Ambil cukup banyak tetangga agar filter posisi/umur tetap menyisakan kandidat.
    n_neighbors = min(total, max(request.top_k * 10, 50))

    distances, indices = registry.knn.kneighbors(scaled_query, n_neighbors=n_neighbors)
    return [
        (int(index), float(distance))
        for index, distance in zip(indices[0], distances[0])
    ]


def _rank_with_numpy(matrix: np.ndarray, query: np.ndarray) -> list[tuple[int, float]]:
    """Perhitungan cadangan: Euclidean pada fitur yang dinormalisasi 0-1."""
    scaled_matrix = matrix / 100.0
    scaled_query = query / 100.0
    distances = np.linalg.norm(scaled_matrix - scaled_query, axis=1)
    order = np.argsort(distances)
    return [(int(index), float(distances[index])) for index in order]
