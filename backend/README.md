# ScoutML API

Backend pencarian pemain dengan **KNN** (kemiripan gaya bermain) dan **SHAP**
(penjelasan "pasar menghargai apa dari pemain ini"). Semua angka berasal dari
dataset nyata FBref + Transfermarkt musim 2025/26, bukan atribut gaya FIFA.

## Menjalankan

```powershell
# 1. sekali saja: buat venv dan pasang dependensi
python -m venv backend/.venv
backend/.venv/Scripts/python.exe -m pip install -r backend/requirements.txt

# 2. jalankan API
backend/.venv/Scripts/python.exe -m uvicorn app.main:app --reload --app-dir backend
```

- Dokumentasi interaktif: <http://127.0.0.1:8000/docs>
- Cek status: `GET /api/v1/health`

## Endpoint

| Method | Path | Isi |
|---|---|---|
| GET | `/health` | Status, jumlah pemain, model siap atau tidak |
| GET | `/meta/features` | 10 statistik lapangan / 5 statistik kiper per arketipe |
| GET | `/meta/tactics` | Preset taktik per arketipe + R² model nilai pasar |
| GET | `/players` | Daftar pemain: arketipe, liga, umur, harga, cari nama |
| GET | `/players/{id}` | Detail pemain + persentil |
| GET | `/players/{id}/explain` | Kelebihan & kekurangan (SHAP) |
| GET | `/players/{id}/similar` | Tetangga terdekat + alasan mirip & pembeda |
| GET | `/players/{id}/fit` | Kecocokan dengan satu taktik |
| POST | `/scout` | Cari pemain dengan target statistik nyata (per-90) |
| POST | `/scout/tactic` | Cari pemain dengan preset taktik atau slider persentil |
| POST | `/compare` | Bandingkan dua pemain |
| GET | `/best-fit/{id}` | Rekomendasi pengganti yang menutup kekurangan |

Contoh:

```powershell
# cari striker muda dengan gol 0,6 dan tembakan 3,5 per 90
curl.exe -X POST http://127.0.0.1:8000/api/v1/scout `
  -H "Content-Type: application/json" `
  -d '{"archetype":"ST","criteria":{"npg_p90":0.6,"sh_p90":3.5},"max_age":24,"top_k":5}'
```

## Arketipe

KNN dijalankan **per arketipe**, jadi bek tengah hanya dibandingkan dengan bek
tengah: `GK, CB, FB, DM, CM, AM, W, ST`.

| Arketipe | Pemain |
|---|---|
| CB | 420 |
| CM | 341 |
| FB | 298 |
| W | 285 |
| ST | 258 |
| DM | 150 |
| GK | 139 |
| AM | 108 |

Total 1.999 pemain (minimal 450 menit bermain).

## Statistik yang dipakai

Pemain lapangan: gol non-penalti, assist, tembakan, tembakan on target, umpan
silang, intersep, tekel berhasil, pelanggaran dibuat, pelanggaran diterima,
offside (semua per 90 menit).

Kiper: save %, kebobolan per 90, clean sheet %, penyelamatan per 90, tembakan
dihadapi per 90.

## Artefak

API ini **tidak melatih model saat request**. Artefak dibangun sekali:

```powershell
backend/.venv/Scripts/python.exe ml/export_artifacts.py      # pipeline: ~5 menit, butuh DATASET/
backend/.venv/Scripts/python.exe ml/build_backend_artifacts.py
backend/.venv/Scripts/python.exe ml/verify_artifacts.py      # pemeriksaan isi artefak
```

`ml/export_artifacts.py` digenerasi dari `scouting_knn_shap_colab.ipynb` lewat
`ml/notebook_to_script.py`. Kalau notebook diubah, jalankan ulang generatornya.

Yang masuk repo:

| File | Ukuran | Isi |
|---|---|---|
| `app/data/players.json` | 1,5 MB | 1.999 pemain: statistik, persentil, konteks |
| `app/ml/artifacts/knn_models.joblib` | 185 KB | Pipeline + bobot + `NearestNeighbors` per arketipe |
| `app/ml/artifacts/value_models.joblib` | 1 MB | Model nilai pasar per arketipe (untuk SHAP) |
| `app/ml/artifacts/feature_names.json` | 12 KB | Urutan statistik, arah logika, bobot |
| `app/ml/artifacts/tactics.json` | 8 KB | Preset taktik, label arketipe |

`DATASET/` (1,5 GB) **tidak** masuk repo; taruh sendiri di root proyek.

## Uji

```powershell
cd backend
.venv/Scripts/python.exe -m pytest -q
```

24 tes mencakup: kelengkapan metadata, filter pemain, pagar verdict
(kelebihan/kekurangan searah logika sepak bola dan hanya di tugas inti
arketipe), urutan skor KNN, simetri perbandingan, filter best-fit, atribusi
jarak yang aditif, serta kasus salah masukan.

## Batasan yang perlu ditulis jujur

1. **SHAP menjelaskan model nilai pasar, bukan kebenaran mutlak.** Pasar lebih
   menghargai gol/assist daripada tekel/intersep; itu keterbatasan data.
2. **Atribusi jarak KNN mengukur kemiripan gaya, bukan kualitas.** Dua pemain
   bisa sangat mirip tapi beda kelas, karena itu nilai pasar selalu ditampilkan.
3. **Perbandingan beda arketipe** hanya memakai persentil dan diberi peringatan.
4. **Model nilai pasar tidak akurat untuk menaksir harga** (R² 0,50-0,77 dan
   kesalahan tipikal puluhan persen). Ia dipakai untuk menjelaskan pola.
5. **Skor kemiripan**: `100 × exp(−jarak / jarak_tipikal)`. Jarak tipikal
   antar pemain searketipe menghasilkan skor sekitar 37, bukan 50 seperti yang
   tertulis di narasi notebook.
