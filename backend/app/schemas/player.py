"""Skema Pydantic untuk data pemain.

Nama field `stats` harus sama dengan `PlayerFeature.jsonKey` di sisi Flutter:
pace, shooting, passing, dribbling, defending, physical, vision, stamina.
"""

from pydantic import BaseModel, Field


class FeatureMeta(BaseModel):
    """Metadata satu fitur model."""

    key: str = Field(..., description="Kunci JSON fitur, mis. 'pace'.")
    label: str = Field(..., description="Nama tampilan fitur.")
    description: str = Field("", description="Penjelasan singkat fitur.")


class PlayerOut(BaseModel):
    """Data satu pemain yang dikirim ke aplikasi."""

    id: str
    name: str
    club: str
    position: str
    age: int
    stats: dict[str, float] = Field(
        default_factory=dict,
        description="Nilai tiap fitur pada skala 0-100.",
    )


class PlayersResponse(BaseModel):
    """Balasan endpoint `GET /players`."""

    total: int
    players: list[PlayerOut]
