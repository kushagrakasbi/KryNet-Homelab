---
name: fleet-health
description: >-
  Automated health check for the KryNet 3-node fleet (Agni, Prime, Legion) —
  containers, network ports, GPU thermals, ZFS pool integrity, DNS and uptime
  monitoring. Use when the user asks "is the fleet healthy", "check the servers",
  "what's down", "why is <service> slow", after any deployment, or as the first step
  when something is misbehaving and the cause is unknown. ALWAYS use after a power
  outage, power cut, UPS event, or any time nodes were rebooted or restarted — "validate
  everything", "is everything back up" — which starts with scripts/fleet-validate.sh.
---

# 🏥 KryNet Fleet Health Check Skill

This skill provides standard diagnostic procedures for evaluating the overall health of the KryNet 3-node homelab infrastructure.

## 🔗 Source → this skill

| Feeds this skill | Sync when |
|---|---|
| `AGENTS.md` | fleet topology or node roles change |
| `config/gatus/`, `config/prometheus/` | a monitored endpoint or alert is added |
| `stacks/*/monitoring-*.yml` | the monitoring stack changes |
| `scripts/fleet-validate.sh` | a check is added, or a new failure class is found after an outage |

When any of those change, re-read this skill and update it in the same PR.
Reverse check: `grep -l "<changed-file>" .agents/skills/*/SKILL.md`


## ⚡ After a power outage or any restart — run this FIRST

```bash
scripts/fleet-validate.sh     # ~10 s, read-only · 0 healthy / 1 findings / 2 something unchecked
```

Works from the work laptop **and** the personal Mac, with the Mac asleep: SSH only, Prime's containers
read through Agni's Dozzle. It prints the *reason* for every dead container, not just "down".

🔴 **The damage from a power cycle is a container that FAILED TO START** (exit 128, `RestartCount=0`),
which Docker never retries. On 2026-09-27 that was seven containers from two causes — a kernel with
no NVIDIA module on Legion, and an SMB automount that raced Prime's boot on Agni. Signatures, fixes,
and how to read Prime without Portainer: **[`reference/post-outage.md`](reference/post-outage.md)**.

⚠️ Exit 2 is not a pass. `SKIP` lines were not checked.

## 🎯 Target Nodes
* **🔥 Agni (`192.168.0.200`):** Ingress (Caddy), DNS (AdGuard), Authentication, Prometheus Master
* **🌟 Prime (`192.168.0.100`):** ZFS Storage Pools, Media (*arr/Jellyfin), Immich Core
* **⚡ Legion (`192.168.0.150`):** GPU Compute (RTX 3060), Ollama, LiteLLM, Immich ML (:3003), Tdarr Node

---

## 🛠️ Step-by-Step Diagnostic Procedures

### 1. Check Container Health Across All Nodes
```bash
# Agni and Legion:
ssh agni   "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
ssh legion "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```
🔴 **`ssh prime docker ps` prints NOTHING** — `truenas_admin` is not in the `docker` group and `sudo`
there needs an interactive password. It exits cleanly with empty output, so the natural reading is
"Prime has no containers". It has 36. Use the Portainer Docker API proxy:

```bash
TOKEN=$(ssh personal-mac 'cat ~/.portainer/prime_token' | tr -d '[:space:]')
curl -sk -H "X-API-Key: $TOKEN" \
  "https://portainer.lan.kkasbi.in/api/endpoints/2/docker/containers/json" \
  | python3 -c 'import json,sys
for c in json.load(sys.stdin): print(c["Names"][0], c["State"], c["Status"])'
```

> **Note on Stack Management:** For deploying or editing stacks, always use **Portainer** (`https://portainer.lan.kkasbi.in` or Agni Master) and stack definitions in `stacks/<node>/`.

### 1a. Check Disk Hygiene (images and scratch)
```bash
ssh agni   "docker system df"
ssh legion "docker system df"
```

🔴 **`docker system df`'s RECLAIMABLE column is not what `docker image prune` will free.** It counts
every *unused* image including tagged ones — and those tagged images are the rollback targets. Only
untagged images are dangling. The gap is large enough to make a cleanup plan wrong: Legion reported
`58.61GB (69%)` reclaimable while holding just **4** dangling images. To size a prune honestly:

```bash
ssh <node> "docker images -f dangling=true --format '{{.ID}}\t{{.Size}}'"
```

And even that over-reads, because per-image `Size` double-counts shared layers. **Measure the result
with `df -h /`, not with the reported "Total reclaimed space"** — on Legion the reclaim was reported
as 5.59 GB while the filesystem dropped 16 GB.

🔴 **`docker system prune -a` is forbidden on this fleet.** It removes unused *tagged* images, which
is precisely the previous release of every service — the thing a rollback needs. `docker image prune`
only. Record the dangling IDs before pruning; a `:latest` service's previous version becomes dangling
the moment a newer pull steals the tag, so it is the rollback target with its name removed.


### 2. Check Legion GPU Health & Thermals
```bash
ssh legion@192.168.0.150 "nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu --format=csv"
```
* **Expected:** Temperature < 75°C, Memory used by Ollama / Immich ML / NVENC.

🔴 **Legion is a laptop and was thermally pinned for weeks unnoticed** — CPU package 95–100 °C, 9.5 M
throttle events, GPU held in **P0 at 33 W** by Frigate's three NVDEC decoders. Pausing Frigate's cameras
(2026-10-02) took it to 77 °C / P8 within minutes. Gatus now alerts on a 15-min average above 90 °C.
⚠️ **A hot CPU with an idle GPU can mean containers have LOST the GPU** and are inferring on the CPU —
see `reference/post-outage.md` §7. ⚠️ `ideapad_acpi`'s `fan_mode` cannot be changed on this model: a
write of `4` is accepted and silently reads back `0`.

### 3. Check AI Gateway & Local LLM Status
```bash
# Check LiteLLM Gateway:
curl -s http://192.168.0.150:4000/health/liveliness

# Check Immich ML CUDA endpoint:
curl -s http://192.168.0.150:3003/ping

# Check Ollama tags:
curl -s http://192.168.0.150:11434/api/tags | jq '.models[].name'
```

### 4. Check Prime ZFS Storage Pools
```bash
ssh prime "export PATH=\$PATH:/usr/sbin
           zpool status -x
           zpool list -o name,cap,free orion andromeda"
```
* **Expected:** `all pools are healthy`, and **`orion` capacity under 80%** — ZFS write performance
  degrades past that. `zpool`/`zfs` are not on `truenas_admin`'s `PATH`; without the `export` the
  error is `sudo: a password is required`, which reads as a permissions wall rather than a `PATH` one.

🔴 **Deleting files inside a snapshotted dataset frees nothing.** The blocks are still referenced by
every snapshot taken while the file existed, so the space moves from `usedbydataset` into
`usedbysnapshots` and the pool's `FREE` does not move at all. Measured on `orion/apps-config` when
132 GB of orphaned Tdarr scratch was removed:

```
before   used 136G   usedbydataset 132G    usedbysnapshots 336M   pool 75%, 450G free
after    used 136G   usedbydataset 55.1M   usedbysnapshots 132G   pool 75%, 450G free
```

So **check the accounting split before promising anyone a number**, and again before concluding a
cleanup failed:

```bash
ssh prime "export PATH=\$PATH:/usr/sbin
           zfs get -Ho property,value used,usedbydataset,usedbysnapshots <dataset>
           zfs list -t snapshot -o name,creation -s creation <dataset> | sed -n '2p;\$p'"
```

Space returns as the snapshots age out. Freeing it sooner means destroying **every** snapshot taken
since the files were created — not just the old ones — because the blocks existed continuously
across all of them. For `orion/apps-config` that is the whole local config-rollback history for every
Prime app, which is rarely the right trade.

⚠️ **`orion/ix-apps/docker` has no snapshots** (`usedbysnapshots 0B`), so image pruning there *does*
free immediately. The rule above applies to the config and media datasets, not the image store.

### 5. Check Caddy Reverse Proxy Validation on Agni
```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

### 6. Check Immich v3 Server & VectorChord Extension on Prime
```bash
# Immich API Ping
curl -s http://192.168.0.100:2283/api/server/ping

# Immich Version Check
curl -s http://192.168.0.100:2283/api/server/version
```
* **Expected:** `{"res":"pong"}` and `{"major":3,"minor":1,"patch":0}`.

### 7. Check Tailscale Mesh VPN Across Fleet
```bash
# Local Mac / Agent check:
tailscale status

# Remote node check:
ssh agni "docker exec tailscale-agni tailscale status"
ssh prime "docker -H tcp://127.0.0.1:2375 logs tailscale-tailscale-1 --tail 10"
ssh legion "docker exec tailscale-legion tailscale status"
```
* **Expected:** `agni-server` (100.89.216.106), `prime-server` (100.102.169.42), `legion-server` (100.117.26.106) all active.

### 8. Check DNS Resolution (AdGuard Primary & Secondary)

⚠️ **Not actually split-horizon.** AdGuard's rewrites are configured but **inert** — resolution comes
from public Cloudflare DNS, where `*.lan.kkasbi.in` and `*.kkasbi.in` point at `192.168.0.200` and
`*.krynet.cc` points at Agni's Tailscale IP. The expectation below still holds; the mechanism is not
what the name implies. See `docs/networking.md`.
```bash
# Primary DNS (Agni)
dig @192.168.0.200 photos.lan.kkasbi.in +short

# Secondary DNS (Prime)
dig @192.168.0.100 photos.lan.kkasbi.in +short
```
* **Expected:** Both return `192.168.0.200` (Agni Caddy Ingress).

### 9. Check Portainer API & Stack State
```bash
# Check all stacks across Agni, Prime, and Legion via helper
./scripts/portainer-helper.sh stacks all
```
* **Expected:** Returns running status for stacks across all 3 nodes.

### 10. Check Legion NVIDIA GPU Metrics Exporter
```bash
curl -s http://192.168.0.150:9835/metrics | grep -E "(nvidia_smi_temperature_gpu|nvidia_smi_utilization_gpu)"
```
* **Expected:** Returns valid GPU temperature and compute utilization metrics.

### 11. Check Gatus Status Page & Probes
```bash
# Query Gatus status endpoint
curl -s http://192.168.0.200:3001/api/v1/endpoints/statuses | jq '.[] | {name: .name, group: .group, healthy: .results[-1].success}'
```
* **Expected:** All **41** fleet service probes return `"healthy": true`.

#### Is alerting actually working? Prove it, don't assume it

✅ **Verified 2026-09-12: both Gotify and Discord fire on failure and on recovery.** Evidence: a real
incident produced `handleAlertsToTrigger` for both providers, hourly reminders, then
`handleAlertsToResolve ... has been RESOLVED` for both; and a deliberate canary produced both again.

🔴 **A green status page says nothing about whether an alert would reach you.** To test, append a
canary endpoint pointing at a port nothing listens on, with `failure-threshold: 1`:

```yaml
  - name: "ZZZ Alerting Canary (temporary)"
    group: "Core"
    url: "tcp://127.0.0.1:59999"
    interval: 30s
    conditions: ["[CONNECTED] == true"]
    alerts:
      - {type: gotify,  failure-threshold: 1, success-threshold: 1}
      - {type: discord, failure-threshold: 1, success-threshold: 1}
```

Then `docker logs gatus | grep handleAlerts` and confirm a `Sending <provider> alert` line for
**each** provider, with no `failed to send` after it. Remove the canary when done.

⚠️ **Grep for `handleAlerts`, and do not `tail` the result too tightly.** Providers log on the same
second, so a short `tail` can show one and hide the other — that briefly looked like Gotify had
broken when it had not.

⚠️ **Deleting the canary does not produce a RESOLVED alert** — Gatus logs `Canceling current
execution` and stops monitoring it. To exercise `send-on-resolved`, point the canary at something you
can break and then fix.

✅ **Gatus HOT-RELOADS its config file** — no restart needed. Copy the file in and watch for a fresh
`config.ValidateAlertingConfig` line.

🔴 **The alerting credentials are env refs, not literals.** `config/gatus/config.yaml` uses
`${GOTIFY_TOKEN}` / `${DISCORD_WEBHOOK_URL}`; values live only in the Portainer env for
`monitoring-stack` (Agni, stack 12). Gatus expands them from its container environment — confirmed by
`configuredProviders=[discord gotify]` at startup plus a successful send.

### 12. Check Automated 12-Hour Backups in Healthchecks
```bash
# Verify Healthchecks container status on Agni
docker logs --tail 20 healthchecks | grep "GET /ping/"
```
* **Expected:** recent pings from all THREE nodes — `RClone Agni`, `RClone Krynet` (Prime) and
  `RClone Legion`.

🔴 **This previously claimed Legion reported and it did NOT.** Legion's backup ran correctly for weeks
while pinging nothing; the dead-man switch was added 2026-09-20. Do not treat "the backup container is
running" as evidence the backup is monitored — those are different claims, and `backup-prime` still has
no Docker healthcheck precisely because the *outcome* is what's watched.

**Read Healthchecks' own DB rather than grepping nginx logs** — it gives status, period, grace and
ping counts in one shot, and the log only shows pings that arrived:

```bash
ssh agni 'python3 - <<PY
import sqlite3, shutil, os
shutil.copy("/home/agni/apps/docker/healthchecks/config/hc.sqlite","/tmp/hc.db")
c=sqlite3.connect("file:/tmp/hc.db?mode=ro", uri=True)
for n,t,g,st,np,last in c.execute(
        "SELECT name,timeout,grace,status,n_pings,last_ping FROM api_check ORDER BY name"):
    print("{:<16} period={:g}h grace={:g}m status={:<8} pings={:<5} last={}".format(
        n, t/3600/1e6, g/60/1e6, st, np, str(last)[:19]))
c.close(); os.remove("/tmp/hc.db")
PY'
```

⚠️ **Durations are stored in MICROSECONDS** (Django `DurationField`), so dividing by 3600 alone yields
absurd values like `2.4e+07h`. All three are **period 24 h, grace 1 h**.
⚠️ **`last_start` is CLEARED on success**, so a check showing `last_start` set is mid-run, not broken.
⚠️ `--ignore-errors` in the rclone commands means a success ping proves the **run completed**, not that
every file copied.

### 13. Check Inter-Node Throughput & EasyMesh Backhaul
```bash
# Test corridor-to-office backhaul throughput (Agni -> Prime via OpenSpeedtest :8992)
ssh agni 'curl -s --max-time 4 -w "%{speed_download} bytes/sec in %{time_total}s\n" -o /dev/null "http://192.168.0.100:8992/downloading?size=10000000"'

# Test intra-office / backhaul from Legion
ssh legion 'curl -s --max-time 4 -w "%{speed_download} bytes/sec in %{time_total}s\n" -o /dev/null "http://192.168.0.100:8992/downloading?size=10000000"'
```
* **Expected:** Both return `> 100,000,000 bytes/sec` (100–115 MB/s, ~900–940 Mbps wire-speed Gigabit).
* 🔴 **Failure Mode:** If speed drops to `~1,100,000 bytes/sec` (~8.8–9.2 Mbps), the physical backhaul between the corridor Archer BE400 and home office Archer AX10 has auto-negotiated down to **10BASE-T (10 Mbps)** or silently dropped to weak wireless mesh.
* **Hardware Rule:** The corridor backhaul cable MUST be plugged into the **Blue WAN port** on the Archer AX10 (not the Orange LAN ports) to force the dedicated Gigabit PHY handshake. See [`docs/2026-11-NETWORK-SPEED-AND-TOPOLOGY-AUDIT.md`](docs/2026-11-NETWORK-SPEED-AND-TOPOLOGY-AUDIT.md).

### 14. Check Gluetun VPN Tunnel & Downloader Pipeline
```bash
# Verify qBittorrent WebUI responds through Gluetun
curl -sk -o /dev/null -w "%{http_code}\n" https://qbit.lan.kkasbi.in/

# Verify Seerr API responds through Gluetun
curl -sk https://request.lan.kkasbi.in/api/v1/status | jq .version

# Verify VPN Watchdog daemon logs on Prime
ssh prime "docker -H tcp://127.0.0.1:2375 logs vpn-watchdog --tail 15"
```
* **Expected:** qBittorrent returns HTTP 200, Seerr returns valid JSON version (e.g. `3.5.1`), and `vpn-watchdog` logs show `VPN HEALTHY` and `All dependents healthy`.

### 15. Check Audiobook Stack (Audiobookshelf & Chaptarr)
```bash
# Verify Audiobookshelf API
curl -sk https://abs.lan.kkasbi.in/status | jq .status

# Verify Chaptarr WebUI / API
curl -sk -o /dev/null -w "%{http_code}\n" https://chaptarr.lan.kkasbi.in/ping
```
* **Expected:** Audiobookshelf returns `"ok": true`, Chaptarr returns HTTP 200.


---

## ✅ Closing the check

A health sweep is only useful if its result is stated plainly. Finish with:

0. **Record it.** If the result differs from `docs/handoff/HANDOFF.md` §2–3, update that file
   (`session-handoff` skill) — a health sweep nobody writes down is repeated by the next agent.
1. **One line per node** — healthy, or what specifically is not.
2. **Name anything that could not be checked** (node unreachable, credential
   missing) rather than silently omitting it. An unchecked item read as "fine" is
   the failure mode this skill exists to prevent.
3. **If nothing is wrong, say so explicitly.** Do not invent findings to look
   thorough.

```bash
# fastest whole-fleet answer before any of the above
curl -s http://192.168.0.200:3001/api/v1/endpoints/statuses \
  | jq -r '.[] | select(.results[-1].success == false) | .name'
```

Empty output = every probe passing. Start here; drill in only where it points.
