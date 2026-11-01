---
name: caddy-proxy
description: >-
  Safely adds, modifies, validates and zero-downtime reloads Caddy reverse-proxy
  routes on Agni. Use when the user says "add a route", "expose <service>", "change
  the upstream", "the URL 502s", "reload Caddy", or whenever config/caddy/Caddyfile
  is edited — validation before reload is mandatory and this skill enforces it.
---

# 🛡️ Caddy Reverse Proxy Management Skill

This skill guides agents in adding routes, updating upstream destinations, and validating Caddy configuration on **🔥 Agni (`192.168.0.200`)**.

## 🔗 Source → this skill

| Feeds this skill | Sync when |
|---|---|
| `config/caddy/Caddyfile` | a route is added, renamed, or its upstream moves |
| `stacks/agni/caddy-stack.yml` | the bind-mount path or image changes |

When any of those change, re-read this skill and update it in the same PR.
Reverse check: `grep -l "<changed-file>" .agents/skills/*/SKILL.md`


## 🔒 Safety Rules
1. **Never reload without validation:** An invalid Caddyfile kills SSL termination and access for the entire fleet — including the dashboards you would use to notice.
2. **Always validate inside the Docker container:**
   ```bash
   docker exec caddy caddy validate --config /etc/caddy/Caddyfile
   ```
3. **Only reload if validation returned exit code 0:**
   ```bash
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```
4. **Every route gets BOTH hostnames** — `<svc>.krynet.cc` *and* `<svc>.lan.kkasbi.in`. A route with only one is unreachable from any network where that domain is filtered or unresolvable.

---

## 🚚 Getting the edited Caddyfile onto Agni

`config/caddy/Caddyfile` in this repo is the source of truth. The container reads it
through a **bind mount** declared in `stacks/agni/caddy-stack.yml`:

```
/home/agni/apps/docker/caddy/Caddyfile  →  /etc/caddy/Caddyfile
```

So editing the repo alone changes nothing. Copy it to the host path, then validate
and reload:

```bash
# 1. from your workstation, in this repo
scp config/caddy/Caddyfile agni:/home/agni/apps/docker/caddy/Caddyfile

# 2. validate BEFORE reloading — exit code 0 required
ssh agni "docker exec caddy caddy validate --config /etc/caddy/Caddyfile"

# 3. reload only if step 2 passed (zero downtime, no restart)
ssh agni "docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
```

Because it is a bind mount, no stack redeploy is needed — and a `docker compose`
restart is never the right tool here.

**Drift check** — the deployed copy should be byte-identical to the repo:

```bash
ssh agni 'sha256sum /home/agni/apps/docker/caddy/Caddyfile' | cut -d' ' -f1
shasum -a 256 config/caddy/Caddyfile | cut -d' ' -f1
```

If those differ, someone edited the host copy directly. Reconcile into the repo
before doing anything else — the host copy is not the record.

---

## 📝 Route Templates

### 1. Simple HTTP Upstream
```caddy
    # Service Name
    @myservice host service.lan.kkasbi.in service.lan.kkasbi.in
    handle @myservice {
        reverse_proxy http://192.168.0.150:8080
    }
```

### 2. HTTPS Upstream with Self-Signed Certs (e.g. Portainer)
```caddy
    @portainer host portainer.lan.kkasbi.in portainer.lan.kkasbi.in
    handle @portainer {
        reverse_proxy https://192.168.0.100:9443 {
            transport http {
                tls_insecure_skip_verify
            }
        }
    }
```

---

## ✅ Verify the route actually serves

Validation and reload succeeding does **not** mean the route works. Check it:

```bash
# expect 200, 302, or the service's own redirect — NOT 502/503
curl -sI https://<svc>.lan.kkasbi.in | head -1
curl -sI https://<svc>.lan.kkasbi.in | head -1

# no new errors after the reload
ssh agni 'docker logs --tail 20 caddy' | grep -i error || echo "no errors"

# the container's own healthcheck runs `caddy validate` every 30s
ssh agni 'docker inspect --format "{{.State.Health.Status}}" caddy'
```

A `502` means Caddy is fine and the **upstream** is not — check the target
host:port directly before touching the Caddyfile again.

### Audit: any route missing its second hostname

```bash
grep -E '^\s*@[a-z0-9_]+ host ' config/caddy/Caddyfile \
  | grep 'krynet\.cc' | grep -v 'lan\.kkasbi\.in'
```

No output means every route has both. Run it after adding routes.
