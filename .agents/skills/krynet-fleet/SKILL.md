---
name: krynet-fleet
description: >-
  Connects to and inspects the personal 3-node home fleet from either machine — the
  work laptop or the personal Mac — SSH aliases, service URLs, health checks, container
  and log inspection, and the network constraints that differ between the two. Use when the user says "check the fleet",
  "ssh to prime/agni/legion", "is <service> up", "what's the URL for <service>",
  "check the containers", or when any task touches the home servers from this
  machine.
---

# KryNet fleet — reaching it from either machine

Reach and inspect the fleet. Most of this file is written from the **work laptop**, where two extra
constraints apply; the personal-Mac differences are in *Which machine can do what*.

**Current state of the work, open incidents and what to do next:** `docs/handoff/HANDOFF.md` — read it
before acting. **Fastest health answer:** `scripts/fleet-validate.sh` (SSH only, either machine).

## Source → this skill

| Feeds this skill | Sync when |
|---|---|
| `home-server/AGENTS.md` | fleet topology, deploy mechanism, or safety rules change |
| `home-server/config/caddy/Caddyfile` | a route is added or renamed → regenerate `reference/services.md` |
| `~/.ssh/config.d/personal-homelab.conf` | a node IP or user changes |

---

## 🔴 Two constraints, this laptop only

**1. `krynet.cc` is blocked here** by corporate web filtering. Use the
`*.lan.kkasbi.in` equivalent — the proxy serves both domains for every route.
Full map: [`reference/services.md`](reference/services.md).

**2. SSH by IP only.** `*.lan.kkasbi.in` is a wildcard A record pointing at Agni's
proxy (HTTP routing by hostname). `prime.lan.kkasbi.in` resolves to `192.168.0.200`
— **Agni, not Prime**. Use the configured aliases, which already use IPs.

**No Tailscale here** → the fleet is reachable only on the home LAN. Check first if
anything is unreachable:

```bash
ipconfig getifaddr en0        # expect 192.168.0.x
```

If you are not on that subnet, stop. Nothing below will work, and that is expected
rather than broken.

---

## 🔴 Which machine can do what

The single most common time-waster is attempting something from the wrong machine. Nothing below is a
permission problem to work around — it is the intended split.

| Capability | This (work) laptop | Personal Mac |
|---|---|---|
| `ssh agni` / `prime` / `legion` | ✅ **on the home LAN only** | ✅ |
| `*.lan.kkasbi.in` | ✅ | ✅ |
| `*.krynet.cc` | ❌ **corp web filtering** | ✅ |
| Tailscale (off-LAN reach) | ❌ not installed | ✅ |
| Portainer API token | ❌ not stored here — read over SSH per command | ✅ `~/.portainer/{prime,agni}_token` (mode 600) |
| `git push` to GitHub | ❌ no credentials, by design | ✅ SSH remote, works non-interactively |

**Portainer, from this laptop.** Read the token into the session; never write it to disk here.

```bash
TOKEN=$(ssh personal-mac 'cat ~/.portainer/prime_token' | tr -d '[:space:]')
API=https://portainer.lan.kkasbi.in          # Prime's Portainer; agni_token + portainer2 for Agni/Legion
curl -sk -H "X-API-Key: $TOKEN" "$API/api/stacks" | python3 -m json.tool | head
```

🔴 **Portainer proxies the whole Docker Engine API** at `/api/endpoints/<id>/docker/...`, which is how
to build and inspect images **without `sudo` on the node**. `sudo` on Prime needs a password and
cannot be scripted — so the Portainer API is not a convenience, it is the only automatable path.

🔴 **The personal Mac sleeps** and stops answering SSH while still answering ping. Both the Portainer
token and the GitHub push live there, so a sleeping Mac blocks every deploy. **Ask for a wake; never
accept a pasted token** — a token in a transcript is permanent.

**On the personal Mac** the tokens are local (`tr -d '[:space:]' < ~/.portainer/prime_token`), you push
to GitHub directly, and `*.krynet.cc` resolves — the rest of this file still applies.

**Moving code out — work laptop only** (no GitHub credentials there):

```bash
SPEC="refs/heads/${B}"                       # braces required: zsh eats `:r` as a history modifier
git push personal-mac:Projects/home-server "${SPEC}:${SPEC}"
ssh personal-mac "cd ~/Projects/home-server && git push -u origin ${B}"
```

Then open the PR with the GitHub API (`gh` is not installed on the Mac). Details:
the `personal-transfer` skill.

---

## Nodes

| Alias | IP | User | Role |
|---|---|---|---|
| `agni` | `192.168.0.200` | `agni` | Caddy ingress, AdGuard DNS, Prometheus/Grafana/Gatus, Home Assistant, Vaultwarden, Portainer **server** |
| `prime` | `192.168.0.100` | `truenas_admin` | TrueNAS SCALE, ZFS (`orion`, `andromeda`), Immich, Jellyfin, *arr stack, Paperless, **nucleus prod** |
| `legion` | `192.168.0.150` | `legion` | RTX 3060, Ollama, LiteLLM `:4000`, Immich ML, Tdarr node, Portainer **agent** |

---

## Steps

### Check the fleet is reachable

```bash
for h in agni prime legion; do
  printf '%-8s ' "$h"
  ssh -o ConnectTimeout=5 -o BatchMode=yes "$h" 'echo ok' 2>&1 | tail -1
done
```

`BatchMode=yes` makes a missing/locked key fail fast instead of hanging on a
password prompt. `Permission denied` here means the key is not yet installed on that
node — not that the node is down.

### Container status

```bash
ssh <node> "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

### Logs

```bash
ssh <node> "docker logs --tail 100 -f <container>"
```

Or the web log viewer at `logs.lan.kkasbi.in`, which covers all nodes.

### GPU (Legion)

```bash
ssh legion "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv"
```

A model that silently fell back to CPU shows as low GPU utilisation with the service
still "up" — that presents as "everything got slow", not as an error.

### Storage (Prime)

```bash
ssh prime "zpool list; zpool status -x"
```

`zpool status -x` prints `all pools are healthy` or only the problem pools.

### LLM gateway

```bash
curl -s http://192.168.0.150:4000/health/liveliness
curl -s http://192.168.0.150:4000/v1/models | python3 -m json.tool | head -30
```

Check this **before** debugging a harness that seems to hang. A gateway that is up
but has lost an upstream key fails identically to a broken harness config; the
`/v1/models` list disambiguates in one call.

### Uptime overview

`status.lan.kkasbi.in` (Gatus) is the fastest whole-fleet answer — check it before
SSH-ing anywhere.

---

## 🔴 Changing anything

**Deploy through Portainer Stacks, not `docker compose` on a host.** Stack
definitions in `home-server/stacks/<node>/` are the source of truth. The Docker CLI
on a host is for read-only diagnostics only. `scripts/portainer-helper.sh` drives it
programmatically.

**Caddy: validate before reload.**

```bash
ssh agni "docker exec caddy caddy validate --config /etc/caddy/Caddyfile"
ssh agni "docker exec caddy caddy reload  --config /etc/caddy/Caddyfile"
```

A bad Caddyfile takes the entire fleet offline at once, dashboards included.

**Before anything destructive** — volumes, migrations, bulk updates — use the
production warning block in `../../CLAUDE.md` and wait for an explicit yes. Real
data, no staging, often no second copy.

---

## Traps

| Trap | What actually happens |
|---|---|
| `ssh prime.lan.kkasbi.in` | Logs into **Agni**. The domain is a wildcard to the proxy. |
| Opening a `krynet.cc` URL from this laptop | Blocked by web filtering. Use `.lan.kkasbi.in`. |
| Assuming reachability off-LAN | No Tailscale here. Check the subnet first. |
| `docker compose up` on a node | Bypasses Portainer; next redeploy orphans or replaces it |
| Reloading Caddy unvalidated | Whole-fleet outage |
| `docker compose down -v` | Destroys named volumes. Permanent. |
| Wrong `PUID`/`PGID` on Prime | `568`, not `1000` — permission errors that look like app bugs |
| Password prompt on `ssh <node>` | The key is not installed on that node yet |
| Writing a Portainer token to a file on this laptop | Corp-managed disk. Read it per command; never persist |
| `git push origin ...` from this laptop | No credentials by design. Push via the Mac |
| `"refs/heads/$B:refs/heads/$B"` in zsh | `:r` is eaten as a history modifier — the refspec arrives mangled. Use `${B}` |
| `ssh prime "cat remote" > local-backup` | **Truncates `local-backup` BEFORE `cat` runs.** Re-running after the remote file is gone destroys the good copy, exit 0 |
| Trusting `PRAGMA integrity_check` on a backup | A **0-byte** file returns `ok`. Verify by ROW COUNT |

---

## Verify

```bash
ipconfig getifaddr en0                                   # on the home LAN?
ssh -o BatchMode=yes prime 'hostname && uptime'          # key works, node up
curl -sI https://status.lan.kkasbi.in | head -1          # ingress + DNS work
```

Those three cover network, auth and ingress — the three things that break.
