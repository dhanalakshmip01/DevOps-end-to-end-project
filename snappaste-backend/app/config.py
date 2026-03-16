from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "SnapPaste"
    environment: str = "development"
    database_url: str = "postgresql://snappaste:snappaste@localhost:5432/snappaste"
    allowed_origins: list[str] = ["http://localhost:3000", "http://localhost:5173"]

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
