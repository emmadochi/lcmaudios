# 🚀 AWS Production Deployment Guide — LCM Audios

**Target Domain:** `http://audios.lifechangerstouch.org` / `https://audios.lifechangerstouch.org`  
**Stack:** Node.js (TypeScript / Express) · PostgreSQL · Nginx Reverse Proxy · PM2 · Certbot (SSL) · Flutter

---

## 📋 Table of Contents
1. [Server Provisioning & Prerequisites](#1-server-provisioning--prerequisites)
2. [PostgreSQL Database Setup](#2-postgresql-database-setup)
3. [Deploying the Node.js Backend](#3-deploying-the-nodejs-backend)
4. [Process Management with PM2](#4-process-management-with-pm2)
5. [Nginx Reverse Proxy Configuration](#5-nginx-reverse-proxy-configuration)
6. [Free SSL / HTTPS Setup (Certbot)](#6-free-ssl--https-setup-certbot)
7. [Connecting & Building the Flutter Mobile App](#7-connecting--building-the-flutter-mobile-app)
8. [Verification & Health Checks](#8-verification--health-checks)
9. [Maintenance & Useful Commands](#9-maintenance--useful-commands)

---

## 1. Server Provisioning & Prerequisites

Run these commands on your AWS EC2 / Lightsail instance (Ubuntu 22.04 / 24.04 LTS recommended):

### Step 1.1 · Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git ufw build-essential
```

### Step 1.2 · Install Node.js (v20 LTS)
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v # Should display v20.x
npm -v
```

### Step 1.3 · Install Global CLI Tools
```bash
sudo npm install -g pm2 typescript
```

---

## 2. PostgreSQL Database Setup

If you are hosting PostgreSQL on the same AWS server:

```bash
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create Database and User
sudo -u postgres psql
```

Inside the PostgreSQL prompt (`postgres=#`):
```sql
CREATE DATABASE lcmaudios;
CREATE USER lcmuser WITH ENCRYPTED PASSWORD 'YOUR_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE lcmaudios TO lcmuser;
\q
```

---

## 3. Deploying the Node.js Backend

### Step 3.1 · Clone Repository
```bash
cd /var/www
sudo git clone https://github.com/YOUR_GITHUB_REPO/LCMAudios.git
sudo chown -R $USER:$USER /var/www/LCMAudios
cd /var/www/LCMAudios/backend
```

### Step 3.2 · Configure Environment Variables (`.env`)
Create and edit `/var/www/LCMAudios/backend/.env`:

```bash
nano .env
```

Paste the following configuration:
```env
# SERVER CONFIGURATION
PORT=5000
NODE_ENV=production
API_HOST=https://audios.lifechangerstouch.org
CORS_ORIGIN=*

# DATABASE CONNECTION URL
DATABASE_URL="postgresql://lcmuser:YOUR_STRONG_PASSWORD@localhost:5432/lcmaudios?schema=public"

# AUTHENTICATION
JWT_SECRET="generate_a_very_secure_random_string_here_min_32_characters"

# STORAGE & STREAMING (OPTIONAL CLOUD INTEGRATION)
R2_BUCKET_NAME="lcmaudios-media"
```

### Step 3.3 · Install Dependencies & Build
```bash
npm install
npx prisma generate
npx prisma migrate deploy
npm run db:seed  # Seeds initial categories and admin data
npm run build
```

---

## 4. Process Management with PM2

PM2 ensures the backend stays online 24/7 and restarts automatically if the server reboots or crashes.

```bash
# Start backend process
pm2 start dist/server.js --name lcmaudios-backend

# Configure startup on system reboot
pm2 startup
# (Run the sudo env PATH=... command printed on screen if prompted)

# Save the process list
pm2 save
```

Check status:
```bash
pm2 status
pm2 logs lcmaudios-backend
```

---

## 5. Nginx Reverse Proxy Configuration

Nginx acts as the front-facing web server on port 80/443, proxying traffic to the Node.js API running on port 5000.

### Step 5.1 · Install Nginx
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Step 5.2 · Configure Site
Create `/etc/nginx/sites-available/lcmaudios`:
```bash
sudo nano /etc/nginx/sites-available/lcmaudios
```

Paste the following Nginx configuration:
```nginx
server {
    listen 80;
    server_name audios.lifechangerstouch.org;

    # Allow audio uploads up to 150MB
    client_max_body_size 150M;

    # Gzip Compression for Fast Metadata & API responses
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Step 5.3 · Enable Site & Reload Nginx
```bash
sudo ln -s /etc/nginx/sites-available/lcmaudios /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

---

## 6. Free SSL / HTTPS Setup (Certbot)

HTTPS is essential for Android & iOS mobile applications to communicate securely without network blocks.

### Step 6.1 · Run Certbot
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d audios.lifechangerstouch.org
```

* Enter your email address.
* Agree to the terms of service.
* Select option to redirect all HTTP traffic to HTTPS.

Certbot automatically configures SSL certificates and sets up automatic renewal.

---

## 7. Connecting & Building the Flutter Mobile App

The Flutter mobile app is configured to communicate with your AWS server.

### Step 7.1 · Verify API URL in `api_service.dart`
In [lib/services/api_service.dart](file:///c:/xampp/htdocs/LCMAudios/lcm_audios_app/lib/services/api_service.dart#L8):
```dart
static const String _liveCloudUrl = 'https://audios.lifechangerstouch.org/api/v1';
```

### Step 7.2 · Build Release APK
Run locally on your development machine:
```bash
cd lcm_audios_app
flutter clean
flutter pub get
flutter build apk --release
```

**Output APK Location:**
`lcm_audios_app/build/app/outputs/flutter-apk/app-release.apk`

---

## 8. Verification & Health Checks

Once deployed, verify all endpoints:

| Feature | URL | Expected Response |
|---------|-----|-------------------|
| **Health Check** | `https://audios.lifechangerstouch.org/health` | `{"status":"online"}` |
| **API Endpoints** | `https://audios.lifechangerstouch.org/api/v1/tracks` | JSON List of Tracks |
| **Admin Dashboard** | `https://audios.lifechangerstouch.org/admin` | Admin Portal UI |

---

## 9. Maintenance & Useful Commands

| Task | Command |
|------|---------|
| View live API logs | `pm2 logs lcmaudios-backend` |
| Restart backend after code pull | `pm2 restart lcmaudios-backend` |
| Reload Nginx | `sudo systemctl reload nginx` |
| Check SSL certificate renewal | `sudo certbot renew --dry-run` |
| Check server memory & CPU | `pm2 monit` or `htop` |
