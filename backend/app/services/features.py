"""Metadata statistik dan arketipe, dibaca dari artefak hasil pipeline ML.

Berkas `backend/app/ml/artifacts/feature_names.json` adalah sumber kebenaran:
ia memberi tahu urutan statistik per arketipe, label Indonesia, arah logika
(`good_dir`), statistik yang boleh disebut kekurangan, dan bobot KNN.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any

#: Nilai default bila statistik tidak tersedia (sama dengan pipeline training).
DEFAULT_FEATURE_VALUE: float = 0.0

#: Ambang default bila artefak tidak membawa nilainya.
DEFAULT_MIN_EFFECT: float = 0.03
DEFAULT_MIN_PCT_GAP: float = 10.0

_CONTEXT_LABELS = {
    "Age": "Usia",
    "Min": "Menit main",
    "start_rate": "Rasio jadi starter",
    "plus_p90": "Plus/minus per 90",
    "crd_p90": "Kartu kuning per 90",
    "ctx_liga": "Liga",
}


@dataclass(frozen=True)
class FeatureSpec:
    """Satu statistik pada satu arketipe."""

    key: str
    label: str
    good_dir: int
    weight: float

    @property
    def invert(self) -> bool:
        return self.good_dir < 0


@dataclass
class Metadata:
    """Seluruh metadata yang dibutuhkan layanan lain."""

    archetypes: dict[str, list[str]]
    labels: dict[str, str]
    good_dir: dict[str, int]
    weakness_ok: dict[str, list[str]]
    weights: dict[str, dict[str, float]]
    hexagon_axes: dict[str, list[dict[str, Any]]]
    archetype_labels: dict[str, str]
    tactics: dict[str, dict[str, dict[str, Any]]]
    value_model_info: dict[str, dict[str, Any]]
    min_effect: float = DEFAULT_MIN_EFFECT
    min_pct_gap: float = DEFAULT_MIN_PCT_GAP

    def features(self, archetype: str) -> list[FeatureSpec]:
        weights = self.weights.get(archetype, {})
        return [
            FeatureSpec(
                key=key,
                label=self.labels.get(key, key),
                good_dir=self.good_dir.get(key, 0),
                weight=float(weights.get(key, 1.0)),
            )
            for key in self.archetypes[archetype]
        ]

    def feature_keys(self, archetype: str) -> list[str]:
        return list(self.archetypes[archetype])

    def label(self, key: str) -> str:
        return self.labels.get(key, key)

    def archetype_label(self, key: str) -> str:
        return self.archetype_labels.get(key, key)

    def weakness_features(self, archetype: str) -> list[str]:
        return list(self.weakness_ok.get(archetype, []))

    @property
    def context_labels(self) -> dict[str, str]:
        return dict(_CONTEXT_LABELS)


def _read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def load_metadata(artifacts_dir: Path) -> Metadata:
    """Memuat metadata dari folder artefak.

    `feature_names.json` berisi statistik + pagar logika; `tactics.json`
    berisi preset taktik dan label arketipe.
    """
    features = _read_json(artifacts_dir / "feature_names.json")
    tactics = _read_json(artifacts_dir / "tactics.json")

    return Metadata(
        archetypes={key: list(value) for key, value in features["archetypes"].items()},
        labels=dict(features["labels"]),
        good_dir={key: int(value) for key, value in features["good_dir"].items()},
        weakness_ok={key: list(value) for key, value in features["weakness_ok"].items()},
        weights={
            arch: {key: float(value) for key, value in weights.items()}
            for arch, weights in features.get("feature_weights", {}).items()
        },
        hexagon_axes=dict(features.get("hexagon_axes", {})),
        archetype_labels=dict(tactics.get("labels", {})),
        tactics=dict(tactics.get("presets", {})),
        value_model_info=dict(tactics.get("value_models", {})),
        min_effect=float(features.get("min_effect", DEFAULT_MIN_EFFECT)),
        min_pct_gap=float(features.get("min_pct_gap", DEFAULT_MIN_PCT_GAP)),
    )


@lru_cache(maxsize=1)
def get_cached_metadata(path: str) -> Metadata:
    return load_metadata(Path(path))
