# ☁️ Cloud Deployment Guide — LCM Audios

This guide covers deploying the **LCM Audios** backend API + PostgreSQL database
to Railway (recommended) or Render + Supabase, then connecting the Flutter app.

---

## Pre-Deployment Checklist

- [ ] Project pushed to GitHub repository
- [ ] `backend/.env` is in `.gitignore` (never commit secrets)
- [ ] `npx prisma generate` passes locally
- [ ] `npx tsc --noEmit` passes (0 errors)
- [ ] `GET /health` returns `{ status: "online" }` locally

---

## Option A — Railway (Recommended · ~5 min)

Railway detects [`railway.json`](file:///c:/xampp/htdocs/LCMAudios/railway.json) and
[`backend/Dockerfile`](file:///c:/xampp/htdocs/LCMAudios/backend/Dockerfile) automatically.

### Step 1 · Push to GitHub
```bash
git init
git add .
git commit -m "feat: LCM Audios production-ready backend"
git remote add origin https://github.com/YOUR_USERNAME/LCMAudios.git
git push -u origin main
```

### Step 2 · Create Railway project
1. Go to [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub repo**
2. Select your `LCMAudios` repository
3. Railway detects `railway.json` and starts building

### Step 3 · Add PostgreSQL
1. In your Railway project → **+ New** → **Database** → **Add PostgreSQL**
2. Click your **API service** → **Variables** → add:

| Variable | Value |
|----------|-------|
| `NODE_ENV` | `production` |
| `PORT` | `5000` |
| `JWT_SECRET` | *(generate a strong random string)* |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` ← Railway links this automatically |

### Step 4 · Verify
Railway generates a public URL like `https://lcm-audios-api.up.railway.app`.

```bash
curl https://lcm-audios-api.up.railway.app/health
# → { "status": "online", "service": "LCM Audios Backend API & Ingestion Pipeline" }

curl https://lcm-audios-api.up.railway.app/api/v1/tracks
# → { "count": 4, "tracks": [...] }
```

> **Note:** On first deploy, `prisma migrate deploy` runs automatically inside Docker
> before the server starts (wired into `CMD` in the Dockerfile). Seed data is
> included in migrations via `prisma/seed.ts` — run manually once:
> ```bash
> railway run npm run db:seed
> ```

---

## Option B — Render + Supabase (Free Tier)

[`render.yaml`](file:///c:/xampp/htdocs/LCMAudios/render.yaml) defines the full
infrastructure-as-code. One click deploys both API and database.

### Step 1 · Create Supabase database
1. Go to [supabase.com](https://supabase.com) → New project
2. **Project Settings** → **Database** → copy the **Connection String (URI)**:
   ```
   postgresql://postgres:[PASSWORD]@db.[PROJECT-ID].supabase.co:5432/postgres
   ```

### Step 2 · Deploy on Render
1. Go to [render.com](https://render.com) → **New** → **Blueprint**
2. Connect your GitHub repo — Render detects `render.yaml` automatically
3. Set `DATABASE_URL` to the Supabase URI from Step 1
4. Click **Apply** — Render builds and deploys

### Step 3 · Run seed (once)
In Render Shell or via CLI:
```bash
npm run db:seed
```

---

## Connecting the Flutter App

Once deployed, update `_liveCloudUrl` in
[`api_service.dart`](file:///c:/xampp/htdocs/LCMAudios/lcm_audios_app/lib/services/api_service.dart#L9):

```dart
// Line 9 — replace with your actual Railway or Render URL:
static const String _liveCloudUrl = 'https://lcm-audios-api.up.railway.app/api/v1';
```

Then rebuild the release APK:
```bash
cd lcm_audios_app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `JWT_SECRET` | ✅ | Auth token signing key (min 32 chars) |
| `NODE_ENV` | ✅ | Set to `production` |
| `PORT` | ✅ | API listen port (default `5000`) |
| `API_HOST` | Optional | Base URL for HLS playlist URLs |
| `CORS_ORIGIN` | Optional | Allowed CORS origins (default `*`) |

---

## Architecture After Deployment

```
Flutter App (Android / iOS / Web)
        │
        │  HTTPS REST API
        ▼
Railway / Render  ←── Node.js Express (Docker)
        │                    │
        │                    ├── Prisma ORM
        │                    ├── HLS Transcoder (npm ffmpeg)
        │                    └── JWT Auth
        │
        ▼
PostgreSQL (Railway Postgres / Supabase)
  Users · Tracks · LyricLines · SermonNotes · TelemetryEvents
```
