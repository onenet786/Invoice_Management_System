# Invoicey — Enterprise Invoice & Billing Platform

Cross-platform enterprise invoice management, quotation generation, dynamic PDF rendering, OCR scanning, and real-time cloud synchronization across Mobile, Web, and Desktop.

---

## 🚀 Quick Links & Documentation

- **aaPanel Hosting Guide (Ubuntu 24)**: [docs/AAPANEL_HOSTING_GUIDE.md](docs/AAPANEL_HOSTING_GUIDE.md) — Step-by-step production hosting on Ubuntu 24.04 with aaPanel, Node.js PM2, PostgreSQL, and Nginx reverse proxy.
- **Web Application**: Located in [web_app/](web_app/) (open `web_app/index.html` directly or serve via Nginx).
- **Backend Sync API**: Located in [server/](server/) (Express + PostgreSQL with revision tracking and conflict detection).
- **System Logic & Architecture**: [docs/LOGIC_EXPLANATION.md](docs/LOGIC_EXPLANATION.md).
- **User Guide**: [docs/USER_GUIDE.md](docs/USER_GUIDE.md).
- **Interactive Walkthrough Demo**: [walkthrough_demo/index.html](walkthrough_demo/index.html).

---

## 💻 Tech Stack & Platforms

| Component | Technology | Description |
|---|---|---|
| **Mobile & Desktop** | Flutter 3.x, Dart | Android, iOS, Windows, macOS, Linux native builds |
| **Web Edition** | HTML5, Vanilla CSS, JS (ES6+) | Production-grade web application with 100% mobile feature parity |
| **Backend API** | Node.js, Express, ES Modules | Multi-tenant cloud sync, Google OAuth, optimistic concurrency |
| **Database** | PostgreSQL 16+ with `pgcrypto` | Row-level data isolation, JSONB payload snapshots |
| **Server Stack** | Ubuntu 24.04, aaPanel, Nginx, PM2 | Dedicated hosting setup with SSL and automated backups |

---

## 🏁 Quick Start

### 1. Launch Web Application Locally
```powershell
# Open directly in your browser:
start web_app/index.html

# Or serve via Python:
python -m http.server 8080 --directory web_app
```

### 2. Run Backend Sync Server
```powershell
cd server
npm install
cp .env.example .env
# Edit .env with your PostgreSQL credentials
npm start
```

### 3. Run Flutter App
```powershell
flutter pub get
flutter run
```

---

## 🌐 Production Deployment
For complete instructions on deploying the Web App, Node.js API, and PostgreSQL on a dedicated server with **Ubuntu 24** and **aaPanel**, follow the **[aaPanel Hosting Guide](docs/AAPANEL_HOSTING_GUIDE.md)**.
