# padel-api (NestJS)

Separate backend project for the Flutter MVP (`/Padel`) with PostgreSQL-ready setup for Neon + Render.

## Quick Start

```bash
cp .env.example .env
npm install
npm run start:dev
```

API runs on `http://localhost:3000`.

Local development uses file-persistent SQL.js when `DATABASE_URL` is empty, so accounts and data survive restart.
If you want to force local mode even when a URL exists, set `DB_DRIVER=sqljs`.
The API ships with no seed/demo users; a fresh database starts empty.

Local persistence env vars:

- `DB_LOCAL_PERSIST=true`
- `DB_LOCAL_PATH=data/padel-local.sqlite`

Set `DB_LOCAL_PERSIST=false` only if you explicitly want in-memory temporary data.

## Neon + Render

Use these env vars on Render:

- `DATABASE_URL` -> Neon connection string
- `DB_SSL=true`
- `DB_SYNC=true` (MVP only)
- `DB_DRIVER` should be empty (or unset)
- `DB_LOCAL_PERSIST` can be ignored on Render when using Neon
- `PORT` provided by Render automatically

Start command on Render:

```bash
npm run start:prod
```

Build command on Render:

```bash
npm run build
```

After Render is live, build the Flutter web app with the Render API URL:

```bash
flutter build web --dart-define=PADEL_API_URL=https://your-api.onrender.com
```

## Main Endpoints (MVP)

- `GET /health`
- `GET /users`
- `POST /users`
- `POST /users/login`
- `POST /users/:id/follow/:targetId`
- `DELETE /users/:id/follow/:targetId`
- `GET /users/:id/followers`
- `GET /users/:id/following`
- `GET /posts`
- `POST /posts`
- `POST /posts/:id/like`
- `GET /matches`
- `GET /matches/:id`
- `POST /matches`
- `POST /matches/:id/join`
- `POST /matches/:id/leave`
- `POST /matches/:id/invite`
- `POST /matches/:id/requests/:participantId/approve`
- `POST /matches/:id/requests/:participantId/reject`
- `POST /matches/:id/requests/:participantId/hold`
- `GET /notifications/:userId`
- `POST /notifications/:id/read`

### Required `POST /users` fields

- `name`
- `handle`
- `email`
- `phoneNumber`
- `birthDate` (ISO date string)
- `password` (min 6 chars)
- Optional: `photoData` (base64 string)

### Required `POST /users/login` fields

- `email`
- `password`

### Private join request

For private matches, call `POST /matches/:id/join` with:

```json
{
  "userId": "uuid",
  "inviteCode": "ABC123"
}
```

## Flutter Connection

Run Flutter with API URL:

```bash
flutter run --dart-define=PADEL_API_URL=http://127.0.0.1:3000
```

For Android emulator use:

```bash
flutter run --dart-define=PADEL_API_URL=http://10.0.2.2:3000
```
