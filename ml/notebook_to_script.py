"""Mengubah notebook pelatihan menjadi script yang bisa dijalankan tanpa Colab.

Sumber kebenaran tetap `scouting_knn_shap_colab.ipynb`. Script ini hanya
menyalin sel kode apa adanya, lalu menambahkan beberapa penyesuaian kecil:

- Sel demo (yang hanya mencetak contoh untuk dilihat manusia) dilewati.
- Import `matplotlib` dibuang karena tidak dipakai di notebook.
- `OUT_DIR` diarahkan ke `ml/export/` dan script selalu berjalan dari root repo,
  supaya `find_file` menemukan `DATASET/...`.

Pakai:

    python ml/notebook_to_script.py
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK = ROOT / "scouting_knn_shap_colab.ipynb"
TARGET = ROOT / "ml" / "export_artifacts.py"

# Sel yang isinya hanya demonstrasi ("Kasus 1-4"): hasilnya sudah tercakup uji.
DEMO_CELLS = {39, 40, 41, 42}

HEADER = '''"""Pipeline artefak Scoutify: KNN + SHAP.

DIGENERASI dari `scouting_knn_shap_colab.ipynb` oleh `ml/notebook_to_script.py`.
Jangan edit file ini langsung - ubah notebook lalu jalankan ulang:

    python ml/notebook_to_script.py
    python ml/export_artifacts.py

Butuh file di `DATASET/pemain` dan `DATASET/transfermarket` (lihat .gitignore).
Hasil ditulis ke `ml/export/`.
"""

import os
import sys
from pathlib import Path

# Windows memakai cp1252 secara default; notebook memakai karakter Σ, ±, →.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Selalu bekerja dari root repo agar path dataset ditemukan.
os.chdir(Path(__file__).resolve().parents[1])
'''


def cell_source(cell: dict) -> str:
    source = cell.get("source", "")
    if isinstance(source, list):
        return "".join(source)
    return source


def main() -> None:
    notebook = json.loads(NOTEBOOK.read_text(encoding="utf-8"))

    parts: list[str] = [HEADER]
    skipped: list[int] = []

    for index, cell in enumerate(notebook["cells"], start=1):
        if cell.get("cell_type") != "code":
            continue
        if index in DEMO_CELLS:
            skipped.append(index)
            continue

        code = cell_source(cell)
        if not code.strip():
            continue

        # matplotlib tidak dipakai untuk apa pun selain import.
        code = "\n".join(
            line for line in code.splitlines() if "matplotlib.pyplot" not in line
        )

        # Arahkan output export ke ml/export/.
        code = code.replace(
            'OUT_DIR = "/content/export" if os.path.isdir("/content") else "export"',
            'OUT_DIR = "ml/export"',
        )

        parts.append(f"# --- sel notebook {index} ---------------------------------------------\n{code.rstrip()}\n")

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text("\n\n".join(parts), encoding="utf-8")

    print(f"Ditulis: {TARGET.relative_to(ROOT)}")
    print(f"Sel kode dipakai : {len(parts) - 1}")
    print(f"Sel demo dilewati: {skipped}")


if __name__ == "__main__":
    main()
