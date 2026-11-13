"""Pemuatan dataset pemain dan artefak model.

Artefak dihasilkan oleh `ml/export_artifacts.py` + `ml/build_backend_artifacts.py`
dan disimpan di `backend/app/ml/artifacts/`:

- ``knn_models.joblib``  -> pipeline KNN per arketipe (log1p + StandardScaler +
  bobot fitur + NearestNeighbors)
- ``value_models.joblib`` -> model nilai pasar per arketipe (dipakai SHAP)
- ``feature_names.json``  -> metadata statistik, arah logika, bobot
- ``tactics.json``        -> preset taktik per arketipe

Dataset pemain ada di ``backend/app/data/players.json``. Semua model KNN bersifat
*transductive*: tidak ada training saat request, hanya jarak antar pemain.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import numpy as np

from app.core.config import Settings, get_settings
from app.services.features import Metadata, load_metadata


@dataclass
class ValueModel:
    """Model nilai pasar satu arketipe beserta konteksnya."""

    model: Any
    cols: list[str]
    base_log: float
    reliability: str
    r2_test: float
    n: int

    @property
    def base_value_eur(self) -> float:
        return float(np.exp(self.base_log))


@dataclass
class ArchetypeModel:
    """Semua yang dibutuhkan untuk membandingkan satu arketipe."""

    key: str
    features: list[str]
    prep: Any
    weights: np.ndarray
    knn: Any
    uids: np.ndarray
    stats: np.ndarray
    z: np.ndarray
    d_ref: float
    row_of: dict[int, int] = field(default_factory=dict)
    value: ValueModel | None = None

    def row(self, uid: int) -> int:
        return self.row_of[int(uid)]

    @property
    def n(self) -> int:
        return len(self.uids)

    def similarity(self, distance: float) -> float:
        """Jarak -> skor 0-100; 50 berarti sejauh pasangan pemain pada umumnya."""
        return float(100.0 * np.exp(-distance / max(self.d_ref, 1e-9)))


class ModelRegistry:
    """Menyimpan dataset pemain dan artefak model yang sudah dimuat."""

    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()
        self.metadata: Metadata | None = None
        self.players: list[dict[str, Any]] = []
        self.by_id: dict[int, dict[str, Any]] = {}
        self.archetypes: dict[str, ArchetypeModel] = {}
        self.load_errors: list[str] = []

    # ------------------------------------------------------------------
    # Status
    # ------------------------------------------------------------------
    @property
    def knn_ready(self) -> bool:
        return bool(self.archetypes)

    @property
    def shap_ready(self) -> bool:
        return bool(self.archetypes) and all(m.value is not None for m in self.archetypes.values())

    @property
    def ready(self) -> bool:
        return self.knn_ready and bool(self.players)

    # ------------------------------------------------------------------
    # Pemuatan
    # ------------------------------------------------------------------
    def load(self) -> None:
        """Memuat dataset dan artefak. Dipanggil sekali saat startup."""
        self._load_metadata()
        self._load_players()
        self._load_models()

    def _load_metadata(self) -> None:
        try:
            self.metadata = load_metadata(self.settings.artifacts_path)
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as error:
            self.load_errors.append(f"metadata: {error}")
            self.metadata = None

    def _load_players(self) -> None:
        path = self.settings.players_path
        if not path.exists():
            self.load_errors.append(f"dataset pemain tidak ditemukan: {path}")
            return

        with path.open(encoding="utf-8") as handle:
            payload = json.load(handle)

        players = payload["players"] if isinstance(payload, dict) else payload
        self.players = [self._normalise_player(item) for item in players]
        self.players.sort(key=lambda item: int(item["id"]))
        self.by_id = {int(item["id"]): item for item in self.players}

    @staticmethod
    def _normalise_player(item: dict[str, Any]) -> dict[str, Any]:
        """Pastikan semua angka berbentuk float/int Python (bukan NaN)."""
        player = dict(item)
        player["stats"] = {
            key: float(value) for key, value in (item.get("stats") or {}).items()
        }
        player["percentiles"] = {
            key: float(value) for key, value in (item.get("percentiles") or {}).items()
        }
        player["context"] = {
            key: float(value) for key, value in (item.get("context") or {}).items()
        }
        return player

    def _load_models(self) -> None:
        if self.metadata is None:
            return

        knn_bundle = self._load_joblib(self.settings.artifacts_path / "knn_models.joblib")
        value_bundle = self._load_joblib(self.settings.artifacts_path / "value_models.joblib")
        if knn_bundle is None:
            self.load_errors.append("knn_models.joblib tidak bisa dimuat")
            return

        models = knn_bundle.get("models", {})
        value_models = (value_bundle or {}).get("value_models", {})
        bases = (value_bundle or {}).get("base", {})

        for key, bundle in models.items():
            uids = np.asarray([int(uid) for uid in bundle["uids"]], dtype=int)
            features = [str(name) for name in bundle["features"]]

            rows: list[list[float]] = []
            for uid in uids:
                player = self.by_id.get(int(uid))
                stats = (player or {}).get("stats", {})
                rows.append([float(stats.get(name, 0.0)) for name in features])
            stats_matrix = np.asarray(rows, dtype=float)

            weights = np.asarray(bundle.get("weights", np.ones(len(features))), dtype=float)
            z = np.asarray(bundle["prep"].transform(stats_matrix), dtype=float) * weights

            value = None
            if key in value_models:
                info = value_models[key]
                value = ValueModel(
                    model=info["model"],
                    cols=[str(col) for col in info["cols"]],
                    base_log=float(bases.get(key, 0.0)),
                    reliability=str(info.get("reliability", "cukup")),
                    r2_test=float(info.get("r2_test", 0.0)),
                    n=int(info.get("n", len(uids))),
                )

            self.archetypes[key] = ArchetypeModel(
                key=key,
                features=features,
                prep=bundle["prep"],
                weights=weights,
                knn=bundle["nn"],
                uids=uids,
                stats=stats_matrix,
                z=z,
                d_ref=_typical_distance(z),
                row_of={int(uid): index for index, uid in enumerate(uids)},
                value=value,
            )

    @staticmethod
    def _load_joblib(path: Path) -> dict[str, Any] | None:
        if not path.exists():
            return None
        try:
            import joblib
        except ImportError as error:  # pragma: no cover - joblib ada di requirements
            raise RuntimeError("joblib tidak terpasang") from error
        try:
            return joblib.load(path)
        except Exception as error:  # noqa: BLE001 - artefak rusak tidak boleh mematikan API
            raise RuntimeError(f"gagal memuat {path.name}: {error}") from error

    # ------------------------------------------------------------------
    # Akses data
    # ------------------------------------------------------------------
    def find_player(self, player_id: str | int) -> dict[str, Any] | None:
        try:
            return self.by_id.get(int(player_id))
        except (TypeError, ValueError):
            return None

    def model_for(self, player: dict[str, Any]) -> ArchetypeModel:
        archetype = player["archetype"]
        model = self.archetypes.get(archetype)
        if model is None:
            raise KeyError(f"arketipe '{archetype}' tidak punya model")
        return model

    def players_in(self, archetype: str) -> list[dict[str, Any]]:
        return [player for player in self.players if player["archetype"] == archetype]

    def value_vector(self, player: dict[str, Any]) -> np.ndarray:
        """Vektor input model nilai pasar, mengikuti urutan `ValueModel.cols`."""
        model = self.model_for(player)
        value = model.value
        if value is None:
            raise KeyError(f"arketipe '{model.key}' tidak punya model nilai pasar")

        league = player.get("league") or ""
        context = player.get("context", {})
        by_name: dict[str, float] = {
            **{key: float(value_) for key, value_ in player["stats"].items()},
            "Age": float(player.get("age") or 0),
            "Min": float(player.get("minutes") or 0),
            "start_rate": float(context.get("start_rate", 0.0)),
            "plus_p90": float(context.get("plus_p90", 0.0)),
            "crd_p90": float(context.get("crd_p90", 0.0)),
        }

        vector = []
        for col in value.cols:
            if col.startswith("lg_"):
                league_name = col[3:].replace("_", " ")
                vector.append(1.0 if league == league_name else 0.0)
            else:
                vector.append(float(by_name.get(col, 0.0)))
        return np.asarray([vector], dtype=float)

    def value_matrix(self, model: ArchetypeModel) -> np.ndarray:
        """Matriks input model nilai pasar untuk semua pemain arketipe ini."""
        if model.value is None:
            return np.empty((0, 0), dtype=float)
        rows = [self.value_vector(self.by_id[int(uid)])[0] for uid in model.uids]
        return np.asarray(rows, dtype=float)

    def league_cols(self) -> list[str]:
        for model in self.archetypes.values():
            if model.value is not None:
                return [col for col in model.value.cols if col.startswith("lg_")]
        return []


def archetype_of(player: dict[str, Any]) -> str:
    return str(player.get("archetype", "-"))


def _typical_distance(z: np.ndarray) -> float:
    """Median jarak antar pemain: patokan skor 50 pada kemiripan."""
    if len(z) < 2:
        return 1.0
    squared = np.sum(z**2, axis=1)
    d2 = squared[:, None] + squared[None, :] - 2.0 * (z @ z.T)
    np.fill_diagonal(d2, np.nan)
    median = float(np.nanmedian(np.sqrt(np.maximum(d2, 0.0))))
    return median if median > 0 else 1.0


_registry: ModelRegistry | None = None


def get_registry() -> ModelRegistry:
    """Singleton registry. Muat otomatis saat pertama kali diakses."""
    global _registry
    if _registry is None:
        _registry = ModelRegistry()
        _registry.load()
    return _registry


def reset_registry() -> None:
    """Kosongkan singleton (dipakai uji)."""
    global _registry
    _registry = None
