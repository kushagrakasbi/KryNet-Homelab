# 📸 Immich v2 to v3 Upgrade & VectorChord Migration

**Target Node:** 🌟 Prime (`192.168.0.100`) & ⚡ Legion (`192.168.0.150`)  
**Execution Date:** August 23, 2026  
**Status:** 🟢 **100% COMPLETE & VERIFIED**  
**Server Version:** `v3.1.0`  
**Database Engine:** PostgreSQL 14 with **VectorChord 0.4.3** & **pgvector 0.8.1**  

---

## 🎯 Executive Overview

Immich was upgraded from `v2.7.5` to **`v3.1.0`** across the KryNet fleet. The upgrade introduced a major database architecture shift from the deprecated `pgvecto.rs` vector extension to **VectorChord** (`vchord.so` + `pgvector`), delivering higher vector search throughput and reduced RAM consumption.

The upgrade followed strict production-grade zero-data-loss protocols, utilizing redundant application SQL dumps, TrueNAS ZFS atomic dataset snapshots, and Portainer stack definitions.

---

## 🔍 Key Architectural Changes

1. **Vector Engine Replacement (`pgvecto.rs` ➔ `VectorChord`):**
   - Official Immich PostgreSQL image changed to: `ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0`.
   - Obsolete `command:` overrides (`-c shared_preload_libraries=vectors.so`) and custom checksum healthchecks were removed.
   - Initialized `shm_size: 128mb` and `DB_STORAGE_TYPE: 'HDD'` for optimal operation on Prime's WD Red Plus HDD ZFS mirror pool (`andromeda`).
2. **Microservices & API Consolidation:**
   - Single unified `immich-server` container running both API and microservices workers.
3. **Machine Learning GPU Offload:**
   - ML inference hosted on **⚡ Legion (`192.168.0.150:3003`)** using `immich-machine-learning:v3-cuda` on the RTX 3060 6GB GPU.
   - Prime's `stack.env` routes inference via `IMMICH_MACHINE_LEARNING_URL=http://192.168.0.150:3003`.
4. **Caching & Companion Tools:**
   - Redis upgraded to **ValKey 8** (`valkey:8-bookworm`).
   - Immich Power Tools upgraded to `ghcr.io/varun-raj/immich-power-tools:latest`.

---

## 🛡️ Pre-Flight Redundant Backup Records

Before making any container or database modifications, the following safety layers were taken and verified on Prime:

```
┌─────────────────────────────────────────────────────────────┐
│                 VERIFIED PRE-FLIGHT BACKUPS                 │
├─────────────────────────────────────────────────────────────┤
│ 1. Application-Level Compressed SQL Dump (704 MB)           │
│    /mnt/andromeda/apps/immich/immich_db_backup_pre_v3_*.sql │
│                                                             │
│ 2. TrueNAS ZFS Atomic Dataset Snapshots:                    │
│    • andromeda/apps/immich/db@pre-v3-upgrade-20260823       │
│    • andromeda/apps/immich/uploads@pre-v3-upgrade-20260823  │
│    • andromeda/apps/immich/ml@pre-v3-upgrade-20260823       │
│    • orion/apps-config@pre-v3-upgrade-20260823              │
│                                                             │
│ 3. Portainer Stack Definition Backup:                       │
│    /mnt/orion/apps-config/immich-v2-backup/                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Prime Stack Compose Definition

**Source of Truth:** [`stacks/prime/immich.yml`](../../stacks/prime/immich.yml)

```yaml
services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-v3}
    volumes:
      - /mnt/andromeda/apps/immich/uploads:/data
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 2283:2283
    env_file:
      - stack.env
    depends_on:
      - redis
      - database
    restart: unless-stopped
    healthcheck:
      disable: false
    networks:
      - kry_net
      - traefik_proxy

  # ML for Immich is offloaded to Legion (stacks/legion/immich-ml.yml: http://192.168.0.150:3003)

  # Redis for Immich
  redis:
    container_name: immich_redis
    image: docker.io/valkey/valkey:8-bookworm@sha256:42cba146593a5ea9a622002c1b7cba5da7be248650cbb64ecb9c6c33d29794b1
    healthcheck:
      test: redis-cli ping || exit 1
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy

  # Postgres for Immich (VectorChord)
  database:
    container_name: immich_postgres
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
      POSTGRES_INITDB_ARGS: --data-checksums
      DB_STORAGE_TYPE: 'HDD'
    ports:
      - "5432:5432"
    env_file:
      - stack.env
    volumes:
      - /mnt/andromeda/apps/immich/db:/var/lib/postgresql/data
    shm_size: 128mb
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy

  # Power Tools for Immich
  power-tools:
    container_name: immich_power_tools
    image: ghcr.io/varun-raj/immich-power-tools:latest
    ports:
      - "8001:3000"
    env_file:
      - stack.env
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy

networks:
  kry_net:
    external: true
  traefik_proxy:
    external: true
```

---

## 🧪 Post-Migration Verification Records

| Verification Test | Command / Target | Result | Status |
| :--- | :--- | :--- | :--- |
| **Server Version API** | `curl http://192.168.0.100:2283/api/server/version` | `{"major":3,"minor":1,"patch":0}` | ✅ PASS |
| **Server Ping** | `curl http://192.168.0.100:2283/api/server/ping` | `{"res":"pong"}` | ✅ PASS |
| **Vector Engine (`\dx`)** | `psql -U postgres -d immich` | `vchord 0.4.3`, `vector 0.8.1` | ✅ PASS |
| **CLIP Vector Reindex** | Container log inspection | `87,706` vectors indexed | ✅ PASS |
| **Face Vector Reindex** | Container log inspection | `173,656` vectors indexed | ✅ PASS |
| **Geodata Import** | Container log inspection | `227,901` geodata records in 5.91s | ✅ PASS |
| **ML Node Offload** | `http://192.168.0.150:3003` | Connected & Healthy (CUDA RTX 3060) | ✅ PASS |
| **Reverse Proxy Ingress**| `curl https://photos.krynet.cc` | `HTTP/2 200 OK` (Caddy on Agni) | ✅ PASS |
| **Power Tools Web** | `http://192.168.0.100:8001` | `HTTP/1.1 200 OK` | ✅ PASS |

---

## 🔄 Emergency Rollback Playbook (< 2 Minutes)

If any future disaster recovery is required:
1. In Portainer ➔ Stop the `immich` stack.
2. Roll back TrueNAS ZFS dataset to the pre-upgrade snapshot:
   ```bash
   ssh prime "midclt call zfs.snapshot.rollback 'andromeda/apps/immich/db@pre-v3-upgrade-20260823' '{\"force\": true}'"
   ```
3. Restore the v2 Compose YAML from `/mnt/orion/apps-config/immich-v2-backup/docker-compose.yml`.
4. Redeploy stack in Portainer.
