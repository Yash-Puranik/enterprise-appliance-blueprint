# Enterprise Appliance Blueprint

[![CI Pipeline](https://github.com/your-org/enterprise-appliance-blueprint/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/enterprise-appliance-blueprint/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-v2%2B-blue)](https://docs.docker.com/compose/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16--alpine-336791.svg)](https://www.postgresql.org/)
[![Nginx](https://img.shields.io/badge/Nginx-Alpine-009639.svg)](https://nginx.org/)

A turnkey, self-hosted B2B appliance blueprint engineered for on-premise deployments. This blueprint packages a zero-trust network topology, automated lifecycle orchestration, embedded UI telemetry, and disaster recovery automation into a deterministic single-command deployment.

---

## Architecture Overview

The appliance runs on an isolated internal bridge network (`internal_net`), restricting host surface exposure to public ingress on port 80. All database and API traffic remains network-isolated.

```text
                           [ Client Browser / API Consumer ]
                                           │
                                           │ HTTP :80
                                           ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ Host Machine                                                                           │
│                                                                                        │
│   ┌────────────────────────────────────────────────────────────────────────────────┐   │
│   │ Web Gateway Container (`web`)                                                  │   │
│   │ • Base: `nginx:alpine`                                                         │   │
│   │ • Embedded Telemetry UI (`/`)                                                  │   │
│   │ • Reverse Proxy Gateway (`/api/*` ──► `http://api:8000/*`)                    │   │
│   └──────────────────────────────────────┬─────────────────────────────────────────┘   │
│                                          │                                             │
│                                  `internal_net`                                        │
│                                  (Bridge Network)                                      │
│                                          │                                             │
│          ┌───────────────────────────────┴───────────────────────────────┐             │
│          ▼                                                               ▼             │
│   ┌──────────────────────────────┐                              ┌──────────────────┐   │
│   │ Backend API Service (`api`)  │                              │ Database (`db`)  │   │
│   │ • Application Logic          │                              │ • PostgreSQL 16  │   │
│   │ • Internal Port: 8000        │◄─────── SQL Queries ────────►│ • Volume:        │   │
│   │ • Status Probe: `/status`    │       (Port: 5432)           │   `postgres_data`│   │
│   └──────────────────────────────┘                              └──────────────────┘   │
│                                                                          ▲             │
│                                                                          │             │
│   ┌──────────────────────────────┐                                       │             │
│   │ Automation Engine            │                                       │             │
│   │ • `scripts/install.sh` ──────┼─ Provisions Host, Generates Secrets ──┘             │
│   │ • `scripts/backup.sh` ───────┴─ Zero-byte Safe Compressed Dumps (`pg_dump`)        │
│   └────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘

.
├── .env.example              # Baseline template for runtime credentials (tracked)
├── .env                      # Active runtime environment secrets (git-ignored)
├── docker-compose.yml        # Multi-container declaration & resource controls
├── nginx.conf                # Ingress routing rules, proxy headers & worker configs
├── .github/
│   └── workflows/
│       └── ci.yml            # CI pipeline for linting, syntax, and build tests
├── scripts/
│   ├── install.sh            # Day-0 idempotency bootstrapper & environment provisioner
│   └── backup.sh             # Day-2 automated streaming backup & retention engine
└── services/
    └── web/
        └── Dockerfile        # Gateway build with embedded status dashboard

