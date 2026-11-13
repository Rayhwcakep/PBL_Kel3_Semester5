"""Membangun artefak backend dari hasil `ml/export_artifacts.py`.

Input  : `ml/export/` (players.csv, model_info.json, *.joblib)
Output : `backend/app/data/players.json`
         `backend/app/ml/artifacts/` (knn_models.joblib, value_models.joblib,
         model_info.json, feature_names.json, tactics.json)

Format `players.json` mengikuti skema 10 statistik per-90 (5 untuk kiper),
bukan 8 atribut gaya FIFA, karena hanya angka inilah yang benar-benar ada di
dataset FBref/Transfermarkt.

Pakai:

    python ml/build_backend_artifacts.py
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.pipeline import Pipeline


class WeightedScale(BaseEstimator, TransformerMixin):
    """Salinan kelas dari notebook, dibutuhkan agar `joblib.load` bisa membuka
    artefak hasil `ml/export_artifacts.py` (kelas tercatat sebagai `__main__`)."""

    def __init__(self, weights=None):
        self.weights = weights

    def fit(self, X, y=None):
        self.weights_ = np.asarray(self.weights, dtype=float)
        return self

    def transform(self, X):
        return np.asarray(X, dtype=float) * self.weights_


ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT / "ml" / "export"
BACKEND = ROOT / "backend" / "app"
DATA_DIR = BACKEND / "data"
ARTIFACT_DIR = BACKEND / "ml" / "artifacts"

# Kolom identitas pemain di players.csv yang diteruskan apa adanya.
PROFILE_COLS = {
    "uid": "id",
    "Player": "name",
    "Squad": "club",
    "Comp": "league",
    "sub_position": "position",
    "pos_group": "position_group",
    "arch": "archetype",
    "Age": "age",
    "Min": "minutes",
    "market_value_in_eur": "market_value_eur",
    "value_growth_1y": "value_growth_1y",
    "image_url": "image_url",
    "foot": "foot",
    "contract_expiration_date": "contract_until",
}

#: Variabel konteks yang dipakai model nilai pasar (bukan kemampuan bermain).
CONTEXT_COLS = ("start_rate", "plus_p90", "crd_p90")


def _clean(value):
    """Ubah NaN/NaT pandas menjadi None agar JSON tetap valid."""
    if value is None:
        return None
    if isinstance(value, float) and value != value:  # NaN
        return None
    if pd.isna(value):
        return None
    return value


def build_players(players_csv: Path, arch_features: dict[str, list[str]]) -> list[dict]:
    frame = pd.read_csv(players_csv)

    players: list[dict] = []
    for row in frame.to_dict(orient="records"):
        archetype = row.get("arch")
        if archetype not in arch_features:
            continue

        features = arch_features[archetype]
        stats = {
            feature: round(float(row[feature]), 4)
            for feature in features
            if feature in row and _clean(row[feature]) is not None
        }
        percentiles = {
            feature: round(float(row[f"pct_{feature}"]), 1)
            for feature in features
            if f"pct_{feature}" in row and _clean(row[f"pct_{feature}"]) is not None
        }

        player = {target: _clean(row.get(source)) for source, target in PROFILE_COLS.items()}
        player["id"] = str(int(row["uid"]))
        player["stats"] = stats
        player["percentiles"] = percentiles
        player["context"] = {
            key: round(float(row[key]), 6)
            for key in CONTEXT_COLS
            if key in row and _clean(row[key]) is not None
        }
        players.append(player)

    players.sort(key=lambda item: int(item["id"]))
    return players


def _write_portable_knn(source: Path, target: Path) -> None:
    """Ubah bundel KNN agar bisa dimuat proses Python mana pun.

    Pipeline di notebook memakai kelas `WeightedScale` buatan sendiri. Saat
    di-`joblib.dump`, kelas itu tercatat sebagai `__main__.WeightedScale` -
    hanya bisa dimuat oleh script yang mendefinisikannya. Di sini bobot
    dipisahkan menjadi array biasa, sehingga artefak hanya memuat kelas
    scikit-learn.
    """
    bundle = joblib.load(source)
    portable: dict[str, dict] = {}

    for archetype, model in bundle["models"].items():
        steps = list(model["prep"].steps)
        weights = np.ones(len(model["features"]), dtype=float)

        if steps and isinstance(steps[-1][1], WeightedScale):
            weights = np.asarray(steps[-1][1].weights_, dtype=float)
            steps = steps[:-1]

        # Buang nama kolom yang tersimpan saat fit: kalau tidak, transform dengan
        # numpy array memunculkan peringatan scikit-learn di runtime.
        for _, step in steps:
            if hasattr(step, "feature_names_in_"):
                del step.feature_names_in_

        portable[archetype] = {
            "prep": Pipeline(steps),
            "nn": model["nn"],
            "features": list(model["features"]),
            "uids": np.asarray(model["uids"], dtype=int),
            "weights": weights,
            "n": int(model["n"]),
        }

    joblib.dump(
        {
            "models": portable,
            "arch_feats": bundle.get("arch_feats", {}),
            "weights": bundle.get("weights", {}),
            "min_minutes": bundle.get("min_minutes"),
        },
        target,
    )


def main() -> None:
    if not EXPORT.exists():
        raise SystemExit(
            "ml/export/ belum ada. Jalankan dulu: python ml/export_artifacts.py"
        )

    info = json.loads((EXPORT / "model_info.json").read_text(encoding="utf-8"))
    arch_features: dict[str, list[str]] = info["arch_features"]
    labels: dict[str, str] = info["labels"]
    good_dir: dict[str, int] = info["good_dir"]

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    # 1) Profil pemain + statistik per-90 + persentil.
    players = build_players(EXPORT / "players.csv", arch_features)
    payload = {
        "count": len(players),
        "archetypes": sorted(arch_features),
        "players": players,
    }
    (DATA_DIR / "players.json").write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

    # 2) Model KNN + model nilai pasar (SHAP memakai yang ini saat startup).
    _write_portable_knn(EXPORT / "knn_models.joblib", ARTIFACT_DIR / "knn_models.joblib")
    shutil.copyfile(EXPORT / "value_models.joblib", ARTIFACT_DIR / "value_models.joblib")

    # 3) Metadata fitur per arketipe: urutan kolom menyesuaikan Flutter & SHAP.
    feature_names = {
        "archetypes": arch_features,
        "labels": labels,
        "good_dir": good_dir,
        "weakness_ok": info["weakness_ok"],
        "min_effect": info["min_effect"],
        "min_pct_gap": info["min_pct_gap"],
        "feature_weights": info["feature_weights"],
        "hexagon_axes": info["hexagon_axes"],
    }
    (ARTIFACT_DIR / "feature_names.json").write_text(
        json.dumps(feature_names, ensure_ascii=False, indent=1), encoding="utf-8"
    )

    # 4) Preset taktik + label arketipe.
    tactics = {
        "labels": info["arch_label"],
        "presets": info["tactics"],
        "value_models": info["value_models"],
    }
    (ARTIFACT_DIR / "tactics.json").write_text(
        json.dumps(tactics, ensure_ascii=False, indent=1), encoding="utf-8"
    )

    # 5) Salinan konfigurasi lengkap untuk keperluan audit.
    (ARTIFACT_DIR / "model_info.json").write_text(
        json.dumps(info, ensure_ascii=False, indent=1), encoding="utf-8"
    )

    size_kb = sum(p.stat().st_size for p in ARTIFACT_DIR.glob("*")) / 1024
    print(f"players.json      : {len(players):5d} pemain, "
          f"{(DATA_DIR / 'players.json').stat().st_size / 1024:8.0f} KB")
    print(f"artefak model     : {size_kb:8.0f} KB di {ARTIFACT_DIR.relative_to(ROOT)}")
    for archetype, features in sorted(arch_features.items()):
        count = sum(1 for p in players if p["archetype"] == archetype)
        print(f"  {archetype:3s} {count:5d} pemain, {len(features)} fitur")


if __name__ == "__main__":
    main()
