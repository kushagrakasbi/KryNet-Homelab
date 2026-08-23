# Migration Guide: Prime → Agni

This guide documents the process of migrating network core services from KryNet-Prime (192.168.0.100) to KryNet-Agni (192.168.0.200).

## 📋 Pre-Migration Checklist

- [x] Agni OS installed (Ubuntu Server 24.04 LTS)
- [x] Static IP configured (192.168.0.200)
- [x] Docker and Docker Compose installed
- [x] Directory structure created (`~/apps/docker`)
- [x] Data migrated from Prime via SCP
- [x] Permissions fixed on migrated files

## 🔄 Services Being Migrated

| Service | Current (Prime) | Target (Agni) | Reason |
|---------|----------------|---------------|--------|
| **Caddy** | 192.168.0.100 | 192.168.0.200 | Central reverse proxy |
| **AdGuard Home** | 192.168.0.100 | 192.168.0.200 | Primary DNS server |
| **Home Assistant** | 192.168.0.100 | 192.168.0.200 | Smart home hub |
| **Tailscale** | 192.168.0.100 | 192.168.0.200 | VPN mesh network |

## 📦 Data Migration Steps (Already Completed)

### 1. AdGuard Home

```bash
# On Prime (TrueNAS)
cd /mnt/orion/apps-config
tar -czf adguard-backup.tar.gz adguardhome/

# Transfer to Agni
scp adguard-backup.tar.gz user@192.168.0.200:~/

# On Agni
cd ~/apps/docker
tar -xzf ~/adguard-backup.tar.gz
mv adguardhome adguard
chown -R $USER:$USER adguard/
```

### 2. Home Assistant

```bash
# On Prime
cd /mnt/orion/apps-config
tar -czf ha-backup.tar.gz homeassistant/

# Transfer to Agni
scp ha-backup.tar.gz user@192.168.0.200:~/

# On Agni
cd ~/apps/docker
tar -xzf ~/ha-backup.tar.gz
mv homeassistant ha
chown -R $USER:$USER ha/
```

### 3. Caddy

```bash
# On Prime
cd /mnt/orion/apps-config
tar -czf caddy-backup.tar.gz caddy/

# Transfer to Agni
scp caddy-backup.tar.gz user@192.168.0.200:~/

# On Agni
cd ~/apps/docker
tar -xzf ~/caddy-backup.tar.gz
chown -R $USER:$USER caddy/
```

## 🚀 Deployment Process

### Step 1: Deploy Stack on Agni

```bash
# On Agni
cd ~/apps/docker

# Run the deployment script
./deploy.sh

# Or manually:
docker compose build caddy
docker compose up -d
```

### Step 2: Verify Services

```bash
# Check container status
docker compose ps

# Check logs
docker compose logs -f

# Test individual services
curl http://localhost:3000  # AdGuard
curl http://localhost:8123  # Home Assistant
curl http://localhost:80    # Caddy
```

### Step 3: Update DNS Configuration

#### Option A: Gradual Migration (Recommended)

1. **Add Agni as Secondary DNS** on router:
   - Primary DNS: `192.168.0.100` (Prime)
   - Secondary DNS: `192.168.0.200` (Agni)

2. **Test from a single device**:
   ```bash
   # Set DNS to 192.168.0.200 only
   nslookup ha.krynet.cc 192.168.0.200
   ```

3. **Monitor for 24 hours** - Check logs on both nodes

4. **Swap DNS priority**:
   - Primary DNS: `192.168.0.200` (Agni)
   - Secondary DNS: `192.168.0.100` (Prime)

5. **Monitor for another 24 hours**

6. **Remove Prime DNS** once stable

#### Option B: Direct Cutover

1. **Update router DHCP settings**:
   - Primary DNS: `192.168.0.200`
   - Secondary DNS: `1.1.1.1` (Cloudflare fallback)

2. **Flush DNS cache on all devices**:
   ```bash
   # macOS
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
   
   # Windows
   ipconfig /flushdns
   
   # Linux
   sudo systemd-resolve --flush-caches
   ```

### Step 4: Update Cloudflare Tunnel

1. **Log into Cloudflare Zero Trust dashboard**

2. **Update tunnel configuration**:
   - Old: `http://192.168.0.100:80`
   - New: `http://192.168.0.200:80`

3. **Test external access**:
   ```bash
   curl https://ha.krynet.cc
   curl https://photos.krynet.cc
   ```

### Step 5: Update Tailscale

1. **Verify Agni is advertising subnet**:
   ```bash
   tailscale status
   ```

2. **Approve subnet routes** in Tailscale admin console

3. **Test VPN access**:
   ```bash
   # From remote device on Tailscale
   curl http://192.168.0.200:3000  # AdGuard
   ```

## 🧪 Testing Checklist

### DNS Resolution
- [ ] `nslookup ha.krynet.cc 192.168.0.200` returns correct IP
- [ ] `nslookup photos.krynet.cc 192.168.0.200` returns `192.168.0.100`
- [ ] Ad blocking is working (test with ad-heavy site)
- [ ] Split-horizon DNS working (LAN vs external)

### Reverse Proxy (Caddy)
- [ ] `https://ha.krynet.cc` accessible from LAN
- [ ] `https://photos.krynet.cc` proxies to Prime correctly
- [ ] SSL certificates are valid (check browser)
- [ ] HTTP/3 is working (check in browser DevTools)

### Home Assistant
- [ ] Web UI accessible at `http://192.168.0.200:8123`
- [ ] All devices discovered and working
- [ ] Automations still functioning
- [ ] Mobile app can connect

### AdGuard Home
- [ ] Web UI accessible at `http://192.168.0.200:3000`
- [ ] DNS queries being logged
- [ ] Filters and blocklists active
- [ ] Custom DNS rewrites working

### Tailscale
- [ ] Subnet routes advertised (`192.168.0.0/24`)
- [ ] Exit node working
- [ ] MagicDNS resolving correctly
- [ ] Can access LAN services remotely

## 🔙 Rollback Plan

If issues arise, you can quickly rollback:

### Quick Rollback (DNS Only)

```bash
# On router, change DNS back to:
Primary DNS: 192.168.0.100
Secondary DNS: 1.1.1.1
```

### Full Rollback (Stop Agni Services)

```bash
# On Agni
cd ~/apps/docker
docker compose down

# Services will automatically fail over to Prime
```

### Emergency Rollback (Cloudflare Tunnel)

1. Log into Cloudflare Zero Trust
2. Change tunnel target back to `192.168.0.100:80`
3. External access restored immediately

## 📊 Monitoring During Migration

### Key Metrics to Watch

1. **DNS Query Success Rate**
   - Check AdGuard dashboard on both nodes
   - Should be >99.9%

2. **Service Response Times**
   - Use Uptime Kuma to monitor
   - Alert if >500ms response time

3. **Container Health**
   ```bash
   watch -n 5 'docker compose ps'
   ```

4. **System Resources**
   ```bash
   htop  # Watch RAM/CPU usage
   df -h # Watch disk space
   ```

### Log Monitoring

```bash
# Watch all services
docker compose logs -f

# Watch specific service
docker compose logs -f caddy
docker compose logs -f adguardhome

# Check for errors
docker compose logs | grep -i error
```

## 🎯 Post-Migration Tasks

### Immediate (Day 1)
- [ ] Monitor logs continuously
- [ ] Test all critical services
- [ ] Verify DNS resolution across all devices
- [ ] Check SSL certificate renewal

### Short-term (Week 1)
- [ ] Monitor uptime and performance
- [ ] Verify backup jobs are running
- [ ] Test failover scenarios
- [ ] Update documentation

### Long-term (Month 1)
- [ ] Decommission services on Prime
- [ ] Update monitoring dashboards
- [ ] Optimize resource allocation
- [ ] Plan for Agni hardware upgrade (SkullSaints Mini-PC)

## 🛠️ Troubleshooting

### Issue: DNS not resolving

**Symptoms:** Domains not resolving, timeouts

**Solution:**
```bash
# Check AdGuard is listening
sudo ss -tulpn | grep :53

# Check AdGuard logs
docker compose logs adguardhome | tail -50

# Test DNS directly
dig @192.168.0.200 ha.krynet.cc
```

### Issue: Caddy SSL errors

**Symptoms:** Certificate errors, HTTPS not working

**Solution:**
```bash
# Check Cloudflare API token
docker compose exec caddy env | grep CLOUDFLARE

# Force certificate renewal
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# Check Caddy logs
docker compose logs caddy | grep -i error
```

### Issue: Home Assistant devices offline

**Symptoms:** Smart devices not responding

**Solution:**
```bash
# Verify host networking
docker compose exec homeassistant ip addr

# Check mDNS/Avahi
sudo systemctl status avahi-daemon

# Restart Home Assistant
docker compose restart homeassistant
```

### Issue: Tailscale not advertising routes

**Symptoms:** Can't access LAN from VPN

**Solution:**
```bash
# Check Tailscale status
docker compose exec tailscale tailscale status

# Verify routes in Tailscale admin console
# Approve subnet routes if needed

# Restart Tailscale
docker compose restart tailscale
```

## 📝 Notes

- **Downtime:** Expect 5-10 minutes during DNS cutover
- **Testing Window:** Allow 24-48 hours for thorough testing
- **Backup:** All original configs backed up on Prime
- **Support:** Monitor r/selfhosted and Caddy forums for issues

## ✅ Success Criteria

Migration is considered successful when:

1. ✅ All services running on Agni for 48+ hours
2. ✅ No DNS resolution failures
3. ✅ SSL certificates auto-renewing
4. ✅ Home Assistant devices all online
5. ✅ External access via Cloudflare Tunnel working
6. ✅ Tailscale VPN fully functional
7. ✅ No increase in error rates or latency
8. ✅ Family members report no issues (WAF test passed!)

---

**Migration Date:** TBD  
**Estimated Duration:** 2-4 hours  
**Risk Level:** Medium (can rollback quickly)  
**Prepared by:** Kushagra Kasbi
