"""Konfigurasi aplikasi backend, dibaca dari environment / file `.env`."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Root folder `backend/`.
BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    """Pengaturan aplikasi.

    Nilai dapat dioverride lewat environment variable atau file `.env`.
    """

    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "ScoutML API"
    app_version: str = "1.0.0"

    # Prefix seluruh endpoint. Harus sama dengan `AppConfig.apiPrefix` di Flutter.
    api_prefix: str = "/api/v1"

    cors_origins: str = "*"

    # Folder artefak model ML (model KNN, scaler, dll).
    artifacts_dir: str = "app/ml/artifacts"

    # Dataset pemain dalam format JSON.
    players_file: str = "app/data/players.json"

    @property
    def artifacts_path(self) -> Path:
        return (BASE_DIR / self.artifacts_dir).resolve()

    @property
    def players_path(self) -> Path:
        return (BASE_DIR / self.players_file).resolve()

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    """Mengembalikan instance Settings (di-cache)."""
    return Settings()
