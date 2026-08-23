# 🔥 KryNet-Agni Stack - Phase 3 Complete

## 📦 What's Been Created

All files for deploying the KryNet-Agni network core stack have been generated and are ready for deployment.

### File Structure

```
stacks/agni/
├── docker-compose.yml      # Main stack definition
├── Dockerfile              # Caddy with Cloudflare DNS plugin
├── Caddyfile              # Reverse proxy configuration
├── .env.example           # Environment variable template
├── .gitignore             # Prevents committing sensitive data
├── deploy.sh              # Automated deployment script
├── README.md              # Comprehensive setup guide
├── MIGRATION.md           # Step-by-step migration guide
└── QUICKREF.md            # Quick reference for daily ops
```

## 🎯 Stack Components

### Services Included

1. **Portainer** - Container management UI
   - Port: 9443 (HTTPS)
   - Volume: Named volume for data persistence

2. **Caddy** - Reverse proxy with automatic HTTPS
   - Network: `host` mode
   - Custom build with Cloudflare DNS plugin
   - Handles all domain routing

3. **AdGuard Home** - Primary DNS server
   - Network: `host` mode
   - Web UI: Port 3000 (changed from 80)
   - DNS: Port 53 (TCP/UDP)

4. **Home Assistant** - Smart home automation
   - Network: `host` mode
   - Port: 8123
   - Privileged mode for device access

5. **Tailscale** - Mesh VPN
   - Network: `host` mode
   - Subnet router for 192.168.0.0/24
   - Exit node enabled

## 🔧 Key Configuration Details

### Caddy Routing Strategy

**Local Services (on Agni - 127.0.0.1):**
- `adguard.krynet.cc` → `127.0.0.1:3000`
- `ha.krynet.cc` → `127.0.0.1:8123`
- `portainer2.krynet.cc` → `127.0.0.1:9443`

**Remote Services (on Prime - 192.168.0.100):**
- `photos.krynet.cc` → `192.168.0.100:2283` (Immich)
- `media.krynet.cc` → `192.168.0.100:8096` (Jellyfin)
- All *arr stack services
- All monitoring services
- All media automation services

### Network Mode: Host

All services use `network_mode: host` because:
- **Caddy:** Needs to bind to ports 80/443 for reverse proxy
- **AdGuard:** Needs port 53 for DNS
- **Home Assistant:** Needs device discovery via mDNS
- **Tailscale:** Needs to manage routing tables

### AdGuard Port Change

**Important:** AdGuard's web UI has been moved from port 80 to port 3000 to avoid conflict with Caddy.

The deployment script automatically updates this in `AdGuardHome.yaml`:
```yaml
http:
  address: 0.0.0.0:3000  # Changed from 80
```

## 🚀 Deployment Steps

### On Your Local Machine (macOS)

```bash
# Navigate to the repo
cd /Users/kkasbi/Github/home-server/stacks/agni

# Verify files are present
ls -la

# Commit to git (optional but recommended)
git add .
git commit -m "Add KryNet-Agni stack configuration"
git push
```

### On Agni (192.168.0.200)

```bash
# Option 1: Clone the repo (if not already done)
cd ~
git clone <your-repo-url> home-server
cd home-server/stacks/agni

# Option 2: Copy files directly
scp -r /Users/kkasbi/Github/home-server/stacks/agni user@192.168.0.200:~/

# Run the deployment script
cd ~/agni  # or wherever you copied the files
chmod +x deploy.sh
./deploy.sh
```

The deployment script will:
1. ✅ Create directory structure at `~/apps/docker`
2. ✅ Copy stack files to the correct locations
3. ✅ Prompt you to edit `.env` with credentials
4. ✅ Verify migrated data is present
5. ✅ Update AdGuard port to 3000
6. ✅ Build Caddy image with Cloudflare plugin
7. ✅ Launch the stack
8. ✅ Display service status

### Manual Deployment (Alternative)

If you prefer manual control:

```bash
# On Agni
cd ~/apps/docker

# Copy files
cp ~/agni/docker-compose.yml .
cp ~/agni/.env.example .env
mkdir -p caddy
cp ~/agni/Dockerfile caddy/
cp ~/agni/Caddyfile caddy/

# Edit environment variables
nano .env
# Add your CLOUDFLARE_API_TOKEN and TS_AUTHKEY

# Update AdGuard port
nano adguard/conf/AdGuardHome.yaml
# Change 'address: 0.0.0.0:80' to 'address: 0.0.0.0:3000'

# Build and launch
docker compose build caddy
docker compose up -d

# Monitor
docker compose logs -f
```

## 📋 Pre-Deployment Checklist

- [ ] Agni is running Ubuntu Server 24.04 LTS
- [ ] Static IP configured: `192.168.0.200`
- [ ] Docker and Docker Compose installed
- [ ] Data migrated from Prime:
  - [ ] AdGuard config at `~/apps/docker/adguard/conf/`
  - [ ] Home Assistant config at `~/apps/docker/ha/config/`
  - [ ] Caddy data at `~/apps/docker/caddy/data/`
- [ ] Cloudflare API token ready
- [ ] Tailscale auth key ready

## 🧪 Post-Deployment Testing

### 1. Verify Containers
```bash
docker compose ps
# All should show "Up" status
```

### 2. Test Local Access
```bash
# AdGuard
curl http://192.168.0.200:3000

# Home Assistant
curl http://192.168.0.200:8123

# Portainer
curl -k https://192.168.0.200:9443
```

### 3. Test DNS Resolution
```bash
# From any device on the network
nslookup ha.krynet.cc 192.168.0.200
# Should return 192.168.0.200

nslookup photos.krynet.cc 192.168.0.200
# Should return 192.168.0.100 (Prime)
```

### 4. Test Reverse Proxy
```bash
# From a browser, visit:
https://ha.krynet.cc
https://photos.krynet.cc
https://portainer2.krynet.cc
```

### 5. Check SSL Certificates
```bash
# Verify certificates are issued
docker compose exec caddy caddy list-certificates
```

## 🔄 Migration Timeline

### Phase 1: Preparation ✅
- OS installation
- Static IP configuration
- Data migration

### Phase 2: Stack Creation ✅
- Docker Compose configuration
- Caddyfile setup
- Documentation

### Phase 3: Deployment (Current)
- Deploy stack on Agni
- Verify all services
- Test DNS and routing

### Phase 4: DNS Cutover (Next)
- Update router DNS to point to Agni
- Monitor for 24-48 hours
- Verify failover works

### Phase 5: Finalization
- Update Cloudflare Tunnel
- Decommission services on Prime
- Update monitoring dashboards

## 📚 Documentation

- **[README.md](README.md)** - Comprehensive setup guide with troubleshooting
- **[MIGRATION.md](MIGRATION.md)** - Step-by-step migration process with rollback procedures
- **[QUICKREF.md](QUICKREF.md)** - Quick reference for daily operations
- **[.env.example](.env.example)** - Environment variable template

## 🎯 Next Steps

1. **Deploy the stack** on Agni using `deploy.sh`
2. **Verify all services** are running correctly
3. **Test DNS resolution** from various devices
4. **Monitor logs** for 24 hours
5. **Update router DNS** to point to Agni (gradual cutover recommended)
6. **Update Cloudflare Tunnel** configuration
7. **Test external access** via Cloudflare
8. **Verify Tailscale** subnet routing
9. **Decommission services** on Prime once stable
10. **Update documentation** with any learnings

## ⚠️ Important Notes

### Environment Variables
Make sure to set these in `.env`:
- `CLOUDFLARE_API_TOKEN` - For DNS-01 challenge (SSL certificates)
- `TS_AUTHKEY` - For Tailscale authentication

### AdGuard Port
The web UI port **must** be changed to 3000 before starting the stack, otherwise it will conflict with Caddy.

### Data Migration
Ensure all data has been migrated from Prime before deploying. The stack expects:
- `~/apps/docker/adguard/conf/AdGuardHome.yaml`
- `~/apps/docker/ha/config/configuration.yaml`
- `~/apps/docker/caddy/Caddyfile` (will be copied by deploy script)

### Rollback Plan
If anything goes wrong, you can quickly rollback by:
1. Stopping the stack: `docker compose down`
2. Reverting DNS on router to point back to Prime
3. Services will continue running on Prime

## 🎉 Success Criteria

The deployment is successful when:
- ✅ All 5 containers are running (`docker compose ps`)
- ✅ AdGuard web UI accessible at `http://192.168.0.200:3000`
- ✅ Home Assistant accessible at `http://192.168.0.200:8123`
- ✅ Portainer accessible at `https://192.168.0.200:9443`
- ✅ DNS queries resolving correctly
- ✅ Caddy proxying to both local and remote services
- ✅ SSL certificates issued and valid
- ✅ No errors in logs

## 🙏 Credits

Based on the existing KryNet infrastructure running on Prime, adapted for the "Network Core" role on Agni.

---

**Created:** January 26, 2026  
**Status:** Ready for Deployment  
**Target Node:** KryNet-Agni (192.168.0.200)  
**Architecture:** "The Heavy & The Light"
