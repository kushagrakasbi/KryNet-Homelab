# 🛠️ Operations Playbook

**KryNet Homelab — Runbooks for common operational tasks and incident resolution**

---

## 📋 Table of Contents

1. [Server Restart Recovery](#server-restart-recovery)
2. [Docker Daemon Issues](#docker-daemon-issues)
3. [Stack Management](#stack-management)
4. [Preventive Configuration](#preventive-configuration)

---

## 🔄 Server Restart Recovery

### Symptom: "Port Already Allocated" / Bind Errors After Reboot

After a power cycle or unclean shutdown, Portainer may fail to restart stacks with errors like:

```
Error response from daemon: driver failed programming external connectivity:
Bind for 0.0.0.0:8096 failed: port is already allocated
```

**Root Cause:** Docker's internal state thinks containers are still holding ports even though the processes are gone. Clearing exited containers alone won't fix it — port allocations are tracked at the daemon level.

### Resolution Steps

> ⚠️ **Note:** You're SSH-ing from your Mac. All commands below require `sudo` — easiest to use `sudo -i` for a root shell.

```bash
# SSH into the affected server (using passwordless alias)
ssh prime  # or ssh truenas_admin@192.168.0.100

# Switch to root shell (avoids double-sudo issues with subshells)
sudo -i

# 1. Force-stop all containers
docker stop $(docker ps -aq)

# 2. Force-remove all containers
docker rm -f $(docker ps -aq)

# 3. Clear stale Docker network state (releases orphaned port bindings)
docker network prune -f

# 4. Restart Docker daemon — this is the key step that clears daemon-level state
systemctl restart docker

# 5. Exit root shell
exit
```

After Docker restarts, go to **Portainer → Stacks** and redeploy each stack.

### If Ports Are Still Stuck

Check for rogue `docker-proxy` processes manually:

```bash
sudo -i

# Find docker-proxy processes still holding ports
ss -tlnp | grep docker-proxy

# Kill them if found
pkill docker-proxy

# Restart Docker
systemctl restart docker

exit
```

### Recommended Stack Deploy Order

Deploy stacks in this order to respect service dependencies:

| Order | Stack | Reason |
|-------|-------|--------|
| 1 | `dns-stack.yml` | DNS must be up first |
| 2 | `tailscale.yml` | VPN connectivity |
| 3 | `monitoring-sensors.yml` | Enables observability |
| 4 | `media-stack.yml` | Gluetun VPN → downloaders → *arr → Jellyfin |
| 5 | `immich.yml` | PostgreSQL → Redis → Server → ML |
| 6 | `audiobookshelf.yml` | Independent |
| 7 | `homarr.yml` | Dashboard (needs other services up) |
| 8 | `speedtest.yml` | Independent |
| 9 | `rclone-stack.yml` | Backup (runs on schedule) |

---

## 🐳 Docker Daemon Issues

### Symptom: Permission Denied on Docker Socket

```
permission denied while trying to connect to the Docker daemon socket at
unix:///var/run/docker.sock
```

**Fix:** Always use `sudo` or switch to root:

```bash
# Option A: Prefix every command
sudo docker ps

# Option B: Root shell (recommended for multi-command sessions)
sudo -i
docker ps
# ... more commands ...
exit
```

**Permanent fix** — add your user to the docker group (TrueNAS SCALE):

```bash
sudo usermod -aG docker napster
# Log out and back in for group change to take effect
```

### Symptom: Docker Daemon Won't Start

```bash
sudo -i

# Check daemon status
systemctl status docker

# View recent logs
journalctl -u docker --since "10 minutes ago"

# Force restart
systemctl restart docker

# If still failing, check for corrupted state
ls -la /var/run/docker.sock
rm -f /var/run/docker.sock
systemctl restart docker

exit
```

---

## 📦 Stack Management

### Redeploying All Stacks via CLI

If Portainer itself is down, deploy stacks from the command line:

```bash
sudo -i
cd /mnt/orion/apps-config

# Deploy a specific stack (use the env file)
docker compose --env-file stack.env -f media-stack.yml up -d
docker compose --env-file stack.env -f immich.yml up -d
docker compose --env-file stack.env -f dns-stack.yml up -d
# ... repeat for other stacks
```

### Checking What's Running vs. What Should Be

```bash
# All running containers
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort

# Containers that exited (potential failures)
sudo docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}"

# Find which port is conflicting
sudo ss -tlnp | grep :<PORT_NUMBER>
```

### Cleaning Up Docker State

```bash
sudo -i

# Remove stopped containers
docker container prune -f

# Remove unused images (saves disk space)
docker image prune -f

# Remove unused volumes (⚠️ CAREFUL — check before running)
docker volume ls -f dangling=true    # List first
docker volume prune -f               # Then prune

# Full system cleanup (containers, images, networks, build cache)
docker system prune -f

exit
```

---

## 🛡️ Preventive Configuration

### Docker Shutdown Timeout

Add to `/etc/docker/daemon.json` to give containers time to gracefully stop during system shutdown:

```json
{
  "shutdown-timeout": 30
}
```

Then reload: `sudo systemctl restart docker`

### Restart Policy Best Practice

Use `restart: unless-stopped` in compose files instead of `restart: always`:

```yaml
services:
  jellyfin:
    restart: unless-stopped   # Won't restart containers you intentionally stopped
```

This prevents containers from fighting each other for ports during messy restarts.

### Systemd Docker Startup Delay (Optional)

If stacks auto-start before Docker is fully ready, add a startup delay:

```bash
sudo systemctl edit docker.service
```

Add:

```ini
[Service]
ExecStartPost=/bin/sleep 5
```

This gives Docker 5 seconds to fully initialize before Portainer starts launching stacks.

## ❓ Multi-Node Cluster FAQ & Troubleshooting

### 1. "Port Already Allocated" / Bind Errors After Container Crash or Reboot
**Symptom:** When restarting a container or stack, Docker throws `driver failed programming external connectivity: Bind for 0.0.0.0:xxxx failed: port is already allocated`.
**Root Cause:** Orphaned `docker-proxy` processes or stale Docker bridge networks hold the socket in the kernel table even after containers are stopped or deleted.
**Resolution (Prime or Legion):**
```bash
sudo -i
# 1. Kill orphaned docker-proxy processes
pkill docker-proxy

# 2. Prune stale network bindings
docker network prune -f

# 3. Restart Docker daemon to clear daemon-level port locks
systemctl restart docker
exit
```

---

### 2. Portainer Agent Connection Fails / Environment Not Showing
**Symptom:** Agni Portainer cannot connect to `192.168.0.150:9001` or the environment fails to initialize.
**Diagnosis & Fix:**
1. **Check Ubuntu Firewall (UFW) on Legion:**
   ```bash
   sudo ufw status
   # If active, allow LAN traffic:
   sudo ufw allow from 192.168.0.0/24
   ```
2. **Verify Agent Mode in Portainer UI:**
   * Make sure you select **Agent** (NOT Edge Agent, NOT API).
   * URL format: `192.168.0.150:9001`.
3. **Test TCP Connectivity from Agni:**
   ```bash
   nc -zv 192.168.0.150 9001
   # Should return: Connection to 192.168.0.150 9001 port [tcp/*] succeeded!
   ```

---

### 3. "network xxx was found but has incorrect label com.docker.compose.network"
**Symptom:** Deploying a stack in Portainer throws `compose up operation failed: network legion_net was found but has incorrect label`.
**Root Cause:** The network was created manually via `docker network create` on the CLI, but Docker Compose expected to manage the network lifecycle itself.
**Fix:** In the compose file, declare the network as `external: true`:
```yaml
networks:
  legion_net:
    name: legion_net
    external: true
```

---

### 4. How to Verify Immich Machine Learning Remote Offload (CUDA)
**Checklist:**
1. **On Prime (`stack.env`):**
   ```bash
   IMMICH_MACHINE_LEARNING_URL=http://192.168.0.150:3003
   ```
2. **On Prime:** Stop local ML container (`docker stop immich_machine_learning`) and restart `immich_server` (`docker restart immich_server`).
3. **In Immich Web UI:**
   * Go to **`https://photos.krynet.cc`** → **Administration** → **Settings** → **Machine Learning Settings**.
   * Status should display **Healthy / Connected** to `http://192.168.0.150:3003`.
4. **On Legion:** Verify GPU inference in logs:
   ```bash
   docker logs immich_machine_learning --tail 50
   # Should show: CUDA device available: NVIDIA GeForce RTX 3060 Laptop GPU
   ```

---

### 5. Multi-Node Prometheus Scrape Configuration on Agni
To scrape metrics from all 3 nodes, configure `/home/agni/apps/docker/prometheus/config/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  # 1. Monitor Agni (Self - Network Core)
  - job_name: 'agni'
    static_configs:
      - targets: ['node-exporter:9100', 'cadvisor:8080']

  # 2. Monitor Prime (Remote - Storage Hub)
  - job_name: 'prime'
    static_configs:
      - targets: ['192.168.0.100:9100', '192.168.0.100:8087']

  # 3. Monitor Legion (Remote - AI & GPU Compute Engine)
  - job_name: 'legion'
    static_configs:
      - targets: ['192.168.0.150:9100', '192.168.0.150:8087']
```
Reload Prometheus: `docker restart prometheus`.

---

---

## 💾 6. Disaster Recovery & Database Restoration Runbooks

### Runbook A: Immich PostgreSQL (VectorChord) Database Restoration
Immich generates automated daily compressed database dumps in `/mnt/andromeda/apps/immich/uploads/backups/immich-db-backup-*.sql.gz` which are synced to pCloud.

**To restore Immich from a backup dump:**
```bash
# 1. SSH into Prime
ssh prime "sudo -i"

# 2. Stop Immich Server to prevent new transactions
docker stop immich_server

# 3. Locate the latest backup file
LATEST_BACKUP=$(ls -t /mnt/andromeda/apps/immich/uploads/backups/*.sql.gz | head -n 1)
echo "Restoring from: $LATEST_BACKUP"

# 4. Restore database into immich_postgres container
zcat "$LATEST_BACKUP" | docker exec -i immich_postgres psql -U postgres -d immich

# 5. Restart Immich Server
docker start immich_server

# 6. Verify Immich API ping
curl -s http://127.0.0.1:2283/api/server/ping
```

**Alternative: Point-in-Time ZFS Snapshot Rollback (Instant):**
```bash
# List available automated daily snapshots:
zfs list -t snapshot | grep andromeda/apps/immich/db

# Stop Immich and rollback to snapshot:
docker stop immich_server immich_postgres
zfs rollback -r andromeda/apps/immich/db@auto-YYYY-MM-DD_02-00-daily
docker start immich_postgres immich_server
```

---

### Runbook B: Vaultwarden Password Vault Restoration (Agni)
Vaultwarden SQLite databases and RSA keys are backed up every 12h to `pcloud:Backups/Krynet-Agni/vaultwarden/`.

**To restore Vaultwarden:**
```bash
# 1. SSH into Agni
ssh agni

# 2. Stop Vaultwarden container
docker stop vaultwarden

# 3. Restore data directory from local pCloud cache or rclone pull
docker exec backup-agni rclone sync pcloud:Backups/Krynet-Agni/vaultwarden /data/vaultwarden --config /config/rclone.conf

# 4. Start Vaultwarden
docker start vaultwarden
```

---

### Runbook C: Paperless-ngx Document Index & Database Restoration (Prime)
Paperless documents and index files are stored in `/mnt/andromeda/apps/paperless/documents/`.

**To restore Paperless documents:**
```bash
# 1. SSH into Prime
ssh prime "sudo -i"

# 2. Stop paperless
docker stop paperless-ngx paperless-redis

# 3. Restore documents dataset from ZFS snapshot:
zfs rollback -r andromeda/apps/paperless/documents@auto-YYYY-MM-DD_02-00-daily

# 4. Start paperless
docker start paperless-redis paperless-ngx
```

---

**Last Updated:** August 2026  
**Applies to Fleet:** 🔥 Agni (`192.168.0.200`), 🌟 Prime (`192.168.0.100`), ⚡ Legion (`192.168.0.150`)  
**Shell Note:** When SSH-ing to TrueNAS or Ubuntu nodes, use `sudo -i` for root maintenance tasks.
