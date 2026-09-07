# Production Hosting Guide: Invoicey on Ubuntu 24 & aaPanel

This guide provides step-by-step instructions for deploying and hosting **Invoicey** (Enterprise Web Edition + Express Node.js Sync Server + PostgreSQL Database) on a **Dedicated Server running Ubuntu 24.04 LTS managed via aaPanel**.

---

## 📋 System Architecture on aaPanel

```
                             INTERNET (HTTPS :443)
                                       │
                                       ▼
                     ┌───────────────────────────────────┐
                     │   aaPanel Nginx Web Server        │
                     │   (SSL: Let's Encrypt Auto-Renew) │
                     └─────────────────┬─────────────────┘
                                       │
                ┌──────────────────────┴──────────────────────┐
                ▼                                             ▼
  Static Web App Requests (/)                    API Requests (/v1, /health)
  Document Root:                                 Reverse Proxy Target:
  /www/wwwroot/invoice.yourdomain.com            http://127.0.0.1:3000
  (HTML, CSS, JS, Assets)                                     │
                                                              ▼
                                                 ┌────────────────────────┐
                                                 │ Node.js PM2 Process    │
                                                 │ (invoicey-sync-api)    │
                                                 └────────────┬───────────┘
                                                              │ SQL
                                                              ▼
                                                 ┌────────────────────────┐
                                                 │ PostgreSQL 16+ Database│
                                                 │ Database: invoicey     │
                                                 │ User: invoicey_user    │
                                                 └────────────────────────┘
```

---

## 🛠️ Prerequisites

Ensure the following components are installed and active in your aaPanel dashboard:

1. **Nginx** (v1.24+ or v1.26+) — from aaPanel App Store.
2. **PostgreSQL Manager** — installed and running from aaPanel App Store.
3. **Node.js Project Manager** or **PM2 Manager** — installed from aaPanel App Store.
4. **Node.js v20.x LTS or v22.x** installed via Node.js Version Manager in aaPanel.
5. Domain DNS `A` record pointing to your dedicated server's public IP address (e.g. `invoice.yourdomain.com`).

---

## Step 1: Set Up PostgreSQL Database in aaPanel

### Option A: Using aaPanel Web Interface
1. Go to **aaPanel** ➔ **Databases** ➔ **PostgreSQL**.
2. Click **Add Database**:
   - **Database Name**: `invoicey`
   - **Username**: `invoicey_user`
   - **Password**: Generate a strong password (e.g. `Str0ng_Inv0icey_Pass!2026`)
   - **Character Set**: `UTF8`
3. Click **Submit**.

### Option B: Using Server SSH Terminal
Alternatively, execute directly via SSH:
```bash
sudo -u postgres psql -c "CREATE USER invoicey_user WITH ENCRYPTED PASSWORD 'Str0ng_Inv0icey_Pass!2026';"
sudo -u postgres psql -c "CREATE DATABASE invoicey OWNER invoicey_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE invoicey TO invoicey_user;"
```

### Import Database Schema
Run the initial migration to create the `pgcrypto` extension, `app_users`, and `workspaces` tables:
```bash
sudo -u postgres psql -d invoicey -f /path/to/Invoice_Management_System/server/sql/001_initial.sql
```
*Or copy-paste the SQL directly:*
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS app_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  google_subject TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS workspaces (
  user_id UUID PRIMARY KEY REFERENCES app_users(id) ON DELETE CASCADE,
  revision BIGINT NOT NULL DEFAULT 0,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## Step 2: Deploy the Node.js API Backend

### 1. Create Server Directory
In SSH or via aaPanel **Files**:
```bash
mkdir -p /www/wwwroot/invoicey-api
```

### 2. Upload Backend Files
Copy the contents of the `server/` directory from your repository to `/www/wwwroot/invoicey-api`:
- `package.json`
- `src/server.js`
- `sql/`

### 3. Configure `.env`
Create `/www/wwwroot/invoicey-api/.env` with your production settings:
```bash
nano /www/wwwroot/invoicey-api/.env
```
Paste and update:
```env
PORT=3000
DATABASE_URL=postgresql://invoicey_user:Str0ng_Inv0icey_Pass!2026@127.0.0.1:5432/invoicey
JWT_SECRET=generate-a-long-random-string-at-least-64-chars-long
GOOGLE_OAUTH_CLIENT_IDS=your-web-client-id.apps.googleusercontent.com,your-android-client-id.apps.googleusercontent.com
CORS_ORIGINS=https://invoice.yourdomain.com
```

> [!TIP]
> Generate a cryptographically secure `JWT_SECRET` directly on Ubuntu:
> ```bash
> openssl rand -base64 48
> ```

### 4. Install Dependencies
```bash
cd /www/wwwroot/invoicey-api
npm install --production
```

### 5. Add Project in aaPanel Node.js Project Manager
1. Open aaPanel ➔ **Website** ➔ **Node project** (or **Node.js Manager** / **PM2**).
2. Click **Add Node Project**:
   - **Project Name**: `invoicey-api`
   - **Path**: `/www/wwwroot/invoicey-api`
   - **Run Command**: `npm start` (or Startup File: `src/server.js`)
   - **Node Version**: Select `v20.x` or `v22.x`
   - **Port**: `3000`
   - **Run as**: `www`
3. Click **Submit**.
4. Verify that status indicates **Running** (Green).

### 6. Test Local Endpoint
Verify via terminal that the API and database connect cleanly:
```bash
curl http://127.0.0.1:3000/health
```
Expected response:
```json
{"status":"ok"}
```

---

## Step 3: Deploy the Web Application Frontend

### 1. Create Web Site in aaPanel
1. In aaPanel ➔ **Website** ➔ **Add Site**:
   - **Domain**: `invoice.yourdomain.com`
   - **Root Directory**: `/www/wwwroot/invoice.yourdomain.com`
   - **FTP / Database**: Leave disabled (not needed)
   - **PHP Version**: Pure HTML (Static)
2. Click **Submit**.

### 2. Copy Web App Files
Upload the contents of `web_app/` into `/www/wwwroot/invoice.yourdomain.com`:
```bash
cp -r /path/to/Invoice_Management_System/web_app/* /www/wwwroot/invoice.yourdomain.com/
chown -R www:www /www/wwwroot/invoice.yourdomain.com/
chmod -R 755 /www/wwwroot/invoice.yourdomain.com/
```

Files should be arranged as:
```
/www/wwwroot/invoice.yourdomain.com/
├── index.html
├── css/
│   └── style.css
└── js/
    └── app.js
```

---

## Step 4: Configure Nginx Reverse Proxy & SSL in aaPanel

### 1. Issue SSL Certificate (Let's Encrypt)
1. In aaPanel ➔ **Website** ➔ Click on `invoice.yourdomain.com`.
2. Select the **SSL** tab on the left.
3. Click **Let's Encrypt**:
   - Check `invoice.yourdomain.com`
   - Verification method: **File verification**
4. Click **Apply**.
5. Once certificate is issued, toggle **Force HTTPS** to ON.

---

### 2. Configure Nginx (Static Serving + API Reverse Proxy)
Open your site settings ➔ **Config file** in aaPanel, and replace or configure the `server { ... }` block to match this production configuration:

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name invoice.yourdomain.com;
    index index.html;
    root /www/wwwroot/invoice.yourdomain.com;

    # SSL Configuration (Managed by aaPanel)
    ssl_certificate    /www/server/panel/vhost/cert/invoice.yourdomain.com/fullchain.pem;
    ssl_certificate_key    /www/server/panel/vhost/cert/invoice.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Force HTTPS redirect
    if ($server_port !~ 443){
        rewrite ^(/.*)$ https://$host$1 permanent;
    }

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Gzip Compression
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.1;
    gzip_comp_level 5;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # 1. API Reverse Proxy for Synchronization Routes (/v1)
    location /v1/ {
        proxy_pass http://127.0.0.1:3000/v1/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
        client_max_body_size 10m;
    }

    # 2. API Health Check Route (/health)
    location = /health {
        proxy_pass http://127.0.0.1:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 3. Static Assets Caching
    location ~* \.(css|js|png|jpg|jpeg|gif|svg|ico|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
        access_log off;
    }

    # 4. Frontend Single-Page App Fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    access_log  /www/wwwlogs/invoice.yourdomain.com.log;
    error_log  /www/wwwlogs/invoice.yourdomain.com.error.log;
}
```

Click **Save** in aaPanel. Nginx will automatically reload without downtime.

---

## Step 5: Verification & End-to-End Testing

### 1. Test External Health Check
Run from your local computer or terminal:
```bash
curl -I https://invoice.yourdomain.com/health
```
Expected output:
```http
HTTP/2 200
content-type: application/json; charset=utf-8
```
```bash
curl https://invoice.yourdomain.com/health
```
Output:
```json
{"status":"ok"}
```

### 2. Verify Web Application
1. Open `https://invoice.yourdomain.com` in your browser.
2. Verify that:
   - Dashboard KPI metrics and charts render cleanly.
   - Click the header **Sync Widget** ➔ click **Test Server Connection** ➔ verify **"Sync API is online"** notification.
   - Generate an invoice or scan an OCR quote.
   - Click **Preview & Print PDF** and test all 5 templates.

### 3. Connect Mobile App to Server
On your Android/iOS/Desktop Flutter app:
1. Open **Settings** ➔ **Cloud Sync Endpoint**.
2. Enter: `https://invoice.yourdomain.com`
3. Authenticate with Google Sign-In or your session token.
4. Changes made on mobile will sync seamlessly to the web application with revision tracking and conflict detection!

---

## Step 6: Automated Backups & Maintenance via aaPanel

### 1. Automated Daily Database Backup
1. In aaPanel ➔ **Cron**.
2. Click **Add Task**:
   - **Type**: `Backup Database`
   - **Database**: `invoicey`
   - **Cycle**: Daily at `03:00`
   - **Keep Copies**: `30`
3. Click **Add Task**.

### 2. Code Updates & Git CI/CD
To deploy code updates in the future, run:
```bash
# Update Web App
cd /path/to/repo
git pull
cp -r web_app/* /www/wwwroot/invoice.yourdomain.com/

# Update API
cp -r server/* /www/wwwroot/invoicey-api/
cd /www/wwwroot/invoicey-api && npm install --production
# Restart in PM2
pm2 restart invoicey-api
```

---

## 🔧 Troubleshooting on Ubuntu 24 & aaPanel

| Issue | Cause | Solution |
|---|---|---|
| `502 Bad Gateway` on `/v1` | Node.js process stopped or port mismatch | Check aaPanel **PM2 Manager** or run `pm2 logs invoicey-api`. Ensure `.env` specifies `PORT=3000`. |
| `PostgreSQL connection refused` | Database service stopped or wrong credentials | Check aaPanel **Databases** tab. Run `sudo systemctl status postgresql`. Verify password in `.env`. |
| `CORS Error in Browser Console` | Origin domain not in `.env` | Ensure `CORS_ORIGINS=https://invoice.yourdomain.com` is set in `/www/wwwroot/invoicey-api/.env` and restart PM2. |
| `403 Forbidden` on Web App | Incorrect Linux file permissions | Run `chown -R www:www /www/wwwroot/invoice.yourdomain.com/` and `chmod -R 755 /www/wwwroot/invoice.yourdomain.com/`. |
| `HTTP 409 Conflict` during sync | Simultaneous updates from another device | Normal behavior. Download latest workspace before submitting conflicting changes. |
