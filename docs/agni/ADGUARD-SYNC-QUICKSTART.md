# AdGuard Home Sync - Quick Deployment

## 🚀 Quick Setup

### 1. Copy Configuration to Agni

```bash
# On your local machine
scp stacks/agni/adguardhome-sync.yaml agni@192.168.0.200:/home/agni/apps/docker/adguard-sync/adguardhome-sync.yaml
```

### 2. Set Passwords

**Option A: Direct Edit (Quick)**
```bash
# On Agni
nano /home/agni/apps/docker/adguard-sync/adguardhome-sync.yaml

# Replace:
# ${ADGUARD_PRIME_PASSWORD} → your actual Prime password
# ${ADGUARD_AGNI_PASSWORD} → your actual Agni password
```

**Option B: Environment Variables (Recommended)**
```bash
# On Agni, edit .env
nano /home/agni/apps/docker/.env

# Add:
ADGUARD_PRIME_PASSWORD=your_prime_password
ADGUARD_AGNI_PASSWORD=your_agni_password
PUID=1000
PGID=1000
TZ=Asia/Kolkata
```

### 3. Deploy

The AdGuard Sync service is already configured in `adguard-stack.yml`.

**Using Portainer:**
1. Create new stack named "adguard-agni"
2. Paste contents of `adguard-stack.yml`
3. Add environment variables
4. Deploy

**Using Command Line:**
```bash
cd /home/agni/apps/docker
docker compose -f adguard-stack.yml up -d
```

### 4. Verify

```bash
# Check logs
docker logs -f adguardhome-sync

# Access web UI
# http://192.168.0.200:8082
```

## ✅ Expected Behavior

- Sync runs every 5 minutes
- Initial sync on container start
- One-way: Prime → Agni
- DNS rewrites, filters, settings all synced

## 📚 Full Documentation

See [ADGUARD-SYNC.md](../../docs/agni/ADGUARD-SYNC.md) for:
- Detailed configuration
- Troubleshooting
- Monitoring
- Security notes

---

**Sync Direction:** Prime (192.168.0.100:7000) → Agni (127.0.0.1:7000)  
**Sync Interval:** 5 minutes  
**Web UI:** http://192.168.0.200:8082
