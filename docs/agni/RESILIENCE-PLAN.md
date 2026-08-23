# KryNet Resilience & High Availability Plan

## 🎯 Architecture Overview

**Current Setup:** "The Heavy & The Light"
- **Agni (Sentinel):** Network core, always-on, low power (15W)
- **Prime (Data Plane):** Storage, compute, media, high power (150W)

## 🔍 Current State Analysis

### Enabled Services

#### Agni (192.168.0.200) - Always Running
| Service | Purpose | Critical? | SPOF? |
|---------|---------|-----------|-------|
| **Caddy** | Reverse proxy, SSL termination | ✅ Yes | ✅ Yes |
| **AdGuard Home** | Primary DNS, ad blocking | ✅ Yes | ✅ Yes |
| **AdGuard Sync** | DNS config sync from Prime | ⚠️ Nice-to-have | No |
| **Home Assistant** | Smart home automation | ✅ Yes | ✅ Yes |
| **Portainer** | Container management | ⚠️ Nice-to-have | No |
| **Tailscale** | VPN mesh, subnet router | ✅ Yes | ⚠️ Partial |

#### Prime (192.168.0.100) - On-Demand
| Service | Purpose | Critical? | SPOF? |
|---------|---------|-----------|-------|
| **Cloudflared** | Cloudflare Tunnel | ✅ Yes | ✅ Yes |
| **Immich** | Photo management | ⚠️ Important | Yes |
| **Jellyfin** | Media server | ⚠️ Nice-to-have | Yes |
| **Media Stack** | *arr automation | ⚠️ Nice-to-have | Yes |
| **Monitoring** | Uptime Kuma, Prometheus, etc. | ⚠️ Important | Yes |
| **Dashboards** | Homepage, Homarr | ⚠️ Nice-to-have | No |
| **Speedtest** | Network testing | ⚠️ Nice-to-have | No |

### Single Points of Failure (SPOF)

| Component | Impact if Failed | Mitigation |
|-----------|------------------|------------|
| **Agni Server** | Complete network failure | UPS, hardware redundancy |
| **Caddy on Agni** | No SSL/proxy access | Secondary proxy on Prime |
| **AdGuard on Agni** | No DNS resolution | Secondary DNS (Cloudflare 1.1.1.1) |
| **Prime Server** | No storage/media/photos | Backups to Agni + Cloud |
| **Internet Connection** | No external access | Tailscale failover, mobile hotspot |
| **Power** | Everything offline | UPS for Agni (critical) |

## 🛡️ Resilience Improvements

### Priority 1: Critical Infrastructure (Implement First)

#### 1.1 DNS Failover
**Problem:** If Agni fails, no DNS resolution

**Solution:**
```yaml
# Router DNS Configuration
Primary DNS: 192.168.0.200 (Agni - AdGuard)
Secondary DNS: 1.1.1.1 (Cloudflare)
Tertiary DNS: 8.8.8.8 (Google)
```

**Benefits:**
- Automatic failover if Agni is down
- No split-horizon DNS on fallback (acceptable for emergency)

#### 1.2 Reverse Proxy Redundancy
**Problem:** If Caddy on Agni fails, no HTTPS access

**Solution:** Deploy secondary Caddy on Prime
```bash
# On Prime, create backup Caddy stack
# Only enable if Agni fails
# Use different ports initially: 8080/8443
```

**Failover Process:**
1. Detect Caddy failure on Agni
2. Start Caddy on Prime
3. Update DNS to point to Prime temporarily
4. Restore Agni, switch back

#### 1.3 Power Protection
**Problem:** Power outage kills everything

**Solution:**
- **Agni:** UPS (minimum 30 minutes runtime)
  - APC Back-UPS 600VA (~$80)
  - Graceful shutdown script
- **Prime:** Optional UPS or accept downtime
  - Media/storage can wait
  - Focus budget on Agni protection

### Priority 2: Data Protection (Implement Second)

#### 2.1 Configuration Backup
**Problem:** Losing Docker configs means complete rebuild

**Solution:** Syncthing bidirectional sync

**Agni → Prime Backup:**
```
/home/agni/apps/docker/ → /mnt/andromeda/backups/agni-config/
```

**Prime → Agni Backup:**
```
/mnt/orion/apps-config/ → /home/agni/backups/prime-config/
```

**Frequency:** Real-time sync
**Retention:** Keep 30 days of versions

#### 2.2 Critical Data Backup
**Problem:** Photo/document loss is unacceptable

**3-2-1 Backup Strategy:**
- **3 Copies:** Live (Prime) + Backup (Agni) + Cloud (Backblaze B2)
- **2 Media:** HDD (Prime) + SSD (Agni if space allows)
- **1 Offsite:** Encrypted cloud backup

**Implementation:**
```
Immich Photos:
├─ Live: /mnt/andromeda/apps/immich/ (Prime)
├─ Backup: /home/agni/backups/immich/ (Agni - via Syncthing)
└─ Cloud: Backblaze B2 (via rclone cron)

Paperless Documents:
├─ Live: /mnt/andromeda/apps/paperless/ (Prime)
├─ Backup: /home/agni/backups/paperless/ (Agni - via Syncthing)
└─ Cloud: Backblaze B2 (via rclone cron)
```

### Priority 3: Monitoring & Alerting (Implement Third)

#### 3.1 Health Monitoring
**Deploy on Agni:**
- Uptime Kuma (already on Prime, add to Agni)
- Monitor critical services:
  - Caddy (HTTPS check)
  - AdGuard (DNS query check)
  - Home Assistant (HTTP check)
  - Tailscale (ping check)

#### 3.2 Alert Channels
**Setup:**
- Gotify (self-hosted notifications)
- Email alerts (Gmail SMTP)
- Telegram bot (optional)

**Alert on:**
- Service down > 2 minutes
- Disk usage > 80%
- Memory usage > 90%
- CPU temp > 75°C (if available)

### Priority 4: Network Resilience (Implement Fourth)

#### 4.1 Tailscale Mesh Redundancy
**Current:** Single Tailscale on Agni

**Improvement:**
- Keep Tailscale on Agni (primary subnet router)
- Enable Tailscale on Prime (backup subnet router)
- Both advertise 192.168.0.0/24
- Tailscale automatically fails over

#### 4.2 Cloudflare Tunnel Redundancy
**Current:** Single tunnel on Prime

**Improvement:**
- Primary tunnel on Prime
- Backup tunnel on Agni (disabled, ready to enable)
- Same tunnel token, different connectors
- Cloudflare automatically load balances

## 📋 Failover Scenarios

### Scenario 1: Agni Complete Failure

**Impact:**
- ❌ No DNS (until router fails over to 1.1.1.1)
- ❌ No reverse proxy (no HTTPS access to services)
- ❌ No Home Assistant
- ✅ Prime services still running (direct IP access)
- ✅ Tailscale still works (via Prime)

**Recovery Steps:**
1. Router automatically fails over DNS to 1.1.1.1
2. Access services via Tailscale or direct IP
3. Enable backup Caddy on Prime (if configured)
4. Fix/replace Agni hardware
5. Restore from backups

**RTO (Recovery Time Objective):** 1-2 hours
**RPO (Recovery Point Objective):** 0 (real-time sync)

### Scenario 2: Prime Complete Failure

**Impact:**
- ✅ Network still works (Agni handles DNS/proxy)
- ❌ No photos, documents, media
- ❌ No media automation
- ❌ No monitoring dashboards
- ✅ Critical services (DNS, HA) still work

**Recovery Steps:**
1. Network continues functioning normally
2. Access backed-up photos on Agni (read-only)
3. Fix/replace Prime hardware
4. Restore from Agni backups + cloud

**RTO:** 4-8 hours (hardware dependent)
**RPO:** < 1 hour (Syncthing sync interval)

### Scenario 3: Internet Outage

**Impact:**
- ✅ Local network fully functional
- ❌ No external access
- ❌ No Cloudflare Tunnel
- ⚠️ Tailscale works (LAN only)

**Mitigation:**
- All services accessible via LAN
- Mobile hotspot as backup internet
- Tailscale can route through mobile

### Scenario 4: Power Outage

**With UPS on Agni:**
- ✅ Agni runs for 30+ minutes
- ✅ Graceful shutdown if extended
- ❌ Prime shuts down immediately
- ✅ Network core survives short outages

**Without UPS:**
- ❌ Everything offline
- ⚠️ Risk of data corruption
- **Recommendation:** UPS for Agni is critical

## 🎯 Implementation Roadmap

### Phase 1: Immediate (This Week)
- [ ] Configure router DNS failover (1.1.1.1 secondary)
- [ ] Deploy Syncthing on both Agni and Prime
- [ ] Configure config backup sync
- [ ] Test DNS failover manually

### Phase 2: Short Term (This Month)
- [ ] Purchase UPS for Agni
- [ ] Configure graceful shutdown scripts
- [ ] Set up Uptime Kuma on Agni
- [ ] Configure Gotify alerts
- [ ] Test Agni failure scenario

### Phase 3: Medium Term (Next 3 Months)
- [ ] Implement 3-2-1 backup for photos
- [ ] Set up Backblaze B2 integration
- [ ] Deploy backup Caddy on Prime (disabled)
- [ ] Enable Tailscale on Prime (backup)
- [ ] Document all recovery procedures

### Phase 4: Long Term (Next 6 Months)
- [ ] Consider second Agni-class device (Pi 5?)
- [ ] Implement automated failover scripts
- [ ] Set up off-site backup location
- [ ] Regular disaster recovery drills

## 📊 Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| **Network Uptime** | ~99% | 99.9% |
| **DNS Failover Time** | Manual | < 30 seconds |
| **Data Loss (RPO)** | Unknown | < 1 hour |
| **Recovery Time (RTO)** | Unknown | < 4 hours |
| **Backup Coverage** | Partial | 100% critical data |

## 💰 Cost Estimate

| Item | Cost | Priority |
|------|------|----------|
| UPS for Agni (600VA) | $80 | High |
| Backblaze B2 (500GB) | $3/month | Medium |
| Backup Agni Device (Pi 5) | $150 | Low |
| **Total Initial** | **$80-230** | - |
| **Monthly** | **$3** | - |

---

**Last Updated:** January 26, 2026  
**Next Review:** February 26, 2026  
**Owner:** Infrastructure Team
