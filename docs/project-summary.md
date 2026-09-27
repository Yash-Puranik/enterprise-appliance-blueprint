# 🚀 Enterprise Appliance Blueprint

[![Status](https://img.shields.io/badge/Status-Operational-brightgreen?style=for-the-badge&logo=statuspage)](http://localhost:8080)
[![Docker](https://img.shields.io/badge/Docker-Compose_V2-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![Nginx](https://img.shields.io/badge/Gateway-Nginx_Alpine-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org)
[![Node.js](https://img.shields.io/badge/Backend-Express_3000-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/Database-Postgres_15-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org)

---

## 🎯 1. Project Purpose

The primary goal of the **Enterprise Appliance Blueprint** is to deliver a hardened, production-grade, self-contained service appliance deployable on any host with **zero manual system dependencies** beyond the Docker runtime.

It enforces a strict **3-Tier Air-Gapped Network Topology**:
- 🌐 **Edge Ingress (`web`):** Public front-door mapping `:8080` to `:80`. Shields internal components and delivers an embedded telemetry console.
- ⚙️ **Application Tier (`api`):** Private Node.js Express service processing business workflows and telemetry probes.
- 🗄️ **Persistent Store (`db`):** Isolated PostgreSQL instance operating strictly within internal Docker networking.

---

## 🛠️ 2. Key Milestones & Engineering Solutions

### 🛡️ A. Ingress & Port Architecture Alignment
- **Problem:** Host port collisions on `:80` and upstream `502 Bad Gateway` errors due to port mismatches between Nginx (`:8000`) and Express (`:3000`).
- **Solution:** 
  - Standardized external access on **`:8080`** (`8080:80`).
  - Aligned reverse-proxy routing to internal target `http://api:3000/`.
  - Kept backend and database ports private via `expose`, preventing unwanted host exposures.

### ⚡ B. Frontend Resilience & Syntax Crash Prevention
- **Problem:** When services degraded or routes failed, Nginx/Express emitted HTML error pages. Naive client `fetch` calls tried to execute `JSON.parse('<...')`, triggering:
  `SyntaxError: Unexpected token '<'`.
- **Solution:**
  - Designed a **defensive polling engine** validating HTTP status codes before reading data.
  - Implemented text-first payload inspection to trap raw HTML and surface diagnostic traces on-screen.
  - Baked the UI directly into `services/web/Dockerfile` using quoted heredocs (`cat <<'EOF'`) to eliminate host filesystem mount inconsistencies.

### 🔑 C. Active Database Probing & Credential Drift
- **Problem:** Database authentication crashed with:
  `password authentication failed for user "postgres"`
  Updating passwords in `docker-compose.yml` had no effect because Postgres preserves credentials inside its persistent volume from its first initialization.
- **Solution:**
  - Implemented live SQL round-trip health checks (`SELECT 1`) via `pg.Pool` inside `/status`.
  - Cleaned connection strings to pure alphanumeric literals to avoid delimiter parsing breaks.
  - Established the definitive volume reset runbook: `docker compose down -v`.

---

## 🗺️ 3. Traffic & Network Map

```text
  [ Client Browser ]
          │
     HTTP :8080 (Public)
          ▼
┌────────────────────────────────────────┐
│  🟢 Nginx Edge Gateway (:80)           │
│  - Static Asset Delivery               │
│  - Reverse Proxy Route: /api/ -> :3000 │
└───────────────────┬────────────────────┘
                    │
           Bridge: internal_net
                    │
                    ▼
┌────────────────────────────────────────┐
│  🟡 Node.js Express API (:3000)        │
│  - Route: GET /status                  │
│  - Active Health Telemetry             │
└───────────────────┬────────────────────┘
                    │
           Bridge: internal_net
                    │
                    ▼
┌────────────────────────────────────────┐
│  🔵 PostgreSQL Engine (:5432)          │
│  - Volume: db_data                     │
│  - Auth: Isolated Internal Credentials │
└────────────────────────────────────────┘


