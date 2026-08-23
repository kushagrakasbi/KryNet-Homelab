---
name: caddy-proxy
description: Procedures for safely modifying, validating, and zero-downtime reloading the Caddy reverse proxy on Agni (192.168.0.200).
---

# 🛡️ Caddy Reverse Proxy Management Skill

This skill guides agents in adding routes, updating upstream destinations, and validating Caddy configuration on **🔥 Agni (`192.168.0.200`)**.

## 🔒 Safety Rules
1. **Never reload without validation:** An invalid Caddyfile kills SSL termination and access for the entire fleet.
2. **Always validate inside the Docker container:**
   ```bash
   docker exec caddy caddy validate --config /etc/caddy/Caddyfile
   ```
3. **Only reload if validation returned exit code 0:**
   ```bash
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

---

## 📝 Route Templates

### 1. Simple HTTP Upstream
```caddy
    # Service Name
    @myservice host service.krynet.cc service.lan.kkasbi.in
    handle @myservice {
        reverse_proxy http://192.168.0.150:8080
    }
```

### 2. HTTPS Upstream with Self-Signed Certs (e.g. Portainer)
```caddy
    @portainer host portainer.krynet.cc
    handle @portainer {
        reverse_proxy https://192.168.0.100:9443 {
            transport http {
                tls_insecure_skip_verify
            }
        }
    }
```
