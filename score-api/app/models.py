from datetime import datetime, timezone
from uuid import uuid4

from pydantic import BaseModel, Field, field_validator


class ScoreCreate(BaseModel):
    name: str = Field(min_length=1, max_length=10)
    score: int = Field(ge=0)
    level: int = Field(ge=0)
    rowsHit: int = Field(ge=0)
    time: int = Field(ge=0)

    @field_validator("name")
    @classmethod
    def normalize_name(cls, value: str) -> str:
        return value.strip().upper()


class ScoreDocument(BaseModel):
    id: str
    name: str
    score: int
    level: int
    rowsHit: int
    time: int
    submittedAt: str
    monthBucket: str

    @classmethod
    def from_score_create(cls, payload: ScoreCreate) -> "ScoreDocument":
        now = datetime.now(timezone.utc)
        return cls(
            id=str(uuid4()),
            name=payload.name,
            score=payload.score,
            level=payload.level,
            rowsHit=payload.rowsHit,
            time=payload.time,
            submittedAt=now.isoformat(),
            monthBucket=now.strftime("%Y-%m"),
        )


class LeaderboardScore(BaseModel):
    name: str
    score: int
