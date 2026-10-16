"""Metadata fitur model.

Urutan `FEATURE_KEYS` harus sama dengan urutan `PlayerFeature` di Flutter
dan urutan kolom saat kamu melatih model.
"""

from app.schemas.player import FeatureMeta

FEATURES: list[FeatureMeta] = [
    FeatureMeta(key="pace", label="Pace", description="Kecepatan lari pemain"),
    FeatureMeta(key="shooting", label="Shooting", description="Kualitas penyelesaian akhir"),
    FeatureMeta(key="passing", label="Passing", description="Akurasi dan kualitas umpan"),
    FeatureMeta(key="dribbling", label="Dribbling", description="Kemampuan menggiring bola"),
    FeatureMeta(key="defending", label="Defending", description="Kemampuan bertahan dan merebut bola"),
    FeatureMeta(key="physical", label="Physical", description="Kekuatan dan duel fisik"),
    FeatureMeta(key="vision", label="Vision", description="Visi bermain dan kreativitas"),
    FeatureMeta(key="stamina", label="Stamina", description="Daya tahan selama pertandingan"),
]

FEATURE_KEYS: list[str] = [feature.key for feature in FEATURES]

FEATURE_LABELS: dict[str, str] = {feature.key: feature.label for feature in FEATURES}

# Nilai default bila pengguna tidak mengisi sebuah fitur.
DEFAULT_FEATURE_VALUE: float = 50.0
