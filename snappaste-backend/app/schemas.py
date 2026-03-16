import uuid
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class ExpiryOption(str, Enum):
    ONE_HOUR = "1h"
    ONE_DAY = "1d"
    ONE_WEEK = "1w"
    NEVER = "never"


class SupportedLanguage(str, Enum):
    PLAINTEXT = "plaintext"
    PYTHON = "python"
    JAVASCRIPT = "javascript"
    TYPESCRIPT = "typescript"
    BASH = "bash"
    SQL = "sql"
    JSON = "json"
    YAML = "yaml"
    GO = "go"
    RUST = "rust"
    JAVA = "java"
    CPP = "cpp"
    HTML = "html"
    CSS = "css"
    MARKDOWN = "markdown"


class PasteCreate(BaseModel):
    title: str | None = Field(default=None, max_length=255)
    content: str = Field(min_length=1, max_length=500_000)
    language: SupportedLanguage = SupportedLanguage.PLAINTEXT
    expiry: ExpiryOption = ExpiryOption.NEVER


class PasteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    short_code: str
    title: str | None
    content: str
    language: str
    expires_at: datetime | None
    view_count: int
    created_at: datetime


class PasteListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    short_code: str
    title: str | None
    language: str
    expires_at: datetime | None
    view_count: int
    created_at: datetime
