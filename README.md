# Scoutify — PBL Kelompok 3 Semester 5

Aplikasi scouting pemain sepak bola: antarmuka Flutter, backend FastAPI, dan
model KNN + SHAP yang dilatih dari data FBref + Transfermarkt 2025/26.

## Struktur

```
lib/            aplikasi Flutter (UI + state)
backend/        API FastAPI + artefak model  -> lihat backend/README.md
ml/             script pipeline: notebook -> artefak backend
DATASET/        data mentah (tidak masuk git, unduh sendiri)
```

## Menjalankan backend

```powershell
python -m venv backend/.venv
backend/.venv/Scripts/python.exe -m pip install -r backend/requirements.txt
backend/.venv/Scripts/python.exe -m uvicorn app.main:app --reload --app-dir backend
```

Buka <http://127.0.0.1:8000/docs>. Detail endpoint, daftar statistik, dan
batasan model ada di [backend/README.md](backend/README.md).

## Menjalankan aplikasi

```powershell
flutter run
```

Saat ini aplikasi masih memakai data contoh (`AppConfig.useMockData = true`).
Untuk memakai API asli:

```powershell
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Catatan: skema data backend sudah memakai **10 statistik nyata** (gol, assist,
tembakan, umpan silang, tekel, intersep, ...), sedangkan `PlayerFeature` di
Flutter masih 8 atribut gaya. Penyamaan kontrak data belum dikerjakan.

## Melatih ulang model

```powershell
python ml/notebook_to_script.py        # notebook -> script
backend/.venv/Scripts/python.exe ml/export_artifacts.py
backend/.venv/Scripts/python.exe ml/build_backend_artifacts.py
backend/.venv/Scripts/python.exe ml/verify_artifacts.py
```

Butuh `DATASET/pemain/players_data-2025_2026.csv`,
`DATASET/transfermarket/players.csv`, dan
`DATASET/transfermarket/player_valuations.csv`.
