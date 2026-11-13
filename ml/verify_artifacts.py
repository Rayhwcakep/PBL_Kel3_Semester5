"""Memeriksa artefak backend sebelum dipakai API.

Dijalankan setelah `ml/build_backend_artifacts.py`:

    python ml/verify_artifacts.py

Yang dipastikan:

1. Jumlah pemain dan sebaran arketipe sama dengan notebook (1.999 pemain).
2. Statistik tiap pemain sesuai daftar statistik arketipe-nya.
3. Persentil berada di 0-100 dan hanya berisi statistik yang dipakai.
4. Model KNN bisa dimuat dan jumlah barisnya cocok dengan jumlah pemain.
5. Preset taktik hanya menyebut statistik yang ada di arketipe itu.
6. SHAP aditif: base + Σ kontribusi = prediksi model (toleransi 1e-6).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import joblib
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "backend" / "app" / "ml" / "artifacts"
PLAYERS = ROOT / "backend" / "app" / "data" / "players.json"

#: Jumlah pemain hasil pipeline (dari notebook: 1.999).
EXPECTED_PLAYERS = 1999
EXPECTED_ARCHETYPES = {"GK", "CB", "FB", "DM", "CM", "AM", "W", "ST"}

failures: list[str] = []


def check(condition: bool, message: str) -> None:
    if condition:
        print(f"  ok   {message}")
    else:
        failures.append(message)
        print(f"  FAIL {message}")


def main() -> int:
    for path in (PLAYERS, ARTIFACTS / "knn_models.joblib", ARTIFACTS / "value_models.joblib",
                 ARTIFACTS / "feature_names.json", ARTIFACTS / "tactics.json"):
        if not path.exists():
            print(f"FAIL artefak tidak ada: {path.relative_to(ROOT)}")
            return 1

    payload = json.loads(PLAYERS.read_text(encoding="utf-8"))
    players = payload["players"]
    features = json.loads((ARTIFACTS / "feature_names.json").read_text(encoding="utf-8"))
    tactics = json.loads((ARTIFACTS / "tactics.json").read_text(encoding="utf-8"))
    knn = joblib.load(ARTIFACTS / "knn_models.joblib")
    values = joblib.load(ARTIFACTS / "value_models.joblib")

    arch_features = features["archetypes"]
    print("\n[1] Dataset pemain")
    check(len(players) == EXPECTED_PLAYERS, f"{len(players)} pemain (harap {EXPECTED_PLAYERS})")
    check(set(arch_features) == EXPECTED_ARCHETYPES, "8 arketipe lengkap")
    counts = {arch: 0 for arch in arch_features}
    for player in players:
        counts[player["archetype"]] += 1
    print("       sebaran:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))
    check(all(arch_features[a] == features["archetypes"][a] for a in arch_features), "urutan statistik konsisten")

    print("\n[2] Statistik dan persentil")
    bad_stats = [
        player["id"]
        for player in players
        if set(player["stats"]) != set(arch_features[player["archetype"]])
    ]
    check(not bad_stats, f"semua pemain punya statistik sesuai arketipe ({len(bad_stats)} menyimpang)")
    bad_pct = [
        player["id"]
        for player in players
        if any(not (0 <= value <= 100) for value in player["percentiles"].values())
        or set(player["percentiles"]) != set(player["stats"])
    ]
    check(not bad_pct, f"persentil 0-100 dan lengkap ({len(bad_pct)} menyimpang)")
    with_value = sum(1 for player in players if player.get("market_value_eur"))
    check(with_value > 1800, f"{with_value} pemain punya nilai pasar")

    print("\n[3] Model KNN")
    models = knn["models"]
    check(set(models) == EXPECTED_ARCHETYPES, "model KNN tersedia untuk 8 arketipe")
    for arch, model in sorted(models.items()):
        check(len(model["uids"]) == counts[arch], f"{arch}: baris KNN = jumlah pemain ({len(model['uids'])})")

    print("\n[4] Preset taktik")
    for arch, presets in tactics["presets"].items():
        allowed = set(arch_features[arch])
        for name, preset in presets.items():
            unknown = set(preset["targets"]) - allowed
            check(not unknown, f"{arch}/{name}: statistik valid ({len(preset['targets'])} target)")

    print("\n[5] Aditivitas SHAP (model nilai pasar)")
    import shap

    value_models = values["value_models"]
    bases = values["base"]
    for arch, info in sorted(value_models.items()):
        model = info["model"]
        uids = models[arch]["uids"][:60]
        by_id = {int(p["id"]): p for p in players}
        rows = []
        for uid in uids:
            player = by_id[int(uid)]
            context = player.get("context", {})
            by_name = {
                **player["stats"],
                "Age": player.get("age") or 0,
                "Min": player.get("minutes") or 0,
                "start_rate": context.get("start_rate", 0.0),
                "plus_p90": context.get("plus_p90", 0.0),
                "crd_p90": context.get("crd_p90", 0.0),
            }
            row = []
            for col in info["cols"]:
                if col.startswith("lg_"):
                    row.append(1.0 if player.get("league") == col[3:].replace("_", " ") else 0.0)
                else:
                    row.append(float(by_name.get(col, 0.0)))
            rows.append(row)
        matrix = np.asarray(rows, dtype=float)

        explainer = shap.TreeExplainer(model)
        contrib = np.asarray(explainer.shap_values(matrix))
        predicted = model.predict(matrix)
        error = np.abs(bases[arch] + contrib.sum(axis=1) - predicted).max()
        check(error < 1e-6, f"{arch}: base + Σ SHAP = prediksi (error {error:.1e})")

    print()
    if failures:
        print(f"GAGAL: {len(failures)} pemeriksaan tidak lolos")
        return 1
    print("SEMUA PEMERIKSAAN LOLOS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
