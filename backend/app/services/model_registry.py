"""Pemuatan dataset pemain dan artefak model ML.

Ini adalah **titik sambung** utama untuk model yang sudah kamu latih.

Letakkan file berikut di folder `app/ml/artifacts/` (lihat `app/ml/README.md`):

- ``scaler.joblib``      -> objek scaler (mis. ``sklearn.preprocessing.StandardScaler``)
- ``knn_model.joblib``   -> model KNN yang sudah di-``fit``
                            (``NearestNeighbors``, ``KNeighborsClassifier``, atau
                            ``KNeighborsRegressor``)
- ``model.joblib``       -> (opsional) model yang akan dijelaskan dengan SHAP
- ``explainer.joblib``   -> (opsional) objek ``shap.Explainer`` yang sudah dibuat
- ``feature_names.json`` -> (opsional) urutan nama fitur saat training

Bila artefak tidak ada, backend tetap berjalan memakai perhitungan cadangan
(``numpy``) sehingga kontrak API bisa diuji lebih dulu.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from app.core.config import Settings, get_settings
from app.services.features import DEFAULT_FEATURE_VALUE, FEATURE_KEYS


@dataclass
class ModelRegistry:
    """Menyimpan dataset pemain dan artefak model yang sudah dimuat."""

    settings: Settings = field(default_factory=get_settings)

    players: list[dict[str, Any]] = field(default_factory=list)
    feature_names: list[str] = field(default_factory=lambda: list(FEATURE_KEYS))

    scaler: Any | None = None
    knn: Any | None = None
    model: Any | None = None
    explainer: Any | None = None

    @property
    def ml_ready(self) -> bool:
        """True bila model KNN milikmu berhasil dimuat."""
        return self.knn is not None

    @property
    def shap_ready(self) -> bool:
        """True bila penjelas SHAP milikmu berhasil dimuat."""
        return self.explainer is not None and self.model is not None

    def load(self) -> None:
        """Memuat dataset dan artefak. Panggil sekali saat startup."""
        self.players = self._load_players()
        self._load_artifacts()

    # ------------------------------------------------------------------
    # Dataset pemain
    # ------------------------------------------------------------------
    def _load_players(self) -> list[dict[str, Any]]:
        path = self.settings.players_path
        if not path.exists():
            return []
        with path.open(encoding="utf-8") as handle:
            data = json.load(handle)

        # Menerima dua bentuk: list langsung, atau {"players": [...]}.
        raw_players = data["players"] if isinstance(data, dict) else data

        players: list[dict[str, Any]] = []
        for item in raw_players:
            stats = {
                key: float(item.get("stats", {}).get(key, DEFAULT_FEATURE_VALUE))
                for key in FEATURE_KEYS
            }
            players.append(
                {
                    "id": str(item.get("id", "")),
                    "name": item.get("name", "Tanpa Nama"),
                    "club": item.get("club", "-"),
                    "position": item.get("position", "-"),
                    "age": int(item.get("age", 0)),
                    "stats": stats,
                }
            )
        return players

    def find_player(self, player_id: str) -> dict[str, Any] | None:
        for player in self.players:
            if player["id"] == player_id:
                return player
        return None

    # ------------------------------------------------------------------
    # Artefak model
    # ------------------------------------------------------------------
    def _load_artifacts(self) -> None:
        artifacts = self.settings.artifacts_path
        if not artifacts.exists():
            return

        self.feature_names = self._load_feature_names(artifacts)
        self.scaler = self._load_joblib(artifacts / "scaler.joblib")
        self.knn = self._load_joblib(artifacts / "knn_model.joblib")
        self.model = self._load_joblib(artifacts / "model.joblib")
        self.explainer = self._load_joblib(artifacts / "explainer.joblib")

    def _load_feature_names(self, artifacts: Path) -> list[str]:
        path = artifacts / "feature_names.json"
        if not path.exists():
            return list(FEATURE_KEYS)
        try:
            with path.open(encoding="utf-8") as handle:
                names = json.load(handle)
            if isinstance(names, list) and names:
                return [str(name) for name in names]
        except (json.JSONDecodeError, OSError):
            pass
        return list(FEATURE_KEYS)

    @staticmethod
    def _load_joblib(path: Path) -> Any | None:
        if not path.exists():
            return None
        try:
            import joblib  # diimpor lokal agar backend tetap jalan tanpa joblib
        except ImportError:
            return None
        try:
            return joblib.load(path)
        except Exception:  # noqa: BLE001 - artefak rusak tidak boleh mematikan API
            return None


_registry: ModelRegistry | None = None


def get_registry() -> ModelRegistry:
    """Singleton registry. Muat otomatis saat pertama kali diakses."""
    global _registry
    if _registry is None:
        _registry = ModelRegistry()
        _registry.load()
    return _registry
