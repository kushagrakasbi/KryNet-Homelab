---
name: portainer-ops
description: >-
  Deploys, redeploys, starts, stops and inspects Portainer stacks across Agni, Prime
  and Legion without the web UI. Use when the user says "deploy <stack>", "redeploy
  <service>", "restart <service>", "what stacks are running", or whenever a compose
  file under stacks/ changes — this is the correct deployment path, not `docker
  compose` on a host.
---

# 🐳 KryNet Portainer Operations Skill

This skill provides procedures and CLI conventions for managing Docker Stacks across the KryNet 3-node homelab infrastructure programmatically via Portainer REST API.

## 🔗 Source → this skill

| Feeds this skill | Sync when |
|---|---|
| `scripts/portainer-helper.sh` | its subcommands or endpoint IDs change |
| `stacks/*/` | a stack is added or renamed |

When any of those change, re-read this skill and update it in the same PR.
Reverse check: `grep -l "<changed-file>" .agents/skills/*/SKILL.md`


---

## 🗺️ Portainer Cluster Architecture

| Portainer Instance | Ingress URL | Node / Environment | Endpoint ID | Target Scope |
| :--- | :--- | :--- | :--- | :--- |
| **🔥 Agni Master** | `https://portainer2.lan.kkasbi.in` | `agni-server` (Local) | `4` | Ingress (Caddy), DNS, Vaultwarden, Monitoring |
| **🔥 Agni Master** | `https://portainer2.lan.kkasbi.in` | `Legion` (Agent) | `6` | AI Compute, Ollama CUDA, LiteLLM, Immich ML |
| **🌟 Prime Portainer** | `https://portainer.lan.kkasbi.in` | `krynet-server` (Local) | `2` | TrueNAS Applications, Immich, Media (*Arr) |

---

## 🛠️ CLI Automation Engine: `scripts/portainer-helper.sh`

The [`scripts/portainer-helper.sh`](../../../scripts/portainer-helper.sh) script automatically resolves tokens from `~/.portainer/agni_token` and `~/.portainer/prime_token`.

### 1. Inspect Environments & Stacks
```bash
# List all environments on Agni and Prime:
./scripts/portainer-helper.sh environments

# List all running stacks across the fleet:
./scripts/portainer-helper.sh stacks all

# List stacks on a specific node:
./scripts/portainer-helper.sh stacks agni
./scripts/portainer-helper.sh stacks prime
./scripts/portainer-helper.sh stacks legion
```

### 2. Deploy or Update Stacks from Repository YAML
```bash
# Deploy / Update on Agni:
./scripts/portainer-helper.sh deploy agni caddy-stack stacks/agni/caddy-stack.yml

# Deploy / Update on Prime:
./scripts/portainer-helper.sh deploy prime immich stacks/prime/immich.yml

# Deploy / Update on Legion:
./scripts/portainer-helper.sh deploy legion ai-stack stacks/legion/ai-stack.yml
```

### 3. Trigger Instant Image Re-pull & Redeploy
```bash
./scripts/portainer-helper.sh redeploy prime immich
./scripts/portainer-helper.sh redeploy legion ai-stack
```

### 4. Stack Lifecycle Control
```bash
# Stop a stack:
./scripts/portainer-helper.sh stop prime syncthing-stack

# Start a stack:
./scripts/portainer-helper.sh start prime syncthing-stack

# Retrieve live compose YAML from Portainer:
./scripts/portainer-helper.sh get-stack prime immich
```

### 5. Inspect Running Containers
```bash
./scripts/portainer-helper.sh containers agni
./scripts/portainer-helper.sh containers prime
./scripts/portainer-helper.sh containers legion
```

---

## 🐳 The Docker API proxy — build, exec, file transfer

`sudo` on Prime needs a password and `truenas_admin` is not in the `docker` group, so the
Docker CLI there cannot write. Portainer proxies the full Docker API at
`/api/endpoints/<id>/docker/...`, which needs no sudo. Endpoint **2** is Prime.

```bash
TOKEN=$(ssh personal-mac 'cat ~/.portainer/prime_token' | tr -d '[:space:]')
API=https://portainer.lan.kkasbi.in     # krynet.cc is filtered from the work laptop
```

### Build an image from a repo

```bash
cd <repo> && git archive --format=tar HEAD > /tmp/ctx.tar   # ~5 MB, not 337 MB
curl -sk --max-time 1200 -X POST -H "X-API-Key: $TOKEN" \
  -H "Content-Type: application/x-tar" --data-binary @/tmp/ctx.tar \
  "$API/api/endpoints/2/docker/build?t=<image>:<tag>&dockerfile=Dockerfile&forcerm=1"
```

Use `git archive`, not the working directory: a `Dockerfile` with `COPY . .` and no
`.dockerignore` otherwise ships `node_modules`. The response streams and is buffered until
the build finishes, so run it backgrounded and poll `/images/json` for the tag.

### Run a command in a container

POST `/containers/<name>/exec` with `{"Cmd":[...],"AttachStdout":true,"AttachStderr":true,"Tty":true}`,
then POST `/exec/<id>/start` with `{"Detach":false,"Tty":true}`. Read the exit code from
`/exec/<id>/json`. Add `"User":"0"` to run as root.

🔴 **This is the only automatable way to run a command on Prime**, because `sudo` there needs an
interactive password. Used in anger for nucleus's operator CLI (`audit-budget-classes`,
`normalize-budget-classes`, `merge-categories`, `import-wallet`).

A reusable shell function, and the two things that bite:

```bash
run_in_container() {          # $1 = a JSON array, e.g. '["nucleus","audit-budget-classes"]'
  local EXEC_ID
  EXEC_ID=$(curl -sk -X POST -H "X-API-Key: $TOKEN" -H 'Content-Type: application/json' \
    -d "{\"AttachStdout\":true,\"AttachStderr\":true,\"Cmd\":$1}" \
    "$API/api/endpoints/2/docker/containers/nucleus/exec" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["Id"])')
  curl -sk -X POST -H "X-API-Key: $TOKEN" -H 'Content-Type: application/json' \
    -d '{"Detach":false,"Tty":false}' "$API/api/endpoints/2/docker/exec/$EXEC_ID/start" \
    | LC_ALL=C tr -cd '[:print:]\n' | grep -v '^.\{0,3\}{"time"'
}
```

⚠️ **1. The output stream is multiplexed**, so control bytes appear between lines and mangle the first
character of some of them. Strip with `LC_ALL=C tr -cd '[:print:]\n'` — plain `tr -d` fails with
`Illegal byte sequence` on macOS. Set `"Tty":false` and the framing is at least consistent.

⚠️ **2. An app that logs on startup will interleave its own JSON log lines** with your command's
output, because the operator CLI boots the same binary (migrations included). Filter them:
`grep -v '{"time"'`. Do not mistake `migrations complete applied=0` for command output.

⚠️ **Arguments containing spaces must be separate array elements**, not a quoted string:
`["nucleus","merge-categories","--into","Gifts & Donations"]`. There is no shell, so no word
splitting and no quote removal.

### Copy a file in — two traps that both look like Docker bugs

```bash
# 1. macOS stamps com.apple.quarantine on downloads and tar carries it, so Docker fails with
#    lsetxattr com.apple.quarantine ... operation not supported
xattr -c myfile.csv
COPYFILE_DISABLE=1 tar --disable-copyfile -cf up.tar -C dir myfile.csv
curl -sk -X PUT -H "X-API-Key: $TOKEN" -H "Content-Type: application/x-tar" \
  --data-binary @up.tar "$API/api/endpoints/2/docker/containers/<name>/archive?path=/tmp"
```

**2.** Uploaded files land owned by the **tar's uid**, not the container's app user, so the
app cannot delete them. Remove them with an exec as root. 🔴 Never leave credentials or
financial data sitting in a container layer.

### Deploy a stack

```bash
curl -sk -X PUT -H "X-API-Key: $TOKEN" -H "Content-Type: application/json" \
  --data @payload.json "$API/api/stacks/<id>?endpointId=2"
# payload: {"stackFileContent":"<yaml>","env":[{"name":"TAG","value":"..."}],
#           "prune":false,"pullImage":false}
```

🔴 **Assert the stack content's guards before pushing it.** Fetch the live content from
`/api/stacks/<id>/file`, check the invariants that keep the service alive (for nucleus:
`user: "568:568"` and `NUCLEUS_TRUST_PROXY=false`), and **refuse** rather than push if they
are missing. A stack file without the first crash-looped production once already.

Prefer changing only the tag env var over rewriting the content — fewer ways to be wrong.

### The token lives on the personal Mac, which sleeps

`~/.portainer/{prime,agni}_token`, mode 600, on the personal Mac only. It **stops answering
SSH while still answering ping**, so a sleeping Mac blocks every deploy. Ask for a wake rather
than accepting a pasted token — a token in a transcript is permanent.

## 🔒 Operational Guidelines for AI Agents

1. **Source of Truth:** Compose definitions under `stacks/<node>/<stack-name>.yml` are the source of truth.
2. **Never Run Direct `docker compose up` on Nodes:** Always deploy via `./scripts/portainer-helper.sh deploy` to preserve UI visibility, environment variable mapping, and Portainer stack tracking.
3. **Bootstrap Exception:** Only `stacks/legion/portainer-agent.yml` is started via host Compose to initialize communication with the Agni master server.

---

## ✅ Verify after a deploy

`deploy` returning success means Portainer accepted the stack — not that the service
works. Always confirm:

```bash
# 1. container is running AND healthy (not merely "Up")
./scripts/portainer-helper.sh containers <node> | grep <service>

# 2. no startup errors
ssh <node> "docker logs --tail 30 <container>" | grep -iE 'error|fatal|panic' || echo "clean"

# 3. reachable through the proxy, if it has a route
curl -sI https://<svc>.lan.kkasbi.in | head -1
```

A container that starts and then fails its healthcheck reports `Up` for a while
first — `Up` alone is not a pass. If the service has a Gatus probe, check that too;
it is the same signal the fleet uses.

**If a deploy needs rolling back:** redeploy the previous image tag from the stack
file. That only works if tags are pinned — which is why they are.

---

## 📌 nucleus deploy state (update on every deploy)

The most frequently deployed stack on the fleet. Stack **72**, endpoint **2** (Prime).

| | |
|---|---|
| Running | `nucleus:2026.08.30-d1dff45` → `sha256:4098a594d364` (schema **34**) |
| Rollback | `nucleus:2026.08.30-fefabfe` → `sha256:356bc4439ec0`, present on the host |
| Reachable | `finance.lan.kkasbi.in` → `192.168.0.100:8081` |
| Data | `/mnt/orion/apps-config/nucleus/data`, owned **568:568** |
| History | **11 deploys on 2026-08-30, zero baseline drift on all eleven** |

🔴 **The compose content must contain `user: "568:568"`.** Deploying a stack file without it
crash-loops production — it has happened once. Take the content from the repo's current `main` (or
read the live stack and diff it), and assert the line is present before the PUT.

**Before the PUT, prove you are shipping what you tested:**

```bash
git rev-parse main^{tree} <tested-commit>^{tree}    # identical hashes = the gate applies
```

Full runbook, including the migration-rehearsal and rollback-rehearsal steps:
`ai-docs-personal/nucleus-hardening-2026-08/08-OPERATIONS.md`.
