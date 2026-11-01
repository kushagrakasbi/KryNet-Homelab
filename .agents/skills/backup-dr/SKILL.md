---
name: backup-dr
description: >-
  Verifies 3-2-1 backup coverage, manages ZFS snapshots, and executes database
  disaster-recovery runbooks. Use when the user says "check the backups", "is <x>
  backed up", "restore <service>", "take a snapshot", before any destructive
  operation or migration, and whenever a new stateful service is added.
---

# 💾 KryNet 3-2-1 Backup & Disaster Recovery Skill

This skill provides procedures for auditing the multi-node backup architecture and executing disaster recovery runbooks across **Agni**, **Prime**, and **Legion**.

## 🔗 Source → this skill

| Feeds this skill | Sync when |
|---|---|
| `scripts/nucleus-backup.sh` | the backup target or schedule changes |
| `docs/HOME-ASSISTANT-DISASTER-RECOVERY-AND-MIGRATION-RUNBOOK.md` | the restore procedure changes |

When any of those change, re-read this skill and update it in the same PR.
Reverse check: `grep -l "<changed-file>" .agents/skills/*/SKILL.md`


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

---

## ✅ A backup is a hypothesis until it is restored

Verifying that a backup *exists* is not verifying that it *works*. The only proof is
a restore.

**After any restore runbook above:**

```bash
# service came back
ssh <node> "docker ps --filter name=<container> --format '{{.Names}} {{.Status}}'"

# the data is actually there — count something, do not just check it opens
# (SQLite services: integrity_check plus a row count)
sqlite3 <restored.db> "PRAGMA integrity_check;"
sqlite3 <restored.db> "SELECT COUNT(*) FROM <a busy table>;"
```

**Periodically, without an incident to force it:** restore one service into a
throwaway location and confirm the row counts. Never test a restore by overwriting
the live volume.

### 🔴 SQLite services: the `.db` file alone is not a backup

Any service whose database runs in **WAL mode** keeps recent committed data in a
`-wal` sidecar until a checkpoint. Copying only the `.db` file silently loses it, and
the resulting copy still passes `integrity_check`.

Use a WAL-aware snapshot, from a read-only connection:

```bash
sqlite3 "file:/path/to/service.db?mode=ro" ".backup '/tmp/snapshot.db'"
```

`?mode=ro` matters: a read-write connection may checkpoint on close, writing to a
live database from what looks like a read command.

**Restoring in** has the mirror hazard — a new `.db` beside a stale `-wal`/`-shm`
will be replayed over or refused. Stop the container, remove all three files, copy
in, fix ownership, start, then verify.

---

## 🔴 All three nodes share ONE pCloud token

The `[pcloud]` section's `token =` line is identical in all three `rclone.conf` files (verified by hash,
2026-10-05). **When it is revoked, every off-site backup fails** — but each Healthchecks check only goes
`down` at that node's next run, so the fleet looks one-third broken for up to 12 h.

**Signature** (container log): `pcloud error: Revoked 'access_token' provided, you need to re-authorize
the application`, then `Healthcheck: FAILED`.

**Re-authorize** (owner — OAuth needs a browser, so on the personal Mac):

```bash
rclone authorize "pcloud"    # prints a token JSON — paste it, never commit it
```

Replace the `token =` line in all three files, then restart each backup container (its loop runs
immediately on start) and confirm every check turns `up` **and** the log says `Healthcheck: SUCCESS`:

| Node | File | Container |
|---|---|---|
| Agni | `/home/agni/apps/docker/rclone/config/rclone.conf` | `backup-agni` |
| Legion | `/home/legion/apps/docker/rclone/config/rclone.conf` | `backup-legion` |
| Prime | `/mnt/orion/apps-config/rclone/rclone.conf` (writable by `truenas_admin`) | `backup-prime` — restart via Portainer |

Compare tokens without printing them: `grep '^token' <file> | sha256sum | cut -c1-12`.

## 🔴 Two ways a backup lies (measured on this fleet, 2026-08-30)

**1. `PRAGMA integrity_check` returns `ok` for a 0-byte file.** An empty file is trivially
self-consistent, so the check cannot distinguish "intact" from "empty". A `nucleus.db` pre-deploy
backup was verified at creation (2.6 MB, `ok`, 1607 transactions), then found at **0 bytes** two hours
later — still reporting `ok`.

**Verify by ROW COUNT, against a figure you know:**

```bash
sqlite3 "$BACKUP" "SELECT COUNT(*) FROM transactions;"   # compare with production
sqlite3 "$BACKUP" "SELECT SUM(amount) FROM transactions WHERE type='expense';"
```

**2. `ssh host "cat remote" > local` truncates `local` BEFORE `cat` runs.** That is how the file above
became empty: the line was re-run after the remote temp had been cleaned up, so `cat` failed, the
redirect had already emptied the destination, and the shell exited **0**. A silent, successful-looking
destruction of the only copy.

```bash
# Refuse rather than overwrite. Timestamped names make collisions impossible anyway.
DEST=~/Downloads/nucleus-pre-$(date -u +%Y%m%dT%H%M%SZ).db
[ -e "$DEST" ] && { echo "REFUSING: $DEST exists"; exit 1; }
```

**And re-verify immediately before you rely on it**, not only when it was taken. A backup that was
good an hour ago is a hypothesis about now.
