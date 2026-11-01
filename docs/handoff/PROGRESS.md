# 📈 Progress log — newest first

Each entry: what changed, **how it was verified**, and anything a later agent must not re-derive.
Add an entry at every milestone, not at the end of the session (`session-handoff` skill).
Older detail (Aug–Sep 2026) lives in the owner's planning notes; this log starts where the repo became
the source of truth for handoff.

---

## 2026-11-01 — Gluetun VPN Singapore hardening, autonomous watchdog healing & dashboard updates

- 🛡️ **VPN Resilience:** Hardened Gluetun WireGuard tunnel on Prime with `WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL=25s` and pinned `SERVER_CITIES=Singapore` to prevent silent NAT state drops on Indian broadband connections.
- 🤖 **Autonomous VPN Watchdog (`vpn-watchdog`):** Enhanced `watchdog.sh` with active auto-healing. Daemon probes `http://localhost:8000/v1/publicip/ip` inside Gluetun every 60s; if unresponsive for 3 consecutive checks, it restarts Gluetun automatically and triggers cascading restarts for downstream dependents (`qbittorrent`, `seerr`) to restore networking.
- 🎨 **Homepage Dashboard:** Fixed broken Jellyfin widget on Homepage after Jellyfin 12+ API upgrade by adding `version: 2` (fixed 404 on `/emby/Items/Counts`, displaying live 157 Movies, 17 Series, 2,075 Episodes).
- 🔒 **Service Hardening:**
  - Disabled public registrations on Vaultwarden (`SIGNUPS_ALLOWED=false`).
  - Fixed FreshRSS domain configuration to `https://rss.lan.kkasbi.in`.
- 🩺 **Fleet Telemetry:** Added automated Gluetun, qBittorrent, and Seerr health checks into `scripts/fleet-validate.sh`.

---

## 2026-11-01 — Complete Audiobook Ecosystem deployment & library deduplication

- 📚 **Audiobook Automation (Chaptarr):** Deployed `chaptarr/chaptarr:latest` (.NET 10 successor to Readarr, port 8789) on Prime media stack. Integrated with Prowlarr categories 3030/7000 and qBittorrent.
- 🎧 **Streaming Server (Audiobookshelf):** Reorganized 124 audiobook titles into 54 standardized author/series folders on `/mnt/andromeda/media/audiobooks`. Configured Caddy reverse proxy (`abs.lan.kkasbi.in` and `abs.krynet.cc`) and verified API scan.
- 🤖 **Zero-Touch Ingestion (Libation Headless):** Deployed `rmcrackan/libation:latest` under `audiobookshelf-stack` on Prime with automated 6-hour sync. Standardized naming template `<has series#->{Series}/{Series} - {Series Number} - {Title}/{Title} - {Series Number}`.
- 🧹 **Library Hygiene & Deduplication:** Marked 110 kids (Peppa Pig) and unwanted titles as deleted in `LibationContext.db` (`IsDeleted = 1`) to suppress re-downloads, and deduplicated on-disk library using `scripts/audiobook-validate.py`.

---

## 2026-11-01 — Fleet throughput audit & EasyMesh backhaul bottleneck resolved

- 🔍 **Root-caused homelab 9-15 Mbps slowness:** Extensive empirical throughput matrix measured across all nodes.
  - Prime (wired directly to Archer BE400 in corridor): **745.4 Mbps** to Internet.
  - Personal Mac (Wi-Fi 7/6 160MHz to Archer BE400 in corridor): **630.5 Mbps** to Internet, **624.6 Mbps** direct to Prime (`:8992`).
  - Agni ↔ Legion (inside Archer AX10 switch): **946.0 Mbps** wire speed.
  - **The bottleneck:** Archer AX10 (office) ↔ Archer BE400 (corridor) Ethernet backhaul was auto-negotiating at **10BASE-T (10 Mbps)** when plugged into Orange LAN Port 4.
  - Because Caddy sits on Agni (`192.168.0.200`), all domain URLs (`*.lan.kkasbi.in`, Immich, OpenSpeedtest) traversed the 10 Mbps backhaul, throttling all services.
- 🛠️ **Physical Remediation:** Moved backhaul cable on Archer AX10 from Orange LAN Port 4 to the **Blue WAN Port**. Archer BE400 UI instantly reflected `Link Speed: 1000 Mbps (wired)`.
- ✅ **Post-fix verification across all permutations:**
  - Agni ↔ Prime: **944 Mbps** (was 8.9 Mbps — 105x speedup)
  - Legion ↔ Prime: **945 Mbps** (was 9.1 Mbps — 103x speedup)
  - Mac ↔ Agni: **806 Mbps** (was 8.8 Mbps — 91x speedup)
  - Mac ↔ Legion: **818 Mbps** (was 8.4 Mbps — 97x speedup)
  - Caddy Reverse Proxy (`ospt.lan.kkasbi.in`): **572–610 Mbps** (was 7.9 Mbps — 73x speedup)
  - Internet on Agni / Legion: **684–755 Mbps** (was 8.3 Mbps — 90x speedup)
  - Fleet latencies: Wired 1.0–1.4 ms; Wi-Fi 5.8–8.3 ms; DNS 1–6 ms.
- Fully documented in [`docs/2026-11-NETWORK-SPEED-AND-TOPOLOGY-AUDIT.md`](file:///Users/kkasbi/Projects/home-server/docs/2026-11-NETWORK-SPEED-AND-TOPOLOGY-AUDIT.md).

---

## 2026-11-01 — Gluetun VPN Singapore hardening, autonomous watchdog healing & dashboard updates

- 🛡️ **VPN Resilience:** Hardened Gluetun WireGuard tunnel on Prime with `WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL=25s` and pinned `SERVER_CITIES=Singapore` to prevent silent NAT state drops on Indian broadband connections.
- 🤖 **Autonomous VPN Watchdog (`vpn-watchdog`):** Enhanced `watchdog.sh` with active auto-healing. Daemon probes `http://localhost:8000/v1/publicip/ip` inside Gluetun every 60s; if unresponsive for 3 consecutive checks, it restarts Gluetun automatically and triggers cascading restarts for downstream dependents (`qbittorrent`, `seerr`) to restore networking.
- 🎨 **Homepage Dashboard:** Fixed broken Jellyfin widget on Homepage after Jellyfin 12+ API upgrade by adding `version: 2` (fixed 404 on `/emby/Items/Counts`, displaying live 157 Movies, 17 Series, 2,075 Episodes).
- 🔒 **Service Hardening:**
  - Disabled public registrations on Vaultwarden (`SIGNUPS_ALLOWED=false`).
  - Fixed FreshRSS domain configuration to `https://rss.lan.kkasbi.in`.
- 🩺 **Fleet Telemetry:** Added automated Gluetun, qBittorrent, and Seerr health checks into `scripts/fleet-validate.sh`.

---

## 2026-11-01 — Complete Audiobook Ecosystem deployment & library deduplication

- 📚 **Audiobook Automation (Chaptarr):** Deployed `chaptarr/chaptarr:latest` (.NET 10 successor to Readarr, port 8789) on Prime media stack. Integrated with Prowlarr categories 3030/7000 and qBittorrent.
- 🎧 **Streaming Server (Audiobookshelf):** Reorganized 124 audiobook titles into 54 standardized author/series folders on `/mnt/andromeda/media/audiobooks`. Configured Caddy reverse proxy (`abs.lan.kkasbi.in` and `abs.krynet.cc`) and verified API scan.
- 🤖 **Zero-Touch Ingestion (Libation Headless):** Deployed `rmcrackan/libation:latest` under `audiobookshelf-stack` on Prime with automated 6-hour sync. Standardized naming template `<has series#->{Series}/{Series} - {Series Number} - {Title}/{Title} - {Series Number}`.
- 🧹 **Library Hygiene & Deduplication:** Marked 110 kids (Peppa Pig) and unwanted titles as deleted in `LibationContext.db` (`IsDeleted = 1`) to suppress re-downloads, and deduplicated on-disk library using `scripts/audiobook-validate.py`.

---

## 2026-10-07 — re-verified before publishing the handoff

- ✅ **pCloud incident resolved** — all three backup checks `up` with pings today; Legion logs
  `Healthcheck: SUCCESS`; no `Revoked` errors in 48 h. (Owner re-authorized.)
- ✅ **Gatus 44/44** — Legion Thermals cleared; CPU 69 °C at load 0.29 with `subgen` still stopped.
- 🔴 **Wifi Socket offline** since 2026-10-06 20:34 UTC — no ping, 6668 closed. Owner power-cycle.
- A single `fleet-validate` DNS timeout against Agni did not reproduce (3/3 retries answered) —
  the DNS probe now retries once before reporting FAIL.
- **Personal Mac checked for the first time:** SSH ✅, `python3`/`dig` ✅, no `~/.ha/token`, no skill
  links, git identity = owner's personal address (as in 13 existing commits — the docs no longer demand
  the noreply address there).
- Legion `sudo` files still not installed.

---

## 2026-11-01 — Gluetun VPN Singapore hardening, autonomous watchdog healing & dashboard updates

- 🛡️ **VPN Resilience:** Hardened Gluetun WireGuard tunnel on Prime with `WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL=25s` and pinned `SERVER_CITIES=Singapore` to prevent silent NAT state drops on Indian broadband connections.
- 🤖 **Autonomous VPN Watchdog (`vpn-watchdog`):** Enhanced `watchdog.sh` with active auto-healing. Daemon probes `http://localhost:8000/v1/publicip/ip` inside Gluetun every 60s; if unresponsive for 3 consecutive checks, it restarts Gluetun automatically and triggers cascading restarts for downstream dependents (`qbittorrent`, `seerr`) to restore networking.
- 🎨 **Homepage Dashboard:** Fixed broken Jellyfin widget on Homepage after Jellyfin 12+ API upgrade by adding `version: 2` (fixed 404 on `/emby/Items/Counts`, displaying live 157 Movies, 17 Series, 2,075 Episodes).
- 🔒 **Service Hardening:**
  - Disabled public registrations on Vaultwarden (`SIGNUPS_ALLOWED=false`).
  - Fixed FreshRSS domain configuration to `https://rss.lan.kkasbi.in`.
- 🩺 **Fleet Telemetry:** Added automated Gluetun, qBittorrent, and Seerr health checks into `scripts/fleet-validate.sh`.

---

## 2026-11-01 — Complete Audiobook Ecosystem deployment & library deduplication

- 📚 **Audiobook Automation (Chaptarr):** Deployed `chaptarr/chaptarr:latest` (.NET 10 successor to Readarr, port 8789) on Prime media stack. Integrated with Prowlarr categories 3030/7000 and qBittorrent.
- 🎧 **Streaming Server (Audiobookshelf):** Reorganized 124 audiobook titles into 54 standardized author/series folders on `/mnt/andromeda/media/audiobooks`. Configured Caddy reverse proxy (`abs.lan.kkasbi.in` and `abs.krynet.cc`) and verified API scan.
- 🤖 **Zero-Touch Ingestion (Libation Headless):** Deployed `rmcrackan/libation:latest` under `audiobookshelf-stack` on Prime with automated 6-hour sync. Standardized naming template `<has series#->{Series}/{Series} - {Series Number} - {Title}/{Title} - {Series Number}`.
- 🧹 **Library Hygiene & Deduplication:** Marked 110 kids (Peppa Pig) and unwanted titles as deleted in `LibationContext.db` (`IsDeleted = 1`) to suppress re-downloads, and deduplicated on-disk library using `scripts/audiobook-validate.py`.

---

## 2026-10-05 — handoff docs; two new incidents found while re-verifying

- **Created `docs/handoff/`** (this folder), the `session-handoff` skill and `scripts/link-skills.sh`;
  `AGENTS.md` now opens with the handoff pointer and the upkeep rule.
- 🔴 **pCloud access token revoked** — `backup-legion` failed 12:09 IST. All three nodes share the token
  (same hash), so Agni and Prime will fail on their next runs. Owner re-auth required (`HANDOFF.md` §3.1).
- 🔴 **Gatus "Legion Thermals" fired** — its first real alert. Cause: `subgen` ran a 13.5 h GPU
  transcription (the backlog from when it had no GPU): CPU 97 °C, GPU 100 % / 90 °C. **`subgen`
  stopped 14:45 UTC.** GPU fell to 81 °C within 3 min; CPU stayed 84 °C at load 0.5 → cooling hardware.
- PS5 plug is back on the LAN (owner power-cycle); its integration now loads.
- Legion `sudo` files still not installed.

## 2026-10-03 — credentials, ping UUIDs, healthchecks; PRs #61–#65 merged

- **Frigate camera credentials → Portainer stack env** (`FRIGATE_CAM_*`). Done on Legion by a script
  that never printed or exported a credential. **Verified:** substituting the values back into the
  placeholder config reproduced the live file **byte-for-byte** before anything was written; after the
  redeploy all three go2rtc streams answered via `ffprobe` and through HA's camera proxy; the
  hardcoded `FRIGATE_RTSP_PASSWORD` fallback is gone. Frigate rewrote `version: 0.17` → `0.17-0`; the
  repo carries the migrated form.
- **Backup ping UUIDs → stack env** on Prime and Agni. **Verified:** Compose recreated *nothing* — the
  re-rendered config was byte-identical, which proves the variable resolved (an empty value would have
  changed the command).
- **Healthchecks on Prime's `dozzle-agent`, `node-exporter`, `docker-socket-proxy`** — each command first
  exec'd inside the live container. All three reached `(healthy)`; untouched services kept their uptime.
- **Memory-limit rollout dry-run** — 45 services / 24 stacks; plan in `PLAN.md`. Awaiting owner "yes".
- Slip recorded: one command's `ssh` inside `$(…)` swallowed a heredoc, so a script silently did
  nothing (caught because it printed nothing). Use `ssh -n` in command substitutions.

## 2026-10-02 — Legion thermals, HA cleanup, new probes

- **Root cause of weeks at 95–100 °C:** every GPU container had **lost the GPU** after the 09-30
  `unattended-upgrade` (daemon-reload → `Failed to initialize NVML: Unknown Error`) and was running on
  the CPU; plus Frigate's three NVDEC decoders held the GPU in P0 at 33 W. Restarted the five
  containers; paused Frigate's cameras. **Verified:** CPU 96 → 73 °C, GPU 88 → 65 °C (P8, 13 W), throttle
  events/30 s ~3000 → 13. The `fan_mode` hypothesis was **wrong** — the write is ignored on this model.
- Staged `51kernel-hold-for-nvidia` and `71-nvidia-dev-char.rules` on Legion `/tmp` (owner `sudo`).
- **Gatus 41 → 44:** Frigate NVR, Legion GPU (body check — the exporter answered 200 with *no* GPU
  metrics for two days), Legion Thermals (15-min average > 90 °C **or** sensor absent). Failure
  direction proven with a no-alert canary at 50 °C.
- **Tuya cloud config entry deleted** (−50 entities, −7 devices) and orphan
  `script.broadcast_announcement` removed. **Verified** against a row-counted backup: 1077 → 1026
  entities exactly; `protected` 6/6 on. Both device-rename items were already done.
- `drift-check.sh` now masks secrets in diffs (it had printed a live password fallback) and covers
  Frigate's config.
- 55 merged GitHub branches deleted (merged **and** unmoved since merge); 3 kept for owner.

## 2026-09-27/28 — two-day power outage; recovery

- All three nodes restarted by the owner. Damage: **7 containers failed to START** (exit 128,
  `RestartCount=0`), which Docker never retries. Legion: kernel `7.0.0-34` (unattended-upgrade, 09-25)
  had no NVIDIA module → all GPU containers dead. Agni: booted 8 min before Prime → an SMB automount
  failed under copyparty.
- Prime's backup **succeeded** but its ping was lost (sent 3 min after boot, before Tailscale routed
  `hc.krynet.cc`) → ping URLs moved to `hc.lan.kkasbi.in`.
- Owner installed the `-34` NVIDIA module and rebooted Legion (09-28).
- **Added `scripts/fleet-validate.sh`** and `fleet-health/reference/post-outage.md` (#60). Replayed
  against the broken fleet it reported all 16 real findings.

## 2026-09-03 → 21 — the September work (PRs #39–#59)

Phase 1 disk reclaim (realised only as ZFS snapshots aged out) · 12 ghost stacks archived/deleted ·
19 secrets out of git · all three DNS name forms served · alerting tiered and canary-proven ·
`drift-check.sh` · `vpn-watchdog` · automations 14 → 8 · Phase 7 Tuya → local · dashboards rebuilt ·
Legion backup dead-man switch. One row per item, with the reason it mattered: `PLAN.md` §2.
