from __future__ import annotations
from abc import ABC, abstractmethod
from datetime import datetime, timezone
from azure.cosmos import CosmosClient, PartitionKey
from azure.cosmos.exceptions import CosmosResourceNotFoundError
from .config import settings
from .models import LeaderboardScore, ScoreDocument

# Abstract Repository Interface and Implementations
class ScoreRepository(ABC):
    @abstractmethod
    def save_score(self, score: ScoreDocument) -> None:
        raise NotImplementedError

    @abstractmethod
    def get_monthly_leaderboard(self, limit: int) -> list[LeaderboardScore]:
        raise NotImplementedError


class InMemoryScoreRepository(ScoreRepository):
    def __init__(self) -> None:
        self._scores: list[ScoreDocument] = []

    def save_score(self, score: ScoreDocument) -> None:
        self._scores.append(score)

    def get_monthly_leaderboard(self, limit: int) -> list[LeaderboardScore]:
        current_bucket = datetime.now(timezone.utc).strftime("%Y-%m")
        monthly_scores = [s for s in self._scores if s.monthBucket == current_bucket]
        monthly_scores.sort(key=lambda s: s.score, reverse=True)
        return [LeaderboardScore(name=s.name, score=s.score) for s in monthly_scores[:limit]]


class CosmosScoreRepository(ScoreRepository):
    def __init__(self, endpoint: str, key: str, database_name: str,container_name: str,) -> None:
        self._client = CosmosClient(url=endpoint, credential=key)
        self._database = self._client.create_database_if_not_exists(id=database_name)

        try:
            self._container = self._database.get_container_client(container_name)
            self._container.read()
        except CosmosResourceNotFoundError:
            self._container = self._database.create_container_if_not_exists(
                id=container_name,
                partition_key=PartitionKey(path="/monthBucket"),
            )

    def save_score(self, score: ScoreDocument) -> None:
        self._container.upsert_item(score.model_dump())

    def get_monthly_leaderboard(self, limit: int) -> list[LeaderboardScore]:
        current_bucket = datetime.now(timezone.utc).strftime("%Y-%m")
        query = """
        SELECT TOP @limit c.name, c.score
        FROM c
        WHERE c.monthBucket = @monthBucket
        ORDER BY c.score DESC
        """
        params = [
            {"name": "@limit", "value": int(limit)},
            {"name": "@monthBucket", "value": current_bucket},
        ]

        items = list(
            self._container.query_items(
                query=query,
                parameters=params,
                partition_key=current_bucket,
                enable_cross_partition_query=False,
            )
        )
        return [LeaderboardScore(name=i["name"], score=i["score"]) for i in items]


def build_repository() -> ScoreRepository:
    if settings.cosmos_endpoint and settings.cosmos_key:
        return CosmosScoreRepository(
            endpoint=settings.cosmos_endpoint,
            key=settings.cosmos_key,
            database_name=settings.cosmos_database_name,
            container_name=settings.cosmos_container_name,
        )
    return InMemoryScoreRepository()
