# 📚 KryNet-Agni Documentation Index

Welcome to the KryNet-Agni stack documentation! This directory contains all guides and scripts for deploying and managing the network core services on Agni (192.168.0.200).

## 📂 Repository Structure

```
home-server/
├── stacks/agni/              # Stack configuration files
│   ├── docker-compose.yml    # Main stack (Portainer-ready)
│   ├── Dockerfile            # Caddy custom build
│   ├── Caddyfile             # Reverse proxy config
│   ├── .env.example          # Environment template
│   └── README.md             # Stack overview
│
└── docs/agni/                # Documentation & scripts (this directory)
    ├── INDEX.md              # This file
    ├── SUMMARY.md            # Overview & quick start
    ├── README.md             # Comprehensive guide
    ├── ARCHITECTURE.md       # System design
    ├── MIGRATION.md          # Migration procedures
    ├── QUICKREF.md           # Quick reference
    ├── deploy.sh             # Deployment script
    └── validate.sh           # Validation script
```

## 📖 Documentation Guide

### 🚀 Getting Started (Read These First)

1. **[SUMMARY.md](SUMMARY.md)** - Start here!
   - Overview of what's been created
   - Quick deployment instructions
   - Success criteria

2. **[README.md](README.md)** - Comprehensive setup guide
   - Detailed deployment instructions
   - Service configuration details
   - Troubleshooting section

3. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design
   - Network topology diagrams
   - Service distribution
   - Traffic flow examples

### 🔧 Deployment & Operations

4. **[MIGRATION.md](MIGRATION.md)** - Migration guide
   - Step-by-step migration from Prime to Agni
   - Testing checklist
   - Rollback procedures

5. **[QUICKREF.md](QUICKREF.md)** - Quick reference
   - Common commands
   - Service URLs
   - Emergency procedures

### 📁 Configuration Files

6. **[docker-compose.yml](../../stacks/agni/docker-compose.yml)** - Stack definition
   - All 5 services configured
   - Host networking for Caddy, AdGuard, HA, Tailscale
   - Absolute paths for Portainer compatibility

7. **[Dockerfile](../../stacks/agni/Dockerfile)** - Caddy custom build
   - Caddy with Cloudflare DNS plugin
   - Multi-stage build

8. **[Caddyfile](../../stacks/agni/Caddyfile)** - Reverse proxy config
   - Wildcard SSL certificates
   - Routes for local and remote services
   - Cloudflare DNS-01 challenge

9. **[.env.example](../../stacks/agni/.env.example)** - Environment template
   - Required: CLOUDFLARE_API_TOKEN
   - Required: TS_AUTHKEY

### 🛠️ Scripts

10. **[deploy.sh](deploy.sh)** - Automated deployment
    - Creates directory structure
    - Copies files
    - Builds Caddy image
    - Launches stack

11. **[validate.sh](validate.sh)** - Pre-deployment validation
    - Checks system requirements
    - Verifies network configuration
    - Validates migrated data

## 🎯 Quick Navigation by Task

### "I want to deploy Agni for the first time"
1. Read [SUMMARY.md](SUMMARY.md)
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) to understand the setup
3. Follow [MIGRATION.md](MIGRATION.md) for data migration
4. Run `./validate.sh` to check readiness
5. Run `./deploy.sh` to deploy
6. Use [QUICKREF.md](QUICKREF.md) for verification commands

### "I need to troubleshoot an issue"
1. Check [QUICKREF.md](QUICKREF.md) for common commands
2. Review [README.md](README.md) troubleshooting section
3. Consult [MIGRATION.md](MIGRATION.md) for rollback procedures

### "I want to understand the architecture"
1. Read [ARCHITECTURE.md](ARCHITECTURE.md) for visual diagrams
2. Review [Caddyfile](../../stacks/agni/Caddyfile) to see routing logic
3. Check [docker-compose.yml](../../stacks/agni/docker-compose.yml) for service config

### "I need to modify the configuration"
1. Edit [docker-compose.yml](../../stacks/agni/docker-compose.yml) for service changes
2. Edit [Caddyfile](../../stacks/agni/Caddyfile) for routing changes
3. Edit `.env` for credentials
4. Run `docker compose up -d` to apply changes

### "I want to add a new service"
1. Add service to [docker-compose.yml](../../stacks/agni/docker-compose.yml)
2. Add route to [Caddyfile](../../stacks/agni/Caddyfile) if web-accessible
3. Update [README.md](README.md) documentation
4. Redeploy: `docker compose up -d`

## 📊 File Overview

### Documentation Files (this directory)

| File | Lines | Purpose |
|------|-------|---------|
| ARCHITECTURE.md | 380+ | System design and diagrams |
| MIGRATION.md | 385+ | Migration procedures |
| SUMMARY.md | 305+ | Overview and quick start |
| README.md | 241+ | Comprehensive setup guide |
| QUICKREF.md | 229+ | Quick reference |
| INDEX.md | 250+ | This navigation guide |
| deploy.sh | 150+ | Deployment automation |
| validate.sh | 250+ | Pre-deployment checks |

### Stack Files (../../stacks/agni/)

| File | Lines | Purpose |
|------|-------|---------|
| docker-compose.yml | 97 | Stack definition (Portainer-ready) |
| Caddyfile | 224 | Reverse proxy configuration |
| Dockerfile | 11 | Caddy custom build |
| .env.example | 6 | Environment template |

## 🔍 Key Concepts

### The Stack
- **5 Services:** Portainer, Caddy, AdGuard, Home Assistant, Tailscale
- **Network Mode:** All use `host` networking
- **Purpose:** Network core that's always available

### The Architecture
- **"The Heavy & The Light"**
- **Agni (Light):** Network core, low power, always-on
- **Prime (Heavy):** Storage, compute, media, high power

### The Routing
- **Local Services:** Caddy → localhost (Agni)
- **Remote Services:** Caddy → 192.168.0.100 (Prime)
- **Split-Horizon DNS:** Different IPs for LAN vs external

### The Migration
- **Phase 1:** OS setup ✅
- **Phase 2:** Data migration ✅
- **Phase 3:** Stack deployment (current)
- **Phase 4:** DNS cutover (next)
- **Phase 5:** Decommission Prime services

## 🎓 Learning Path

### Beginner
1. Start with [SUMMARY.md](SUMMARY.md)
2. Understand the basics in [README.md](README.md)
3. Follow [deploy.sh](deploy.sh) step-by-step

### Intermediate
1. Study [ARCHITECTURE.md](ARCHITECTURE.md)
2. Review [Caddyfile](Caddyfile) routing logic
3. Understand [docker-compose.yml](docker-compose.yml) configuration

### Advanced
1. Customize [Caddyfile](Caddyfile) for your needs
2. Modify [docker-compose.yml](docker-compose.yml) for additional services
3. Create custom monitoring and alerting

## 🆘 Support Resources

### Documentation
- All `.md` files in this directory
- Inline comments in configuration files
- Main repo [README.md](../../README.md)

### External Resources
- [Caddy Documentation](https://caddyserver.com/docs/)
- [AdGuard Home Wiki](https://github.com/AdguardTeam/AdGuardHome/wiki)
- [Home Assistant Docs](https://www.home-assistant.io/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

### Community
- r/selfhosted on Reddit
- Caddy Community Forum
- Home Assistant Community

## ✅ Pre-Deployment Checklist

Before deploying, ensure:
- [ ] Read [SUMMARY.md](SUMMARY.md)
- [ ] Reviewed [ARCHITECTURE.md](ARCHITECTURE.md)
- [ ] Followed [MIGRATION.md](MIGRATION.md) for data migration
- [ ] Ran `./validate.sh` successfully
- [ ] Created `.env` from `.env.example`
- [ ] Set CLOUDFLARE_API_TOKEN in `.env`
- [ ] Set TS_AUTHKEY in `.env`
- [ ] Verified AdGuard config exists
- [ ] Verified Home Assistant config exists

## 🚀 Deployment Command

```bash
# Validate first
./validate.sh

# Deploy
./deploy.sh

# Or manually
docker compose build caddy
docker compose up -d
docker compose logs -f
```

## 📞 Quick Help

| Issue | See |
|-------|-----|
| Deployment fails | [README.md](README.md) → Troubleshooting |
| DNS not working | [QUICKREF.md](QUICKREF.md) → DNS Resolution |
| SSL errors | [QUICKREF.md](QUICKREF.md) → Check SSL Certificates |
| Need to rollback | [MIGRATION.md](MIGRATION.md) → Rollback Plan |
| Service won't start | [README.md](README.md) → Troubleshooting |

---

**Last Updated:** January 26, 2026  
**Stack Version:** 1.0  
**Target Node:** KryNet-Agni (192.168.0.200)

**Ready to deploy?** Start with [SUMMARY.md](SUMMARY.md)!
