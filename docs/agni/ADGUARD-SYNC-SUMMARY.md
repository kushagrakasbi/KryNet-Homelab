# AdGuard Home Sync Setup - Summary

## ✅ What's Been Created

I've set up AdGuard Home Sync to keep your DNS settings synchronized from Prime to Agni.

### 📁 Files Created

1. **`stacks/agni/adguardhome-sync.yaml`** - Sync configuration
   - Syncs from Prime (192.168.0.100:7000) to Agni (127.0.0.1:7000)
   - Runs every 5 minutes
   - Syncs filters, rewrites, settings, etc.

2. **`stacks/agni/adguard-stack.yml`** - Updated with sync service
   - Includes both AdGuard Home and AdGuard Sync
   - Environment variables for passwords
   - Proper dependencies

3. **`docs/agni/ADGUARD-SYNC.md`** - Comprehensive guide
   - Detailed setup instructions
   - Troubleshooting
   - Monitoring

4. **`stacks/agni/ADGUARD-SYNC-QUICKSTART.md`** - Quick deployment
   - Step-by-step deployment
   - Quick reference

5. **`stacks/agni/.env.example`** - Updated with passwords
   - ADGUARD_PRIME_PASSWORD
   - ADGUARD_AGNI_PASSWORD
   - PUID/PGID/TZ

## 🚀 Quick Deployment

### Step 1: Copy Config to Agni

```bash
# Create directory
ssh agni@192.168.0.200 "mkdir -p /home/agni/apps/docker/adguard-sync"

# Copy sync config
scp stacks/agni/adguardhome-sync.yaml agni@192.168.0.200:/home/agni/apps/docker/adguard-sync/
```

### Step 2: Set Passwords

On Agni, edit `/home/agni/apps/docker/.env`:

```bash
# AdGuard Home Admin Passwords
ADGUARD_PRIME_PASSWORD=your_prime_password_here
ADGUARD_AGNI_PASSWORD=your_agni_password_here

# User/Group IDs
PUID=1000
PGID=1000
TZ=Asia/Kolkata
```

### Step 3: Deploy Stack

**Using Portainer:**
1. Create new stack "adguard-agni"
2. Paste `adguard-stack.yml` contents
3. Add environment variables from `.env`
4. Deploy

**Using Command Line:**
```bash
cd /home/agni/apps/docker
docker compose -f adguard-stack.yml up -d
```

### Step 4: Verify

```bash
# Check logs
docker logs -f adguardhome-sync

# Access web UI
# http://192.168.0.200:8082
```

## 🔄 How It Works

```
┌─────────────────────────────────────────┐
│  Prime (192.168.0.100:7000)             │
│  AdGuard Home - Origin                  │
│  • All DNS settings                     │
│  • Filter lists                         │
│  • DNS rewrites                         │
└──────────────┬──────────────────────────┘
               │
               │ Sync every 5 minutes
               │ (one-way)
               ▼
┌─────────────────────────────────────────┐
│  Agni (127.0.0.1:7000)                  │
│  AdGuard Home - Replica                 │
│  • Receives all settings from Prime     │
│  • Identical configuration              │
│  • Automatic failover ready             │
└─────────────────────────────────────────┘
```

## ✨ What Gets Synced

- ✅ **Filter Lists** - All blocklists and allowlists
- ✅ **DNS Rewrites** - Split-horizon DNS entries
- ✅ **Client Settings** - Per-client configurations
- ✅ **DNS Settings** - Upstream DNS, bootstrap, etc.
- ✅ **Query Log Config** - Log retention settings
- ✅ **Stats Config** - Statistics settings
- ✅ **Services** - Blocked services list
- ❌ **DHCP Settings** - NOT synced (different networks)

## 🎯 Benefits

1. **High Availability** - If Prime fails, Agni has identical DNS settings
2. **Consistency** - Both DNS servers always in sync
3. **Easy Management** - Make changes on Prime, auto-sync to Agni
4. **Failover Ready** - No manual reconfiguration needed

## 📊 Monitoring

- **Web UI:** http://192.168.0.200:8082
- **Logs:** `docker logs -f adguardhome-sync`
- **Sync Status:** Shows last sync time and any errors

## 📚 Documentation

- **Quick Start:** [ADGUARD-SYNC-QUICKSTART.md](stacks/agni/ADGUARD-SYNC-QUICKSTART.md)
- **Full Guide:** [ADGUARD-SYNC.md](docs/agni/ADGUARD-SYNC.md)

## 🔐 Security Notes

- Passwords stored in `.env` file (not committed to git)
- Sync happens over HTTP (internal network only)
- Don't expose port 8082 to internet

---

**Sync Direction:** Prime → Agni (one-way)  
**Sync Interval:** Every 5 minutes  
**Web UI:** http://192.168.0.200:8082  
**Status:** Ready to deploy
