"""Perbandingan dua pemain.

Memakai dua sumber sekaligus (port notebook, Langkah 13):

1. **Atribusi jarak KNN** -> apa yang membuat mereka mirip dan apa pembedanya.
2. **Selisih SHAP nilai pasar** -> dari sudut pandang pasar, siapa lebih
   dihargai dan karena statistik apa.

Supaya tidak menyesatkan, hasilnya dipisah: "unggul (model & angka sepakat)"
vs "unggul secara angka saja" vs "beda angka tapi arah model berlawanan".
Persentil sengaja **tidak** dipakai sebagai syarat, karena pemain elit
menumpuk di 96-100 sehingga selisih besar terlihat kecil.
"""

from __future__ import annotations

from typing import Any

import numpy as np

from app.services.distance import contributions, transform_vector
from app.services.explain_service import ExplainService
from app.services.model_registry import ModelRegistry

#: Selisih angka mentah minimal agar sebuah statistik dianggap berbeda.
MIN_REL_DIFF = 0.10
#: Di atas ini, perbedaan angka dianggap besar (dipakai label "tidak didukung model").
RAW_DIFF = 0.20


def compare(
    registry: ModelRegistry,
    explain: ExplainService,
    player_a: dict[str, Any],
    player_b: dict[str, Any],
    top: int = 3,
) -> dict[str, Any]:
    metadata = registry.metadata
    same_archetype = player_a["archetype"] == player_b["archetype"]

    if not same_archetype:
        return _compare_across_archetypes(registry, player_a, player_b, top)

    model = registry.model_for(player_a)
    index_a = model.row(int(player_a["id"]))
    index_b = model.row(int(player_b["id"]))
    table = contributions(model, model.z[index_a], model.z[index_b])

    phi_a, _ = explain.contributions(player_a)
    phi_b, _ = explain.contributions(player_b)

    rows: list[dict[str, Any]] = []
    for position, feature in enumerate(model.features):
        value_a = float(player_a["stats"].get(feature, 0.0))
        value_b = float(player_b["stats"].get(feature, 0.0))
        pct_a = float(player_a["percentiles"].get(feature, 50.0))
        pct_b = float(player_b["percentiles"].get(feature, 50.0))
        good_dir = metadata.good_dir.get(feature, 0)

        gap_pct = pct_a - pct_b
        gap_good = gap_pct if good_dir >= 0 else -gap_pct
        d_phi = float(phi_a.get(feature, 0.0) - phi_b.get(feature, 0.0))
        rel_diff = abs(value_a - value_b) / max(abs(value_a), abs(value_b), 1e-9)

        if good_dir == 0 or rel_diff < MIN_REL_DIFF:
            winner = "seimbang"
        else:
            raw_better = good_dir * (value_a - value_b)
            if raw_better > 0 and d_phi > 0:
                winner = "A"
            elif raw_better < 0 and d_phi < 0:
                winner = "B"
            elif rel_diff >= RAW_DIFF:
                winner = "tidak didukung model"
            else:
                winner = "seimbang"

        rows.append(
            {
                "feature": feature,
                "label": metadata.label(feature),
                "a": value_a,
                "b": value_b,
                "pct_a": pct_a,
                "pct_b": pct_b,
                "gap_pct": gap_pct,
                "gap_good": gap_good,
                "winner": winner,
                "rel_diff": rel_diff,
                "d_effect": float(np.exp(d_phi) - 1.0),
                "_contrib": float(table["contrib"][position]),
            }
        )

    rows.sort(key=lambda row: row["_contrib"], reverse=True)
    distance = float(table["distance"])
    rank_b = _neighbor_rank(model, index_a, index_b)

    a_better = [row for row in rows if row["winner"] == "A"][:top]
    b_better = [row for row in rows if row["winner"] == "B"][:top]
    raw_only = [row for row in rows if row["winner"] == "tidak didukung model"][:top]

    return {
        "a": player_a,
        "b": player_b,
        "same_archetype": True,
        "warning": None,
        "similarity": model.similarity(distance),
        "neighbor_rank": rank_b,
        "rows": [_strip(row) for row in rows],
        "a_better": [_strip(row) for row in a_better],
        "b_better": [_strip(row) for row in b_better],
        "raw_only": [_strip(row) for row in raw_only],
        "summary": _summary(player_a, player_b, a_better, b_better, raw_only, rows),
    }


def _strip(row: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in row.items() if not key.startswith("_")}


def _neighbor_rank(model, index_a: int, index_b: int) -> int:
    """Peringkat B ketika mencari tetangga dari A (0 = A sendiri)."""
    squared = np.sum((model.z - model.z[index_a]) ** 2, axis=1)
    order = np.argsort(squared)
    return int(np.where(order == index_b)[0][0])


def _compare_across_archetypes(
    registry: ModelRegistry,
    player_a: dict[str, Any],
    player_b: dict[str, Any],
    top: int,
) -> dict[str, Any]:
    """Beda arketipe: tidak ada model bersama, jadi dibandingkan lewat persentil."""
    metadata = registry.metadata
    shared = [
        feature
        for feature in metadata.archetypes[player_a["archetype"]]
        if feature in player_b["percentiles"]
    ]

    rows: list[dict[str, Any]] = []
    for feature in shared:
        pct_a = float(player_a["percentiles"].get(feature, 50.0))
        pct_b = float(player_b["percentiles"].get(feature, 50.0))
        good_dir = metadata.good_dir.get(feature, 0)
        gap_pct = pct_a - pct_b
        rows.append(
            {
                "feature": feature,
                "label": metadata.label(feature),
                "a": float(player_a["stats"].get(feature, 0.0)),
                "b": float(player_b["stats"].get(feature, 0.0)),
                "pct_a": pct_a,
                "pct_b": pct_b,
                "gap_pct": gap_pct,
                "gap_good": gap_pct if good_dir >= 0 else -gap_pct,
                "winner": "seimbang",
                "rel_diff": abs(pct_a - pct_b) / 100.0,
                "d_effect": 0.0,
            }
        )

    rows.sort(key=lambda row: row["rel_diff"])
    a_side = sorted(rows, key=lambda row: row["gap_good"], reverse=True)[:top]
    b_side = sorted(rows, key=lambda row: row["gap_good"])[:top]

    return {
        "a": player_a,
        "b": player_b,
        "same_archetype": False,
        "warning": (
            "Arketipe berbeda: tidak ada model KNN bersama, jadi perbandingan memakai "
            "persentil dan harus ditafsirkan hati-hati."
        ),
        "similarity": None,
        "neighbor_rank": None,
        "rows": rows,
        "a_better": a_side if a_side and a_side[0]["gap_good"] > 0 else [],
        "b_better": b_side if b_side and b_side[0]["gap_good"] < 0 else [],
        "raw_only": [],
        "summary": (
            f"{player_a['name']} ({metadata.archetype_label(player_a['archetype'])}) vs "
            f"{player_b['name']} ({metadata.archetype_label(player_b['archetype'])}): "
            "beda arketipe, jadi hanya persentil yang bisa dibandingkan."
        ),
    }


def _summary(
    player_a: dict[str, Any],
    player_b: dict[str, Any],
    a_better: list[dict[str, Any]],
    b_better: list[dict[str, Any]],
    raw_only: list[dict[str, Any]],
    rows: list[dict[str, Any]],
) -> str:
    name_a, name_b = player_a["name"], player_b["name"]

    def describe(items: list[dict[str, Any]]) -> str:
        return ", ".join(
            f"{row['label']} ({row['rel_diff']:.0%} selisih, dorongan nilai {row['d_effect']:+.0%})"
            for row in items
        )

    parts: list[str] = []
    if a_better:
        parts.append(f"{name_a} unggul dan didukung model nilai pasar di: {describe(a_better)}.")
    if b_better:
        parts.append(f"{name_b} unggul dan didukung model nilai pasar di: {describe(b_better)}.")
    if raw_only:
        parts.append(
            "Ada selisih angka besar yang arahnya berlawanan dengan model nilai pasar "
            f"({describe(raw_only)}) - jangan disebut sebagai keunggulan mutlak."
        )
    if not a_better and not b_better:
        parts.append(
            "Tidak ada statistik yang selisih angka >= 10% sekaligus didukung model nilai pasar. "
            "Keduanya bisa dibilang selevel menurut model."
        )
    return " ".join(parts)
