"""Penjelasan SHAP untuk satu pemain.

SHAP dipakai pada **model nilai pasar** (Gradient Boosting kedalaman 1, jadi
aditif): yang dijelaskan adalah "pasar menghargai apa dari pemain ini", bukan
kebenaran mutlak. Karena itu verdict selalu diberi pagar:

- harus searah logika sepak bola (`good_dir`),
- selisih persentil minimal `min_pct_gap` dari median arketipe,
- "kekurangan" hanya untuk statistik yang memang tugas inti arketipe.

Pagar ini port dari notebook (Langkah 10) supaya API tidak bisa mengeluarkan
kalimat yang bertentangan dengan logika permainan.
"""

from __future__ import annotations

from typing import Any

import numpy as np
import shap

from app.services.model_registry import ModelRegistry


class ExplainService:
    """Menyimpan explainer per arketipe dan menghitung tabel penilaian."""

    def __init__(self, registry: ModelRegistry) -> None:
        self.registry = registry
        self.metadata = registry.metadata
        self._explainers: dict[str, shap.TreeExplainer] = {}
        self._bases: dict[str, float] = {}

    # ------------------------------------------------------------------
    def _explainer(self, archetype: str) -> tuple[shap.TreeExplainer, float]:
        model = self.registry.archetypes[archetype]
        if model.value is None:
            raise KeyError(f"arketipe '{archetype}' tidak punya model nilai pasar")
        if archetype not in self._explainers:
            explainer = shap.TreeExplainer(model.value.model)
            self._explainers[archetype] = explainer
            self._bases[archetype] = float(np.ravel(explainer.expected_value)[0])
        return self._explainers[archetype], self._bases[archetype]

    # ------------------------------------------------------------------
    def contributions(self, player: dict[str, Any]) -> tuple[dict[str, float], float]:
        """Kontribusi SHAP per kolom model + base value (log nilai pasar)."""
        model = self.registry.model_for(player)
        explainer, base = self._explainer(model.key)
        vector = self.registry.value_vector(player)
        values = np.ravel(np.asarray(explainer.shap_values(vector)))
        cols = model.value.cols if model.value is not None else []

        by_col = {col: float(values[index]) for index, col in enumerate(cols)}
        # 15+ kolom liga digabung jadi satu faktor "liga".
        league_total = sum(value for col, value in by_col.items() if col.startswith("lg_"))
        by_col["ctx_liga"] = league_total
        return by_col, base

    # ------------------------------------------------------------------
    def table(self, player: dict[str, Any]) -> list[dict[str, Any]]:
        """Tabel penilaian tiap statistik: nilai, persentil, SHAP, verdict."""
        model = self.registry.model_for(player)
        metadata = self.metadata
        phi_map, _ = self.contributions(player)
        core = set(metadata.weakness_features(model.key))

        rows: list[dict[str, Any]] = []
        for feature in model.features:
            phi = float(phi_map.get(feature, 0.0))
            pct = float(player["percentiles"].get(feature, 50.0))
            good_dir = metadata.good_dir.get(feature, 0)
            effect = float(np.exp(phi) - 1.0)
            gap = good_dir * (pct - 50.0)
            better = pct if good_dir >= 0 else 100.0 - pct

            if abs(effect) < metadata.min_effect or good_dir == 0:
                verdict = "netral"
            elif phi > 0 and good_dir > 0 and gap >= metadata.min_pct_gap:
                verdict = "kelebihan"
            elif phi < 0 and gap <= -metadata.min_pct_gap:
                verdict = "kekurangan" if feature in core else "netral"
            else:
                verdict = "diabaikan"

            rows.append(
                {
                    "feature": feature,
                    "label": metadata.label(feature),
                    "value": float(player["stats"].get(feature, 0.0)),
                    "percentile": pct,
                    "better_than_pct": better,
                    "shap_value": phi,
                    "effect_pct": round(effect * 100.0, 2),
                    "verdict": verdict,
                }
            )
        return rows

    # ------------------------------------------------------------------
    def context(self, player: dict[str, Any]) -> list[dict[str, Any]]:
        """Pengaruh variabel konteks (usia, menit, starter, plus/minus, liga)."""
        phi_map, _ = self.contributions(player)
        labels = self.metadata.context_labels
        rows: list[dict[str, Any]] = []
        for key in ("Age", "Min", "start_rate", "plus_p90", "ctx_liga"):
            if key not in phi_map:
                continue
            effect = float(np.exp(phi_map[key]) - 1.0)
            rows.append(
                {
                    "feature": key,
                    "label": labels.get(key, key),
                    "value": 0.0,
                    "percentile": 0.0,
                    "better_than_pct": 0.0,
                    "shap_value": float(phi_map[key]),
                    "effect_pct": round(effect * 100.0, 2),
                    "verdict": "konteks",
                }
            )
        return rows

    # ------------------------------------------------------------------
    def detail(self, player: dict[str, Any]) -> dict[str, Any]:
        """Paket penjelasan siap kirim ke aplikasi."""
        model = self.registry.model_for(player)
        rows = self.table(player)
        _, base = self.contributions(player)

        strengths = sorted(
            (row for row in rows if row["verdict"] == "kelebihan"),
            key=lambda row: abs(row["effect_pct"]),
            reverse=True,
        )
        weaknesses = sorted(
            (row for row in rows if row["verdict"] == "kekurangan"),
            key=lambda row: abs(row["effect_pct"]),
            reverse=True,
        )

        value = model.value
        return {
            "player": {
                **player,
                "reliability": value.reliability if value else None,
                "r2_test": round(value.r2_test, 3) if value else None,
                "base_value_eur": round(value.base_value_eur) if value else None,
            },
            "strengths": strengths,
            "weaknesses": weaknesses,
            "context": self.context(player),
            "summary": self._summary(player, strengths, weaknesses),
        }

    def _summary(
        self,
        player: dict[str, Any],
        strengths: list[dict[str, Any]],
        weaknesses: list[dict[str, Any]],
    ) -> str:
        model = self.registry.model_for(player)
        metadata = self.metadata
        value = model.value

        def format_part(rows: list[dict[str, Any]]) -> str:
            if not rows:
                return "tidak ada yang menonjol"
            return ", ".join(f"{row['label']} ({row['effect_pct']:+.0f}%)" for row in rows[:2])

        value_eur = player.get("market_value_eur")
        value_text = f"€{value_eur / 1e6:.1f} jt" if value_eur else "nilai pasar tidak tersedia"
        age = player.get("age")
        age_text = f"{age:.0f} tahun" if age else "umur tidak diketahui"

        return (
            f"{player['name']} ({metadata.archetype_label(model.key)}, {age_text}, {value_text}). "
            f"Kelebihan: {format_part(strengths)}. "
            f"Kekurangan: {format_part(weaknesses)}."
            + (
                f" Keandalan model nilai pasar: {value.reliability} (R² uji {value.r2_test:.2f})."
                if value
                else ""
            )
        )
