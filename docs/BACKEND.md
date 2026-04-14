# Backend Contract

V1 reuses the existing `gurgles.beer` Express + SQLite backend. No new server work.

## Base URL

`https://gurgles.beer`

## Endpoints consumed

### `POST /api/scores`

Submit a run's final score.

**Request body (JSON):**
```json
{
  "name": "string, 1-20 chars, trimmed",
  "score": 12345,
  "platform": "ios" | "android",
  "version": "1.0.0+1"
}
```

**Response:** `200 OK` on success, `{ "ok": true }`. Failures are non-blocking for the player — we show the score locally and retry submission in the background.

### `GET /api/scores/top?limit=50`

Fetch top-N scores for the leaderboard scene.

**Response:**
```json
{
  "scores": [
    { "name": "Gurgles", "score": 99999, "createdAt": "2026-04-14T10:00:00Z" }
  ]
}
```

## Client behavior

- Implemented in `lib/services/api_client.dart`.
- All requests time out at 5s.
- On failure, a pending score is queued in `SharedPreferences` and retried on next app launch.
- Player name is stored locally via `SharedPreferences` under `player_name`.

## Open items

- Confirm with web game whether `platform` and `version` fields already exist on the server side, or whether the server ignores unknown fields (it should — safer to send them either way).
- Decide whether to gate submissions behind any anti-cheat token. For V1, no — the web game has none either.
