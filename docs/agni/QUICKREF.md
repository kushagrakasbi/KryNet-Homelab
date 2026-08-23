# KryNet-Agni Quick Reference

## 🚀 Quick Start

```bash
cd ~/apps/docker
docker compose up -d
```

## 📊 Service URLs

| Service | URL | Port |
|---------|-----|------|
| Portainer | https://192.168.0.200:9443 | 9443 |
| AdGuard Home | http://192.168.0.200:3000 | 3000 |
| Home Assistant | http://192.168.0.200:8123 | 8123 |
| Caddy (HTTP) | http://192.168.0.200:80 | 80 |
| Caddy (HTTPS) | https://192.168.0.200:443 | 443 |

## 🔧 Common Commands

### Container Management
```bash
# View status
docker compose ps

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f caddy
docker compose logs -f adguardhome
docker compose logs -f homeassistant

# Restart a service
docker compose restart caddy

# Stop all services
docker compose down

# Start all services
docker compose up -d

# Rebuild Caddy image
docker compose build caddy
docker compose up -d caddy
```

### Updates
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

### Backup
```bash
# Backup entire config
tar -czf ~/agni-backup-$(date +%Y%m%d).tar.gz ~/apps/docker

# Backup specific service
tar -czf ~/adguard-backup-$(date +%Y%m%d).tar.gz ~/apps/docker/adguard
```

## 🐛 Troubleshooting

### Check if ports are in use
```bash
sudo ss -tulpn | grep ':80\|:443\|:53\|:3000\|:8123'
```

### Check DNS resolution
```bash
# Test AdGuard DNS
dig @192.168.0.200 ha.krynet.cc

# Test from localhost
nslookup ha.krynet.cc 127.0.0.1
```

### Check Caddy configuration
```bash
# Validate Caddyfile
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload Caddy config
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Check SSL certificates
```bash
# List certificates
docker compose exec caddy caddy list-certificates

# Check certificate expiry
openssl s_client -connect ha.krynet.cc:443 -servername ha.krynet.cc | openssl x509 -noout -dates
```

### System resources
```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check Docker disk usage
docker system df

# Clean up unused Docker resources
docker system prune -a
```

## 🔐 Environment Variables

Located in: `~/apps/docker/.env`

```bash
CLOUDFLARE_API_TOKEN=your_token_here
TS_AUTHKEY=your_tailscale_key_here
```

## 📝 Configuration Files

| Service | Config Location |
|---------|----------------|
| Caddy | `~/apps/docker/caddy/Caddyfile` |
| AdGuard | `~/apps/docker/adguard/conf/AdGuardHome.yaml` |
| Home Assistant | `~/apps/docker/ha/config/configuration.yaml` |
| Tailscale | `~/apps/docker/tailscale/` |

## 🔄 Service Dependencies

```
Caddy → AdGuard (for DNS resolution)
Home Assistant → (independent)
Tailscale → (independent)
Portainer → (independent)
```

## 🚨 Emergency Procedures

### Complete Stack Failure
```bash
# Stop everything
docker compose down

# Check system resources
df -h && free -h

# Restart
docker compose up -d

# Monitor logs
docker compose logs -f
```

### DNS Not Working
```bash
# Restart AdGuard
docker compose restart adguardhome

# Check if port 53 is available
sudo ss -tulpn | grep :53

# Fallback: Use Cloudflare DNS temporarily
# Set router DNS to 1.1.1.1
```

### Caddy SSL Issues
```bash
# Check Cloudflare API token
docker compose exec caddy env | grep CLOUDFLARE

# Delete certificates and force renewal
docker compose down
rm -rf ~/apps/docker/caddy/data/caddy/certificates
docker compose up -d

# Monitor renewal
docker compose logs -f caddy
```

## 📊 Monitoring

### Health Checks
```bash
# Check all containers are running
docker compose ps | grep -v "Up"

# Check container health
docker ps --filter "health=unhealthy"

# Check recent container restarts
docker ps --filter "status=restarting"
```

### Performance
```bash
# Container resource usage
docker stats

# System load
uptime

# Network connections
sudo ss -s
```

## 🔗 Useful Links

- [Caddy Documentation](https://caddyserver.com/docs/)
- [AdGuard Home Wiki](https://github.com/AdguardTeam/AdGuardHome/wiki)
- [Home Assistant Docs](https://www.home-assistant.io/docs/)
- [Tailscale Docs](https://tailscale.com/kb/)

## 📞 Support

- Check logs first: `docker compose logs -f`
- Review [MIGRATION.md](MIGRATION.md) for troubleshooting
- Consult [README.md](README.md) for detailed setup
- Rollback if needed: See MIGRATION.md

---

**Last Updated:** January 2026  
**Node:** KryNet-Agni (192.168.0.200)
