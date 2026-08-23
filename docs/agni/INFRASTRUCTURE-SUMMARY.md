# KryNet Stack Reorganization - Summary

## ✅ Completed Work

### Phase 1: Stack File Organization

#### Agni Stack Files Created
Created 6 individual stack files in `stacks/agni/`:

1. **adguard-stack.yml** - AdGuard Home + AdGuard Sync
2. **caddy-stack.yml** - Reverse proxy with Cloudflare DNS
3. **homeassistant.yml** - Smart home hub (ready to enable)
4. **speedtest.yml** - OpenSpeedTest for network testing
5. **syncthing.yml** - File sync for backups (disabled, ready to enable)
6. **tailscale.yml** - VPN mesh with subnet routing

#### Prime Stack Files
Verified existing 18 stack files in `stacks/prime/` (already properly organized)

### Phase 2: Infrastructure Documentation

Created comprehensive guides in `docs/agni/`:

1. **RESILIENCE-PLAN.md** - High availability & failover strategies
2. **BACKUP-STRATEGY.md** - 3-2-1 backup implementation
3. **PORT-VALIDATION.md** - Service port reference
4. **CADDYFILE-CHANGES.md** - Reverse proxy configuration
5. **ADGUARD-SYNC.md** - DNS sync setup

## 📊 Service Distribution

### Agni (Sentinel) - 192.168.0.200
**Role:** Network core, always-on, low power (15W)

| Service | Status | Purpose |
|---------|--------|---------|
| Portainer | ✅ Enabled | Container management |
| Caddy | ✅ Enabled | Reverse proxy + SSL |
| AdGuard Home | ✅ Enabled | Primary DNS |
| AdGuard Sync | ✅ Enabled | DNS config sync |
| Home Assistant | ⚠️ Ready | Smart home (enable when migrated) |
| Tailscale | ✅ Enabled | VPN mesh |
| Speedtest | ⚠️ Optional | Network testing |
| Syncthing | ⚠️ Ready | Backup sync (enable for backups) |

### Prime (Data Plane) - 192.168.0.100
**Role:** Storage, compute, media, high power (150W)

| Category | Services | Status |
|----------|----------|--------|
| **Infrastructure** | Cloudflared, Traefik | ✅ Enabled |
| **Storage** | Immich, Paperless | ✅ Enabled |
| **Media** | Jellyfin, *arr stack, qBittorrent | ✅ Enabled |
| **Monitoring** | Uptime Kuma, Prometheus, Dozzle, Grafana | ✅ Enabled |
| **Dashboards** | Homepage, Homarr | ✅ Enabled |
| **AI** | LiteLLM, OpenWebUI | ❌ Disabled |
| **Other** | FreshRSS, NPM | ❌ Disabled |

## 🎯 Key Improvements Recommended

### Priority 1: Immediate (This Week)
1. **DNS Failover** - Configure router with 1.1.1.1 as secondary DNS
2. **Deploy Syncthing** - Enable on both servers for config backup
3. **Test Failover** - Manually test Agni failure scenario

### Priority 2: Short Term (This Month)
1. **UPS for Agni** - Purchase APC Back-UPS 600VA (~$80)
2. **Monitoring** - Deploy Uptime Kuma on Agni
3. **Alerts** - Configure Gotify for service alerts

### Priority 3: Medium Term (3 Months)
1. **Cloud Backup** - Set up Backblaze B2 for photos/documents
2. **Backup Automation** - Weekly rclone sync to cloud
3. **Documentation** - Complete recovery procedures

## 🛡️ Resilience Features

### Single Point of Failure Mitigations

| SPOF | Mitigation | Status |
|------|------------|--------|
| **Agni Server** | UPS + hardware redundancy | ⚠️ Plan created |
| **DNS** | Secondary DNS (1.1.1.1) | ⚠️ Ready to configure |
| **Reverse Proxy** | Backup Caddy on Prime | ⚠️ Plan created |
| **Data Loss** | 3-2-1 backup strategy | ⚠️ Plan created |
| **Power** | UPS for Agni | ⚠️ To purchase |

### Backup Strategy (3-2-1 Rule)

**3 Copies:**
1. Live data on Prime
2. Syncthing backup on Agni
3. Cloud backup on Backblaze B2

**2 Media:**
1. HDD on Prime
2. SSD on Agni (if space allows)

**1 Offsite:**
- Encrypted cloud backup (Backblaze B2)

## 📋 Next Steps

### User Actions Required

1. **Review Documentation**
   - Read RESILIENCE-PLAN.md
   - Read BACKUP-STRATEGY.md
   - Decide on implementation priorities

2. **Configure DNS Failover**
   ```
   Router DNS Settings:
   Primary: 192.168.0.200 (Agni)
   Secondary: 1.1.1.1 (Cloudflare)
   ```

3. **Enable Syncthing**
   ```bash
   # On Prime
   docker compose -f syncthing.yml up -d
   
   # On Agni
   docker compose -f syncthing.yml up -d
   ```

4. **Purchase UPS**
   - APC Back-UPS 600VA or similar
   - Minimum 30 minutes runtime for Agni

5. **Set Up Cloud Backup** (Optional, but recommended)
   - Create Backblaze B2 account
   - Configure rclone
   - Set up weekly backup cron

### Optional Enhancements

1. **CopyParty** - File sharing service (see docs)
2. **Backup Caddy** - Secondary reverse proxy on Prime
3. **Redundant Tailscale** - Enable on Prime as backup
4. **External HDD** - Monthly media backup

## 💰 Cost Summary

| Item | Cost | Priority |
|------|------|----------|
| **UPS for Agni** | $80 one-time | High |
| **Backblaze B2** | $3/month | Medium |
| **External HDD** | $200 one-time | Low |
| **Backup Agni Device** | $150 one-time | Low |

**Total Initial Investment:** $80-430  
**Monthly Recurring:** $3

## 📚 Documentation Index

### Setup Guides
- [RESILIENCE-PLAN.md](RESILIENCE-PLAN.md) - HA & failover
- [BACKUP-STRATEGY.md](BACKUP-STRATEGY.md) - 3-2-1 backups
- [ADGUARD-SYNC.md](ADGUARD-SYNC.md) - DNS sync
- [MIGRATION.md](MIGRATION.md) - Service migration

### Reference
- [PORT-VALIDATION.md](PORT-VALIDATION.md) - Service ports
- [CADDYFILE-CHANGES.md](CADDYFILE-CHANGES.md) - Proxy config
- [QUICKREF.md](QUICKREF.md) - Quick commands
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design

### Stack Files
- `stacks/agni/` - Agni service stacks
- `stacks/prime/` - Prime service stacks
- `Archive/` - Original multi-stack files

## ✅ Success Criteria

- [x] Individual stack files created
- [x] Documentation comprehensive and actionable
- [x] Resilience plan with SPOF analysis
- [x] Backup strategy with 3-2-1 implementation
- [x] Clear next steps for user
- [ ] User implements DNS failover
- [ ] User deploys Syncthing
- [ ] User purchases UPS
- [ ] User sets up cloud backup

---

**Created:** January 26, 2026  
**Status:** Planning Complete, Ready for Implementation  
**Next Review:** After user implements Phase 1
