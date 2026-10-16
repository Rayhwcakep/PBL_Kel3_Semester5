"""Layanan penjelasan SHAP.

Bila kamu meletakkan ``model.joblib`` + ``explainer.joblib`` di folder
artefak, fungsi ini memakai penjelas SHAP milikmu. Jika belum, dipakai
perhitungan cadangan agar kontrak API tetap terpenuhi.

Cara membuat explainer (contoh, jalankan di notebook training):

```python
import joblib, shap
explainer = shap.Explainer(model, background_data)
joblib.dump(explainer, "app/ml/artifacts/explainer.joblib")
joblib.dump(model, "app/ml/artifacts/model.joblib")
```
"""

from __future__ import annotations

from typing import Any

import numpy as np

from app.schemas.scouting import ScoutRequest
from app.services.features import DEFAULT_FEATURE_VALUE
from app.services.model_registry import ModelRegistry, get_registry

# Bobot skala untuk perhitungan cadangan (agar mirip rentang SHAP).
_FALLBACK_SCALE = 0.35


def explain(
    player: dict[str, Any],
    request: ScoutRequest,
    base_value: float,
    prediction: float,
    registry: ModelRegistry | None = None,
) -> dict[str, Any]:
    """Membuat penjelasan kontribusi fitur untuk satu pemain."""
    registry = registry or get_registry()
    feature_names = registry.feature_names

    if registry.shap_ready:
        contributions = _explain_with_shap(
            player, request, feature_names, registry
        )
    else:
        contributions = _explain_fallback(player, request, feature_names)

    return {
        "player_id": player["id"],
        "base_value": float(base_value),
        "prediction": float(prediction),
        "contributions": contributions,
    }


def _explain_with_shap(
    player: dict[str, Any],
    request: ScoutRequest,
    feature_names: list[str],
    registry: ModelRegistry,
) -> list[dict[str, Any]]:
    vector = np.array(
        [[float(player["stats"].get(name, DEFAULT_FEATURE_VALUE)) for name in feature_names]],
        dtype=float,
    )
    if registry.scaler is not None:
        vector = registry.scaler.transform(vector)

    values = registry.explainer(vector).values
    values = np.ravel(np.asarray(values))

    contributions: list[dict[str, Any]] = []
    for index, name in enumerate(feature_names):
        contributions.append(
            {
                "feature": name,
                "value": float(player["stats"].get(name, DEFAULT_FEATURE_VALUE)),
                "shap_value": float(values[index]) if index < len(values) else 0.0,
            }
        )
    return contributions


def _explain_fallback(
    player: dict[str, Any],
    request: ScoutRequest,
    feature_names: list[str],
) -> list[dict[str, Any]]:
    """Cadangan: selisih pemain terhadap kriteria, diskalakan.

    Bukan SHAP sungguhan, hanya agar UI punya data sebelum model dipasang.
    """
    contributions: list[dict[str, Any]] = []
    for name in feature_names:
        player_value = float(player["stats"].get(name, DEFAULT_FEATURE_VALUE))
        target = float(request.criteria.get(name, DEFAULT_FEATURE_VALUE))
        diff = (player_value - target) / 100.0
        contributions.append(
            {
                "feature": name,
                "value": player_value,
                "shap_value": diff * _FALLBACK_SCALE,
            }
        )
    return contributions
