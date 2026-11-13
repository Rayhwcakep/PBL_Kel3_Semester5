"""Atribusi jarak KNN dan skor kemiripan.

Jarak KNN dihitung pada ruang fitur yang sudah `log1p`, distandarkan, dan
dibobot per arketipe. Karena jarak kuadrat bersifat aditif per statistik,
kontribusi tiap statistik **eksak** (bukan aproksimasi Shapley):

    jarak²(A,B) = Σ_f (z_A,f − z_B,f)²

Dokumentasi lengkap ada di `scouting_knn_shap_colab.ipynb` (Langkah 7).
"""

from __future__ import annotations

from typing import Any

import numpy as np

from app.services.features import Metadata
from app.services.model_registry import ArchetypeModel


def contributions(
    model: ArchetypeModel,
    z_a: np.ndarray,
    z_b: np.ndarray,
    mask: np.ndarray | None = None,
) -> dict[str, Any]:
    """Pecah jarak antara dua vektor z menjadi kontribusi per statistik.

    `mask` (0/1) membatasi atribusi ke statistik yang diminta taktik; statistik
    lain tidak menarik jarak.
    """
    diff = np.asarray(z_a, dtype=float) - np.asarray(z_b, dtype=float)
    squared = diff**2
    if mask is not None:
        squared = squared * np.asarray(mask, dtype=float)

    total = float(squared.sum())
    shares = squared / total if total > 0 else squared
    return {
        "feature": list(model.features),
        "contrib": squared,
        "share": shares,
        "distance": float(np.sqrt(total)),
        "masked_distance": float(np.sqrt(total)),
    }


def transform_vector(model: ArchetypeModel, values: np.ndarray) -> np.ndarray:
    """Ubah satu vektor statistik mentah menjadi z yang dipakai KNN."""
    scaled = model.prep.transform(np.asarray([values], dtype=float))
    return np.asarray(scaled[0], dtype=float) * model.weights


def percentile_rank(column: np.ndarray, value: float) -> float:
    """Persentil sebuah nilai di antara kolom searketipe (0-100)."""
    column = np.asarray(column, dtype=float)
    if column.size == 0:
        return 50.0
    below = float(np.sum(column < value))
    equal = float(np.sum(column == value))
    return 100.0 * (below + 0.5 * equal) / column.size


def natural_from_percentile(column: np.ndarray, percentile: float) -> float:
    """Persentil target -> angka per-90 nyata (kuantil sebaran arketipe)."""
    return float(np.percentile(np.asarray(column, dtype=float), percentile))


def verdict(
    feature: str,
    pct_player: float,
    pct_target: float,
    metadata: Metadata,
    *,
    is_core: bool = True,
) -> str:
    """Verdict kecocokan terhadap target taktik (port dari notebook).

    "Kelebihan"/"Kekurangan" hanya untuk statistik yang **diminta tinggi**
    (target >= 60). Kalau taktik hanya minta rendah, penyimpangan disebut
    "beda profil" - bukan kelemahan.
    """
    good_dir = metadata.good_dir.get(feature, 0)
    if good_dir == 0 or not is_core:
        return "netral"

    player_good = pct_player if good_dir > 0 else 100.0 - pct_player
    target_good = pct_target if good_dir > 0 else 100.0 - pct_target
    delta = player_good - target_good
    gap = metadata.min_pct_gap

    if target_good >= 60:
        if delta >= gap:
            return "kelebihan"
        if delta <= -gap:
            return "kekurangan"
        return "sesuai"
    if target_good <= 40:
        return "beda profil" if delta >= gap else "sesuai"
    return "sesuai" if abs(delta) <= gap else "beda profil"


def fit_table(
    model: ArchetypeModel,
    player_vector: np.ndarray,
    target_vector: np.ndarray,
    pct_player: dict[str, float],
    pct_target: dict[str, float],
    metadata: Metadata,
    *,
    mask: np.ndarray | None = None,
) -> list[dict[str, Any]]:
    """Tabel atribusi jarak pemain terhadap profil target + verdict per statistik."""
    z_player = transform_vector(model, player_vector)
    z_target = transform_vector(model, target_vector)
    table = contributions(model, z_player, z_target, mask=mask)

    core = set(metadata.weakness_features(model.key))
    rows: list[dict[str, Any]] = []
    for index, feature in enumerate(model.features):
        p_player = float(pct_player.get(feature, 50.0))
        p_target = float(pct_target.get(feature, 50.0))
        good_dir = metadata.good_dir.get(feature, 0)
        player_good = p_player if good_dir >= 0 else 100.0 - p_player
        target_good = p_target if good_dir >= 0 else 100.0 - p_target
        rows.append(
            {
                "feature": feature,
                "label": metadata.label(feature),
                "value": float(player_vector[index]),
                "target_value": float(target_vector[index]),
                "pct_player": p_player,
                "pct_target": p_target,
                "good_player": player_good,
                "good_target": target_good,
                "delta_good": player_good - target_good,
                "contrib": float(table["contrib"][index]),
                "share": float(table["share"][index]),
                "verdict": verdict(feature, p_player, p_target, metadata, is_core=feature in core),
            }
        )
    rows.sort(key=lambda row: row["contrib"], reverse=True)
    return rows


def short_reason(rows: list[dict[str, Any]], limit: int = 2) -> str:
    """Ringkasan satu baris: apa yang lebih dan apa yang kurang dibanding target."""
    over = sorted(
        (row for row in rows if row["verdict"] == "kelebihan"),
        key=lambda row: row["delta_good"],
        reverse=True,
    )[:limit]
    under = sorted(
        (row for row in rows if row["verdict"] == "kekurangan"),
        key=lambda row: row["delta_good"],
    )[:limit]

    if not over and not under:
        return "sesuai target"

    parts: list[str] = []
    if over:
        parts.append("lebih: " + ", ".join(f"{row['label']} {row['delta_good']:+.0f}" for row in over))
    if under:
        parts.append("kurang: " + ", ".join(f"{row['label']} {row['delta_good']:+.0f}" for row in under))
    return " | ".join(parts)
