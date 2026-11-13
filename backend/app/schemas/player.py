"""Skema Pydantic untuk data pemain.

Skema mengikuti **statistik nyata** dari dataset FBref/Transfermarkt: 10 statistik
per-90 untuk pemain lapangan dan 5 untuk kiper. Kuncinya harus sama dengan
`arch_features` pada `backend/app/ml/artifacts/feature_names.json`.
"""

from __future__ import annotations

from pydantic import BaseModel, Field


class FeatureMeta(BaseModel):
    """Metadata satu statistik model."""

    key: str = Field(..., description="Kunci JSON statistik, mis. 'npg_p90'.")
    label: str = Field(..., description="Nama tampilan statistik.")
    unit: str = Field("per90", description="Satuan: 'per90' atau 'percent'.")
    good_dir: int = Field(
        ..., description="1 = makin tinggi makin baik, -1 = makin tinggi makin buruk, 0 = netral."
    )
    invert: bool = Field(False, description="True bila grafik harus dibalik (good_dir = -1).")
    weight: float = Field(1.0, description="Bobot statistik ini pada jarak KNN arketipe.")


class ArchetypeMeta(BaseModel):
    """Satu arketipe (kelompok peran) beserta statistik yang dipakai."""

    key: str
    label: str
    features: list[FeatureMeta]
    players: int = Field(0, description="Jumlah pemain pada arketipe ini.")


class PlayerOut(BaseModel):
    """Satu pemain yang dikirim ke aplikasi."""

    id: str
    name: str
    club: str | None = None
    league: str | None = None
    position: str | None = Field(None, description="Sub-posisi Transfermarkt, mis. 'Right Winger'.")
    position_group: str | None = Field(None, description="Kelompok kasar: GK/DF/MF/FW.")
    archetype: str = Field(..., description="Kode arketipe: GK, CB, FB, DM, CM, AM, W, ST.")
    age: int | None = None
    minutes: float | None = None
    market_value_eur: float | None = None
    value_growth_1y: float | None = Field(
        None, description="Perubahan nilai pasar 1 tahun (0.25 = +25%)."
    )
    image_url: str | None = None
    foot: str | None = None
    contract_until: str | None = None
    context: dict[str, float] = Field(
        default_factory=dict,
        description="Variabel konteks untuk model nilai pasar (bukan kemampuan bermain).",
    )
    stats: dict[str, float] = Field(
        default_factory=dict, description="Statistik per-90 nyata pada arketipe ini."
    )
    percentiles: dict[str, float] = Field(
        default_factory=dict,
        description="Persentil statistik di antara pemain searketipe (0-100).",
    )


class PlayerDetailOut(PlayerOut):
    """Detail pemain + hasil SHAP model nilai pasar."""

    reliability: str | None = Field(None, description="Keandalan model nilai pasar arketipe ini.")
    r2_test: float | None = Field(None, description="R² uji model nilai pasar.")
    base_value_eur: float | None = Field(
        None, description="Titik awal model (nilai pasar rata-rata arketipe) dalam Euro."
    )


class PlayersResponse(BaseModel):
    """Balasan endpoint `GET /players`."""

    total: int = Field(..., description="Jumlah pemain setelah filter.")
    count: int = Field(..., description="Jumlah pemain pada halaman ini.")
    offset: int = 0
    limit: int | None = None
    players: list[PlayerOut]
