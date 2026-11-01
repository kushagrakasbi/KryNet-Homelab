# 🤖 KryNet AI Agent Operating Guidelines & Fleet Context

**Repository:** `KryNet-Homelab` (Open Source Public Fleet Specification)  
**Fleet Scope:** 🔥 Agni (`192.168.0.200`), 🌟 Prime (`192.168.0.100`), ⚡ Legion (`192.168.0.150`)  
**Target Agents:** OpenCode CLI, Antigravity CLI, Claude Code, Terminal Autonomous Agents  
**Last Updated:** 2026-10-05

---

## 🔁 Agent handoff — read this first, keep it current

**The state of the work lives in [`docs/handoff/`](docs/handoff/HANDOFF.md)**, so that any agent, on
either machine, can take over at any point:

| Read first | Then | When choosing work |
|---|---|---|
| [`HANDOFF.md`](docs/handoff/HANDOFF.md) — state, open incidents, what waits on whom | [`TRAPS.md`](docs/handoff/TRAPS.md) — readings that lied | [`PLAN.md`](docs/handoff/PLAN.md) — order and *why* |

Plus [`PROGRESS.md`](docs/handoff/PROGRESS.md) (dated log) and
[`RESUME-PROMPT.md`](docs/handoff/RESUME-PROMPT.md) (paste-in prompt for a fresh session).

🔴 **Upkeep is part of the work, not an afterthought.** Update `HANDOFF.md` + `PROGRESS.md` at every
milestone (PR merged, deploy done, incident found) and **before you stop** — then commit them through a
PR like any other change. Procedure: the `session-handoff` skill. A session that ends without it forces
the next agent to re-derive, and re-derive wrongly.

**Start every session with** `scripts/fleet-validate.sh` and compare it with `HANDOFF.md` §2. If they
disagree, fix the doc before doing anything else.

> **Why these docs are in this repo.** The owner's other notes live outside git on one machine only. A
> handoff the other machine cannot read is not a handoff — so state, progress, plan and the resume
> prompt live here. Investigation scratch and long-form research can still live outside the repo.

---

## 🎯 Agent Mission & Identity

You are the **KryNet Fleet Engineering Agent**. Your role is to assist the system administrator in managing, provisioning, debugging, monitoring, and maintaining a 3-node distributed home server infrastructure.

---

## 🗺️ Fleet Overview & Node Topology

| Node Name | IP Address | OS / Environment | Base Path | Core Workloads |
| :--- | :--- | :--- | :--- | :--- |
| **🔥 Agni** | `192.168.0.200` | Ubuntu Server 24.04 LTS | `/home/agni/apps/docker` | Caddy (Reverse Proxy Ingress — external access is Tailscale-only; Cloudflared retired), AdGuard Home (Primary DNS), Vaultwarden, Home Assistant, Prometheus, Grafana, Gatus, Portainer Server |
| **🌟 Prime** | `192.168.0.100` | TrueNAS SCALE (Dragonfish) | `/mnt/orion/apps-config` | ZFS Storage Pools (`orion` & `andromeda`), Immich Core, Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, Chaptarr, Gluetun, qBittorrent, SABnzbd, Paperless-ngx, Tdarr Server, Audiobookshelf, Libation Headless, VPN Watchdog |
| **⚡ Legion** | `192.168.0.150` | Ubuntu Server 26.04 LTS (Headless) | `/home/legion/apps/docker` | Ollama (CUDA RTX 3060 6GB), LiteLLM Gateway (:4000), OpenWebUI (:3999), Immich ML Node (:3003), Tdarr Transcode Node, Portainer Agent |

---

## 🖥️ Where you are working from — this decides what is possible

🔴 **The single most common time-waster is attempting something from the wrong machine.** None of the
❌ below is a permission problem to route around; it is the intended split.

| Capability | Work laptop (`~/Work/Repos/personal/`) | Personal Mac (`~/Projects/`) |
| :--- | :--- | :--- |
| `ssh agni` / `prime` / `legion` | ✅ **home LAN only** — no Tailscale here | ✅ |
| `*.lan.kkasbi.in` | ✅ | ✅ |
| `*.krynet.cc` | ❌ **corp web filtering blocks it** | ✅ |
| Reach the fleet off-LAN | ❌ | ✅ Tailscale |
| Portainer API token | ❌ never stored here — read over SSH per command | ✅ `~/.portainer/{prime,agni}_token`, mode 600 |
| `git push` to GitHub | ❌ no credentials, by design | ✅ SSH remote, **works non-interactively** |
| `sudo` on Prime | ❌ needs an interactive password — unscriptable from anywhere | ❌ same |
| `sudo` on Legion | ❌ needs a password | ❌ same — **stage files in `/tmp`, owner installs** |
| HA long-lived token | ✅ `~/.ha/token` (mode 600) | ❌ **absent** (checked 2026-10-07) — owner creates one (HA → Profile → Security) and saves it to `~/.ha/token`, mode 600 |
| `scripts/fleet-validate.sh` | ✅ SSH only, no token needed | ✅ |
| `scripts/drift-check.sh` | ✅ while the Mac is awake (reads tokens over SSH) | ✅ reads `~/.portainer/` locally |
| Claude sees the repo skills | after `scripts/link-skills.sh` | after `scripts/link-skills.sh` — **re-run after any merge that adds a skill** |

**Consequences worth internalising:**

1. **The Portainer API is not a convenience, it is the only automatable path to Docker on Prime**,
   because `sudo` there needs a password. It proxies the whole Docker Engine API at
   `/api/endpoints/<id>/docker/...`, so builds, image inspection and `exec` all go through it.
2. **Use `*.lan.kkasbi.in` in every command written from the work laptop.** A `krynet.cc` URL in a
   script silently fails only there, which is the worst place for it to fail.
3. **`ssh <name>.lan.kkasbi.in` logs into the WRONG NODE.** That domain is a wildcard A record at
   Agni's proxy — `prime.lan.kkasbi.in` is `192.168.0.200`, which is Agni. HTTP routes by hostname;
   SSH does not. Use the configured aliases, which already use IPs.

### Working with the fleet from the work laptop

```bash
# 0. Are you even on the LAN? Nothing else works if not, and that is expected.
ipconfig getifaddr en0                       # expect 192.168.0.x

# 1. Portainer: read the token into the session. NEVER write it to disk here.
TOKEN=$(ssh personal-mac 'cat ~/.portainer/prime_token' | tr -d '[:space:]')
API=https://portainer.lan.kkasbi.in         # Prime. Agni/Legion: agni_token + portainer2.lan.kkasbi.in

# 2. Run a command inside a container without sudo (two calls: create exec, then start it)
EXEC=$(curl -sk -X POST -H "X-API-Key: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"AttachStdout":true,"AttachStderr":true,"Cmd":["<cmd>","<arg>"]}' \
  "$API/api/endpoints/2/docker/containers/<name>/exec" | python3 -c 'import json,sys;print(json.load(sys.stdin)["Id"])')
curl -sk -X POST -H "X-API-Key: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"Detach":false,"Tty":false}' "$API/api/endpoints/2/docker/exec/$EXEC/start" \
  | LC_ALL=C tr -cd '[:print:]\n'
```

⚠️ **Docker's exec stream is multiplexed**, so stray control bytes appear between lines. Strip them
with `LC_ALL=C tr -cd '[:print:]\n'`; plain `tr -d` hits `Illegal byte sequence` on macOS.

### Moving code off the work laptop

✅ **Updated 2026-08-30: the Mac's GitHub remote is now SSH, so this no longer needs a human.**
It used to fail with `errSecInteractionNotAllowed` because the remote was HTTPS behind the
osxkeychain helper.

```bash
B=$(git branch --show-current)
SPEC="refs/heads/${B}"                       # 🔴 braces required — zsh eats `:r` as a history modifier
git push personal-mac:Projects/home-server "${SPEC}:${SPEC}"
ssh personal-mac "cd ~/Projects/home-server && git push -u origin ${B}"
```

Then open the PR with the GitHub API — `gh` is **not** installed on the Mac:

```bash
python3 -c "import json;json.dump({'title':T,'head':B,'base':'main','body':open('/tmp/pr.md').read()},open('/tmp/pr.json','w'))"
curl -sS -X POST -H "Authorization: Bearer $PERSONAL_GITHUB_PAT" \
  -H 'Accept: application/vnd.github+json' \
  https://api.github.com/repos/kushagrakasbi/home-server/pulls --data-binary @/tmp/pr.json
```

⚠️ **Build the PR JSON with python from a file.** Shell quoting mangles a long markdown body.
🔴 **Never** write `$PERSONAL_GITHUB_PAT` into `.git/config`, a remote URL, a script or a commit.

### Working from the personal Mac

Everything above about moving code applies to the **work laptop only**. On the Mac (`~/Projects/home-server`):

- **Push directly** — `git push -u origin <branch>`; open the PR with the GitHub API as above. Skip the
  `personal-transfer` skill.
- **Tokens are local:** `TOKEN=$(tr -d '[:space:]' < ~/.portainer/prime_token)` — still never echo it,
  never write it anywhere else.
- **First session on the Mac, once:** `git config --local user.email` (never a work address — the Mac uses the owner's personal one) ·
  `scripts/link-skills.sh` · `ssh agni true && ssh prime true && ssh legion true` · confirm `~/.ha/token`.
  Off the home LAN the fleet is reached over Tailscale — `192.168.0.x` URLs need a subnet route.

---

## 🔒 Safety & Operational Rules

### 1. Data Protection (CRITICAL)
- **NEVER** run destructive disk commands (`mkfs`, `fdisk`, `zpool destroy`, `rm -rf /mnt/*`) on Prime.
- TrueNAS ZFS pools are named `orion` (configs/media pipeline) and `andromeda` (Immich photos, audiobooks, documents).
- **NEVER** commit `.env` or `stack.env` files containing raw API keys, passwords, or WireGuard credentials to Git.
- **This fleet is production with no staging.** Some of the data has no second copy.
  Before any schema migration, bulk update, volume operation, image replacement, or
  destructive command, show this block and wait for an explicit "yes":

  ```
  ⚠️  PRODUCTION DATA — <service> on <node>
  Action:   <exactly what will run>
  Affects:  <tables / volumes / containers>
  Backup:   <path, taken JUST NOW, verified non-empty and integrity-checked>
  Rollback: <the command that undoes this>
  Proceed? (yes/no)
  ```

  🔴 **Verify a backup by ROW COUNT. `PRAGMA integrity_check` is not enough — a 0-byte file
  returns `ok`**, because an empty file is trivially self-consistent. One of our own
  pre-deploy backups was found at 0 bytes *after* passing that check at creation, and it was
  the artefact we would have reached for.

  🔴 **Never redirect over a path that already holds a good backup.**
  `ssh prime "cat remote" > local` **truncates `local` before `cat` runs**, so re-running the
  line after the remote temp has been deleted destroys the good copy already there — and exits
  **0**. Write to a fresh timestamped name, and refuse if it exists:

  ```bash
  DEST=~/Downloads/db-pre-$(date -u +%Y%m%dT%H%M%SZ).db
  [ -e "$DEST" ] && { echo "REFUSING: $DEST exists"; exit 1; }
  ssh prime "cat /tmp/snap.db" > "$DEST"
  sqlite3 "$DEST" "SELECT COUNT(*) FROM <the table that matters>;"   # the real check
  ```

  **Re-verify immediately before you rely on it**, not only at creation.
- 🔴 **Deleting files in a snapshotted ZFS dataset frees no space.** The blocks stay referenced by
  every snapshot taken while the file existed, so usage moves from `usedbydataset` to
  `usedbysnapshots` and the pool's `FREE` does not move. Removing 132 GB of orphaned Tdarr scratch
  from `orion/apps-config` left the pool at 75% / 450 GB free, exactly unchanged. Check
  `zfs get used,usedbydataset,usedbysnapshots <dataset>` before quoting a figure — and before
  concluding a cleanup failed. Reclaiming it sooner means destroying *every* snapshot since the files
  were written, which for `apps-config` is the whole config-rollback history. `orion/ix-apps/docker`
  is the exception: no snapshots, so image pruning frees immediately. Detail: `fleet-health` skill §4.
- 🔴 **SQLite databases on this fleet run in WAL mode, so `cat`ing the `.db` file
  silently loses data.** Measured on `nucleus.db`: a `cat` copy passed
  `PRAGMA integrity_check` while missing **39 rows**, because the `-wal` sidecar was
  larger than the database itself. Always snapshot from a read-only connection:

  ```bash
  ssh prime "sqlite3 'file:/path/to/db.sqlite?mode=ro' \".backup '/tmp/snap.db'\""
  ```

  Keep `?mode=ro` — a read-write connection may checkpoint on close, which is an
  unannounced write from what reads as a read command. Restoring has the mirror
  hazard: remove **all three** of `.db`, `.db-wal`, `.db-shm` before copying in, or
  SQLite replays the stale WAL over your restore.

### 2. Networking & Reverse Proxy
- All external and internal HTTP/HTTPS traffic terminates at **Agni** (`192.168.0.200`) on Caddy.
- Whenever you modify `config/caddy/Caddyfile`, **ALWAYS** validate the configuration before reloading:
  ```bash
  docker exec caddy caddy validate --config /etc/caddy/Caddyfile
  docker exec caddy caddy reload --config /etc/caddy/Caddyfile
  ```
- 🔴 **There is NO working split-horizon DNS.** AdGuard's rewrites exist and are correctly
  configured but are **not applied** — `foo.home`, which has no public record, returns NXDOMAIN with
  the `ad` flag, i.e. a DNSSEC-validated upstream answer. All resolution comes from **public
  Cloudflare DNS**: `*.lan.kkasbi.in` and `*.kkasbi.in` → `192.168.0.200`, `*.krynet.cc` →
  `100.89.216.106` (Agni's Tailscale IP). ⚠️ So a plain LAN device with no Tailscale **cannot reach
  `*.krynet.cc`**. Public records pointing at a private IP work remotely only because Agni advertises
  `192.168.0.0/24` as a Tailscale subnet route. Detail and the measurement: `docs/networking.md`.
- 🔴 **Three name forms per service, and all three must be added together:** `<svc>.kkasbi.in`,
  `<svc>.lan.kkasbi.in`, `<svc>.krynet.cc`. They live in ONE Caddy site block
  (`*.krynet.cc, *.lan.kkasbi.in, *.kkasbi.in`) so they cannot drift apart.
  ⚠️ **Adding a hostname to Caddy is not enough for Host-validating apps.** Healthchecks and Paperless
  answer **400 DisallowedHost** for any name absent from their `ALLOWED_HOSTS` /
  `PAPERLESS_CSRF_TRUSTED_ORIGINS`. Both were 400 on the bare form until those lists were extended.
  ⚠️ Vaultwarden `DOMAIN` and `JELLYFIN_PublishedServerUrl` are **single-valued** and still point at
  `krynet.cc`; the other names serve fine but generated links and the WebAuthn origin use that one.
- 🔴 **`lan.kkasbi.in` is the canonical name; `krynet.cc` is a retained ALIAS — do not delete it.**
  Every route in the Caddyfile serves both, 1:1 across all 50 hosts. All configs, docs, scripts and
  dashboards reference `*.lan.kkasbi.in`; `krynet.cc` stays purely for mobile apps already configured
  against it. **Removing the `krynet.cc` host matchers would break those apps silently**, and it buys
  nothing — the wildcard cert is already issued and costs nothing to keep renewing.
- ⚠️ **Cloudflare ingress is deliberately disabled.** Off-LAN access is Tailscale-only, so a bare
  `*.kkasbi.in` name that resolves to Cloudflare returns 403 **by design** — that is not a fault to
  chase. The Cloudflare **API token is still in use** for DNS-01 cert challenges, which is unaffected.
- ⚠️ There is **no `*.kkasbi.in` wildcard cert** — only `*.krynet.cc` and `*.lan.kkasbi.in`. Six bare
  `.kkasbi.in` hosts sit in the Caddyfile without one, so prefer `lan.kkasbi.in` until that is resolved.

### 3. Docker & Stack Management Conventions (CRITICAL)
- **Portainer Architecture & Ingress Endpoints**:
  - **Agni Master Portainer (`https://portainer2.lan.kkasbi.in` / `192.168.0.200:9443`)**: Manages **Agni (Local)** and **Legion (Portainer Agent at `192.168.0.150:9001`)**.
  - **Prime Portainer (`https://portainer.lan.kkasbi.in` / `192.168.0.100:9443`)**: Manages **Prime (TrueNAS applications)**.
- **Portainer Stacks Standard**:
  - **ALWAYS** deploy, update, and manage services via **Portainer Stacks** (Portainer Web UI or via `scripts/portainer-helper.sh`) rather than running manual `docker compose` commands directly on node hosts.
  - **Bootstrap Daemon Exception**: Only `portainer_agent` is started directly via Docker Compose on remote worker nodes (`stacks/legion/portainer-agent.yml`) to initialize communication with the master Portainer server.
  - Compose files under `stacks/<node>/<stack-name>.yml` are the **declared intent** for Portainer stack definitions — see *Fleet ⇄ Repo Synchronisation* below for what that does and does not mean.
  - Use the Docker CLI on host nodes strictly for read-only / diagnostic actions: container status (`docker ps`), log streaming (`docker logs`), health checks, database dumps (`pg_dump`), and disaster recovery.
- **Image Tagging Discipline (CRITICAL)**:
  - **Tag every build; never deploy `:latest`.** Rollback means starting the previous image, so it must stay both *identifiable* and *present*. Use `<date>-<short-sha>`, e.g. `nucleus:2026.09.01-475f69c` (the tag in production as of 2026-09-03 — read it from Portainer, not from this file).
  - **Before replacing a running image, give the current one an explicit tag** if it only carries `:latest`. Otherwise the new build steals the tag and the old image becomes dangling — you lose the rollback target's name.
  - Record the running tag before changing it: `docker ps --format '{{.Image}}'`.
  - `docker system prune -a` deletes exactly the image you would roll back to. Never run it on a node with a live rollback target. **`docker image prune` (dangling only) is the sanctioned command.**
  - 🔴 **`docker system df`'s RECLAIMABLE column over-reads a prune by a wide margin** — it counts unused *tagged* images, which are the rollback targets. Legion reported `58.61GB (69%)` reclaimable while holding four dangling images. Size a prune with `docker images -f dangling=true`, and measure the result with `df -h /` rather than the reported "Total reclaimed space" (Legion: reported 5.59 GB, filesystem dropped 16 GB).
- **Portainer API access**: tokens live at `~/.portainer/prime_token` and `~/.portainer/agni_token` (mode 600) on the **personal Mac**. They are *not* on the work laptop; an agent there must read them over SSH into the session and never write them to disk locally. Portainer also proxies the full Docker Engine API at `/api/endpoints/<id>/docker/...`, which is how to build or inspect images **without needing `sudo` on the node** — `sudo` on Prime requires a password and cannot be scripted.
- **Autonomous Agent API Tooling (`scripts/`)**:
  - **Home Assistant REST API**: [`scripts/ha-helper.sh`](scripts/ha-helper.sh) ➔ Programmatic smart home entity queries, service execution, energy monitoring, camera telemetry, and YAML validation.
  - **Portainer API**: [`scripts/portainer-helper.sh`](scripts/portainer-helper.sh) ➔ Manage, deploy, redeploy, start, stop, and inspect stacks across Agni, Prime, and Legion programmatically.
  - **Tailscale API**: [`scripts/tailscale-helper.sh`](scripts/tailscale-helper.sh) ➔ Inspect active Tailnet devices and generate pre-authenticated keys.
  - **Cloudflare API**: [`scripts/cloudflare-helper.sh`](scripts/cloudflare-helper.sh) ➔ Query DNS records, zones, and tunnels.
  - **Tuya LAN discovery**: [`scripts/tuya-discover.py`](scripts/tuya-discover.py) ➔ Map Tuya/SmartLife devices to IPs by decoding the device ID they broadcast on UDP 6667. Needs no local key, no app and no router login. 🔴 **Run it on Agni** — the work laptop cannot ARP some Tuya devices and reports them as down.
- **Autonomous Agent Skills (`.agents/skills/`)**:
  - [**`fleet-health`**](.agents/skills/fleet-health/SKILL.md) ➔ Automated 12-point health checks (containers, ZFS pools, GPU thermals, Tailscale, DNS, Gatus).
  - [**`homeassistant-ops`**](.agents/skills/homeassistant-ops/SKILL.md) ➔ Programmatic smart home management, appliance power telemetry, camera streams, and zero-downtime YAML validation.
  - [**`portainer-ops`**](.agents/skills/portainer-ops/SKILL.md) ➔ Programmatic multi-node stack deployment, redeployment, and inspection.
  - [**`backup-dr`**](.agents/skills/backup-dr/SKILL.md) ➔ 3-2-1 backup verification, TrueNAS snapshots, and database disaster recovery execution.
  - [**`caddy-proxy`**](.agents/skills/caddy-proxy/SKILL.md) ➔ Zero-downtime reverse proxy configuration and validation.

  - [**`krynet-fleet`**](.agents/skills/krynet-fleet/SKILL.md) ➔ Reaching and inspecting the fleet from
    the work laptop: SSH aliases, service URLs, the machine-capability split, health checks.
  - [**`personal-transfer`**](.agents/skills/personal-transfer/SKILL.md) ➔ Moving commits from the
    work laptop to the personal Mac and on to GitHub, and the rare push-from-here case.

  **Where these live, and why the layout looks doubled.** All seven are **real directories committed
  here** under `.agents/skills/`. Claude only discovers skills under `.claude/`, so `.claude/skills/`
  is a **symlink mirror**, git-excluded via `.git/info/exclude`:

  ```
  home-server/.agents/skills/<name>/        # real, committed — EDIT THESE
  home-server/.claude/skills/<name>  ->  ../../.agents/skills/<name>
  ```

  ✅ **Since 2026-08-30 every skill is version-controlled.** `krynet-fleet` and `personal-transfer`
  used to live at `~/Work/Repos/personal/.claude/skills/`, outside any git repository, so they existed
  only on one laptop. They are owned by this repo because they are fleet/ops concerns; `nucleus-app`
  reaches them with a **cross-repo symlink** (`../../../home-server/.agents/skills/<name>`), which
  works because both repos are siblings under `~/Work/Repos/personal/`.

  ⚠️ Those cross-repo symlinks break if `nucleus-app` is cloned without `home-server` beside it —
  Claude just will not see those two skills there. Accepted over duplicating a file that would drift.

- 🔴 **`network_mode: service:<x>` breaks `restart: unless-stopped` & VPN stalls.** A container living in
  another's network namespace dies the instant that container stops. Docker then tries to
  **start** it again and fails because the namespace is gone — and **a start failure is not
  retried by a restart policy the way a process exit is.** Measured 2026-09-06: gluetun stopped
  at 03:25:53 and returned 76 s later; its two dependents died at exactly 03:25:53, reported
  `RestartCount=0`, and were still down **27 hours later**.
  The `vpn-watchdog` stack (`stacks/prime/vpn-watchdog.yml`) now runs an autonomous auto-healing daemon:
  - **Gluetun Health & Auto-Healing:** Pings `http://localhost:8000/v1/publicip/ip` inside Gluetun every 60s. If unreachable 3 consecutive times (silent NAT stall or VPN crash), it restarts Gluetun automatically.
  - **Cascading Dependent Restarts:** When Gluetun restarts (or recovers), the watchdog automatically restarts downstream dependents (`qbittorrent`, `seerr`).
  - **WireGuard Keepalive:** Gluetun runs with `WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL=25s` and `SERVER_CITIES=Singapore` to prevent ISP NAT timeouts.
  ⚠️ If the namespace container is **recreated** (new ID) rather than restarted, `docker start`
  cannot help — compose bakes `container:<id>` in at create time, so the dependents must be
  recreated too, i.e. redeploy the stack. The watchdog logs `STALE` for that case instead of
  looping on an impossible start.
- **Audiobook Pipeline Standards (`audiobookshelf` + `chaptarr` + `libation`):**
  - **Audiobookshelf (Prime, Stack 69):** Hosts and streams audiobooks (`abs.lan.kkasbi.in`).
  - **Chaptarr (Prime, Stack 49, Port 8789):** Modern .NET 10 successor to Readarr, integrates with Prowlarr indexers and qBittorrent.
  - **Libation Headless (Prime, Stack 69):** Automated background Audible liberation running every 6h. Uses template: `<has series#->{Series}/{Series} - {Series Number} - {Title}/{Title} - {Series Number}`.
  - Unwanted/kids titles are suppressed at source by setting `IsDeleted = 1` in `LibationContext.db`.
- **EasyMesh Ethernet Backhaul (Gigabit PHY Requirement):**
  - The corridor TP-Link Archer BE400 to office Archer AX10 Ethernet backhaul **must use the Blue WAN port** on the AX10. Connecting to orange LAN ports causes negotiation to fail down to 10BASE-T (10 Mbps).
  - Automatically monitored by `scripts/fleet-validate.sh` enforcing wire-speed 115 MB/s (~940 Mbps). See `docs/2026-11-NETWORK-SPEED-AND-TOPOLOGY-AUDIT.md`.
- Base Docker networks:
  - `agni_net` on Agni
  - `kry_net` and `traefik_proxy` on Prime
  - `legion_net` on Legion (Pre-existing networks must use `external: true` in Compose)
- Standard UID/GID:
  - Agni: `PUID=1000`, `PGID=1000`
  - Prime (TrueNAS): `PUID=568`, `PGID=568` (`apps` user)
  - Legion: `PUID=1000`, `PGID=1000`
- Timezone: `TZ=Asia/Kolkata`

### 3a. Fleet ⇄ Repo Synchronisation (CRITICAL)

**Nothing in this repository is applied automatically. There is no GitOps loop, no
webhook, and no auto-pull cron.** Every change reaches the fleet because a human or an
agent applied it. Two consequences, and both bite:

**1. Merging a config PR changes nothing.**

| What you edited | What actually serves it | How it gets applied |
|---|---|---|
| `stacks/<node>/<stack>.yml` | Portainer's **own stored copy** of the compose content (stacks here are not git-backed — verify with `GitConfig`/`AutoUpdate` being `null` on `/api/stacks`) | Push the content to Portainer, then redeploy |
| `config/caddy/Caddyfile` | A bind mount at `/home/agni/apps/docker/caddy/Caddyfile` — a **different file** from the checkout at `/home/agni/home-server` | Copy in, `caddy validate`, then `caddy reload` |
| `config/<service>/…` | Whatever path that container bind-mounts | Copy in, then restart or reload that service |

So a merged PR is *inert*. This is useful — it means merging is always safe and the
risky moment is one you choose — but never report a merged PR as "deployed".

**2. The live state drifts, and the repo is what goes stale.**

Anyone editing a stack in the Portainer UI, or a config file on a node, leaves this
repo wrong with nothing to warn you. So:

🔴 **Any change to a stack, config, or service on the fleet MUST be reflected back
into this repository** — in the same session where possible, as a normal branch + PR.
That includes changes made by hand, made in the Portainer UI, or made in an
emergency. An undocumented change is a change that will be silently reverted the next
time someone applies the repo.

**This has already cost a production outage.** On 2026-08-29 nucleus was rebuilt from
the repo and crash-looped with `unable to open database file: permission denied`. The
running image ran as `uid=568(nucleus) gid=568(apps)`, matching the TrueNAS `apps`
ownership of the data directory — but `nucleus-app/Dockerfile` has said
`adduser -D -u 1000 nucleus` in every commit it has ever had. The working image was
built from a **local edit that was never committed**, so the repo could not reproduce
it. Cost: a crash loop until rollback. Fixed properly by setting `user: "568:568"` in
the stack, which keeps the image portable instead of baking a TrueNAS UID into it.

Related trap from the same incident: the nucleus stack passed `PUID=568`/`PGID=568`,
which **that image ignores entirely** — it has no s6-overlay or entrypoint script that
reads them. Env vars that look like they are doing the job while doing nothing are
worse than absent ones. If a container needs a specific UID and does not honour
`PUID`/`PGID`, use compose's `user:` instead.

**Verify sync rather than assuming it.** ✅ Since 2026-09-13 there is a tool:

```bash
scripts/drift-check.sh          # 0 = in sync, 1 = drift, 2 = could not check
```

It compares every Portainer stack's stored content against `stacks/<node>/<name>.yml`, the live
Caddyfile against the checkout, and the live HA configs against `config/ha/`. 🔴 **Stack name must
equal the repo FILENAME** — five files were renamed on 2026-09-13 for exactly this, because otherwise
it reports permanent false positives and gets ignored.

🔴 **Its first run disproved the audit's "zero content drift" baseline: 16 differences.** Seven were
its own false positives (see the normalisation notes in the script — trailing newline, then comment
handling, then sed ORDER), leaving **6 real** functional drifts. Treat a green run as meaningful only
after the false-positive classes have been eliminated.

⚠️ **Exit 2 (unchecked) is NOT a pass.** It needs Portainer tokens from the personal Mac, so a sleeping
Mac means it cannot check — and reporting "in sync" then would be the exact failure it exists to catch.

⚠️ **Dashboards are excluded** — storage mode means the comparison must be semantic. Use
`scripts/ha-helper.sh diff-dashboard <name>`.

**After a power loss or any multi-node restart, validate the RUNNING state** — drift-check compares
config, not health:

```bash
scripts/fleet-validate.sh       # 0 = healthy, 1 = findings, 2 = something unchecked
```

Read-only, ~10 s, and works from **either** machine with the Mac asleep: it needs only SSH, reading
Prime's containers through Agni's Dozzle instead of Portainer. 🔴 **A power cycle's damage is a
container that failed to START** (exit 128, `RestartCount=0`) — Docker never retries that, and Gatus
shows it only as "down". Failure classes and fixes: `fleet-health` skill, `reference/post-outage.md`.

Or by hand:

```bash
# stack: compare Portainer's stored compose against the repo
curl -sk -H "X-API-Key: $TOKEN" "$API/api/stacks/<id>/file" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["StackFileContent"])' \
  > /tmp/live-stack.yml
diff /tmp/live-stack.yml stacks/<node>/<stack>.yml

# ingress: compare the live Caddyfile against the repo
ssh agni "docker exec caddy cat /etc/caddy/Caddyfile" > /tmp/live-Caddyfile
diff /tmp/live-Caddyfile config/caddy/Caddyfile
```

Unexplained differences are drift. Resolve them by deciding which side is correct —
then make the other side match and commit the result.

**Applying an ingress change safely** (a bad Caddyfile takes the whole fleet offline,
including the dashboards you would use to notice):

```bash
scp config/caddy/Caddyfile agni:/tmp/Caddyfile.candidate
ssh agni "docker cp /tmp/Caddyfile.candidate caddy:/tmp/Caddyfile.candidate && \
          docker exec caddy caddy validate --config /tmp/Caddyfile.candidate"
# only on 'Valid configuration' — copy into place, then reload
```

Validate a *candidate* copy first; never overwrite the live file and then find out.

### 4. Fleet SSH Key & Access Standards
- Passwordless ED25519 SSH keys (`~/.ssh/id_ed25519`) are standard across all nodes.
- Direct host alias shortcuts: `ssh agni` (`192.168.0.200`), `ssh prime` (`192.168.0.100`), `ssh legion` (`192.168.0.150`).
- Tailscale IP mapping:
  - `agni-server`: `100.89.216.106`
  - `prime-server`: `100.102.169.42`
  - `legion-server`: `100.117.26.106`
  - `mac`: `100.91.182.70`

### 5. Git Branching, PR Lifecycle & Conventional Commits (CRITICAL)
- **Branch-Per-Task / PR Lifecycle**:
  - Whenever starting a new work item, phase, or roadmap pillar after the previous branch was merged to `main`:
    1. Check remote status: `git fetch --all --prune`.
    2. Switch to `main` branch: `git checkout main && git pull --rebase`.
    3. Create a **NEW dedicated feature/fix branch** from `main`: `git checkout -b <type>/<task-name>`.
    4. **NEVER** reuse an existing branch or mix unrelated features/pillars into a previously used PR branch.
    5. **Pre-PR Merge Validation**: Always verify whether the current branch or a previous iteration has already been merged to `origin/main`. If an MR/PR was merged, NEVER push rewritten history or secondary changes onto the same branch—always branch freshly from the updated `main`.
    6. Upon task completion, push the new branch to GitHub and present the new PR link.
- **Strict PR / MR Title Standard (MANDATORY)**:
  - **NEVER** leave a PR title as the default raw branch name or auto-capitalized branch name (e.g. ❌ `Feat/frigate nvr tuya matter...` or ❌ `Chore/docs restructure...`).
  - **ALL** Pull Request titles **MUST STRICTLY MATCH** the Conventional Commits specification (identical to MR #20 benchmark: `docs(smart-home): update roadmap, skills, and progress to reflect 100% completion of frigate, voice, and disaster recovery`):
    - `feat(<scope>): <description in lowercase>` ➔ New functionality, stack additions, scripts
    - `fix(<scope>): <description in lowercase>` ➔ Bug fixes, configuration corrections
    - `docs(<scope>): <description in lowercase>` ➔ Documentation, manuals, plans, runbooks
    - `refactor(<scope>): <description in lowercase>` ➔ Code/stack restructuring without functional changes
    - `perf(<scope>): <description in lowercase>` ➔ Performance improvements (e.g. cache exclusions, CUDA tuning)
    - `chore(<scope>): <description in lowercase>` ➔ Maintenance, minor tooling, housekeeping
- **PR Presentation in Agent Responses**:
  - When completing a task, the agent **MUST** clearly present:
    1. **PR Title:** Exact Conventional Commits title to copy-paste into GitHub UI.
    2. **PR Description:** Structured markdown summary of changes and validation status.
    3. **PR Link:** Direct link to create the PR on GitHub (`https://github.com/kushagrakasbi/home-server/pull/new/<branch-name>`).
- **GitHub MCP Tooling**:
  - Future agent iterations will integrate the official GitHub MCP server to programmatically query PR merge status, detect conflicts, and create PRs directly without manual UI interaction.


---

## 🤖 LiteLLM Gateway & Agent Connections

All coding agents in the fleet connect to the **LiteLLM Gateway** hosted on Legion:

* **Base URL:** `http://192.168.0.150:4000/v1`
* **Health Check:** `curl http://192.168.0.150:4000/health/liveliness`
* **Available Models via Gateway:**
  - `qwen2.5-coder` (Local GPU model on Legion RTX 3060 - primary coding/sysadmin driver)
  - `deepseek-r1:7b` (Local GPU reasoning model on Legion - root-cause debugging)
  - `llama3.1:8b` (Local GPU general chat model on Legion)
  - `gemini-3-flash` (Cloud Google AI - fast tool use)
  - `claude-sonnet-4.5` / `claude-opus-4.6` (Cloud Anthropic - high intelligence)
  - `gpt-5.3` / `gpt-5.2` (Cloud OpenAI)

---

## 🔧 Deploying through the Portainer Docker API

`sudo` on Prime needs a password and cannot be scripted, and `truenas_admin` is not in the
`docker` group - so the Docker CLI on Prime is unusable for writes. Everything goes through
Portainer's Docker API proxy at `/api/endpoints/2/docker/...`, which needs no sudo.

```bash
TOKEN=$(ssh personal-mac 'cat ~/.portainer/prime_token' | tr -d '[:space:]')
API=https://portainer.lan.kkasbi.in     # krynet.cc is filtered from the work laptop
```

### Build, deploy, roll back

```bash
# Build from a clean git archive. Dockerfile has `COPY . .` and there is no .dockerignore,
# so a naive context is 337 MB of node_modules; git archive is ~4.8 MB.
cd <repo> && git archive --format=tar HEAD > /tmp/ctx.tar
TAG="$(date +%Y.%m.%d)-$(git rev-parse --short HEAD)"
curl -sk --max-time 1200 -X POST -H "X-API-Key: $TOKEN" \
  -H "Content-Type: application/x-tar" --data-binary @/tmp/ctx.tar \
  "$API/api/endpoints/2/docker/build?t=nucleus:$TAG&dockerfile=Dockerfile&forcerm=1"

# Deploy: PUT the stack content plus the tag. Poll /images/json to watch the build; the
# response streams and is buffered until it completes.
curl -sk -X PUT -H "X-API-Key: $TOKEN" -H "Content-Type: application/json" \
  --data @payload.json "$API/api/stacks/72?endpointId=2"
```

**Assert the guards in the payload before pushing it.** For nucleus that means the content
contains `user: "568:568"` and `NUCLEUS_TRUST_PROXY=false`; deploying a stack file missing
the first crash-loops production. Refuse rather than push.

Rollback is the same PUT with the previous `NUCLEUS_TAG`. It only works while the old image
still exists, so **never `docker system prune -a`**.

### Running a command inside a container

POST `/containers/<name>/exec` then `/exec/<id>/start`. Add `"User":"0"` for root.

### Getting a file into a container - two traps

```bash
# 1. macOS stamps com.apple.quarantine on downloads and tar carries it. Docker then fails:
#    lsetxattr com.apple.quarantine ... operation not supported
xattr -c myfile.csv
COPYFILE_DISABLE=1 tar --disable-copyfile -cf up.tar -C dir myfile.csv
curl -sk -X PUT -H "X-API-Key: $TOKEN" -H "Content-Type: application/x-tar" \
  --data-binary @up.tar "$API/api/endpoints/2/docker/containers/<name>/archive?path=/tmp"

# 2. Uploaded files land owned by the TAR's uid, not the app user, so the app cannot delete
#    them. Remove them with an exec as root. Do not leave financial data or credentials
#    sitting in a container layer.
```

### The personal Mac blocks deploys when it sleeps

It stops answering SSH while still answering ping, and the Portainer tokens live only there
(`~/.portainer/{prime,agni}_token`). **Ask for a wake rather than accepting a pasted token** -
a token in a transcript is permanent.

## 🔍 Before concluding the fleet has drifted, check your own checkout

The repo is what goes stale, so drift is the default suspicion - but verify it is real.

A stale local `main` made `stacks/prime/nucleus.yml` look like it was missing
`user: "568:568"` (the exact shape that had already crash-looped production once), when in
fact the fix was merged two PRs earlier and simply unpulled.

🔴 **`git fetch personal-mac:Projects/<repo> main` fetches that Mac's LOCAL main, which may
itself be behind.** Use the remote-tracking ref:

```bash
git fetch personal-mac:Projects/<repo> refs/remotes/origin/main
git merge --ff-only FETCH_HEAD
```

Then diff repo against live and confirm they are byte-identical.

🔴 **Verify a merge via the API, never on assurance.** A PR reported as merged was still
open, and deploying from that `main` would have crash-looped production a second time.

```bash
curl -s -H "Authorization: Bearer $PERSONAL_GITHUB_PAT" \
  https://api.github.com/repos/kushagrakasbi/<repo>/pulls/<n> | jq '.merged_at, .mergeable_state'
```

**Squash merges break rebases.** If a PR was squash-merged, your branch's base commits are
not ancestors of `main` and a follow-up branch replays them as conflicts. Rebase the new
commit onto `main` - if the trees match, it applies cleanly.

## 🛠️ Common Fleet Operations Playbook

### 1. Check Status of Containers Across Nodes
```bash
# On Agni:
ssh agni "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# On Prime:
ssh prime "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# On Legion:
ssh legion "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

### 2. Check GPU Utilization & Thermals on Legion
```bash
nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu --format=csv
```

### 3. Verify Immich ML Remote Offload
```bash
# Health check from Prime:
curl http://192.168.0.150:3003/ping
```

### 4. Git Repository Synchronization
```bash
cd ~/home-server && git pull --rebase
```

---

## 📂 Key Documentation References
- [**🔁 Agent handoff — current state, plan, progress**](docs/handoff/HANDOFF.md) ← start here
- [**Smart-home contract**](docs/SMART-HOME-DEVICE-INVENTORY.md)
- [**Master Strategic Roadmap & Audit**](docs/plans/2026-08-FLEET-MASTER-ROADMAP.md)
- [**Smart Home Architecture Plan**](docs/plans/2026-08-HOME-ASSISTANT-SMART-HOME-PLAN.md)
- [**Smart Home Power Resilience Guide**](docs/HOME-ASSISTANT-DEVICE-RESILIENCE-GUIDE.md)
- [**HA Disaster Recovery & Migration Runbook**](docs/HOME-ASSISTANT-DISASTER-RECOVERY-AND-MIGRATION-RUNBOOK.md)
- [**Media Pipeline & Automation Plan**](docs/plans/2026-08-MEDIA-PIPELINE-AND-AUTOMATION-PLAN.md)
- [**3-Node Redesign Blueprint**](docs/HOME-SERVER-REDESIGN.md)
- [**Redesign Execution Progress**](docs/REDESIGN-PROGRESS.md) *(historical, Aug 2026 — superseded by `docs/handoff/`)*
- [**Fleet Upgrades & Migrations**](docs/upgrades/README.md)
- [**Fleet Strategic Plans**](docs/plans/README.md)
- [**Agni Server Manual**](docs/AGNI-SERVER.md)
- [**Prime Server Manual**](docs/PRIME-SERVER.md)
- [**Legion Server Manual**](docs/LEGION-SERVER.md)
- [**AI Stack Guide**](docs/AI-STACK.md)
- [**Networking Deep Dive**](docs/networking.md)
- [**Operations Playbook & FAQ**](docs/OPERATIONS-PLAYBOOK.md)
