"""Uji kontrak API: isi balasan, pagar verdict, dan filter.

Jalankan:

    cd backend
    .venv/Scripts/python.exe -m pytest -q

Tes ini memakai artefak asli di `backend/app/ml/artifacts` dan
`backend/app/data/players.json`, jadi tidak ada mock model.
"""

from __future__ import annotations

import numpy as np
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.model_registry import get_registry

PREFIX = "/api/v1"


@pytest.fixture(scope="module")
def client() -> TestClient:
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="module")
def registry():
    return get_registry()


def _first(client: TestClient, **params) -> dict:
    body = client.get(f"{PREFIX}/players", params={"limit": 1, **params}).json()
    assert body["players"], f"tidak ada pemain untuk filter {params}"
    return body["players"][0]


def _search(client: TestClient, name: str) -> dict:
    return _first(client, search=name)


# ---------------------------------------------------------------------------
# 1. Dataset dan metadata
# ---------------------------------------------------------------------------


def test_health_ready(client: TestClient):
    body = client.get(f"{PREFIX}/health").json()
    assert body["status"] == "ok"
    assert body["players_loaded"] == 1999
    assert body["archetypes_loaded"] == 8
    assert body["model_ready"] and body["shap_ready"]
    assert body["errors"] == []


def test_meta_features_lengkap(client: TestClient):
    body = client.get(f"{PREFIX}/meta/features").json()
    assert len(body["archetypes"]) == 8
    by_key = {item["key"]: item for item in body["archetypes"]}
    assert len(by_key["ST"]["features"]) == 10
    assert len(by_key["GK"]["features"]) == 5
    # Arah logika tidak boleh hilang: pelanggaran dan kebobolan itu "makin kecil makin baik".
    good_dir = {feature["key"]: feature["good_dir"] for item in body["archetypes"] for feature in item["features"]}
    assert good_dir["fls_p90"] == -1
    assert good_dir["ga_p90"] == -1
    assert good_dir["npg_p90"] == 1


def test_meta_tactics_valid(client: TestClient, registry):
    body = client.get(f"{PREFIX}/meta/tactics").json()
    assert len(body["archetypes"]) == 8
    for item in body["archetypes"]:
        allowed = set(registry.metadata.archetypes[item["archetype"]])
        for preset in item["presets"]:
            assert set(preset["targets"]) <= allowed
            assert preset["label"] and preset["description"]


# ---------------------------------------------------------------------------
# 2. Daftar dan detail pemain
# ---------------------------------------------------------------------------


def test_filter_players_ditaati(client: TestClient):
    body = client.get(
        f"{PREFIX}/players",
        params={"archetype": "CB", "max_age": 23, "limit": 200},
    ).json()
    assert body["total"] > 0
    assert all(player["age"] <= 23 for player in body["players"])
    assert all(player["archetype"] == "CB" for player in body["players"])

    with_value = client.get(
        f"{PREFIX}/players", params={"max_value_eur": 5_000_000, "limit": 100}
    ).json()["players"]
    assert all(player["market_value_eur"] <= 5_000_000 for player in with_value)


def test_detail_pemain_membawa_konteks_model(client: TestClient):
    player = _search(client, "haaland")
    detail = client.get(f"{PREFIX}/players/{player['id']}").json()
    assert detail["archetype"] == "ST"
    assert detail["reliability"] in {"baik", "cukup", "rendah"}
    assert 0 < detail["r2_test"] < 1
    assert detail["base_value_eur"] > 0
    assert set(detail["stats"]) == set(detail["percentiles"])


# ---------------------------------------------------------------------------
# 3. SHAP: pagar verdict (port cek #3 & #4 notebook)
# ---------------------------------------------------------------------------


def test_kelebihan_dan_kekurangan_searah_logika(client: TestClient, registry):
    metadata = registry.metadata
    players = client.get(f"{PREFIX}/players", params={"limit": 200}).json()["players"]

    checked = 0
    for player in players:
        detail = client.get(f"{PREFIX}/players/{player['id']}/explain").json()
        archetype = player["archetype"]
        core = set(metadata.weakness_features(archetype))

        for row in detail["strengths"]:
            assert row["shap_value"] > 0
            assert row["effect_pct"] >= metadata.min_effect * 100
            assert metadata.good_dir[row["feature"]] == 1
            assert row["better_than_pct"] - 50 >= metadata.min_pct_gap

        for row in detail["weaknesses"]:
            assert row["shap_value"] < 0
            assert row["effect_pct"] <= -metadata.min_effect * 100
            assert row["feature"] in core, "kekurangan di luar tugas inti arketipe"
            assert 50 - row["better_than_pct"] >= metadata.min_pct_gap

        assert detail["summary"]
        checked += 1
    assert checked == len(players)


def test_kiper_memakai_lima_statistik(client: TestClient):
    keeper = _first(client, archetype="GK")
    detail = client.get(f"{PREFIX}/players/{keeper['id']}/explain").json()
    assert len(keeper["stats"]) == 5
    assert {row["feature"] for row in detail["strengths"] + detail["weaknesses"]} <= set(keeper["stats"])


# ---------------------------------------------------------------------------
# 4. KNN: skor, filter, dan pencarian taktik
# ---------------------------------------------------------------------------


def test_similar_skor_dan_urutan(client: TestClient):
    player = _search(client, "haaland")
    body = client.get(f"{PREFIX}/players/{player['id']}/similar", params={"limit": 10}).json()

    assert body["same_archetype"] is True
    assert len(body["neighbors"]) == 10
    scores = [item["similarity"] for item in body["neighbors"]]
    assert all(0 <= score <= 100 for score in scores)
    assert scores == sorted(scores, reverse=True)
    assert all(item["player"]["id"] != player["id"] for item in body["neighbors"])
    assert all(item["player"]["archetype"] == player["archetype"] for item in body["neighbors"])
    # porsi atribusi jarak harus berjumlah 1
    shares = [row["share"] for row in body["similar_because"] + body["different_because"]]
    assert all(0 <= share <= 1 for share in shares)


def test_pencarian_kriteria_lebih_dekat_dari_acak(client: TestClient):
    target = {"npg_p90": 0.6, "sh_p90": 3.5}
    body = client.post(
        f"{PREFIX}/scout",
        json={"archetype": "ST", "criteria": target, "top_k": 10},
    ).json()
    assert body["k"] == 10
    assert len(body["results"]) == 10
    assert all(0 <= item["similarity"] <= 100 for item in body["results"])
    scores = [item["similarity"] for item in body["results"]]
    assert scores == sorted(scores, reverse=True)

    percentiles = body["target_percentiles"]
    assert percentiles["npg_p90"] > 50  # 0.6 gol per 90 itu di atas median striker
    # statistik yang tidak diminta memakai median arketipe
    assert percentiles["off_p90"] == pytest.approx(50.0, abs=1.0)


def test_taktik_hanya_menilai_statistik_yang_diminta(client: TestClient, registry):
    body = client.post(
        f"{PREFIX}/scout/tactic",
        json={"archetype": "W", "tactic": "wide_creator", "top_k": 8},
    ).json()
    presets = registry.metadata.tactics["W"]["wide_creator"]["targets"]
    assert body["tactic"] == "wide_creator"
    assert set(presets) <= set(body["target_percentiles"])
    assert all(item["why"] for item in body["results"])

    under = [item for item in body["results"] if "kurang" in (item["why"] or "")]
    assert under, "harus ada kandidat yang kurang di statistik yang diminta taktik"


def test_filter_umur_dihormati_di_pencarian(client: TestClient):
    body = client.post(
        f"{PREFIX}/scout/tactic",
        json={"archetype": "ST", "tactic": "poacher", "top_k": 8, "max_age": 24},
    ).json()
    assert body["results"]
    assert all(item["player"]["age"] <= 24 for item in body["results"])


# ---------------------------------------------------------------------------
# 5. Perbandingan
# ---------------------------------------------------------------------------


def test_compare_simetris(client: TestClient):
    a = _search(client, "haaland")
    b = _search(client, "schick")

    forward = client.post(f"{PREFIX}/compare", json={"a": a["id"], "b": b["id"]}).json()
    backward = client.post(f"{PREFIX}/compare", json={"a": b["id"], "b": a["id"]}).json()

    assert forward["same_archetype"] is True
    gap_a = {row["feature"]: row["gap_pct"] for row in forward["rows"]}
    gap_b = {row["feature"]: row["gap_pct"] for row in backward["rows"]}
    for feature, value in gap_a.items():
        assert value == pytest.approx(-gap_b[feature], abs=1e-9)

    winners_a = {row["feature"]: row["winner"] for row in forward["rows"]}
    winners_b = {row["feature"]: row["winner"] for row in backward["rows"]}
    swap = {"A": "B", "B": "A", "seimbang": "seimbang", "tidak didukung model": "tidak didukung model"}
    for feature, value in winners_a.items():
        assert swap[value] == winners_b[feature]

    assert {row["feature"] for row in forward["a_better"]} == {
        row["feature"] for row in backward["b_better"]
    }


def test_compare_diri_sendiri_seimbang(client: TestClient):
    player = _search(client, "haaland")
    body = client.post(f"{PREFIX}/compare", json={"a": player["id"], "b": player["id"]}).json()
    assert body["neighbor_rank"] == 0
    assert all(row["winner"] == "seimbang" for row in body["rows"])
    assert body["a_better"] == [] and body["b_better"] == []
    assert body["raw_only"] == []


def test_compare_beda_arketipe_diberi_peringatan(client: TestClient):
    forward = _search(client, "haaland")
    back = _search(client, "saliba")
    body = client.post(f"{PREFIX}/compare", json={"a": forward["id"], "b": back["id"]}).json()
    assert body["same_archetype"] is False
    assert body["warning"]
    assert body["similarity"] is None
    assert body["a"] != body["b"]


# ---------------------------------------------------------------------------
# 6. Best-fit
# ---------------------------------------------------------------------------


def test_best_fit_dari_kandidat_knn(client: TestClient, registry):
    player = _search(client, "haaland")
    body = client.get(
        f"{PREFIX}/best-fit/{player['id']}",
        params={"needs": "tklw_p90,int_p90", "top_k": 5, "max_age": 24},
    ).json()

    assert len(body["candidates"]) == 5
    fits = [candidate["fit"] for candidate in body["candidates"]]
    assert all(0 <= fit <= 100 for fit in fits)
    assert fits == sorted(fits, reverse=True)
    assert all(candidate["player"]["id"] != player["id"] for candidate in body["candidates"])
    assert all(candidate["player"]["age"] <= 24 for candidate in body["candidates"])
    assert set(body["needs"]) == {"tklw_p90", "int_p90"}
    assert all(candidate["why"] for candidate in body["candidates"])


def test_best_fit_menolak_statistik_arketipe_lain(client: TestClient):
    keeper = _first(client, archetype="GK")
    response = client.get(
        f"{PREFIX}/best-fit/{keeper['id']}", params={"needs": "npg_p90"}
    )
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# 7. Kasus salah masukan
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("method", "path", "payload", "expected"),
    [
        ("get", f"{PREFIX}/players/999999", None, 404),
        ("post", f"{PREFIX}/scout", {"archetype": "XX", "criteria": {}}, 400),
        ("post", f"{PREFIX}/scout", {"archetype": "ST", "criteria": {"pace": 80}}, 400),
        ("post", f"{PREFIX}/scout/tactic", {"archetype": "ST", "tactic": "stopper"}, 400),
        ("post", f"{PREFIX}/compare", {"a": "1", "b": "999999"}, 404),
    ],
)
def test_kasus_salah_masukan(client: TestClient, method: str, path: str, payload, expected: int):
    if method == "get":
        response = client.get(path)
    else:
        response = client.post(path, json=payload)
    assert response.status_code == expected
    assert response.json()["detail"]


# ---------------------------------------------------------------------------
# 8. Konsistensi matematis dengan notebook
# ---------------------------------------------------------------------------


def test_atribusi_jarak_aditif(client: TestClient, registry):
    """Σ kontribusi harus sama dengan jarak² yang dipakai KNN (cek #1 notebook)."""
    from app.services.distance import contributions

    model = registry.archetypes["CB"]
    index_a, index_b = 0, 3
    table = contributions(model, model.z[index_a], model.z[index_b])
    expected = float(np.sum((model.z[index_a] - model.z[index_b]) ** 2))

    assert table["contrib"].sum() == pytest.approx(expected, abs=1e-9)
    assert table["share"].sum() == pytest.approx(1.0, abs=1e-9)
    assert np.isfinite(table["contrib"]).all()


def test_skor_kemiripan_pada_jarak_tipikal(registry):
    """Skor = 100 × exp(−jarak / jarak_tipikal); jarak tipikal memberi ~37."""
    expected = 100.0 * np.exp(-1.0)
    for archetype, model in registry.archetypes.items():
        assert model.d_ref > 0, archetype
        assert model.similarity(model.d_ref) == pytest.approx(expected, abs=1e-6)
        assert model.similarity(0.0) == pytest.approx(100.0, abs=1e-6)
        assert model.similarity(model.d_ref * 2) < model.similarity(model.d_ref)


def test_nilai_pasar_prediksi_masuk_akal(client: TestClient, registry):
    """Prediksi model nilai pasar harus dalam orde Euro, bukan log."""
    from app.services.explain_service import ExplainService

    explain = ExplainService(registry)
    keeper = registry.by_id[int(_first(client, archetype="GK")["id"])]
    _, base = explain.contributions(keeper)
    assert np.exp(base) > 100_000
