# 📚 KryNet Documentation Index

**Central navigation for all Krynet Homelab documentation**

---

## 🗺️ Quick Navigation

### Primary Documentation

| Document | Description | Last Updated |
|----------|-------------|--------------|
| [**README.md**](../README.md) | Project overview and architecture | Feb 2026 |
| [**AGNI-SERVER.md**](AGNI-SERVER.md) | 🔥 Network Core documentation | Feb 2026 |
| [**PRIME-SERVER.md**](PRIME-SERVER.md) | 🌟 Storage Hub documentation | Feb 2026 |

### Technical Deep Dives

| Document | Description | Lines |
|----------|-------------|-------|
| [**networking.md**](networking.md) | Complete networking architecture | 1135 |
| [**services.md**](services.md) | Service configuration guide | 1027 |

### Quick References

| Document | Description |
|----------|-------------|
| [**NETWORKING-QUICKREF.md**](NETWORKING-QUICKREF.md) | One-page networking guide |

---

## 📁 Documentation Structure

```
docs/
├── INDEX.md                    # This file
├── AGNI-SERVER.md             # 🔥 Network core docs
├── PRIME-SERVER.md            # 🌟 Storage hub docs  
├── NETWORKING-QUICKREF.md     # Quick networking reference
├── networking.md              # Deep dive: networking
├── services.md                # Deep dive: services
└── agni/                      # Legacy Agni documentation
    ├── INDEX.md
    ├── ARCHITECTURE.md
    ├── BACKUP-STRATEGY.md
    ├── MIGRATION.md
    ├── RESILIENCE-PLAN.md
    └── ...
```

---

## 🎯 Find What You Need

### By Server

| Need | Document |
|------|----------|
| Agni configuration | [AGNI-SERVER.md](AGNI-SERVER.md) |
| Prime configuration | [PRIME-SERVER.md](PRIME-SERVER.md) |
| Stack files | [stacks/agni/](../stacks/agni) or [stacks/prime/](../stacks/prime) |

### By Topic

| Topic | Document | Section |
|-------|----------|---------|
| Caddy reverse proxy | [AGNI-SERVER.md](AGNI-SERVER.md) | Network Stack |
| Cloudflare Tunnel | [networking.md](networking.md) | Cloudflare Tunnel Deep Dive |
| Split-horizon DNS | [networking.md](networking.md) | Split-Horizon DNS Architecture |
| Tailscale VPN | [networking.md](networking.md) | Tailscale Mesh VPN |
| ZFS storage | [PRIME-SERVER.md](PRIME-SERVER.md) | Storage Architecture |
| Media stack (*arr) | [PRIME-SERVER.md](PRIME-SERVER.md) | Media Automation Stack |
| Immich photos | [PRIME-SERVER.md](PRIME-SERVER.md) | Photo Management |
| Monitoring | [AGNI-SERVER.md](AGNI-SERVER.md) | Monitoring Stack |
| Backups | Both server docs | Backup Configuration |

### By Task

| Task | Document | Section |
|------|----------|---------|
| Add new service | [networking.md](networking.md) | Caddy configuration |
| Troubleshoot DNS | [NETWORKING-QUICKREF.md](NETWORKING-QUICKREF.md) | Troubleshooting |
| Check service status | [AGNI-SERVER.md](AGNI-SERVER.md) | Maintenance |
| Restore from backup | Server docs | Backup Configuration |
| View container logs | [NETWORKING-QUICKREF.md](NETWORKING-QUICKREF.md) | Common Operations |

---

## 🔗 External Resources

### Stack Files

| Location | Contents |
|----------|----------|
| [stacks/agni/](../stacks/agni) | Agni Docker Compose files |
| [stacks/prime/](../stacks/prime) | Prime Docker Compose files |

### Configuration Files

| Location | Contents |
|----------|----------|
| [config/caddy/](../config/caddy) | Caddyfile |
| [config/homepage/](../config/homepage) | Homepage dashboard config |

---

## 📆 Document History

| Date | Change |
|------|--------|
| Feb 2026 | Created AGNI-SERVER.md, PRIME-SERVER.md, consolidated README.md |
| Jan 2026 | Updated networking.md and services.md |
| Jan 2025 | Initial documentation structure |

---

**Maintained by:** Krynet Homelab  
**Repository:** [home-server](https://github.com/yourusername/home-server)
