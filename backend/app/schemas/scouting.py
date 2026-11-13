"""Skema Pydantic untuk scouting: pencarian, penjelasan, perbandingan, best-fit."""

from __future__ import annotations

from pydantic import BaseModel, Field

from app.schemas.player import PlayerDetailOut, PlayerOut

# ---------------------------------------------------------------------------
# Filter yang bisa dipakai di hampir semua endpoint
# ---------------------------------------------------------------------------


class PlayerFilter(BaseModel):
    """Filter kandidat. Semua opsional."""

    max_age: int | None = Field(None, ge=15, le=45)
    min_age: int | None = Field(None, ge=15, le=45)
    max_value_eur: float | None = Field(None, ge=0, description="Batas nilai pasar (Euro).")
    league: str | None = Field(None, description="Cocokkan sebagian nama liga.")
    exclude_id: str | None = Field(None, description="Pemain yang tidak boleh muncul (mis. dirinya).")


# ---------------------------------------------------------------------------
# Pencarian
# ---------------------------------------------------------------------------


class ScoutRequest(PlayerFilter):
    """Body JSON untuk `POST /scout`.

    `criteria` berisi nilai statistik **nyata** (per-90), bukan skala 0-100.
    Statistik yang tidak diisi memakai median arketipe.
    """

    archetype: str = Field(..., description="Kode arketipe, mis. 'ST'.")
    criteria: dict[str, float] = Field(
        default_factory=dict,
        description="Target statistik, mis. {'npg_p90': 0.6, 'sh_p90': 3.5}.",
    )
    top_k: int = Field(10, ge=1, le=50)


class TacticScoutRequest(PlayerFilter):
    """Body JSON untuk `POST /scout/tactic`.

    Pakai `tactic` (preset) atau `sliders` (persentil 0-100), boleh keduanya.
    `sliders` menimpa target preset.
    """

    archetype: str = Field(..., description="Kode arketipe, mis. 'CB'.")
    tactic: str | None = Field(None, description="Preset taktik, mis. 'stopper'.")
    sliders: dict[str, float] | None = Field(
        None, description="Target persentil manual per statistik (0-100)."
    )
    top_k: int = Field(10, ge=1, le=50)
    explain: bool = Field(True, description="Sertakan ringkasan lebih/kurang tiap kandidat.")


class ScoutingResultOut(BaseModel):
    """Satu kandidat hasil pencarian."""

    rank: int
    similarity: float = Field(
        ...,
        description=(
            "Skor kemiripan 0-100 = 100 × exp(−jarak / jarak_tipikal arketipe). "
            "Mendekati 100 untuk pemain sangat mirip, sekitar 37 pada jarak tipikal."
        ),
    )
    distance: float = Field(..., description="Jarak KNN (semakin kecil semakin mirip).")
    player: PlayerOut
    why: str | None = Field(
        None, description="Ringkasan selisih terhadap target, mis. 'lebih: Assist +14 | kurang: Tekel -11'."
    )


class ScoutResponse(BaseModel):
    """Balasan `POST /scout` dan `POST /scout/tactic`."""

    archetype: str
    tactic: str | None = None
    k: int
    target: dict[str, float] = Field(default_factory=dict, description="Profil target yang dipakai.")
    target_percentiles: dict[str, float] = Field(default_factory=dict)
    results: list[ScoutingResultOut]


# ---------------------------------------------------------------------------
# Penjelasan SHAP
# ---------------------------------------------------------------------------


class ContributionOut(BaseModel):
    """Satu baris penilaian statistik."""

    feature: str
    label: str
    value: float = Field(..., description="Nilai statistik pemain (per-90).")
    percentile: float = Field(..., description="Persentil di antara pemain searketipe.")
    better_than_pct: float = Field(..., description="Lebih baik dari berapa persen pemain searketipe.")
    shap_value: float = Field(..., description="Kontribusi SHAP pada log nilai pasar.")
    effect_pct: float = Field(..., description="Pengaruh ke nilai pasar dalam persen.")
    verdict: str = Field(..., description="Kelebihan / Kekurangan / Netral / Diabaikan.")


class ExplainResponse(BaseModel):
    """Balasan `GET /players/{id}/explain`."""

    player: PlayerDetailOut
    strengths: list[ContributionOut]
    weaknesses: list[ContributionOut]
    context: list[ContributionOut] = Field(
        default_factory=list, description="Pengaruh variabel konteks (usia, menit, liga)."
    )
    summary: str = Field(..., description="Ringkasan satu paragraf siap tampil.")


# ---------------------------------------------------------------------------
# Pemain mirip
# ---------------------------------------------------------------------------


class NeighborReasonOut(BaseModel):
    feature: str
    label: str
    a: float = Field(..., description="Nilai pada pemain acuan.")
    b: float = Field(..., description="Nilai pada tetangga.")
    pct_a: float
    pct_b: float
    contribution: float = Field(..., description="Kontribusi ke jarak kuadrat.")
    share: float = Field(..., description="Porsi terhadap total jarak (0-1).")


class SimilarPlayerOut(BaseModel):
    player: PlayerOut
    similarity: float
    distance: float
    rank: int = Field(..., description="Peringkat tetangga (1 = paling mirip).")
    closer_than_pct: float = Field(..., description="Lebih dekat dari berapa persen pemain searketipe.")


class SimilarResponse(BaseModel):
    player: PlayerOut
    same_archetype: bool
    neighbors: list[SimilarPlayerOut]
    similar_because: list[NeighborReasonOut] = Field(default_factory=list)
    different_because: list[NeighborReasonOut] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Perbandingan
# ---------------------------------------------------------------------------


class CompareRequest(BaseModel):
    """Body JSON untuk `POST /compare`."""

    a: str = Field(..., description="ID pemain pertama.")
    b: str = Field(..., description="ID pemain kedua.")


class CompareRowOut(BaseModel):
    feature: str
    label: str
    a: float
    b: float
    pct_a: float
    pct_b: float
    gap_pct: float = Field(..., description="Selisih persentil (A - B).")
    gap_good: float = Field(..., description="Selisih setelah arah logika diterapkan.")
    winner: str = Field(..., description="A / B / seimbang / tidak didukung model.")
    rel_diff: float = Field(..., description="Selisih relatif angka mentah (0-1).")
    d_effect: float = Field(..., description="Selisih dorongan nilai pasar (A - B).")


class CompareResponse(BaseModel):
    a: PlayerOut
    b: PlayerOut
    same_archetype: bool
    warning: str | None = None
    similarity: float | None = None
    neighbor_rank: int | None = Field(
        None, description="Peringkat B sebagai tetangga A (0 = pemain yang sama)."
    )
    rows: list[CompareRowOut]
    a_better: list[CompareRowOut] = Field(default_factory=list)
    b_better: list[CompareRowOut] = Field(default_factory=list)
    raw_only: list[CompareRowOut] = Field(
        default_factory=list, description="Angka beda jauh tapi arah model berlawanan."
    )
    summary: str = ""


# ---------------------------------------------------------------------------
# Best-fit
# ---------------------------------------------------------------------------


class BestFitCandidateOut(BaseModel):
    player: PlayerOut
    similarity: float
    fit: float = Field(..., description="Skor kecocokan 0-100 (kemiripan + perbaikan bersih).")
    gain: float = Field(..., description="Kebutuhan yang berhasil ditutup (porsi).")
    loss: float = Field(..., description="Kelebihan yang harus dikorbankan (porsi).")
    why: str


class BestFitResponse(BaseModel):
    player: PlayerOut
    needs: dict[str, float] = Field(default_factory=dict, description="Kekurangan acuan + bobotnya.")
    keep: dict[str, float] = Field(default_factory=dict, description="Kelebihan acuan yang dijaga.")
    candidates: list[BestFitCandidateOut]
