# AdGuard Home Sync - Setup Guide

## 📋 Overview

AdGuard Home Sync keeps your DNS settings synchronized between:
- **Origin (Prime):** 192.168.0.100:7000 - Primary AdGuard instance
- **Replica (Agni):** 127.0.0.1:7000 - Secondary AdGuard instance

This ensures both DNS servers have identical:
- Filter lists
- DNS rewrites (split-horizon DNS)
- Client settings
- Query log configuration
- Statistics configuration

## 🔧 Setup Instructions

### Step 1: Prepare Configuration Directory

On Agni:
```bash
mkdir -p /home/agni/apps/docker/adguard-sync
```

### Step 2: Copy Configuration File

Copy `adguardhome-sync.yaml` to Agni:
```bash
# From your local machine
scp stacks/agni/adguardhome-sync.yaml agni@192.168.0.200:/home/agni/apps/docker/adguard-sync/
```

### Step 3: Set Passwords in Configuration

Edit the configuration file on Agni:
```bash
nano /home/agni/apps/docker/adguard-sync/adguardhome-sync.yaml
```

Replace the password placeholders:
- `${ADGUARD_PRIME_PASSWORD}` → Your Prime AdGuard admin password
- `${ADGUARD_AGNI_PASSWORD}` → Your Agni AdGuard admin password

**OR** use environment variables in the stack (recommended for security).

### Step 4: Update .env File (Recommended)

Add to `/home/agni/apps/docker/.env`:
```bash
# AdGuard Admin Passwords
ADGUARD_PRIME_PASSWORD=your_prime_password_here
ADGUARD_AGNI_PASSWORD=your_agni_password_here
```

Then update the stack to pass these to the container:
```yaml
adguardhome-sync:
  environment:
    - ADGUARD_PRIME_PASSWORD=${ADGUARD_PRIME_PASSWORD}
    - ADGUARD_AGNI_PASSWORD=${ADGUARD_AGNI_PASSWORD}
```

### Step 5: Deploy the Stack

The AdGuard Sync service is already included in `adguard-stack.yml`:

```bash
# Using Portainer: Deploy the adguard-stack.yml
# OR using command line:
cd /home/agni/apps/docker
docker compose -f adguard-stack.yml up -d
```

### Step 6: Verify Sync is Working

Check the sync logs:
```bash
docker logs -f adguardhome-sync
```

You should see:
```
[INFO] Starting AdGuard Home Sync
[INFO] Running initial sync...
[INFO] Syncing from http://192.168.0.100:7000 to http://127.0.0.1:7000
[INFO] Sync completed successfully
```

Access the sync web UI:
```
http://192.168.0.200:8082
```

## 🔍 What Gets Synced

### ✅ Synced Features
- **General Settings** - Basic AdGuard configuration
- **Query Log Config** - Log retention settings
- **Stats Config** - Statistics settings
- **Client Settings** - Per-client configurations
- **Services** - Blocked services list
- **Filters** - All filter lists and custom rules
- **DNS Settings** - Upstream DNS, bootstrap DNS, etc.
- **DNS Rewrites** - Custom DNS entries (important for split-horizon!)

### ❌ NOT Synced
- **DHCP Settings** - Different networks, don't sync
- **Query History** - Only settings, not actual queries
- **Statistics Data** - Only settings, not actual stats

## 🔄 Sync Behavior

- **Frequency:** Every 5 minutes (configurable via `cron` setting)
- **On Startup:** Runs once immediately when container starts
- **Direction:** One-way from Prime → Agni
- **Conflict Resolution:** Agni settings are overwritten by Prime

## 🛠️ Troubleshooting

### Sync Not Working

1. **Check connectivity:**
   ```bash
   # From Agni container
   docker exec adguardhome-sync curl http://192.168.0.100:7000
   ```

2. **Verify passwords:**
   - Make sure AdGuard admin passwords are correct
   - Check if passwords contain special characters (may need escaping)

3. **Check AdGuard API:**
   ```bash
   # Test Prime API
   curl -u admin:password http://192.168.0.100:7000/control/status
   
   # Test Agni API
   curl -u admin:password http://127.0.0.1:7000/control/status
   ```

### Sync Fails with Authentication Error

- Verify admin username is correct (default: `admin`)
- Check password in config file
- Ensure AdGuard Home is fully initialized (not in setup mode)

### Changes on Agni Keep Getting Overwritten

This is expected! AdGuard Sync is one-way:
- **Make changes on Prime** - They will sync to Agni
- **Changes on Agni** - Will be overwritten on next sync

## 📊 Monitoring

### Web UI
Access at: `http://192.168.0.200:8082`

Shows:
- Last sync time
- Sync status
- Error logs

### Docker Logs
```bash
docker logs -f adguardhome-sync
```

### Health Check
```bash
# Check if container is running
docker ps | grep adguardhome-sync

# Check sync status via API
curl http://192.168.0.200:8082/api/status
```

## 🔐 Security Notes

1. **Passwords in Config:**
   - Use environment variables instead of hardcoding
   - Ensure config file has proper permissions: `chmod 600`

2. **Network Security:**
   - Sync happens over HTTP (internal network only)
   - Don't expose sync API (port 8082) to internet

3. **API Access:**
   - Optionally enable authentication for sync web UI
   - Uncomment `api.username` and `api.password` in config

## 📝 Configuration Reference

### Sync Interval

Change sync frequency by editing `cron` in config:
```yaml
cron: "*/5 * * * *"  # Every 5 minutes
cron: "*/15 * * * *" # Every 15 minutes
cron: "0 * * * *"    # Every hour
```

### Selective Sync

Disable specific features:
```yaml
features:
  filters: false  # Don't sync filter lists
  rewrites: false # Don't sync DNS rewrites
```

### Multiple Replicas

Add more replica instances:
```yaml
replicas:
  - url: http://127.0.0.1:7000
    username: admin
    password: password1
  - url: http://192.168.0.200:7000
    username: admin
    password: password2
```

## 🎯 Use Cases

### Scenario 1: High Availability DNS
- Prime fails → Clients use Agni (already synced)
- No manual reconfiguration needed
- Seamless failover

### Scenario 2: Load Balancing
- Router DNS: Primary = Agni, Secondary = Prime
- Both have identical settings
- Distribute DNS query load

### Scenario 3: Testing Changes
- Test filter rules on Prime
- Automatically propagate to Agni
- Consistent DNS behavior across network

## 📚 Additional Resources

- [AdGuard Home Sync GitHub](https://github.com/bakito/adguardhome-sync)
- [AdGuard Home API Docs](https://github.com/AdguardTeam/AdGuardHome/tree/master/openapi)

---

**Last Updated:** January 26, 2026  
**Sync Direction:** Prime (192.168.0.100) → Agni (192.168.0.200)  
**Sync Interval:** 5 minutes
