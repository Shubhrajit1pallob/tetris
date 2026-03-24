from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .models import ScoreCreate, ScoreDocument
from .repository import build_repository

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

repository = build_repository()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/scores")
def post_score(
    name: str = Form(...),
    score: int = Form(...),
    level: int = Form(...),
    rowsHit: int = Form(...),
    time: int = Form(...),
) -> dict[str, str]:
    payload = ScoreCreate(
        name=name,
        score=score,
        level=level,
        rowsHit=rowsHit,
        time=time,
    )
    document = ScoreDocument.from_score_create(payload)
    repository.save_score(document)
    return {"status": "ok"}


@app.get("/api/scores")
def get_scores() -> dict[str, object]:
    scores = repository.get_monthly_leaderboard(limit=settings.leaderboard_limit)
    return {
        "status": "ok",
        "scores": [item.model_dump() for item in scores],
    }
