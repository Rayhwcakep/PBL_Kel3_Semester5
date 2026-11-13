"""Pipeline artefak Scoutify: KNN + SHAP.

DIGENERASI dari `scouting_knn_shap_colab.ipynb` oleh `ml/notebook_to_script.py`.
Jangan edit file ini langsung - ubah notebook lalu jalankan ulang:

    python ml/notebook_to_script.py
    python ml/export_artifacts.py

Butuh file di `DATASET/pemain` dan `DATASET/transfermarket` (lihat .gitignore).
Hasil ditulis ke `ml/export/`.
"""

import os
from pathlib import Path

# Selalu bekerja dari root repo agar path dataset ditemukan.
os.chdir(Path(__file__).resolve().parents[1])


# --- sel notebook 3 ---------------------------------------------
import importlib, subprocess, sys
try:
    import shap  # noqa: F401
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "shap"])
    importlib.invalidate_caches()
print("shap siap")


# --- sel notebook 4 ---------------------------------------------
import os, re, json, unicodedata, warnings
import numpy as np
import pandas as pd
import joblib
import shap

from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.preprocessing import StandardScaler, FunctionTransformer
from sklearn.pipeline import Pipeline
from sklearn.neighbors import NearestNeighbors, KNeighborsClassifier, KNeighborsRegressor
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.dummy import DummyRegressor, DummyClassifier
from sklearn.model_selection import train_test_split, GridSearchCV, KFold, StratifiedKFold, cross_val_score
from sklearn.metrics import r2_score, mean_absolute_error, accuracy_score

warnings.filterwarnings("ignore")
pd.set_option("display.width", 230)
pd.set_option("display.max_columns", 40)
pd.set_option("display.max_colwidth", 90)
RANDOM_STATE = 42


# --- sel notebook 6 ---------------------------------------------
SEARCH_DIRS = ["/content", "/content/DATASET", "/content/DATASET/pemain", "/content/DATASET/transfermarket",
               ".", "DATASET", "DATASET/pemain", "DATASET/transfermarket"]

def find_file(name):
    for d in SEARCH_DIRS:
        p = os.path.join(d, name)
        if os.path.isfile(p):
            return p
    raise FileNotFoundError(f"{name} tidak ditemukan. Upload ke /content atau taruh di DATASET/.")

stats = pd.read_csv(find_file("players_data-2025_2026.csv"))
tm    = pd.read_csv(find_file("players.csv"))
vals  = pd.read_csv(find_file("player_valuations.csv"), parse_dates=["date"])

print("stats :", stats.shape)
print("tm    :", tm.shape)
print("vals  :", vals.shape)


# --- sel notebook 8 ---------------------------------------------
def norm(x):
    x = unicodedata.normalize("NFKD", str(x)).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z ]", "", x).strip()

df = stats.dropna(subset=["Born"]).copy()
df["Born"] = df["Born"].astype(int)
df["pos_group"] = df["Pos"].str.split(",").str[0]              # "MF,FW" -> "MF"
df["Comp"] = df["Comp"].str.split(" ", n=1).str[1]             # "eng Premier League" -> "Premier League"
df["key"] = df["Player"].map(norm)

t = tm[tm["last_season"] >= 2025].copy()                       # hanya pemain aktif
t["key"] = t["name"].map(norm)
t["Born"] = pd.to_datetime(t["date_of_birth"], errors="coerce").dt.year
t = t.dropna(subset=["Born"])
t["Born"] = t["Born"].astype(int)

tm_cols = ["player_id", "key", "Born", "current_club_name", "sub_position", "position", "foot",
           "height_in_cm", "country_of_citizenship", "contract_expiration_date",
           "market_value_in_eur", "highest_market_value_in_eur", "image_url", "url"]
m = df.merge(t[tm_cols], on=["key", "Born"], how="left")

def club_match(r):
    a, b = norm(r["Squad"]), norm(r["current_club_name"])
    return int(bool(b) and (a in b or b in a))

m["club_ok"] = m.apply(club_match, axis=1)
m = (m.sort_values("club_ok", ascending=False)
       .drop_duplicates(subset=["Player", "Squad", "Born"])
       .sort_index().reset_index(drop=True))

ref = vals["date"].max()
v_old = (vals[vals["date"] <= ref - pd.Timedelta(days=365)]
         .sort_values("date").groupby("player_id").tail(1)[["player_id", "market_value_in_eur"]]
         .rename(columns={"market_value_in_eur": "value_1y_ago"}))
m = m.merge(v_old, on="player_id", how="left")
m["value_growth_1y"] = (m["market_value_in_eur"] / m["value_1y_ago"] - 1).round(3)

print(f"Total pemain statistik : {len(m)}")
print(f"Berhasil dicocokkan TM : {m['player_id'].notna().sum()} ({m['player_id'].notna().mean():.0%})")


# --- sel notebook 10 ---------------------------------------------
MIN_MINUTES = 450        # ~5 pertandingan penuh
MIN_ARCH_N  = 25         # arketipe dengan pemain lebih sedikit digabung/dibuang

P90 = {"npg_p90": "G-PK", "ast_p90": "Ast", "sh_p90": "Sh", "sot_p90": "SoT",
       "crs_p90": "Crs", "int_p90": "Int", "tklw_p90": "TklW",
       "fls_p90": "Fls", "fld_p90": "Fld", "off_p90": "Off"}

m["90s"] = pd.to_numeric(m["90s"], errors="coerce").clip(lower=0.1)
for new, col in P90.items():
    m[new] = pd.to_numeric(m[col], errors="coerce") / m["90s"]
m["saves_p90"] = pd.to_numeric(m["Saves"], errors="coerce") / m["90s"]
m["sota_p90"]  = pd.to_numeric(m["SoTA"],  errors="coerce") / m["90s"]
m = m.rename(columns={"Save%": "save_pct", "CS%": "cs_pct", "GA90": "ga_p90"})
for c in ["save_pct", "ga_p90", "cs_pct"]:
    m[c] = pd.to_numeric(m[c], errors="coerce")
m["plus_p90"]   = pd.to_numeric(m["+/-"],  errors="coerce") / m["90s"]
m["crd_p90"]    = pd.to_numeric(m["CrdY"], errors="coerce") / m["90s"]
m["start_rate"] = pd.to_numeric(m["Starts"], errors="coerce") / pd.to_numeric(m["MP"], errors="coerce").clip(lower=1)

OUT_FEATS = ["npg_p90", "ast_p90", "sh_p90", "sot_p90", "crs_p90",
             "int_p90", "tklw_p90", "fls_p90", "fld_p90", "off_p90"]
GK_FEATS  = ["save_pct", "ga_p90", "cs_pct", "saves_p90", "sota_p90"]

ARCH_MAP = {
    "Centre-Back": "CB", "Left-Back": "FB", "Right-Back": "FB",
    "Defensive Midfield": "DM", "Central Midfield": "CM", "Attacking Midfield": "AM",
    "Left Midfield": "W", "Right Midfield": "W", "Left Winger": "W", "Right Winger": "W",
    "Centre-Forward": "ST", "Second Striker": "ST",
}
ARCH_LABEL = {"GK": "Kiper", "CB": "Bek tengah", "FB": "Bek sayap", "DM": "Gelandang bertahan",
              "CM": "Gelandang tengah", "AM": "Gelandang serang", "W": "Pemain sayap", "ST": "Striker"}
ARCH_FEATS = {a: (GK_FEATS if a == "GK" else OUT_FEATS) for a in ARCH_LABEL}

m["arch"] = m["sub_position"].map(ARCH_MAP)
m["arch"] = m["arch"].fillna(m["pos_group"].map({"GK": "GK", "DF": "CB", "MF": "CM", "FW": "ST"}))

players = m[m["Min"] >= MIN_MINUTES].copy()
ok = pd.Series(True, index=players.index)
for a, feats in ARCH_FEATS.items():
    mask = players["arch"] == a
    ok[mask] = players.loc[mask, feats].notna().all(axis=1)
players = players[ok].copy()

vc = players["arch"].value_counts()
players = players[players["arch"].isin(vc[vc >= MIN_ARCH_N].index)].copy()
players = players.dropna(subset=["Age", "Min"]).reset_index(drop=True)
players["uid"] = players.index
ARCH_KEYS = sorted(players["arch"].unique())

# persentil DI DALAM arketipe (bukan di dalam 4 grup kasar)
for a in ARCH_KEYS:
    mask = players["arch"] == a
    for c in ARCH_FEATS[a]:
        players.loc[mask, f"pct_{c}"] = players.loc[mask, c].rank(pct=True) * 100

# konteks untuk model nilai pasar
LEAGUES = sorted(players["Comp"].dropna().unique())
LEAGUE_COLS = ["lg_" + l.replace(" ", "_") for l in LEAGUES]
for l, c in zip(LEAGUES, LEAGUE_COLS):
    players[c] = (players["Comp"] == l).astype(int)
CONTEXT = ["Age", "Min", "start_rate", "plus_p90", "crd_p90"] + LEAGUE_COLS
for c in ["plus_p90", "crd_p90", "start_rate"]:
    players[c] = players[c].fillna(0)

players["log_value"] = np.log(players["market_value_in_eur"])
print("Arketipe:", ARCH_KEYS)
print("Pemain lolos filter:", len(players))


# --- sel notebook 12 ---------------------------------------------
LABELS = {"npg_p90": "Gol non-penalti", "ast_p90": "Assist", "sh_p90": "Tembakan", "sot_p90": "Tembakan on target",
          "crs_p90": "Umpan silang", "int_p90": "Intersep", "tklw_p90": "Tekel berhasil",
          "fls_p90": "Pelanggaran dibuat", "fld_p90": "Pelanggaran diterima", "off_p90": "Offside",
          "save_pct": "Save %", "ga_p90": "Kebobolan", "cs_pct": "Clean sheet %",
          "saves_p90": "Penyelamatan", "sota_p90": "Tembakan dihadapi"}
CTX_LABELS = {"Age": "Usia", "Min": "Menit main", "start_rate": "Rasio jadi starter",
              "plus_p90": "Plus/minus per 90", "crd_p90": "Kartu kuning per 90", "ctx_liga": "Liga"}
GOOD_DIR = {"npg_p90": 1, "ast_p90": 1, "sh_p90": 1, "sot_p90": 1, "crs_p90": 1, "int_p90": 1, "tklw_p90": 1,
            "fld_p90": 1, "fls_p90": -1, "off_p90": -1,
            "save_pct": 1, "ga_p90": -1, "cs_pct": 1, "saves_p90": 0, "sota_p90": 0}

WEAKNESS_OK = {
    "GK": ["save_pct", "ga_p90", "cs_pct"],
    "CB": ["tklw_p90", "int_p90", "fls_p90"],
    "FB": ["tklw_p90", "int_p90", "crs_p90", "ast_p90"],
    "DM": ["tklw_p90", "int_p90", "fls_p90"],
    "CM": ["ast_p90", "tklw_p90", "int_p90", "fld_p90"],
    "AM": ["ast_p90", "sh_p90", "sot_p90", "fld_p90"],
    "W":  ["crs_p90", "ast_p90", "npg_p90", "sh_p90"],
    "ST": ["npg_p90", "sh_p90", "sot_p90", "ast_p90"],
}

MIN_EFFECT  = 0.03     # pengaruh minimal 3% agar dianggap bermakna
MIN_PCT_GAP = 10       # selisih persentil minimal terhadap median arketipe
print("kamus siap:", len(LABELS), "label,", len(WEAKNESS_OK), "arketipe")


# --- sel notebook 13 ---------------------------------------------
summary = (players.groupby("arch")
           .agg(pemain=("uid", "size"),
                nilai_pasar_ada=("log_value", "count"),
                median_nilai_jt=("market_value_in_eur", lambda s: round(s.median() / 1e6, 1)),
                median_umur=("Age", "median"),
                median_menit=("Min", "median"))
           .reindex(ARCH_KEYS))
summary.insert(0, "arketipe", [ARCH_LABEL[a] for a in summary.index])
summary


# --- sel notebook 15 ---------------------------------------------
FEATURE_WEIGHTS = {
    "GK": {"save_pct": 1.5, "ga_p90": 1.3, "cs_pct": 1.2, "saves_p90": 1.0, "sota_p90": 0.8},
    "CB": {"tklw_p90": 1.5, "int_p90": 1.5, "fls_p90": 1.2, "crs_p90": 0.6, "ast_p90": 0.5,
           "npg_p90": 0.5, "sh_p90": 0.6, "sot_p90": 0.6, "fld_p90": 0.8, "off_p90": 0.8},
    "FB": {"crs_p90": 1.4, "ast_p90": 1.3, "tklw_p90": 1.2, "int_p90": 1.1, "npg_p90": 0.7},
    "DM": {"tklw_p90": 1.4, "int_p90": 1.4, "fls_p90": 1.1, "npg_p90": 0.6, "sh_p90": 0.7, "sot_p90": 0.7},
    "CM": {"ast_p90": 1.2, "tklw_p90": 1.1, "int_p90": 1.1, "crs_p90": 1.0},
    "AM": {"ast_p90": 1.4, "sh_p90": 1.2, "sot_p90": 1.2, "fld_p90": 1.1, "tklw_p90": 0.7, "int_p90": 0.7},
    "W":  {"crs_p90": 1.3, "ast_p90": 1.2, "sh_p90": 1.2, "npg_p90": 1.1, "tklw_p90": 0.8},
    "ST": {"npg_p90": 1.5, "sh_p90": 1.3, "sot_p90": 1.3, "ast_p90": 0.8, "tklw_p90": 0.6,
           "int_p90": 0.6, "crs_p90": 0.7},
}

def weight_vector(arch):
    return np.array([FEATURE_WEIGHTS.get(arch, {}).get(f, 1.0) for f in ARCH_FEATS[arch]], dtype=float)

class WeightedScale(BaseEstimator, TransformerMixin):
    """Kalikan matriks z dengan bobot fitur per arketipe (picklable, jadi aman disimpan joblib)."""
    def __init__(self, weights=None):
        self.weights = weights
    def fit(self, X, y=None):
        self.weights_ = np.asarray(self.weights, dtype=float)
        return self
    def transform(self, X):
        return np.asarray(X, dtype=float) * self.weights_

def make_prep(arch):
    w = weight_vector(arch)
    steps = [("log", FunctionTransformer(np.log1p, validate=False)),
             ("scale", StandardScaler())]
    if not np.allclose(w, 1.0):
        steps.append(("weight", WeightedScale(w)))
    return Pipeline(steps)

def transform(mdl, df):
    """DataFrame -> matriks z yang dipakai KNN (sudah log, standar, berbobot)."""
    return np.asarray(mdl["prep"].transform(df[mdl["features"]]), dtype=float)

models = {}
for arch in ARCH_KEYS:
    d = players[players["arch"] == arch].reset_index(drop=True)
    feats = ARCH_FEATS[arch]
    prep = make_prep(arch).fit(d[feats])
    Z = np.asarray(prep.transform(d[feats]), dtype=float)
    nn = NearestNeighbors(metric="euclidean", algorithm="brute").fit(Z)
    models[arch] = {"prep": prep, "nn": nn, "features": feats, "uids": d["uid"].values, "n": len(d)}

# Matriks z tiap arketipe + peta uid -> baris. Dipakai untuk jarak cepat & atribusi.
Z_ALL = {a: transform(mdl, players.loc[mdl["uids"]]) for a, mdl in models.items()}
POS_BY_ARCH = {a: {int(u): i for i, u in enumerate(mdl["uids"])} for a, mdl in models.items()}

# Skala jarak "tipikal" per arketipe -> skor kemiripan 0-100 yang bisa dibaca (50 = jarak tipikal).
D_REF = {}
for a in models:
    Z = Z_ALL[a]
    D = np.sqrt(((Z[:, None, :] - Z[None, :, :]) ** 2).sum(-1))
    np.fill_diagonal(D, np.nan)
    D_REF[a] = float(np.nanmedian(D))

pd.DataFrame([{"arketipe": a, "n": v["n"], "jumlah_fitur": len(v["features"]),
               "jarak_tipikal": round(D_REF[a], 3),
               "bobot": ", ".join(f"{k}×{v2:g}" for k, v2 in FEATURE_WEIGHTS.get(a, {}).items())}
              for a, v in models.items()])


# --- sel notebook 17 ---------------------------------------------
out = players[players["arch"] != "GK"]
pipe = Pipeline([("log", FunctionTransformer(np.log1p, validate=False)),
                 ("scale", StandardScaler()),
                 ("knn", KNeighborsClassifier(15))])
acc = cross_val_score(pipe, out[OUT_FEATS], out["arch"],
                      cv=StratifiedKFold(5, shuffle=True, random_state=RANDOM_STATE)).mean()
base = out["arch"].value_counts(normalize=True).max()
print(f"Uji A - klasifikasi 8 arketipe (5-fold): akurasi {acc:.3f} | baseline tebak terbanyak {base:.3f}")
print(f"        (naik {acc / base:.1f}× di atas baseline)\n")

rows = []
for arch in ARCH_KEYS:
    d = players[(players["arch"] == arch) & players["log_value"].notna()]
    if len(d) < 60:
        continue
    Z = transform(models[arch], d)
    Ztr, Zte, ytr, yte = train_test_split(Z, d["log_value"], test_size=0.2, random_state=RANDOM_STATE)
    knn = KNeighborsRegressor(10).fit(Ztr, ytr)
    dum = DummyRegressor().fit(Ztr, ytr)
    rows.append({"arketipe": arch, "n": len(d),
                 "r2_knn": round(r2_score(yte, knn.predict(Zte)), 3),
                 "r2_tebak_rata2": round(r2_score(yte, dum.predict(Zte)), 3)})
pd.DataFrame(rows)


# --- sel notebook 19 ---------------------------------------------
def distance_contrib(mdl, a_df, b_df, mask=None):
    """Pecah jarak KNN antara dua vektor fitur menjadi kontribusi per statistik (aditif & eksak).
    `mask` (0/1) membatasi atribusi ke statistik yang relevan dengan taktik."""
    za, zb = transform(mdl, a_df)[0], transform(mdl, b_df)[0]
    diff = za - zb
    c = diff ** 2
    if mask is not None:
        c = c * np.asarray(mask, dtype=float)
    tot = float(c.sum())
    return pd.DataFrame({
        "feature": mdl["features"],
        "label": [LABELS[f] for f in mdl["features"]],
        "a": a_df.iloc[0][mdl["features"]].to_numpy(dtype=float),
        "b": b_df.iloc[0][mdl["features"]].to_numpy(dtype=float),
        "z_a": za, "z_b": zb, "diff": diff,
        "contrib": c,
        "share": (c / tot) if tot > 0 else c,
        "distance": np.sqrt(tot),
    })

# --- bukti numerik: jumlah kontribusi = jarak² yang benar-benar dipakai KNN ---
cb = players[players["arch"] == "CB"].reset_index(drop=True)
pa, pb = cb.iloc[0], cb.iloc[3]
t = distance_contrib(models["CB"], players.loc[[pa["uid"]]], players.loc[[pb["uid"]]])
uids_cb = list(models["CB"]["uids"])
dist_cb, idx_cb = models["CB"]["nn"].kneighbors(
    transform(models["CB"], players.loc[[pa["uid"]]]), n_neighbors=len(cb))
jarak_knn = float(dist_cb[0][list(idx_cb[0]).index(uids_cb.index(pb["uid"]))])

print(f"Contoh: {pa['Player']} vs {pb['Player']}")
print(f"  Σ kontribusi      = {t['contrib'].sum():.10f}")
print(f"  jarak² dari KNN   = {jarak_knn ** 2:.10f}")
print(f"  selisih           = {abs(t['contrib'].sum() - jarak_knn ** 2):.2e}")
print(f"  Σ porsi           = {t['share'].sum():.10f}")
assert abs(t["contrib"].sum() - jarak_knn ** 2) < 1e-9
assert abs(t["share"].sum() - 1) < 1e-9
print("\n✓ Atribusi jarak terbukti aditif dan sama dengan jarak KNN.")


# --- sel notebook 21 ---------------------------------------------
GBR_FIXED = dict(max_depth=1, subsample=0.8, min_samples_leaf=5, random_state=RANDOM_STATE)
value_models, rows = {}, []
for arch in ARCH_KEYS:
    d = players[(players["arch"] == arch) & players["log_value"].notna()]
    cols = ARCH_FEATS[arch] + CONTEXT
    X, y = d[cols].fillna(0), d["log_value"]
    Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, random_state=RANDOM_STATE)

    grid = GridSearchCV(GradientBoostingRegressor(**GBR_FIXED),
                        {"n_estimators": [200, 400], "learning_rate": [0.05, 0.1]},
                        cv=KFold(5, shuffle=True, random_state=RANDOM_STATE), scoring="r2").fit(Xtr, ytr)
    pred = grid.predict(Xte)
    r2 = r2_score(yte, pred)
    mae = mean_absolute_error(yte, pred)

    value_models[arch] = {"model": GradientBoostingRegressor(**GBR_FIXED, **grid.best_params_).fit(X, y),
                          "r2_test": float(r2), "n": int(len(d)), "cols": cols,
                          "reliability": "baik" if r2 >= 0.45 else "cukup" if r2 >= 0.30 else "rendah"}
    rows.append({"arketipe": arch, "n": len(d), "r2_test": round(r2, 3),
                 "r2_knn_reg": round(r2_score(yte, KNeighborsRegressor(10).fit(Xtr, ytr).predict(Xte)), 3),
                 "r2_tebak_rata2": round(r2_score(yte, DummyRegressor().fit(Xtr, ytr).predict(Xte)), 3),
                 "kesalahan_tipikal": f"±{(np.exp(mae) - 1) * 100:.0f}%",
                 "keandalan": value_models[arch]["reliability"],
                 "param": grid.best_params_})
pd.DataFrame(rows)


# --- sel notebook 22 ---------------------------------------------
CONTRIB, BASE = {}, {}
for arch in ARCH_KEYS:
    mdl = value_models[arch]["model"]
    cols = value_models[arch]["cols"]
    d = players[players["arch"] == arch]
    X = d[cols].fillna(0)

    explainer = shap.TreeExplainer(mdl)
    sv = explainer.shap_values(X)
    BASE[arch] = float(np.ravel(explainer.expected_value)[0])

    t = pd.DataFrame(sv, columns=cols, index=d["uid"])
    t["ctx_liga"] = t[LEAGUE_COLS].sum(axis=1)        # 5 kolom liga digabung jadi 1 faktor
    CONTRIB[arch] = t.drop(columns=LEAGUE_COLS)

    err = np.abs(BASE[arch] + CONTRIB[arch].sum(axis=1).values - mdl.predict(X))
    print(f"{arch:3s}: {len(d):4d} pemain | titik awal €{np.exp(BASE[arch]) / 1e6:5.1f} jt | "
          f"error aditivitas maks {err.max():.1e} | pemain bermasalah {(err > 1e-6).sum()}")


# --- sel notebook 24 ---------------------------------------------
def eur(x):
    return f"€{x / 1e6:,.1f} jt" if pd.notna(x) else "n/a"

def _fmt(f, v):
    return f"{v:.1f}%" if f in ("save_pct", "cs_pct") else f"{v:.2f}"

def lookup(name, squad=None):
    q = norm(name)
    hit = players[players["key"].str.contains(q, regex=False)]
    exact = hit[hit["key"] == q]
    if len(exact):
        hit = exact
    if squad:
        hit = hit[hit["Squad"].str.contains(squad, case=False, regex=False)]
    return hit

def get_player(who, squad=None):
    """who = nama (str) atau uid (int). None kalau tidak ketemu / ambigu."""
    if isinstance(who, (int, np.integer)):
        return players.loc[who]
    hit = lookup(who, squad)
    if len(hit) == 0:
        print(f"'{who}' tidak ditemukan (mungkin menit main < {MIN_MINUTES}).")
        return None
    if len(hit) > 1:
        print(f"Ada beberapa kandidat untuk '{who}'. Sebutkan klubnya dengan squad='...':")
        print(hit[["Player", "Squad", "Born", "Pos", "arch"]].to_string(index=False))
        return None
    return hit.iloc[0]


# --- sel notebook 26 ---------------------------------------------
def _explain_table(uid, arch=None):
    p = players.loc[uid]
    arch = arch or p["arch"]
    c = CONTRIB[arch].loc[uid]
    core = WEAKNESS_OK[arch]
    rows = []
    for f in ARCH_FEATS[arch]:
        phi, pct, d = float(c[f]), float(p[f"pct_{f}"]), GOOD_DIR[f]
        eff = float(np.exp(phi) - 1)
        gap = d * (pct - 50)                       # > 0 : lebih baik dari median arketipe
        better = pct if d >= 0 else 100 - pct      # "lebih baik dari X% pemain searketipe"
        if abs(eff) < MIN_EFFECT or d == 0:
            verdict = "Netral"
        elif phi > 0 and d > 0 and gap >= MIN_PCT_GAP:      # hanya statistik "makin tinggi makin bagus" boleh jadi kelebihan
            verdict = "Kelebihan"
        elif phi < 0 and gap <= -MIN_PCT_GAP:
            verdict = "Kekurangan" if f in core else "Netral"
        else:
            verdict = "Diabaikan"
        rows.append({"feature": f, "label": LABELS[f], "value": float(p[f]), "pct": pct,
                     "better": better, "phi": phi, "effect": eff, "verdict": verdict})
    return pd.DataFrame(rows)

def explain_player(who, squad=None, verbose=True):
    p = get_player(who, squad)
    if p is None:
        return None
    t = _explain_table(p["uid"])
    c = CONTRIB[p["arch"]].loc[p["uid"]]
    ctx = [{"label": CTX_LABELS[k], "effect": float(np.exp(c[k]) - 1)}
           for k in ["Age", "Min", "start_rate", "plus_p90", "ctx_liga"]]
    vm = value_models[p["arch"]]
    out = {"player": p, "arch": p["arch"], "table": t,
           "strengths": t[t["verdict"] == "Kelebihan"].sort_values("effect", ascending=False),
           "weaknesses": t[t["verdict"] == "Kekurangan"].sort_values("effect"),
           "context": ctx, "reliability": vm["reliability"], "r2_test": vm["r2_test"]}
    if verbose:
        print(f"{p['Player']} — {p['Squad']} ({p['Comp']}), {p['sub_position']}, umur {p['Age']:.0f}, {p['Min']:.0f} menit")
        print(f"Arketipe: {ARCH_LABEL[p['arch']]} | nilai pasar {eur(p['market_value_in_eur'])} | "
              f"keandalan model: {vm['reliability']} (R² uji {vm['r2_test']:.2f})")
        print("\nKELEBIHAN (mendorong nilai naik):")
        for r in out["strengths"].itertuples():
            print(f"  + {r.label}: {_fmt(r.feature, r.value)} (lebih baik dari {r.better:.0f}% pemain searketipe) → {r.effect:+.0%}")
        if out["strengths"].empty:
            print("  (tidak ada yang menonjol)")
        print("KEKURANGAN (menekan nilai):")
        for r in out["weaknesses"].itertuples():
            print(f"  - {r.label}: {_fmt(r.feature, r.value)} (lebih baik dari {r.better:.0f}% pemain searketipe) → {r.effect:+.0%}")
        if out["weaknesses"].empty:
            print("  (tidak ada yang menonjol)")
        print("KONTEKS (bukan kemampuan bermain): " + " | ".join(f"{x['label']} {x['effect']:+.0%}" for x in ctx))
    return out

_ = explain_player("Erling Haaland")


# --- sel notebook 28 ---------------------------------------------
def _pct_of(p, f):
    return float(p[f"pct_{f}"])

def _neighbor_rank(arch, uid_a, uid_b):
    """Peringkat B di antara semua pemain searketipe saat dicari dari A (0 = A sendiri)."""
    i = POS_BY_ARCH[arch][int(uid_a)]
    D = np.sqrt(((Z_ALL[arch] - Z_ALL[arch][i]) ** 2).sum(axis=1))
    order = np.argsort(D)
    rank = int(np.where(order == POS_BY_ARCH[arch][int(uid_b)])[0][0])
    return rank, 100 * (1 - rank / max(len(order) - 1, 1))

def explain_similarity(a, b, squad_a=None, squad_b=None, n=3, verbose=True):
    pa, pb = get_player(a, squad_a), get_player(b, squad_b)
    if pa is None or pb is None:
        return None

    if pa["arch"] != pb["arch"]:
        feats = ARCH_FEATS[pa["arch"]] if pa["arch"] == pb["arch"] else OUT_FEATS
        feats = [f for f in OUT_FEATS if f in players.columns and pa[f"pct_{f}"] == pa[f"pct_{f}"]
                 and pb[f"pct_{f}"] == pb[f"pct_{f}"]]
        t = pd.DataFrame({"feature": feats,
                          "pct_a": [_pct_of(pa, f) for f in feats],
                          "pct_b": [_pct_of(pb, f) for f in feats]})
        t["gap"] = (t["pct_a"] - t["pct_b"]).abs()
        t = t.sort_values("gap").reset_index(drop=True)
        same, diff = t.head(n), t.tail(n).iloc[::-1]
        if verbose:
            print(f"⚠️ Arketipe berbeda: {pa['Player']} ({ARCH_LABEL[pa['arch']]}) vs "
                  f"{pb['Player']} ({ARCH_LABEL[pb['arch']]}).")
            print("   Jarak KNN tidak sebanding karena modelnya berbeda; dibandingkan lewat persentil.\n")
            print("Paling mirip (persentil berdekatan): " + "; ".join(
                f"{LABELS[r.feature]} {r.pct_a:.0f} vs {r.pct_b:.0f}" for r in same.itertuples()))
            print("Paling berbeda: " + "; ".join(
                f"{LABELS[r.feature]} {r.pct_a:.0f} vs {r.pct_b:.0f}" for r in diff.itertuples()))
        return {"A": pa, "B": pb, "same_arch": False, "table": t, "similar": same, "different": diff}

    t = distance_contrib(models[pa["arch"]], players.loc[[pa["uid"]]], players.loc[[pb["uid"]]])
    t["pct_a"] = [_pct_of(pa, f) for f in t["feature"]]
    t["pct_b"] = [_pct_of(pb, f) for f in t["feature"]]
    t = t.sort_values("contrib").reset_index(drop=True)
    same, diff = t.head(n), t.tail(n).iloc[::-1]

    d = float(t["distance"].iloc[0])
    sim = float(100 * np.exp(-d / max(D_REF[pa["arch"]], 1e-9)))
    rank, pct = _neighbor_rank(pa["arch"], pa["uid"], pb["uid"])

    if verbose:
        print(f"A: {pa['Player']} — {pa['Squad']}, {ARCH_LABEL[pa['arch']]}, umur {pa['Age']:.0f}, {eur(pa['market_value_in_eur'])}")
        print(f"B: {pb['Player']} — {pb['Squad']}, {ARCH_LABEL[pb['arch']]}, umur {pb['Age']:.0f}, {eur(pb['market_value_in_eur'])}")
        print(f"Jarak KNN: {d:.3f} | skor kemiripan: {sim:.0f}/100 (50 = jarak tipikal)")
        print(f"B adalah tetangga ke-{rank} dari A — lebih dekat dari {pct:.0f}% pemain searketipe.\n")
        print("MIRIP KARENA (kontribusi jarak terkecil):")
        for r in same.itertuples():
            print(f"  = {r.label}: {_fmt(r.feature, r.a)} vs {_fmt(r.feature, r.b)} "
                  f"(persentil {r.pct_a:.0f} vs {r.pct_b:.0f}; porsi jarak {r.share:.1%})")
        print("PEMBEDA UTAMA (kontribusi jarak terbesar):")
        for r in diff.itertuples():
            arah = "lebih tinggi" if r.a > r.b else "lebih rendah"
            print(f"  ≠ {r.label}: {_fmt(r.feature, r.a)} vs {_fmt(r.feature, r.b)} "
                  f"(A {arah}; persentil {r.pct_a:.0f} vs {r.pct_b:.0f}; porsi jarak {r.share:.1%})")
    return {"A": pa, "B": pb, "same_arch": True, "table": t, "similar": same, "different": diff,
            "similarity": sim, "neighbor_rank": rank, "kedekatan_pct": pct}

_ = explain_similarity("Erling Haaland", "Robert Lewandowski")


# --- sel notebook 30 ---------------------------------------------
TACTICS = {
  "GK": {
    "shot_stopper": {"label": "Shot stopper", "desc": "Banyak penyelamatan, persentase save tinggi.",
                     "targets": {"save_pct": 90, "saves_p90": 80, "ga_p90": 25, "cs_pct": 50, "sota_p90": 50}},
    "clean_sheet":  {"label": "Penjaga clean sheet", "desc": "Jarang kebobolan, clean sheet tinggi.",
                     "targets": {"cs_pct": 90, "ga_p90": 10, "save_pct": 70, "saves_p90": 50, "sota_p90": 30}},
  },
  "CB": {
    "stopper":      {"label": "Bek perebut bola", "desc": "Tekel & intersep tinggi, tidak ikut menyerang.",
                     "targets": {"tklw_p90": 90, "int_p90": 85, "fls_p90": 70, "crs_p90": 10, "ast_p90": 10,
                                 "npg_p90": 10, "sh_p90": 10}},
    "cover":        {"label": "Bek penutup ruang", "desc": "Intersep tinggi, sangat disiplin (sedikit pelanggaran).",
                     "targets": {"int_p90": 90, "tklw_p90": 65, "fls_p90": 15, "crs_p90": 20, "ast_p90": 15}},
  },
  "FB": {
    "attacking_fullback": {"label": "Bek sayap menyerang", "desc": "Umpan silang & assist tinggi, aktif naik.",
                           "targets": {"crs_p90": 90, "ast_p90": 80, "fld_p90": 75, "sh_p90": 60, "tklw_p90": 55}},
    "defensive_fullback": {"label": "Bek sayap bertahan", "desc": "Tekel & intersep tinggi, jarang naik.",
                           "targets": {"tklw_p90": 85, "int_p90": 80, "fls_p90": 65, "crs_p90": 35, "ast_p90": 25}},
  },
  "DM": {
    "destroyer":    {"label": "Perusak serangan", "desc": "Tekel & intersep tinggi, banyak pelanggaran taktis.",
                     "targets": {"tklw_p90": 90, "int_p90": 90, "fls_p90": 75, "ast_p90": 25, "npg_p90": 15}},
    "deep_playmaker": {"label": "Playmaker dalam", "desc": "Distribusi & assist dari belakang, tekel cukup.",
                       "targets": {"ast_p90": 85, "crs_p90": 65, "fld_p90": 60, "tklw_p90": 55, "int_p90": 60}},
  },
  "CM": {
    "box_to_box":   {"label": "Box-to-box", "desc": "Seimbang: bertahan sekaligus menyumbang gol & assist.",
                     "targets": {"tklw_p90": 70, "int_p90": 65, "npg_p90": 60, "sh_p90": 60, "ast_p90": 55}},
    "ball_winner":  {"label": "Perebut bola", "desc": "Tekel & intersep tinggi, jarang mencetak gol.",
                     "targets": {"tklw_p90": 90, "int_p90": 90, "fls_p90": 70, "npg_p90": 20, "sh_p90": 20, "ast_p90": 30}},
    "playmaker":    {"label": "Kreator serangan", "desc": "Assist tinggi, sering dilanggar, tekel rendah.",
                     "targets": {"ast_p90": 90, "crs_p90": 70, "fld_p90": 65, "sh_p90": 55, "tklw_p90": 40}},
  },
  "AM": {
    "creator":      {"label": "Kreator", "desc": "Assist & umpan silang tinggi, jadi target pelanggaran.",
                     "targets": {"ast_p90": 90, "crs_p90": 75, "fld_p90": 75, "sh_p90": 60, "tklw_p90": 30}},
    "shadow_striker": {"label": "Striker bayangan", "desc": "Banyak tembakan & gol dari lini kedua.",
                       "targets": {"npg_p90": 85, "sh_p90": 90, "sot_p90": 85, "ast_p90": 55, "tklw_p90": 25}},
  },
  "W": {
    "wide_creator": {"label": "Winger kreator", "desc": "Umpan silang & assist tinggi, sering dilanggar.",
                     "targets": {"crs_p90": 90, "ast_p90": 80, "fld_p90": 85, "sh_p90": 65, "npg_p90": 55}},
    "inside_forward": {"label": "Winger menusuk", "desc": "Masuk ke dalam untuk menembak & mencetak gol.",
                       "targets": {"npg_p90": 85, "sh_p90": 90, "sot_p90": 85, "ast_p90": 55, "crs_p90": 45}},
  },
  "ST": {
    "poacher":      {"label": "Poacher", "desc": "Finisher di kotak penalti: gol & tembakan tinggi.",
                     "targets": {"npg_p90": 90, "sh_p90": 80, "sot_p90": 85, "ast_p90": 30, "crs_p90": 20,
                                 "tklw_p90": 20, "int_p90": 20}},
    "target_forward": {"label": "Target man", "desc": "Menahan bola, sering dilanggar, jadi tumpuan serangan.",
                       "targets": {"fld_p90": 85, "npg_p90": 70, "ast_p90": 60, "sh_p90": 65, "tklw_p90": 35}},
    "false_nine":   {"label": "False nine", "desc": "Turun menjemput bola, lebih banyak membuat peluang.",
                     "targets": {"ast_p90": 90, "crs_p90": 65, "fld_p90": 65, "npg_p90": 50, "sh_p90": 55}},
  },
}

def tactic_pcts(arch, tactic=None, sliders=None):
    pct = {f: 50 for f in ARCH_FEATS[arch]}
    if tactic:
        pct.update(TACTICS[arch][tactic]["targets"])
    if sliders:
        pct.update(sliders)
    bad = [f for f in pct if f not in ARCH_FEATS[arch]]
    if bad:
        raise ValueError(f"fitur {bad} tidak ada untuk {arch}. Pilihan: {ARCH_FEATS[arch]}")
    return pct

def tactic_to_vector(arch, tactic=None, sliders=None):
    """Persentil target -> angka per-90 nyata, memakai sebaran pemain di arketipe itu."""
    pool = players.loc[players["arch"] == arch, ARCH_FEATS[arch]]
    pct = tactic_pcts(arch, tactic, sliders)
    return pd.DataFrame([{f: pool[f].quantile(p / 100) for f, p in pct.items()}])

def tactic_mask(arch, tactic=None, sliders=None):
    """Statistik yang disebut taktik saja yang dihitung. Statistik lain tidak boleh menarik jarak."""
    spec = set()
    if tactic:
        spec |= set(TACTICS[arch][tactic]["targets"])
    if sliders:
        spec |= set(sliders)
    m = np.array([1.0 if f in spec else 0.0 for f in ARCH_FEATS[arch]])
    return m if m.sum() > 0 else np.ones(len(ARCH_FEATS[arch]))

def _fit_verdict(f, pct_p, pct_t):
    """Verdict terhadap taktik. 'Kelebihan/kekurangan' hanya untuk statistik yang MEMANG DIMINTA tinggi
    oleh taktik; kalau taktik hanya meminta rendah (mis. tekel 20 untuk poacher), penyimpangan disebut 'beda profil'."""
    if GOOD_DIR[f] == 0:
        return "netral"
    gp = pct_p if GOOD_DIR[f] > 0 else 100 - pct_p
    gt = pct_t if GOOD_DIR[f] > 0 else 100 - pct_t
    d = gp - gt
    if gt >= 60:                                   # taktik membutuhkan statistik ini tinggi
        if d >= MIN_PCT_GAP:   return "kelebihan"
        if d <= -MIN_PCT_GAP:  return "kekurangan"
        return "sesuai"
    if gt <= 40:                                   # taktik hanya ingin rendah -> lebih tinggi bukan kelemahan
        return "beda profil" if d >= MIN_PCT_GAP else "sesuai"
    return "sesuai" if abs(d) <= MIN_PCT_GAP else "beda profil"

def _fit_table(p, arch, tgt, pct_t, mask):
    """Atribusi jarak pemain ke profil taktik + verdict per statistik."""
    t = distance_contrib(models[arch], players.loc[[p["uid"]]], tgt, mask=mask)
    t["pct_player"] = [float(p[f"pct_{f}"]) for f in t["feature"]]
    t["pct_target"] = [float(pct_t[f]) for f in t["feature"]]
    t["good_player"] = [v if GOOD_DIR[f] >= 0 else 100 - v for f, v in zip(t["feature"], t["pct_player"])]
    t["good_target"] = [v if GOOD_DIR[f] >= 0 else 100 - v for f, v in zip(t["feature"], t["pct_target"])]
    t["delta_good"] = t["good_player"] - t["good_target"]
    t["verdict"] = [_fit_verdict(f, pp, pt) for f, pp, pt in
                    zip(t["feature"], t["pct_player"], t["pct_target"])]
    return t

def explain_tactic_fit(who, tactic=None, sliders=None, squad=None, n=3, verbose=True):
    p = get_player(who, squad)
    if p is None:
        return None
    arch = p["arch"]
    if tactic and tactic not in TACTICS[arch]:
        print(f"Taktik '{tactic}' tidak ada untuk {ARCH_LABEL[arch]}. Pilihan: {list(TACTICS[arch])}")
        return None
    tgt = tactic_to_vector(arch, tactic, sliders)
    pct_t = tactic_pcts(arch, tactic, sliders)
    mask = tactic_mask(arch, tactic, sliders)
    t = _fit_table(p, arch, tgt, pct_t, mask)

    # "cocok" = statistik yang memang diminta taktik DAN sudah sesuai target (selisih <= 10 poin persentil).
    # Kalau belum ada yang sesuai, tampilkan yang paling dekat dengan catatan jujur.
    req = t[t["pct_target"].notna() & (t["contrib"] > 0)]
    tepat_sasaran = bool((req["verdict"] == "sesuai").any())
    close = (req[req["verdict"] == "sesuai"] if tepat_sasaran else req).sort_values("contrib").head(n)
    over = t[t["verdict"] == "kelebihan"].sort_values("delta_good", ascending=False).head(n)
    under = t[t["verdict"] == "kekurangan"].sort_values("delta_good").head(n)
    sim = float(100 * np.exp(-t["distance"].iloc[0] / max(D_REF[arch], 1e-9)))

    if verbose:
        print(f"Pemain : {p['Player']} — {p['Squad']}, {ARCH_LABEL[arch]}, umur {p['Age']:.0f}, {eur(p['market_value_in_eur'])}")
        if tactic:
            print(f"Taktik : {TACTICS[arch][tactic]['label']} — {TACTICS[arch][tactic]['desc']}")
        else:
            print("Taktik : slider kustom")
        print(f"Skor kecocokan dengan profil taktik: {sim:.0f}/100 (50 = jarak tipikal di arketipe ini)\n")
        if tepat_sasaran:
            print("COCOK KARENA (sudah sesuai target):")
            for r in close.itertuples():
                print(f"  = {r.label}: {_fmt(r.feature, r.a)} (persentil {r.pct_player:.0f}, target {r.pct_target:.0f})")
        else:
            print("BELUM ADA STATISTIK YANG PERSIS SESUAI TARGET. Yang paling dekat:")
            for r in close.itertuples():
                print(f"  ~ {r.label}: {_fmt(r.feature, r.a)} (persentil {r.pct_player:.0f}, target {r.pct_target:.0f}, "
                      f"selisih {r.delta_good:+.0f} poin)")
        if len(over):
            print("KELEBIHAN TERHADAP TAKTIK:")
            for r in over.itertuples():
                print(f"  + {r.label}: persentil {r.pct_player:.0f} vs target {r.pct_target:.0f} ({r.delta_good:+.0f} poin)")
        if len(under):
            print("KEKURANGAN TERHADAP TAKTIK:")
            for r in under.itertuples():
                print(f"  - {r.label}: persentil {r.pct_player:.0f} vs target {r.pct_target:.0f} ({r.delta_good:+.0f} poin)")
        if len(over) == 0 and len(under) == 0 and tepat_sasaran:
            print("(profil sudah sesuai target; tidak ada penyimpangan > 10 poin)")
    return {"player": p, "arch": arch, "table": t, "similarity": sim, "tepat_sasaran": tepat_sasaran,
            "cocok": close, "kelebihan": over, "kekurangan": under}


# --- sel notebook 31 ---------------------------------------------
SHOW = ["Player", "Squad", "Comp", "arch", "Age", "sub_position", "Min",
        "market_value_in_eur", "value_growth_1y", "distance", "similarity"]

def _query(arch, vec_df, k=10, exclude_uid=None, mask=None, max_age=None, min_age=None,
           max_value=None, comp=None, exclude_squad=None):
    """Cari kandidat terdekat. `mask` membatasi jarak ke statistik tertentu (dipakai pencarian taktik)."""
    mdl = models[arch]
    z = transform(mdl, vec_df)[0]
    d2 = (Z_ALL[arch] - z) ** 2
    if mask is not None:
        d2 = d2 * np.asarray(mask, dtype=float)
    D = np.sqrt(d2.sum(axis=1))
    ref = np.median(D[D > 1e-12]) if np.any(D > 1e-12) else 1.0
    cand = players.loc[mdl["uids"]].copy()
    cand["distance"] = D
    cand["similarity"] = (100 * np.exp(-cand["distance"] / ref)).round(1)
    cand = cand.iloc[np.argsort(D)]
    if exclude_uid is not None: cand = cand[cand["uid"] != exclude_uid]
    if max_age:       cand = cand[cand["Age"] <= max_age]
    if min_age:       cand = cand[cand["Age"] >= min_age]
    if max_value:     cand = cand[cand["market_value_in_eur"] <= max_value]
    if comp:          cand = cand[cand["Comp"].str.contains(comp, case=False, na=False)]
    if exclude_squad: cand = cand[cand["Squad"] != exclude_squad]
    cand["distance"] = cand["distance"].round(3)
    return cand.head(k)

def _fit_short(p, arch, tgt, pct_t, mask, n=2):
    """Ringkasan satu baris untuk tabel hasil pencarian: lebih & kurang dibanding target taktik."""
    t = _fit_table(p, arch, tgt, pct_t, mask)
    over = t[t["verdict"] == "kelebihan"].sort_values("delta_good", ascending=False).head(n)
    under = t[t["verdict"] == "kekurangan"].sort_values("delta_good").head(n)
    if over.empty and under.empty:
        return "sesuai target"
    plus = ", ".join(f"{r.label} {r.delta_good:+.0f}" for r in over.itertuples())
    minus = ", ".join(f"{r.label} {r.delta_good:+.0f}" for r in under.itertuples())
    parts = []
    if plus:
        parts.append(f"lebih: {plus}")
    if minus:
        parts.append(f"kurang: {minus}")
    return " | ".join(parts)

def search_by_tactic(arch, tactic=None, sliders=None, k=10, explain=True, **filters):
    tgt = tactic_to_vector(arch, tactic, sliders)
    pct_t = tactic_pcts(arch, tactic, sliders)
    mask = tactic_mask(arch, tactic, sliders)
    out = _query(arch, tgt, k=k, mask=mask, **filters).copy()
    if explain:
        out["kenapa"] = [_fit_short(players.loc[u], arch, tgt, pct_t, mask) for u in out["uid"]]
    if tactic:
        print(f"{ARCH_LABEL[arch]} · {TACTICS[arch][tactic]['label']} — {TACTICS[arch][tactic]['desc']}")
    return out[SHOW + (["kenapa"] if explain else [])]

search_by_tactic("ST", "poacher", k=8, max_age=27)


# --- sel notebook 33 ---------------------------------------------
MIN_REL_CMP = 0.10
RAW_DIFF = 0.20

def _raw_phrase(r, better, worse):
    """Kalimat arah yang benar untuk statistik normal maupun terbalik (mis. offside: makin kecil makin baik)."""
    arah = "lebih tinggi" if GOOD_DIR[r.feature] > 0 else "lebih sedikit"
    return f"{r.label} {_fmt(r.feature, better)} vs {_fmt(r.feature, worse)} ({r.rel_diff:.0%} {arah})"

def explain_compare(a, b, squad_a=None, squad_b=None, verbose=True, n=3):
    pa, pb = get_player(a, squad_a), get_player(b, squad_b)
    if pa is None or pb is None:
        return None
    same = pa["arch"] == pb["arch"]

    if not same:
        res = explain_similarity(pa["uid"], pb["uid"], verbose=False)
        if verbose:
            print(f"A: {pa['Player']} — {ARCH_LABEL[pa['arch']]}, umur {pa['Age']:.0f}, {eur(pa['market_value_in_eur'])}")
            print(f"B: {pb['Player']} — {ARCH_LABEL[pb['arch']]}, umur {pb['Age']:.0f}, {eur(pb['market_value_in_eur'])}")
            print("⚠️ Beda arketipe: tidak ada model KNN bersama, jadi perbandingan memakai persentil dan ditafsirkan hati-hati.\n")
            print("Paling mirip: " + "; ".join(f"{LABELS[r.feature]} {r.pct_a:.0f} vs {r.pct_b:.0f}" for r in res["similar"].itertuples()))
            print("Paling berbeda: " + "; ".join(f"{LABELS[r.feature]} {r.pct_a:.0f} vs {r.pct_b:.0f}" for r in res["different"].itertuples()))
        return {"A": pa, "B": pb, "same_arch": False, "table": res["table"], "warning": "beda arketipe"}

    t = distance_contrib(models[pa["arch"]], players.loc[[pa["uid"]]], players.loc[[pb["uid"]]])
    ca, cb = CONTRIB[pa["arch"]].loc[pa["uid"]], CONTRIB[pa["arch"]].loc[pb["uid"]]
    t["pct_a"] = [_pct_of(pa, f) for f in t["feature"]]
    t["pct_b"] = [_pct_of(pb, f) for f in t["feature"]]
    t["gap_pct"] = t["pct_a"] - t["pct_b"]
    t["gap_good"] = [g if GOOD_DIR[f] >= 0 else -g for f, g in zip(t["feature"], t["gap_pct"])]
    t["dphi"] = [float(ca[f] - cb[f]) for f in t["feature"]]
    t["d_effect"] = np.exp(t["dphi"]) - 1
    t["rel_diff"] = [(abs(x - y) / max(abs(x), abs(y), 1e-9)) for x, y in zip(t["a"], t["b"])]

    def winner(r):
        """Unggul kalau angka mentah beda >= 10% DAN model nilai pasar searah.
        Persentil tidak dipakai sebagai syarat karena pemain elit menumpuk di 96-100."""
        if GOOD_DIR[r.feature] == 0 or r.rel_diff < MIN_REL_CMP:
            return "seimbang"
        raw_better = GOOD_DIR[r.feature] * (r.a - r.b)
        if raw_better > 0 and r.dphi > 0:
            return "A"
        if raw_better < 0 and r.dphi < 0:
            return "B"
        return "tidak didukung model" if r.rel_diff >= RAW_DIFF else "seimbang"
    t["winner"] = [winner(r) for r in t.itertuples()]
    t["beda_angka"] = t["winner"] == "tidak didukung model"

    t = t.sort_values("contrib").reset_index(drop=True)
    similar = t.head(n)
    pembeda = t.tail(n).iloc[::-1]
    a_up = t[t["winner"] == "A"].sort_values("gap_good", ascending=False).head(n)
    b_up = t[t["winner"] == "B"].sort_values("gap_good").head(n)
    raw = t[t["beda_angka"]].sort_values("rel_diff", ascending=False).head(n)

    # keunggulan angka murni (tanpa konfirmasi model) -> tetap dilaporkan, tapi diberi label jelas
    def _raw_side(df, sign):
        return df[(df["rel_diff"] >= MIN_REL_CMP) & (df["gap_good"] * sign > 0)]
    raw_a = _raw_side(t, +1).sort_values("rel_diff", ascending=False).head(n)
    raw_b = _raw_side(t, -1).sort_values("rel_diff", ascending=False).head(n)

    if verbose:
        print(f"A: {pa['Player']} — {pa['Squad']}, {ARCH_LABEL[pa['arch']]}, umur {pa['Age']:.0f}, {eur(pa['market_value_in_eur'])}")
        print(f"B: {pb['Player']} — {pb['Squad']}, {ARCH_LABEL[pb['arch']]}, umur {pb['Age']:.0f}, {eur(pb['market_value_in_eur'])}")
        d = float(t["distance"].iloc[0])
        sim = float(100 * np.exp(-d / max(D_REF[pa["arch"]], 1e-9)))
        rank, pct = _neighbor_rank(pa["arch"], pa["uid"], pb["uid"])
        print(f"Jarak KNN: {d:.3f} | skor kemiripan {sim:.0f}/100 | B tetangga ke-{rank} dari A "
              f"(lebih dekat dari {pct:.0f}% pemain searketipe)\n")
        print("MIRIP DI:")
        for r in similar.itertuples():
            print(f"  = {r.label}: {_fmt(r.feature, r.a)} vs {_fmt(r.feature, r.b)} (persentil {r.pct_a:.0f} vs {r.pct_b:.0f})")
        print("PEMBEDA UTAMA:")
        for r in pembeda.itertuples():
            arah = "lebih tinggi" if r.a > r.b else "lebih rendah"
            print(f"  ≠ {r.label}: {_fmt(r.feature, r.a)} vs {_fmt(r.feature, r.b)} (A {arah}, selisih angka {r.rel_diff:.0%})")
        print(f"\n{pa['Player']} UNGGUL (model & angka sepakat):")
        for r in a_up.itertuples():
            print(f"  + {r.label}: {_fmt(r.feature, r.a)} vs {_fmt(r.feature, r.b)} "
                  f"(selisih angka {r.rel_diff:.0%}; dorongan nilai {r.d_effect:+.0%})")
        if a_up.empty:
            print("  (tidak ada yang menonjol)")
        print(f"{pb['Player']} UNGGUL (model & angka sepakat):")
        for r in b_up.itertuples():
            print(f"  + {r.label}: {_fmt(r.feature, r.b)} vs {_fmt(r.feature, r.a)} "
                  f"(selisih angka {r.rel_diff:.0%}; dorongan nilai {-r.d_effect:+.0%})")
        if b_up.empty:
            print("  (tidak ada yang menonjol)")
        if a_up.empty and b_up.empty:
            print("\nCatatan: tidak ada statistik yang beda >= 10% DAN didukung model nilai pasar sekaligus.")
            print("Sebabnya, model nilai pasar menyamaratakan pemain di level ekstrem (persentil 96-100), "
                  "sehingga selisih angka yang besar tidak selalu menambah dorongan nilai.")
            print("Keunggulan angka murni (tanpa konfirmasi model) tetap dilaporkan di bawah.\n")
        print("UNGGUL SECARA ANGKA (belum tentu dihargai pasar):")
        if len(raw_a):
            print(f"  {pa['Player']} lebih baik di: " + "; ".join(_raw_phrase(r, r.a, r.b) for r in raw_a.itertuples()))
        if len(raw_b):
            print(f"  {pb['Player']} lebih baik di: " + "; ".join(_raw_phrase(r, r.b, r.a) for r in raw_b.itertuples()))
        if raw_a.empty and raw_b.empty:
            print("  (tidak ada selisih angka >= 10% pada statistik yang bisa dinilai baik/buruk)")
        if len(raw):
            print("\nBEDA ANGKA TAPI ARAH MODEL BERLAWANAN (jangan diklaim sebagai keunggulan):")
            for r in raw.itertuples():
                print(f"  ~ {r.label}: {_fmt(r.feature, r.a)} vs {_fmt(r.feature, r.b)}")
    return {"A": pa, "B": pb, "same_arch": True, "table": t, "similar": similar, "different": pembeda,
            "a_better": a_up, "b_better": b_up, "raw_a": raw_a, "raw_b": raw_b,
            "beda_angka": raw, "warning": None}

_ = explain_compare("Lamine Yamal", "Michael Olise")


# --- sel notebook 35 ---------------------------------------------
def find_best_fit(who, k=5, squad=None, needs=None, improve_weight=0.5, pool=40, verbose=True, **filters):
    p = get_player(who, squad)
    if p is None:
        return None
    arch = p["arch"]
    ex = explain_player(p["uid"], verbose=False)

    if needs is None:
        needs = {r.feature: -r.phi for r in ex["weaknesses"].itertuples()}
    elif isinstance(needs, (list, tuple, set)):
        needs = {f: 1.0 for f in needs}
    bad = [f for f in needs if f not in ARCH_FEATS[arch]]
    if bad:
        raise ValueError(f"kebutuhan {bad} tidak valid untuk {ARCH_LABEL[arch]}. Pilihan: {ARCH_FEATS[arch]}")
    keep = {r.feature: r.phi for r in ex["strengths"].itertuples()}

    cands = _query(arch, players.loc[[p["uid"]]], k=pool, exclude_uid=p["uid"], **filters).copy()
    if cands.empty:
        print("Tidak ada kandidat yang lolos filter.")
        return None

    def good(row, f):
        return row[f"pct_{f}"] if GOOD_DIR[f] >= 0 else 100 - row[f"pct_{f}"]

    def weighted_change(row, feats, sign):
        tot = sum(feats.values())
        if not tot:
            return 0.0
        s = 0.0
        for f, w in feats.items():
            delta = sign * (good(row, f) - good(p, f))
            if delta >= MIN_PCT_GAP:
                s += w * delta
        return s / tot / 100.0

    gain = np.array([weighted_change(r, needs, +1) for _, r in cands.iterrows()])
    loss = np.array([weighted_change(r, keep, -1) for _, r in cands.iterrows()])
    net = np.clip(0.5 + gain - loss, 0, 1)

    sim_n = cands["similarity"].values / 100.0          # skor mirip absolut (50 = jarak tipikal)
    w = improve_weight if needs else 0.0                # tanpa kebutuhan -> murni kemiripan
    cands["fit"] = (100 * ((1 - w) * sim_n + w * net)).round(1)

    why = []
    for _, r in cands.iterrows():
        if not needs:
            why.append("(tidak ada kekurangan menonjol; diurutkan berdasarkan kemiripan)")
            continue
        up = sorted([(LABELS[f], good(r, f) - good(p, f)) for f in needs if good(r, f) - good(p, f) >= MIN_PCT_GAP],
                    key=lambda x: -x[1])
        down = sorted([(LABELS[f], good(p, f) - good(r, f)) for f in keep if good(p, f) - good(r, f) >= MIN_PCT_GAP],
                      key=lambda x: -x[1])
        why.append("Menutup: " + (", ".join(f"{n} (+{v:.0f})" for n, v in up[:3]) or "-")
                   + " | Mengorbankan: " + (", ".join(f"{n} (-{v:.0f})" for n, v in down[:3]) or "-"))
    cands["why"] = why

    out = cands.sort_values("fit", ascending=False).head(k)
    if verbose:
        need_txt = ", ".join(LABELS[f] for f in needs) or "(tidak ada kekurangan menonjol)"
        keep_txt = ", ".join(LABELS[f] for f in list(keep)[:4]) or "-"
        print(f"Acuan: {p['Player']} ({p['Squad']}, {ARCH_LABEL[arch]}, umur {p['Age']:.0f})")
        print(f"Kebutuhan yang ingin ditutup : {need_txt}")
        print(f"Kelebihan yang dipertahankan : {keep_txt}")
        if not needs:
            print("⚠️ Pemain acuan tidak punya kekurangan menonjol, jadi daftar ini hanya berisi pemain paling mirip. "
                  "Pakai needs=['tklw_p90', ...] kalau ingin memaksa mencari perbaikan di statistik tertentu.")
    return out[["Player", "Squad", "Comp", "Age", "market_value_in_eur", "similarity", "fit", "why"]]

find_best_fit("Erling Haaland", k=5, max_age=28)


# --- sel notebook 37 ---------------------------------------------
def _top_text(uid, verdict, n=2):
    t = _explain_table(uid)
    t = t[t["verdict"] == verdict]
    t = t.reindex(t["effect"].abs().sort_values(ascending=False).index).head(n)
    return ", ".join(f"{r.label} ({r.effect:+.0%})" for r in t.itertuples()) or "-"

def _lines(df):
    return "\n".join(f"- {r.label}: {_fmt(r.feature, r.value)} (lebih baik dari {r.better:.0f}% pemain searketipe), "
                     f"pengaruh ke nilai {r.effect:+.0%}" for r in df.itertuples()) or "- (tidak ada yang menonjol)"

def _bullets(df, cols):
    return "\n".join("- " + " | ".join(str(getattr(r, c)) for c in cols) for r in df.itertuples()) or "- (tidak ada)"

def build_prompt(mode="scout", who=None, other=None, tactic=None, sliders=None, squad=None, k=4, **filters):
    HEAD = ("Kamu adalah scout sepak bola profesional. Tulis dalam Bahasa Indonesia hanya berdasarkan DATA di bawah. "
            "Jangan mengarang statistik. Kelebihan/kekurangan berasal dari analisis SHAP; itu sudut pandang model, "
            "bukan penilaian mutlak. Kekurangan hanya dinilai pada tugas inti arketipe; daftar kosong bukan berarti "
            "pemain tanpa kekurangan.\n\n")

    if mode == "scout":
        ex = explain_player(who, squad, verbose=False)
        if ex is None:
            return None
        p = ex["player"]
        sim = _query(p["arch"], players.loc[[p["uid"]]], k=k, exclude_uid=p["uid"], **filters)
        sim_lines = "\n".join(
            f"- {r.Player} ({r.Squad}, {ARCH_LABEL[r.arch]}, umur {r.Age:.0f}, {eur(r.market_value_in_eur)}, "
            f"skor mirip {r.similarity}); {_top_text(r.uid, 'Kelebihan')}" for r in sim.itertuples())
        ctx = ", ".join(f"{x['label']} {x['effect']:+.0%}" for x in ex["context"])
        return HEAD + f"""PEMAIN: {p['Player']} | {p['Squad']} ({p['Comp']}) | {ARCH_LABEL[p['arch']]} / {p['sub_position']} | umur {p['Age']:.0f} | {p['Min']:.0f} menit | nilai pasar {eur(p['market_value_in_eur'])}

KELEBIHAN (SHAP):
{_lines(ex['strengths'])}

KEKURANGAN (SHAP):
{_lines(ex['weaknesses'])}

KONTEKS (bukan kemampuan bermain): {ctx}

PEMAIN PALING MIRIP (KNN):
{sim_lines}

Format laporan: (1) Gaya bermain, (2) Kelebihan, (3) Kekurangan, (4) Perbandingan dengan pemain mirip,
(5) Rekomendasi: cocok direkrut atau tidak, dan untuk tipe tim seperti apa."""

    if mode == "compare":
        r = explain_compare(who, other, squad, None, verbose=False)
        if r is None:
            return None
        pa, pb = r["A"], r["B"]
        if not r["same_arch"]:
            body = _bullets(r["table"].head(8), ["feature", "pct_a", "pct_b", "gap"])
            return HEAD + f"""A: {pa['Player']} ({ARCH_LABEL[pa['arch']]})\nB: {pb['Player']} ({ARCH_LABEL[pb['arch']]})
Catatan: beda arketipe, perbandingan memakai persentil.

PERBANDINGAN PERSENTIL:
{body}

Format: (1) Ringkasan, (2) Siapa lebih cocok untuk tim menyerang/bertahan, (3) Risiko, (4) Kesimpulan."""
        return HEAD + f"""A: {pa['Player']} | {pa['Squad']} | {ARCH_LABEL[pa['arch']]} | umur {pa['Age']:.0f} | nilai pasar {eur(pa['market_value_in_eur'])}
B: {pb['Player']} | {pb['Squad']} | {ARCH_LABEL[pb['arch']]} | umur {pb['Age']:.0f} | nilai pasar {eur(pb['market_value_in_eur'])}

MIRIP DI:
{_bullets(r['similar'], ['label', 'a', 'b', 'pct_a', 'pct_b'])}

PEMBEDA UTAMA:
{_bullets(r['different'], ['label', 'a', 'b', 'pct_a', 'pct_b'])}

{pa['Player']} UNGGUL DI:
{_bullets(r['a_better'], ['label', 'a', 'b', 'rel_diff', 'd_effect'])}

{pb['Player']} UNGGUL DI:
{_bullets(r['b_better'], ['label', 'a', 'b', 'rel_diff', 'd_effect'])}

UNGGUL SECARA ANGKA SAJA (belum tentu dihargai pasar; jangan diklaim sebagai keunggulan mutlak):
- {pa['Player']} lebih baik di: {"; ".join(_raw_phrase(x, x.a, x.b) for x in r['raw_a'].itertuples()) or "-"}
- {pb['Player']} lebih baik di: {"; ".join(_raw_phrase(x, x.b, x.a) for x in r['raw_b'].itertuples()) or "-"}

BEDA ANGKA TAPI ARAH MODEL BERLAWANAN (abaikan sebagai keunggulan):
{_bullets(r['beda_angka'], ['label', 'a', 'b'])}

Format: (1) Ringkasan perbandingan, (2) Siapa lebih cocok untuk tim yang menyerang/bertahan, (3) Risiko masing-masing, (4) Kesimpulan 1–2 kalimat."""

    if mode == "tactic":
        p = get_player(who, squad)
        if p is None:
            return None
        ex = explain_tactic_fit(p["uid"], tactic, sliders, verbose=False)
        if ex is None:
            return None
        label = TACTICS[p["arch"]][tactic]["label"] if tactic else "slider kustom"
        desc = TACTICS[p["arch"]][tactic]["desc"] if tactic else "-"
        return HEAD + f"""PEMAIN: {p['Player']} | {p['Squad']} | {ARCH_LABEL[p['arch']]} | umur {p['Age']:.0f} | nilai pasar {eur(p['market_value_in_eur'])}
TAKTIK YANG DICARI: {label} — {desc}
SKOR KEMIRIPAN DENGAN PROFIL TAKTIK: {ex['similarity']:.1f}/100

{"COCOK KARENA:" if ex['tepat_sasaran'] else "BELUM ADA STATISTIK YANG PERSIS SESUAI TARGET. Yang paling dekat:"}
{_bullets(ex['cocok'], ['label', 'a', 'pct_player', 'pct_target'])}

KELEBIHAN TERHADAP TAKTIK:
{_bullets(ex['kelebihan'], ['label', 'pct_player', 'pct_target', 'delta_good'])}

KEKURANGAN TERHADAP TAKTIK:
{_bullets(ex['kekurangan'], ['label', 'pct_player', 'pct_target', 'delta_good'])}

Format: (1) Kenapa cocok untuk taktik ini, (2) Risiko/kekurangan, (3) Saran peran yang paling pas, (4) Kesimpulan."""

    if mode == "best_fit":
        p = get_player(who, squad)
        if p is None:
            return None
        bf = find_best_fit(p["uid"], k=k, needs=None, verbose=False, **filters)
        if bf is None:
            return None
        return HEAD + f"""PEMAIN ACUAN: {p['Player']} | {p['Squad']} | {ARCH_LABEL[p['arch']]} | umur {p['Age']:.0f} | {eur(p['market_value_in_eur'])}

KANDIDAT PENGGANTI (KNN + SHAP):
{_bullets(bf, ['Player', 'Squad', 'Age', 'market_value_in_eur', 'similarity', 'fit', 'why'])}

Format: (1) Siapa kandidat terbaik dan kenapa, (2) Apa yang ditutup dan apa yang dikorbankan, (3) Perbandingan singkat antar kandidat, (4) Rekomendasi akhir."""

    raise ValueError("mode harus salah satu: scout, compare, tactic, best_fit")

print(build_prompt("scout", who="Lamine Yamal", k=3)[:1200])


# --- sel notebook 44 ---------------------------------------------
def run_tests():
    # 1) atribusi jarak
    for arch in ARCH_KEYS:
        d = players[players["arch"] == arch]
        if len(d) < 5:
            continue
        u0, u1 = d["uid"].iloc[0], d["uid"].iloc[4]
        t = distance_contrib(models[arch], players.loc[[u0]], players.loc[[u1]])
        Z = transform(models[arch], players.loc[[u0]])
        dist, idx = models[arch]["nn"].kneighbors(Z, n_neighbors=len(d))
        j = list(models[arch]["uids"]).index(u1)
        pos = list(idx[0]).index(j)
        assert abs(t["contrib"].sum() - dist[0][pos] ** 2) < 1e-9, f"atribusi jarak gagal di {arch}"
        assert abs(t["share"].sum() - 1) < 1e-9
        assert np.isfinite(t["contrib"]).all()

    # 2) aditivitas SHAP nilai pasar
    for arch in ARCH_KEYS:
        d = players[players["arch"] == arch]
        recon = BASE[arch] + CONTRIB[arch].loc[d["uid"]].sum(axis=1).values
        err = np.abs(recon - value_models[arch]["model"].predict(d[value_models[arch]["cols"]].fillna(0)))
        assert err.max() < 1e-6, f"aditivitas SHAP gagal di {arch}"

    # 3) aturan kelebihan/kekurangan
    for uid in players["uid"].sample(120, random_state=1):
        t = _explain_table(uid)
        s, w = t[t["verdict"] == "Kelebihan"], t[t["verdict"] == "Kekurangan"]
        assert (s["phi"] > 0).all() and (s["effect"] >= MIN_EFFECT).all()
        assert (w["phi"] < 0).all() and (w["effect"] <= -MIN_EFFECT).all()
        assert ((s["feature"].map(GOOD_DIR) * (s["pct"] - 50)) >= MIN_PCT_GAP).all()
        assert ((w["feature"].map(GOOD_DIR) * (w["pct"] - 50)) <= -MIN_PCT_GAP).all()
        assert w["feature"].isin(WEAKNESS_OK[players.loc[uid, "arch"]]).all(), "kekurangan di luar tugas inti"

    # 4) kalimat taktik konsisten
    for uid in players["uid"].sample(40, random_state=2):
        p = players.loc[uid]
        arch = p["arch"]
        tactic = list(TACTICS[arch])[0]
        ex = explain_tactic_fit(uid, tactic, verbose=False)
        for r in ex["kelebihan"].itertuples():
            assert r.delta_good > MIN_PCT_GAP
        for r in ex["kekurangan"].itertuples():
            assert r.delta_good < -MIN_PCT_GAP
        assert len(ex["cocok"]) > 0
        assert ex["similarity"] > 0
        if ex["tepat_sasaran"]:                        # kalau disebut "cocok", verdict-nya memang "sesuai"
            assert (ex["cocok"]["verdict"] == "sesuai").all()
            wajib = ex["cocok"][ex["cocok"]["good_target"] >= 60]     # statistik yang diminta tinggi
            assert (wajib["delta_good"].abs() <= MIN_PCT_GAP).all()
        else:                                          # kalau belum sesuai, jangan mengaku cocok
            assert (ex["cocok"]["verdict"] != "sesuai").all()

    # 5) perbandingan simetris & identitas
    r1 = explain_compare("Lamine Yamal", "Michael Olise", verbose=False)
    r2 = explain_compare("Michael Olise", "Lamine Yamal", verbose=False)
    assert np.allclose(r1["table"]["dphi"], -r2["table"]["dphi"])
    assert set(r1["a_better"]["feature"]) == set(r2["b_better"]["feature"])
    assert set(r1["raw_a"]["feature"]) == set(r2["raw_b"]["feature"])
    for rr, sgn in ((r1, 1), (r2, -1)):          # a_better harus didukung model DAN angka
        s = rr["a_better"]
        assert (sgn * s["dphi"] >= 0).all() and (s["rel_diff"] >= MIN_REL_CMP).all()
        assert (sgn * s["gap_good"] > 0).all()
    r3 = explain_compare("Erling Haaland", "Erling Haaland", verbose=False)
    assert (r3["table"]["dphi"] == 0).all() and (r3["table"]["winner"] == "seimbang").all()
    assert r3["raw_a"].empty and r3["raw_b"].empty

    # 6) best-fit
    uid_h = int(get_player("Erling Haaland")["uid"])
    bf = find_best_fit("Erling Haaland", k=5, max_age=28, verbose=False)
    assert len(bf) == 5 and bf["fit"].between(0, 100).all() and (bf["Age"] <= 28).all()
    assert bf["fit"].is_monotonic_decreasing and uid_h not in bf.index
    pool_ids = set(_query("ST", players.loc[[uid_h]], k=40, exclude_uid=uid_h, max_age=28).index)
    assert set(bf.index) <= pool_ids, "best-fit harus berasal dari kandidat KNN"

    # 7) pencarian taktik lebih dekat ke target daripada acak (hanya statistik yang diminta taktik)
    for arch, tactic in [("ST", "poacher"), ("CB", "stopper"), ("W", "wide_creator"), ("GK", "shot_stopper")]:
        tgt = tactic_to_vector(arch, tactic)
        pct_t = tactic_pcts(arch, tactic)
        mask = tactic_mask(arch, tactic)
        feats = [f for f, m in zip(ARCH_FEATS[arch], mask) if m > 0]
        res = _query(arch, tgt, k=10, mask=mask)
        d = players[players["arch"] == arch]
        gap_top = np.mean([np.mean([abs(d.loc[u, f"pct_{f}"] - pct_t[f]) for f in feats]) for u in res["uid"]])
        rnd = d.sample(10, random_state=0)
        gap_rnd = np.mean([np.mean([abs(rnd.loc[u, f"pct_{f}"] - pct_t[f]) for f in feats]) for u in rnd.index])
        assert gap_top < gap_rnd, f"pencarian taktik {arch}/{tactic} tidak lebih baik dari acak"

    # 8) semua kalimat tidak kosong
    for uid in players["uid"].sample(100, random_state=3):
        p = players.loc[uid]
        arch = p["arch"]
        tactic = list(TACTICS[arch])[0]
        assert explain_tactic_fit(uid, tactic, verbose=False)["similarity"] > 0
        assert len(explain_player(uid, verbose=False)["table"]) == len(ARCH_FEATS[arch])
        other = players[players["arch"] == arch].sample(1, random_state=uid)["uid"].iloc[0]
        if other != uid:
            assert explain_similarity(uid, other, verbose=False)["table"].shape[0] == len(ARCH_FEATS[arch])

    # 9) prompt semua mode
    assert "KELEBIHAN" in build_prompt("scout", who="Lamine Yamal")
    assert "UNGGUL" in build_prompt("compare", who="Lamine Yamal", other="Michael Olise")
    assert "TAKTIK" in build_prompt("tactic", who="Lamine Yamal", tactic="wide_creator")
    assert "KANDIDAT" in build_prompt("best_fit", who="Erling Haaland")

    print("✓ Semua tes lulus")

run_tests()


# --- sel notebook 46 ---------------------------------------------
OUT_DIR = "ml/export"
os.makedirs(OUT_DIR, exist_ok=True)

# 1) tabel pemain
app_cols = (["uid", "Player", "Squad", "Comp", "Age", "Born", "Pos", "pos_group", "arch", "sub_position", "Min",
             "player_id", "foot", "height_in_cm", "country_of_citizenship", "contract_expiration_date",
             "market_value_in_eur", "highest_market_value_in_eur", "value_growth_1y", "image_url", "url"]
            + [c for a in ARCH_KEYS for c in ARCH_FEATS[a]]
            + [c for c in players.columns if c.startswith("pct_")])
app_cols = list(dict.fromkeys([c for c in app_cols if c in players.columns]))
players[app_cols].to_csv(f"{OUT_DIR}/players.csv", index=False, encoding="utf-8")

# 2) tetangga + alasan (kalimat SHAP disimpan terstruktur)
TOPN = 15
ARR_BY_ARCH = {a: players.loc[mdl["uids"], ARCH_FEATS[a]].to_numpy(dtype=float) for a, mdl in models.items()}
PCT_BY_ARCH = {a: players.loc[mdl["uids"], [f"pct_{f}" for f in ARCH_FEATS[a]]].to_numpy(dtype=float)
               for a, mdl in models.items()}

def _reasons(uid_a, uid_b, arch, n=2):
    """Alasan mirip & pembeda, dihitung dari dekomposisi jarak (tanpa DataFrame per pasangan)."""
    feats = ARCH_FEATS[arch]
    ia, ib = POS_BY_ARCH[arch][int(uid_a)], POS_BY_ARCH[arch][int(uid_b)]
    c = (Z_ALL[arch][ia] - Z_ALL[arch][ib]) ** 2
    tot = float(c.sum())
    share = c / tot if tot else c
    order = np.argsort(c)

    def pack(idx):
        return [{"feature": feats[j], "label": LABELS[feats[j]],
                 "a": round(float(ARR_BY_ARCH[arch][ia, j]), 3),
                 "b": round(float(ARR_BY_ARCH[arch][ib, j]), 3),
                 "pct_a": round(float(PCT_BY_ARCH[arch][ia, j]), 1),
                 "pct_b": round(float(PCT_BY_ARCH[arch][ib, j]), 1),
                 "share": round(float(share[j]), 4)} for j in idx]

    return pack(order[:n]), pack(order[-n:][::-1])

similar = {}
for arch, mdl in models.items():
    d = players.loc[mdl["uids"]]
    Z = Z_ALL[arch]
    dist, idx = mdl["nn"].kneighbors(Z, n_neighbors=min(TOPN + 1, len(d)))
    for row, uid in enumerate(mdl["uids"]):
        items = []
        for dd, j in zip(dist[row], idx[row]):
            if j == row:
                continue
            nb_uid = int(mdl["uids"][j])
            same, diff = _reasons(uid, nb_uid, arch)
            items.append({"uid": nb_uid,
                          "similarity": round(float(100 * np.exp(-dd / max(D_REF[arch], 1e-9))), 1),
                          "mirip_karena": same, "pembeda": diff})
        similar[int(uid)] = {"arch": arch, "neighbors": items[:TOPN]}

json.dump(similar, open(f"{OUT_DIR}/similar_players.json", "w", encoding="utf-8"), ensure_ascii=False)

# 3) kelebihan/kekurangan + ringkasan kalimat
def _pack(df, n=4):
    df = df.reindex(df["effect"].abs().sort_values(ascending=False).index).head(n)
    return [{"feature": r.feature, "label": r.label, "value": round(float(r.value), 3),
             "better_than_pct": round(float(r.better), 1), "effect_pct": round(float(r.effect) * 100, 1)}
            for r in df.itertuples()]

def _ringkas(p, t):
    s = t[t["verdict"] == "Kelebihan"].reindex(t["effect"].abs().sort_values(ascending=False).index).head(2)
    w = t[t["verdict"] == "Kekurangan"].reindex(t["effect"].abs().sort_values(ascending=False).index).head(2)
    plus = ", ".join(f"{r.label} ({r.effect:+.0%})" for r in s.itertuples()) or "tidak ada yang menonjol"
    minus = ", ".join(f"{r.label} ({r.effect:+.0%})" for r in w.itertuples()) or "tidak ada yang menonjol"
    return (f"{p['Player']} ({ARCH_LABEL[p['arch']]}, {p['Age']:.0f} tahun, {eur(p['market_value_in_eur'])}). "
            f"Kelebihan: {plus}. Kekurangan: {minus}.")

expl = {}
for uid, arch in zip(players["uid"], players["arch"]):
    t = _explain_table(uid, arch)
    c = CONTRIB[arch].loc[uid]
    p = players.loc[uid]
    expl[int(uid)] = {"arketipe": arch, "arketipe_label": ARCH_LABEL[arch],
                      "ringkasan": _ringkas(p, t),
                      "kelebihan": _pack(t[t["verdict"] == "Kelebihan"]),
                      "kekurangan": _pack(t[t["verdict"] == "Kekurangan"]),
                      "konteks": [{"label": CTX_LABELS[k], "effect_pct": round(float(np.exp(c[k]) - 1) * 100, 1)}
                                  for k in ["Age", "Min", "start_rate", "plus_p90", "ctx_liga"]]}
json.dump(expl, open(f"{OUT_DIR}/explanations.json", "w", encoding="utf-8"), ensure_ascii=False)

# 4) dorongan SHAP nilai pasar
parts = []
for arch in ARCH_KEYS:
    t = CONTRIB[arch][ARCH_FEATS[arch] + ["Age", "Min", "start_rate", "plus_p90", "crd_p90", "ctx_liga"]].copy()
    t["base"] = BASE[arch]
    t = t.reset_index().melt(id_vars=["uid", "base"], var_name="feature", value_name="phi")
    t["arch"] = arch
    parts.append(t)
contrib_long = pd.concat(parts, ignore_index=True)
contrib_long["effect_pct"] = ((np.exp(contrib_long["phi"]) - 1) * 100).round(2)
contrib_long["phi"] = contrib_long["phi"].round(4)
contrib_long.to_csv(f"{OUT_DIR}/contrib_long.csv", index=False)

# 5) atribusi jarak ke profil taktik default tiap arketipe
rows = []
for arch in ARCH_KEYS:
    tactic = list(TACTICS[arch])[0]
    tgt, pct_t = tactic_to_vector(arch, tactic), tactic_pcts(arch, tactic)
    mask = tactic_mask(arch, tactic)
    for uid in players.loc[players["arch"] == arch, "uid"]:
        t = _fit_table(players.loc[uid], arch, tgt, pct_t, mask)
        t["uid"] = int(uid); t["arch"] = arch; t["tactic"] = tactic
        rows.append(t)
knn_long = pd.concat(rows, ignore_index=True)
knn_long["share"] = knn_long["share"].round(4)
knn_long["contrib"] = knn_long["contrib"].round(4)
knn_long[["uid", "arch", "tactic", "feature", "a", "pct_player", "pct_target",
          "contrib", "share", "distance", "verdict"]].to_csv(f"{OUT_DIR}/knn_contrib_long.csv", index=False)

# 6) konfigurasi aplikasi
info = {"min_minutes": MIN_MINUTES, "min_arch_n": MIN_ARCH_N,
        "min_effect": MIN_EFFECT, "min_pct_gap": MIN_PCT_GAP,
        "labels": LABELS, "ctx_labels": CTX_LABELS, "good_dir": GOOD_DIR,
        "arch_label": ARCH_LABEL, "arch_features": ARCH_FEATS, "feature_weights": FEATURE_WEIGHTS,
        "tactics": TACTICS, "weakness_ok": WEAKNESS_OK,
        "value_models": {a: {"r2_test": round(v["r2_test"], 3), "reliability": v["reliability"], "n": v["n"],
                             "base_value_eur": round(float(np.exp(BASE[a])))} for a, v in value_models.items()},
        "hexagon_axes": {"outfield": [{"label": LABELS[f], "feature": f, "invert": GOOD_DIR[f] < 0}
                                      for f in ["npg_p90", "ast_p90", "sh_p90", "crs_p90", "tklw_p90", "int_p90"]],
                         "GK": [{"label": LABELS[f], "feature": f, "invert": GOOD_DIR[f] < 0}
                                for f in GK_FEATS]}}
json.dump(info, open(f"{OUT_DIR}/model_info.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)

# 7) model untuk API
joblib.dump({"models": models, "arch_feats": ARCH_FEATS, "weights": FEATURE_WEIGHTS,
             "min_minutes": MIN_MINUTES}, f"{OUT_DIR}/knn_models.joblib")
joblib.dump({"value_models": value_models, "base": BASE, "context": CONTEXT,
             "league_cols": LEAGUE_COLS}, f"{OUT_DIR}/value_models.joblib")

for f in sorted(os.listdir(OUT_DIR)):
    print(f"{f:26s} {os.path.getsize(f'{OUT_DIR}/{f}') / 1024:9.0f} KB")
