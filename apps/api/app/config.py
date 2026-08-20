from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    environment: str = "development"
    cors_origins: list[str] = ["http://localhost:3000"]
    max_upload_size_mb: int = 100
    temp_dir: Path = Path("/tmp/doclyvo")
    retention_hours: int = 24
    libreoffice_binary: str = "soffice"
    libreoffice_timeout_seconds: int = 60
    database_url: str | None = None


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    settings.temp_dir.mkdir(parents=True, exist_ok=True)
    return settings
