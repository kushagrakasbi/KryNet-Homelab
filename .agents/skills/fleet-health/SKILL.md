---
name: fleet-health
description: Automated health check and diagnostic tool for KryNet 3-node cluster (Agni, Prime, Legion). Use to verify containers, network ports, GPU thermals, and ZFS pool integrity.
---

# 🏥 KryNet Fleet Health Check Skill

This skill provides standard diagnostic procedures for evaluating the overall health of the KryNet 3-node homelab infrastructure.

## 🎯 Target Nodes
* **🔥 Agni (`192.168.0.200`):** Ingress (Caddy), DNS (AdGuard), Authentication, Prometheus Master
* **🌟 Prime (`192.168.0.100`):** ZFS Storage Pools, Media (*arr/Jellyfin), Immich Core
* **⚡ Legion (`192.168.0.150`):** GPU Compute (RTX 3060), Ollama, LiteLLM, Immich ML (:3003), Tdarr Node

---

## 🛠️ Step-by-Step Diagnostic Procedures

### 1. Check Container Health Across All Nodes
```bash
# Agni:
ssh agni "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Prime:
ssh prime "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Legion:
ssh legion "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```
> **Note on Stack Management:** For deploying or editing stacks, always use **Portainer** (`https://portainer.krynet.cc` or Agni Master) and stack definitions in `stacks/<node>/`.


### 2. Check Legion GPU Health & Thermals
```bash
ssh legion@192.168.0.150 "nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu --format=csv"
```
* **Expected:** Temperature < 75°C, Memory used by Ollama / Immich ML / NVENC.

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
ssh prime "zpool status -x"
```
* **Expected:** `all pools are healthy`.

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

### 8. Check Split-Horizon DNS Resolution (AdGuard Primary & Secondary)
```bash
# Primary DNS (Agni)
dig @192.168.0.200 photos.krynet.cc +short

# Secondary DNS (Prime)
dig @192.168.0.100 photos.krynet.cc +short
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
* **Expected:** All 38+ fleet service probes return `"healthy": true`.

### 12. Check Automated 12-Hour Backups in Healthchecks
```bash
# Verify Healthchecks container status on Agni
docker logs --tail 20 healthchecks | grep "GET /ping/"
```
* **Expected:** Returns recent successful pings from Agni (`75a5ed4c...`), Prime (`f7d7f21c...`), and Legion.

