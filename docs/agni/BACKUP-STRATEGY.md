# KryNet Backup Strategy

## 🎯 Backup Philosophy: 3-2-1 Rule

- **3 Copies** of data
- **2 Different** media types
- **1 Offsite** backup

## 📊 Data Classification

### Tier 1: Critical (Cannot Lose)
| Data | Location | Size | Backup Priority |
|------|----------|------|-----------------|
| **Photos** | Immich on Prime | ~500GB | ⭐⭐⭐⭐⭐ |
| **Documents** | Paperless on Prime | ~50GB | ⭐⭐⭐⭐⭐ |
| **Docker Configs** | Both servers | ~5GB | ⭐⭐⭐⭐⭐ |
| **Home Assistant Config** | Agni | ~1GB | ⭐⭐⭐⭐ |

### Tier 2: Important (Painful to Lose)
| Data | Location | Size | Backup Priority |
|------|----------|------|-----------------|
| **Media Library** | Prime | ~8TB | ⭐⭐⭐ |
| **Download History** | Prime | ~2TB | ⭐⭐ |

### Tier 3: Replaceable (Can Redownload)
| Data | Location | Size | Backup Priority |
|------|----------|------|-----------------|
| **Jellyfin Metadata** | Prime | ~10GB | ⭐ |
| **Transcode Cache** | Prime | ~100GB | ❌ No backup |

## 🔄 Backup Implementation

### Strategy 1: Real-Time Config Sync (Syncthing)

**Purpose:** Protect Docker configurations and critical configs

**Setup:**
```
Agni ←→ Prime (Bidirectional Sync)

Agni Folders:
├─ /home/agni/apps/docker/ → Synced to Prime
└─ /home/agni/apps/syncthing/data/prime-backup/ ← Receives from Prime

Prime Folders:
├─ /mnt/orion/apps-config/ → Synced to Agni
└─ /mnt/andromeda/backups/agni-config/ ← Receives from Agni
```

**Benefits:**
- Real-time protection
- Automatic versioning (30 days)
- Survives single-server failure
- No manual intervention

**Implementation:** See [SYNCTHING-SETUP.md](SYNCTHING-SETUP.md)

---

### Strategy 2: Daily Photo/Document Backup (Syncthing)

**Purpose:** Protect irreplaceable personal data

**Setup:**
```
Prime → Agni (One-Way Sync)

Photos (Immich):
/mnt/andromeda/apps/immich/uploads/ → /home/agni/backups/immich/

Documents (Paperless):
/mnt/andromeda/apps/paperless/documents/ → /home/agni/backups/paperless/
```

**Schedule:**
- Continuous sync during day (8 AM - 11 PM)
- Pause at night to save power
- Keep 30 days of file versions

**Storage Requirements on Agni:**
- Photos: ~500GB
- Documents: ~50GB
- **Total:** ~550GB (ensure Agni has 1TB+ storage)

---

### Strategy 3: Weekly Cloud Backup (rclone + Backblaze B2)

**Purpose:** Offsite protection against catastrophic failure

**Setup:**
```bash
# Install rclone on Prime
curl https://rclone.org/install.sh | sudo bash

# Configure Backblaze B2
rclone config
# Name: backblaze
# Type: b2
# Account ID: <from Backblaze>
# Application Key: <from Backblaze>
```

**Backup Script:**
```bash
#!/bin/bash
# /home/user/scripts/backup-to-cloud.sh

# Backup photos (encrypted)
rclone sync /mnt/andromeda/apps/immich/uploads/ \
  backblaze:krynet-immich-backup \
  --crypt-password="your-encryption-password" \
  --transfers=4 \
  --checkers=8 \
  --log-file=/var/log/rclone-immich.log

# Backup documents (encrypted)
rclone sync /mnt/andromeda/apps/paperless/documents/ \
  backblaze:krynet-paperless-backup \
  --crypt-password="your-encryption-password" \
  --transfers=4 \
  --checkers=8 \
  --log-file=/var/log/rclone-paperless.log

# Backup configs
rclone sync /mnt/orion/apps-config/ \
  backblaze:krynet-config-backup \
  --crypt-password="your-encryption-password" \
  --transfers=4 \
  --log-file=/var/log/rclone-config.log
```

**Cron Schedule:**
```cron
# Run every Sunday at 2 AM
0 2 * * 0 /home/user/scripts/backup-to-cloud.sh
```

**Cost Estimate:**
- Storage: 500GB photos + 50GB docs = 550GB
- Backblaze B2: $0.006/GB/month = $3.30/month
- Bandwidth: First 3x storage free (1.65TB/month)

---

### Strategy 4: Monthly Media Backup (Optional)

**Purpose:** Backup media library (if desired)

**Options:**

**Option A: External HDD**
- Buy 10TB external drive
- Monthly manual backup via rsync
- Store offsite (friend/family)
- Cost: ~$200 one-time

**Option B: Backblaze B2 (Expensive)**
- 8TB media = $48/month
- Not recommended unless critical

**Option C: Don't Backup**
- Media is replaceable
- Focus on photos/documents
- **Recommended** for cost savings

---

## 📋 Backup Schedule

| Backup Type | Frequency | Method | Retention |
|-------------|-----------|--------|-----------|
| **Docker Configs** | Real-time | Syncthing | 30 days versions |
| **Photos** | Real-time | Syncthing | 30 days versions |
| **Documents** | Real-time | Syncthing | 30 days versions |
| **Cloud Backup** | Weekly | rclone | Unlimited |
| **Media** | Monthly | Manual (optional) | 1 copy |

## 🔧 Implementation Steps

### Step 1: Deploy Syncthing (Week 1)

1. **On Prime:**
   ```bash
   cd /home/user/stacks/prime
   docker compose -f syncthing.yml up -d
   ```

2. **On Agni:**
   ```bash
   cd /home/agni/apps/docker
   docker compose -f syncthing.yml up -d
   ```

3. **Configure Folders:**
   - See [SYNCTHING-SETUP.md](SYNCTHING-SETUP.md)

### Step 2: Set Up Cloud Backup (Week 2)

1. **Create Backblaze B2 Account**
   - Sign up at backblaze.com
   - Create application key
   - Create buckets: krynet-immich-backup, krynet-paperless-backup

2. **Install & Configure rclone**
   ```bash
   curl https://rclone.org/install.sh | sudo bash
   rclone config
   ```

3. **Test Backup**
   ```bash
   # Test with small folder first
   rclone sync /mnt/andromeda/apps/immich/uploads/test/ \
     backblaze:krynet-immich-backup/test/ \
     --dry-run
   ```

4. **Set Up Cron**
   ```bash
   crontab -e
   # Add weekly backup job
   ```

### Step 3: Verify & Monitor (Week 3)

1. **Check Syncthing Status**
   - http://192.168.0.100:8384 (Prime)
   - http://192.168.0.200:8384 (Agni)
   - Verify folders are syncing

2. **Check Cloud Backup**
   ```bash
   rclone ls backblaze:krynet-immich-backup
   ```

3. **Set Up Monitoring**
   - Add Syncthing to Uptime Kuma
   - Monitor rclone logs
   - Alert on backup failures

## 🚨 Recovery Procedures

### Scenario 1: Recover Single File

**From Syncthing:**
1. Access Syncthing web UI
2. Browse to folder
3. Click "Versions"
4. Download desired version

**From Cloud:**
```bash
rclone copy backblaze:krynet-immich-backup/path/to/file.jpg ./
```

### Scenario 2: Recover Entire Service

**Example: Restore Immich after Prime failure**

1. **Restore from Agni backup:**
   ```bash
   # On new/rebuilt Prime
   rsync -avP agni:/home/agni/backups/immich/ /mnt/andromeda/apps/immich/
   ```

2. **Or restore from cloud:**
   ```bash
   rclone sync backblaze:krynet-immich-backup/ /mnt/andromeda/apps/immich/uploads/
   ```

3. **Start Immich:**
   ```bash
   docker compose -f immich.yml up -d
   ```

### Scenario 3: Complete Disaster Recovery

**If both Agni and Prime fail:**

1. **Rebuild servers** with fresh OS
2. **Restore configs from cloud:**
   ```bash
   rclone sync backblaze:krynet-config-backup/ /mnt/orion/apps-config/
   ```

3. **Restore data from cloud:**
   ```bash
   rclone sync backblaze:krynet-immich-backup/ /mnt/andromeda/apps/immich/
   rclone sync backblaze:krynet-paperless-backup/ /mnt/andromeda/apps/paperless/
   ```

4. **Deploy stacks:**
   ```bash
   docker compose up -d
   ```

**RTO:** 8-12 hours (depending on data size)  
**RPO:** < 7 days (weekly cloud backup)

## 📊 Monitoring & Alerts

### Syncthing Monitoring

**Check:**
- Folder sync status
- Last sync time
- Error count
- Disk space

**Alert if:**
- Sync stopped > 1 hour
- Errors > 10
- Disk usage > 90%

### Cloud Backup Monitoring

**Check:**
- Last backup time
- Backup size
- Upload errors

**Alert if:**
- No backup in 8 days
- Backup size decreased > 10%
- Upload failures

## 💰 Cost Summary

| Service | Monthly Cost | Annual Cost |
|---------|--------------|-------------|
| **Backblaze B2 (550GB)** | $3.30 | $40 |
| **Syncthing** | Free | Free |
| **rclone** | Free | Free |
| **Total** | **$3.30** | **$40** |

**One-Time Costs:**
- External HDD (optional): $200

## ✅ Success Criteria

- [ ] Syncthing running on both servers
- [ ] Config sync working bidirectionally
- [ ] Photo/document sync working (Prime → Agni)
- [ ] Cloud backup configured and tested
- [ ] Weekly cloud backup running automatically
- [ ] Recovery procedures documented and tested
- [ ] Monitoring alerts configured

---

**Last Updated:** January 26, 2026  
**Next Review:** Monthly  
**Owner:** Infrastructure Team
