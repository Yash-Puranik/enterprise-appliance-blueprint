# 🛠️ Appliance Operational Cheat Sheet

### 🚀 Lifecycle & Deployment

| Action | Command | Purpose |
|---|---|---|
| **Start Everything** | `docker compose up -d --build` | Builds fresh images and launches all 3 tiers in background |
| **Stop Stack** | `docker compose down` | Safely stops containers without deleting database data |
| **Reset Database** | `docker compose down -v && docker compose up -d` | Deletes stale Postgres volume and re-applies new password |
| **Restart Backend** | `docker compose restart api` | Restarts Express server after JavaScript changes |

---

### 🔍 Verification & Health Checks

| Action | Command | Expected Output |
|---|---|---|
| **Test Ingress API** | `curl -i http://localhost:8080/api/status` | `HTTP/1.1 200 OK` + `{"database":"connected"}` |
| **Check Port Routing** | `docker compose ps` | `web` shows `0.0.0.0:8080->80/tcp`, others have no host port |
| **Test DB Direct** | `docker compose exec api node -e 'require("pg").Pool({connectionString:process.env.DATABASE_URL}).query("SELECT 1",(e)=>console.log(e?e.message:"DB OK"))'` | `DB OK` |

---

### 📜 Live Logs & Troubleshooting

| Target | Command | What to Look For |
|---|---|---|
| **Nginx (Gateway)** | `docker compose logs -f web` | `GET /api/status HTTP/1.1 200` |
| **Express (API)** | `docker compose logs -f api` | `Backend API listening on port 3000` |
| **PostgreSQL (DB)** | `docker compose logs -f db` | `database system is ready to accept connections` |


