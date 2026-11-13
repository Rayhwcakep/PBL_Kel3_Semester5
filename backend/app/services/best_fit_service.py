"""Rekomendasi pengganti (best-fit).

Alur (port notebook, Langkah 14):

1. KNN mengambil kandidat paling mirip (pool 40).
2. SHAP menentukan apa yang penting: kekurangan jadi **kebutuhan**, kelebihan
   jadi **yang harus dipertahankan**.
3. Tiap kandidat dinilai dengan selisih persentil di statistik itu:

       perbaikan bersih = (kebutuhan yang ditutup) - (kelebihan yang dikorbankan)
       skor fit         = campuran kemiripan KNN dan perbaikan bersih

Hanya selisih >= `min_pct_gap` yang dihitung, supaya selisih kecil tidak
dibesar-besarkan.
"""

from __future__ import annotations

from typing import Any, Iterable

import numpy as np

from app.schemas.scouting import PlayerFilter
from app.services.explain_service import ExplainService
from app.services.knn_service import neighbors
from app.services.model_registry import ModelRegistry

#: Ukuran pool kandidat dari KNN sebelum diskor.
POOL_SIZE = 40


def best_fit(
    registry: ModelRegistry,
    explain: ExplainService,
    player: dict[str, Any],
    request: PlayerFilter,
    top_k: int,
    needs: Iterable[str] | None = None,
    improve_weight: float = 0.5,
) -> dict[str, Any]:
    metadata = registry.metadata
    model = registry.model_for(player)

    detail = explain.detail(player)
    weakness_rows = detail["weaknesses"]
    strength_rows = detail["strengths"]

    if needs:
        wanted = [str(name) for name in needs]
        unknown = [name for name in wanted if name not in model.features]
        if unknown:
            raise ValueError(
                f"kebutuhan {unknown} tidak valid untuk arketipe {model.key}. "
                f"Pilihan: {model.features}"
            )
        need_map = {name: 1.0 for name in wanted}
    else:
        # Kekurangan dipakai sebagai kebutuhan; bobot = besarnya dorongan SHAP.
        need_map = {row["feature"]: abs(row["shap_value"]) for row in weakness_rows}

    keep_map = {row["feature"]: abs(row["shap_value"]) for row in strength_rows}

    pool = neighbors(registry, model, int(player["id"]), POOL_SIZE, request)
    if not pool:
        return {
            "player": player,
            "needs": need_map,
            "keep": keep_map,
            "candidates": [],
        }

    def good(value_pct: float, feature: str) -> float:
        return value_pct if metadata.good_dir.get(feature, 0) >= 0 else 100.0 - value_pct

    def weighted_change(candidate: dict[str, Any], weights: dict[str, float], sign: int) -> float:
        total = sum(weights.values())
        if not total:
            return 0.0
        score = 0.0
        for feature, weight in weights.items():
            delta = sign * (
                good(candidate["percentiles"].get(feature, 50.0), feature)
                - good(player["percentiles"].get(feature, 50.0), feature)
            )
            if delta >= metadata.min_pct_gap:
                score += weight * delta
        return score / total / 100.0

    candidates: list[dict[str, Any]] = []
    for uid, distance, _rank in pool:
        candidate = registry.by_id[uid]
        gain = weighted_change(candidate, need_map, +1)
        loss = weighted_change(candidate, keep_map, -1)
        net = float(np.clip(0.5 + gain - loss, 0.0, 1.0))

        similarity = model.similarity(distance)
        weight = improve_weight if need_map else 0.0
        fit = 100.0 * ((1.0 - weight) * (similarity / 100.0) + weight * net)

        candidates.append(
            {
                "player": candidate,
                "similarity": similarity,
                "fit": round(fit, 1),
                "gain": round(gain, 4),
                "loss": round(loss, 4),
                "why": _why(candidate, player, need_map, keep_map, metadata, bool(need_map)),
            }
        )

    candidates.sort(key=lambda item: item["fit"], reverse=True)
    return {
        "player": player,
        "needs": need_map,
        "keep": keep_map,
        "candidates": candidates[:top_k],
    }


def _why(
    candidate: dict[str, Any],
    reference: dict[str, Any],
    needs: dict[str, float],
    keep: dict[str, float],
    metadata,
    has_needs: bool,
) -> str:
    if not has_needs:
        return "tidak ada kekurangan menonjol; diurutkan berdasarkan kemiripan"

    def good_pair(feature: str) -> tuple[float, float]:
        good_dir = metadata.good_dir.get(feature, 0)
        cand = candidate["percentiles"].get(feature, 50.0)
        ref = reference["percentiles"].get(feature, 50.0)
        if good_dir < 0:
            return 100.0 - cand, 100.0 - ref
        return cand, ref

    ups = []
    for feature in needs:
        cand_good, ref_good = good_pair(feature)
        delta = cand_good - ref_good
        if delta >= metadata.min_pct_gap:
            ups.append((metadata.label(feature), delta))
    downs = []
    for feature in keep:
        cand_good, ref_good = good_pair(feature)
        delta = ref_good - cand_good
        if delta >= metadata.min_pct_gap:
            downs.append((metadata.label(feature), delta))

    ups.sort(key=lambda item: item[1], reverse=True)
    downs.sort(key=lambda item: item[1], reverse=True)

    closing = ", ".join(f"{label} (+{delta:.0f})" for label, delta in ups[:3]) or "-"
    sacrificing = ", ".join(f"{label} (-{delta:.0f})" for label, delta in downs[:3]) or "-"
    return f"Menutup: {closing} | Mengorbankan: {sacrificing}"
