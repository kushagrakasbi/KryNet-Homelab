# 🛠️ KryNet Homelab — Improvements & Future Roadmap

**Last Updated:** 21 February 2026  
**Scope:** Agni (192.168.0.200) + Prime (192.168.0.100)

---

## 📋 Table of Contents

1. [Existing Setup Improvements](#existing-setup-improvements)
2. [New Services — Deploying Now](#new-services--deploying-now)
3. [New Services — Future Deployment](#new-services--future-deployment)
4. [Action Summary](#action-summary)

---

## Existing Setup Improvements

### 🔴 High Priority (Security & Data Safety)

#### 1. Backup Immich Photos to Cloud

> [!CAUTION]
> The Prime rclone backup **excludes** `immich/uploads/library/**`. This means your actual photos are **not** backed up to pCloud — only configs. Photos are irreplaceable.

**Fix:** Add a separate rclone sync job for Immich originals, or at minimum remove the exclusion for `immich/uploads/library/**` (will use significant cloud storage).

---

### 🟡 Medium Priority (Operational Health)

#### 2. Remove Deprecated `version:` Key

> **Status:** In Progress — Removed from `stacks/agni/monitoring-stack.yml`. Still needs removal from remaining stack files (including `stacks/agni/tailscale.yml` and others).

---

#### 3. Consolidate Redundant Services

| Redundancy | Decision |
|------------|----------|
| **Homepage** (Agni) + **Homarr** (Prime) | **Keep both** — Homarr serves `lan.kkasbi.in` domains for restricted work computer; Homepage for everything else |
| **OpenSpeedTest** on both servers + **Speedtest Tracker** | Keep one OpenSpeedTest (Agni) + Speedtest Tracker (Prime) |

---

#### 4. Pin Critical Image Versions

Most services use `:latest`. Pin at least these to prevent breaking updates:
- `adguard/adguardhome` → e.g., `v0.107.x`
- `ghcr.io/home-assistant/home-assistant` → e.g., `2026.2`
- `prom/prometheus` → e.g., `v2.x`
- `grafana/grafana` → e.g., `11.x`

---

#### 5. Enable Rclone Backup Encryption

Both rclone jobs sync unencrypted data to pCloud. Use `rclone crypt` remote wrapper to encrypt configs at rest in the cloud.

---

## New Services — Deploying Now

### 🔐 Vaultwarden — Password Manager

**Server:** Agni (survives Prime downtime — critical infrastructure)  
**Access:** `https://vault.krynet.cc`  
**Why:** Shared Bitwarden-compatible password vault for household accounts. Browser extensions + mobile apps.

```yaml
# stacks/agni/vaultwarden-stack.yml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    ports:
      - "8222:80"
    environment:
      - TZ=${TZ}
      - SIGNUPS_ALLOWED=false
      - DOMAIN=https://vault.krynet.cc
    volumes:
      - /home/agni/apps/docker/vaultwarden:/data
    networks:
      - agni_net

networks:
  agni_net:
    external: true
```

> [!IMPORTANT]
> After first signup, set `SIGNUPS_ALLOWED=false` and redeploy to lock registration.

**Post-deploy:**
1. Add `vault.krynet.cc` to Caddy config → `localhost:8222`
2. Add DNS rewrite in AdGuard for `vault.krynet.cc`
3. Add Cloudflare Tunnel route for external access
4. Install Bitwarden browser extension + mobile app
5. Create organization for shared household passwords
6. Add to Gatus health checks and rclone backup exclusions

---

### 📄 Paperless-ngx — Document Management

**Server:** Prime (andromeda pool)    
**Access:** `https://docs.krynet.cc`  
**Why:** OCR, tag, and search all household documents — bills, warranties, insurance, medical, tax papers.

```yaml
# stacks/prime/paperless-stack.yml
services:
  paperless-redis:
    image: docker.io/library/redis:7
    container_name: paperless-redis
    restart: unless-stopped
    volumes:
      - ${DOCKER_CONFIG_PATH}/paperless/redis:/data
    networks:
      - kry_net

  paperless:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    container_name: paperless
    restart: unless-stopped
    depends_on:
      - paperless-redis
    ports:
      - "8010:8000"
    volumes:
      - ${DOCKER_CONFIG_PATH}/paperless/data:/usr/src/paperless/data
      - /mnt/andromeda/apps/paperless/media:/usr/src/paperless/media
      - /mnt/andromeda/apps/paperless/export:/usr/src/paperless/export
      - /mnt/andromeda/apps/paperless/consume:/usr/src/paperless/consume
    environment:
      - PAPERLESS_REDIS=redis://paperless-redis:6379
      - PAPERLESS_TIME_ZONE=${TZ}
      - PAPERLESS_OCR_LANGUAGE=eng+hin
      - PAPERLESS_URL=https://docs.krynet.cc
      - PAPERLESS_ADMIN_USER=admin
      - PAPERLESS_ADMIN_PASSWORD=${PAPERLESS_ADMIN_PASS}
      - USERMAP_UID=${PUID}
      - USERMAP_GID=${PGID}
    networks:
      - kry_net
      - traefik_proxy

networks:
  kry_net:
    external: true
  traefik_proxy:
    external: true
```

**Post-deploy:**
1. Add `docs.krynet.cc` proxy entry in Caddy → `192.168.0.100:8010`
2. Drop files into `/mnt/andromeda/apps/paperless/consume` to auto-import
3. Install Paperless mobile app for scanning documents with phone camera
4. Set up tags: `bills`, `insurance`, `medical`, `tax`, `warranty`, `property`
5. Add to rclone backup (exclude `media/documents/thumbnails/**`)

---

### 📰 FreshRSS — RSS Reader

**Server:** Prime  
**Access:** `https://rss.krynet.cc`  
**Why:** Follow news, blogs, YouTube channels, and tech sites without social media. Separate accounts for each user.

```yaml
# stacks/prime/freshrss-stack.yml
services:
  freshrss:
    image: freshrss/freshrss:latest
    container_name: freshrss
    restart: unless-stopped
    ports:
      - "8086:80"
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - CRON_MIN=2,32
    volumes:
      - ${DOCKER_CONFIG_PATH}/freshrss/data:/var/www/FreshRSS/data
      - ${DOCKER_CONFIG_PATH}/freshrss/extensions:/var/www/FreshRSS/extensions
    networks:
      - kry_net
      - traefik_proxy

networks:
  kry_net:
    external: true
  traefik_proxy:
    external: true
```

**Post-deploy:**
1. Add `rss.krynet.cc` proxy entry in Caddy → `192.168.0.100:8086`
2. Create accounts for you and your wife
3. Import OPML feeds or add manually
4. Mobile: use Reeder (iOS) or FeedMe (Android) with FreshRSS API

---

### 🛒 Grocy — Household & Pantry Management  
*(Alternative: Actual Budget if budgeting is higher priority)*

**Server:** Prime  
**Access:** `https://grocy.krynet.cc`  
**Why:** Grocery/pantry tracking, shopping lists, expiry date alerts, chore management, meal planning.

```yaml
# stacks/prime/grocy-stack.yml
services:
  grocy:
    image: lscr.io/linuxserver/grocy:latest
    container_name: grocy
    restart: unless-stopped
    ports:
      - "9283:80"
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${DOCKER_CONFIG_PATH}/grocy:/config
    networks:
      - kry_net
      - traefik_proxy

networks:
  kry_net:
    external: true
  traefik_proxy:
    external: true
```

**Post-deploy:**
1. Add `grocy.krynet.cc` proxy entry in Caddy → `192.168.0.100:9283`
2. Set up household members
3. Start adding pantry items with expiry dates
4. Create recurring chore schedule
5. Use Grocy Android/iOS app for barcode scanning

---

## New Services — Future Deployment

These are confirmed as desirable but not deploying immediately:

### 📡 Changedetection.io — Website Change Monitor

**Server:** Prime  
**Access:** `https://changes.krynet.cc`  
**Why:** Track price drops, government notices, job postings, apartment listings. Sends notifications via Gotify when content changes.

```yaml
# stacks/prime/changedetection-stack.yml
services:
  changedetection:
    image: ghcr.io/dgtlmoon/changedetection.io:latest
    container_name: changedetection
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      - TZ=${TZ}
      - BASE_URL=https://changes.krynet.cc
    volumes:
      - ${DOCKER_CONFIG_PATH}/changedetection:/datastore
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

### 🔖 Linkding — Bookmark Manager

**Server:** Prime  
**Access:** `https://links.krynet.cc`  
**Why:** Shared bookmarks with tags and full-text search. Browser extensions for one-click saving.

```yaml
# stacks/prime/linkding-stack.yml
services:
  linkding:
    image: sissbruecker/linkding:latest
    container_name: linkding
    restart: unless-stopped
    ports:
      - "9091:9090"
    environment:
      - TZ=${TZ}
    volumes:
      - ${DOCKER_CONFIG_PATH}/linkding:/etc/linkding/data
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

### 📅 Radicale — CalDAV/CardDAV Server

**Server:** Agni (critical personal data — survives Prime downtime)  
**Access:** `https://cal.krynet.cc`  
**Why:** Self-hosted shared calendar and contacts. Syncs with iPhone/Android calendar apps natively.

```yaml
# stacks/agni/radicale-stack.yml
services:
  radicale:
    image: tomsquest/docker-radicale:latest
    container_name: radicale
    restart: unless-stopped
    ports:
      - "5232:5232"
    volumes:
      - /home/agni/apps/docker/radicale/data:/data
      - /home/agni/apps/docker/radicale/config:/config
    networks:
      - agni_net

networks:
  agni_net:
    external: true
```

---

## Action Summary

### Remaining Fixes (Existing Services)

| # | Action | Status | Notes |
|---|--------|--------|-------|
| 1 | Backup Immich photos to cloud | ⏳ Later | Needs rclone config changes |
| 2 | Remove deprecated `version:` | 🔄 In Progress | Done for monitoring-stack, remaining files pending |
| 3 | Consolidate redundant services | 🔄 In Progress | Keeping both dashboards; still need to remove duplicate OpenSpeedTest |
| 4 | Pin critical image versions | ⏳ Later | AdGuard, HA, Prometheus, Grafana |
| 5 | Enable rclone encryption | ⏳ Later | Both rclone stacks |

### New Service Deployment

| # | Service | Server | Stack File | Priority |
|---|---------|--------|------------|----------|
| 1 | **Vaultwarden** | Agni | `stacks/agni/vaultwarden-stack.yml` | 🔴 Deploy now |
| 2 | **Paperless-ngx** | Prime | `stacks/prime/paperless-stack.yml` | 🔴 Deploy now |
| 3 | **FreshRSS** | Prime | `stacks/prime/freshrss-stack.yml` | 🔴 Deploy now |
| 4 | **Grocy** | Prime | `stacks/prime/grocy-stack.yml` | 🔴 Deploy now |
| 5 | **AI Stack** | Prime | `stacks/prime/ai-stack.yml` | 🔴 Deploy now |
| 6 | **Changedetection.io** | Prime | `stacks/prime/changedetection-stack.yml` | 🟡 Future |
| 7 | **Linkding** | Prime | `stacks/prime/linkding-stack.yml` | 🟡 Future |
| 8 | **Radicale** | Agni | `stacks/agni/radicale-stack.yml` | 🟡 Future |

### AI Stack Details

**Server:** Prime (GPU: GTX 1060 3GB, 32GB RAM)
**Docs:** `docs/AI-STACK.md`
**Config:** `config/litellm/config.yaml`

| Component | Port | Access |
|-----------|------|--------|
| **OpenWebUI** | 3999 | `https://ow.krynet.cc` |
| **LiteLLM** | 4000 | `https://litellm.krynet.cc` |
| **Ollama** | 11434 | `https://ollama.krynet.cc` |

**Cloud Models:** Claude Opus 4.6/4.5, Sonnet 4.5, Haiku 4.5, GPT 5.1/5.2/5.3, Gemini 3.1 Pro/Flash, Gemini 3 Pro/Flash
**Local Models (Ollama):** llama3.2, gemma3:4b

---

> [!NOTE]
> All compose snippets in this document are ready to be saved as individual stack files in `stacks/agni/` or `stacks/prime/` and deployed via Portainer.
