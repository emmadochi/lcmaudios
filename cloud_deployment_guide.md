# ☁️ Cloud Deployment Guide: LCM Audios Backend & PostgreSQL Database

This guide explains how to deploy the **LCM Audios Backend Service** and **PostgreSQL Database** to free/low-cost cloud hosts so your **Android APK** and **Web Client** work anywhere in the world over mobile 3G/4G/5G networks.

---

## Deployment Option 1: Railway.app (Recommended — 5 Minutes)

Railway automatically detects the `Dockerfile` in `backend/Dockerfile` and spins up the Express API and PostgreSQL database simultaneously.

### **Step 1: Push Project to GitHub**
1. Create a repository on GitHub (e.g. `LCMAudios`).
2. Push your project code:
   ```bash
   git init
   git add .
   git commit -m "Deploy LCM Audios ecosystem"
   git remote add origin https://github.com/YOUR_USERNAME/LCMAudios.git
   git push -u origin main
   ```

### **Step 2: Deploy on Railway**
1. Go to **[Railway.app](https://railway.app)** and log in with GitHub.
2. Click **New Project** → **Deploy from GitHub repo**.
3. Select your `LCMAudios` repository.
4. Click **+ Add Service** → **Database** → **PostgreSQL**.
5. Under your API service, set the Root Directory to `/backend` or select the included `Dockerfile`.
6. Under **Variables**, add:
   * `PORT`: `5000`
   * `NODE_ENV`: `production`
   * `JWT_SECRET`: `your_random_secret_string`
   * `DATABASE_URL`: `${{Postgres.DATABASE_URL}}` (Railway auto-links this!)
7. Railway will generate a public HTTPS domain (e.g. `https://lcm-audios-api.up.railway.app`).

---

## Deployment Option 2: Render.com + Supabase (Free Tier)

### **Step 1: Create Free PostgreSQL on Supabase**
1. Go to **[Supabase.com](https://supabase.com)** and create a free project.
2. Under **Project Settings** → **Database**, copy your `URI` string:
   `postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-ID].supabase.co:5432/postgres`

### **Step 2: Deploy Backend Web Service on Render**
1. Go to **[Render.com](https://render.com)** and click **New** → **Web Service**.
2. Connect your GitHub repository.
3. Set **Root Directory**: `backend`
4. Set **Build Command**: `npm install && npx prisma generate && npm run build`
5. Set **Start Command**: `npm run start`
6. Add Environment Variables:
   * `DATABASE_URL`: (Paste your Supabase URI from Step 1)
   * `NODE_ENV`: `production`
   * `JWT_SECRET`: `lcm_secret_key`
7. Render will provide a free live URL: `https://lcm-audios.onrender.com`.

---

## 📱 Connecting your Android APK to your Live Cloud URL

Once your backend is live on Railway or Render, update `_liveCloudUrl` in [api_service.dart](file:///c:/xampp/htdocs/LCMAudios/lcm_audios_app/lib/services/api_service.dart#L9):

```dart
static const String _liveCloudUrl = 'https://your-app-name.up.railway.app/api/v1';
```

Then re-build the release APK:
```bash
cd lcm_audios_app
flutter build apk --release
```

Your new APK will connect to your live cloud API worldwide!
