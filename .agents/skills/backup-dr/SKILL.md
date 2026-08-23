---
name: backup-dr
description: 3-2-1 backup verification, ZFS snapshot management, and database disaster recovery execution for KryNet cluster (Agni, Prime, Legion). Use to inspect backup integrity or execute database restoration runbooks.
---

# 💾 KryNet 3-2-1 Backup & Disaster Recovery Skill

This skill provides procedures for auditing the multi-node backup architecture and executing disaster recovery runbooks across **Agni**, **Prime**, and **Legion**.

---

## 🗺️ 3-2-1 Backup Topology

```
┌───────────────────┬───────────────────────────────┬────────────────────────────────────────┐
│ Node / Target     │ Layer 1: Local ZFS Snapshots  │ Layer 2: Encrypted pCloud Cloud Backup │
├───────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ **🔥 Agni**       │ Host Ext4 Local Data          │ 🟢 `pcloud:Backups/Krynet-Agni` (12h)   │
│ (`.200`)          │                               │ (Caddy, Vaultwarden, HA, Healthchecks) │
├───────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ **🌟 Prime**      │ 🟢 `orion/apps-config`        │ 🟢 `pcloud:Backups/Krynet-Prime` (12h)  │
│ (`.100`)          │ • Hourly (keep 3d)            │ • `/Configs` (Apps configs)            │
│                   │ • Daily (keep 14d)            │ • `/Apps` (Immich DB dumps, Paperless) │
│                   │ 🟢 `andromeda/apps`           │                                        │
│                   │ • Daily 02:00 (keep 14d)      │                                        │
│                   │ 🟢 `andromeda/media`          │                                        │
│                   │ • Weekly Sun 03:00 (keep 30d) │                                        │
├───────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ **⚡ Legion**      │ Host Ext4 NVMe Local Data     │ 🟢 `pcloud:Backups/Krynet-Legion` (12h) │
│ (`.150`)          │                               │ (OpenWebUI history, LiteLLM, Tdarr)    │
└───────────────────┴───────────────────────────────┴────────────────────────────────────────┘
```

---

## 🛠️ Verification & Diagnostic Commands

### 1. Audit TrueNAS ZFS Snapshots & Cloud Sync
```bash
# Check snapshot tasks
ssh prime "midclt call pool.snapshottask.query | jq '.[] | {id: .id, dataset: .dataset, lifetime: \"\(.lifetime_value) \(.lifetime_unit)\", schedule: .schedule}'"

# Check Cloud Sync tasks
ssh prime "midclt call cloudsync.query | jq '.[] | {description: .description, direction: .direction, path: .path, enabled: .enabled}'"
```

### 2. Inspect 12-Hour Rclone Backup Logs
```bash
# Agni:
ssh agni "docker logs --tail 30 backup-agni"

# Prime:
ssh prime "docker -H tcp://127.0.0.1:2375 logs --tail 30 backup-prime"

# Legion:
ssh legion "docker logs --tail 30 backup-legion"
```

### 3. Verify Remote pCloud Directory Contents
```bash
ssh agni "docker exec backup-agni rclone --config /config/rclone.conf lsd pcloud:Backups"
```

---

## 🚑 Disaster Recovery Runbooks

### Runbook 1: Immich Database Restoration
```bash
# 1. SSH into Prime
ssh prime "sudo -i"

# 2. Stop server to avoid active writes
docker stop immich_server

# 3. Locate latest dump and restore
LATEST_BACKUP=$(ls -t /mnt/andromeda/apps/immich/uploads/backups/*.sql.gz | head -n 1)
zcat "$LATEST_BACKUP" | docker exec -i immich_postgres psql -U postgres -d immich

# 4. Restart server
docker start immich_server
```

### Runbook 2: Instant ZFS Snapshot Rollback (Immich or Paperless)
```bash
# Rollback Immich DB:
docker stop immich_server immich_postgres
zfs rollback -r andromeda/apps/immich/db@auto-YYYY-MM-DD_02-00-daily
docker start immich_postgres immich_server

# Rollback Paperless Documents:
docker stop paperless-ngx paperless-redis
zfs rollback -r andromeda/apps/paperless/documents@auto-YYYY-MM-DD_02-00-daily
docker start paperless-redis paperless-ngx
```

### Runbook 3: Vaultwarden Restore on Agni
```bash
ssh agni
docker stop vaultwarden
# Use host rclone or run one-off writable restore container:
rclone sync pcloud:Backups/Krynet-Agni/vaultwarden /home/agni/apps/docker/vaultwarden --config /home/agni/apps/docker/rclone/rclone.conf
docker start vaultwarden
```
