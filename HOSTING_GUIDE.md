# Production Hosting Guide (Ubuntu 24 + aaPanel)

The complete, production-ready hosting guide for deploying **Invoicey** (Web Application, Node.js Express Sync API, and PostgreSQL Database) on your **Ubuntu 24.04 LTS dedicated server with aaPanel** is located at:

👉 **[docs/AAPANEL_HOSTING_GUIDE.md](docs/AAPANEL_HOSTING_GUIDE.md)**

---

## 📑 Guide Summary

The guide covers:
1. **PostgreSQL Setup in aaPanel**: Creating database `invoicey`, user `invoicey_user`, and running `server/sql/001_initial.sql`.
2. **Node.js API Deployment**: Configuring `/www/wwwroot/invoicey-api`, `.env`, and starting with aaPanel **Node Project Manager / PM2**.
3. **Web Application Deployment**: Serving `web_app/` static files at `/www/wwwroot/invoice.yourdomain.com`.
4. **Nginx Reverse Proxy & SSL**: Battle-tested Nginx config with Gzip, HTTP/2, Let's Encrypt SSL, and proxy rules for `/v1/` and `/health`.
5. **End-to-End Testing**: Health check curls and browser/mobile sync testing.
6. **Automated Maintenance**: Daily PostgreSQL backup cron jobs and log rotation in aaPanel.
