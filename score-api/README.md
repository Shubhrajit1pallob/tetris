# Score API (FastAPI)

This service provides score submission and leaderboard endpoints compatible with the Tetris frontend:

- `POST /api/scores` with `application/x-www-form-urlencoded`
- `GET /api/scores` returning `{ "status": "ok", "scores": [{"name","score"}] }`

## Run locally

1. Create and activate a virtual environment.
2. Install dependencies:

   pip install -r requirements.txt

3. Copy `.env.example` to `.env` and fill Cosmos values if you want persistent storage.
4. Start API:

   uvicorn app.main:app --reload --port 8000

If Cosmos settings are missing, the API uses in-memory storage for local testing.

## Cosmos DB setup values

Set the following in `.env`:

- `COSMOS_ENDPOINT`
- `COSMOS_KEY`
- `COSMOS_DATABASE_NAME`
- `COSMOS_CONTAINER_NAME`

The container uses partition key `/monthBucket` and stores monthly leaderboard entries.
