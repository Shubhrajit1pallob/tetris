from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "tetris-score-api"
    app_env: str = "dev"
    app_port: int = 8000

    allowed_origins: list[str] = Field(default=["*"])

    cosmos_endpoint: str | None = None
    cosmos_key: str | None = None
    cosmos_database_name: str = "tetris"
    cosmos_container_name: str = "scores"

    leaderboard_limit: int = 20


settings = Settings()
