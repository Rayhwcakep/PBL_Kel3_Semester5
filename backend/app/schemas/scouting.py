"""Skema Pydantic untuk permintaan dan balasan scouting (KNN + SHAP)."""

from pydantic import BaseModel, Field

from app.schemas.player import PlayerOut


class ScoutRequest(BaseModel):
    """Body JSON untuk `POST /scout`."""

    criteria: dict[str, float] = Field(
        ...,
        description="Nilai target tiap fitur (0-100), mis. {'pace': 85}.",
    )
    position: str | None = Field(None, description="Filter posisi (opsional).")
    max_age: int | None = Field(None, description="Filter umur maksimal (opsional).")
    top_k: int = Field(5, ge=1, le=50, description="Jumlah kandidat terdekat.")


class ScoutingResultOut(BaseModel):
    """Satu pemain hasil pencocokan KNN."""

    rank: int
    similarity: float = Field(..., description="Skor kemiripan 0-1.")
    distance: float = Field(..., description="Jarak KNN (semakin kecil semakin mirip).")
    player: PlayerOut


class ContributionOut(BaseModel):
    """Satu kontribusi SHAP untuk sebuah fitur."""

    feature: str = Field(..., description="Kunci fitur, mis. 'pace'.")
    value: float = Field(..., description="Nilai fitur pada pemain (0-100).")
    shap_value: float = Field(
        ...,
        description="Kontribusi SHAP. Positif menaikkan skor, negatif menurunkan.",
    )


class ExplanationOut(BaseModel):
    """Penjelasan SHAP untuk satu pemain."""

    player_id: str
    base_value: float = Field(..., description="Nilai dasar model.")
    prediction: float = Field(..., description="Nilai prediksi akhir model.")
    contributions: list[ContributionOut] = Field(default_factory=list)


class ScoutResponse(BaseModel):
    """Balasan endpoint `POST /scout`."""

    k: int
    query: dict[str, float]
    results: list[ScoutingResultOut]
    explanations: list[ExplanationOut] = Field(default_factory=list)
