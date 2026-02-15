# 📚 KryNet Documentation Index

**Central navigation for all Krynet Homelab documentation**

---

## 🗺️ Quick Navigation

### Primary Documentation

| Document | Description | Last Updated |
|----------|-------------|--------------|
| [**README.md**](../README.md) | Project overview and architecture | Feb 2026 |
| [**AGNI-SERVER.md**](AGNI-SERVER.md) | 🔥 Network Core (SkullSaints Mini PC) | Feb 2026 |
| [**PRIME-SERVER.md**](PRIME-SERVER.md) | 🌟 Storage Hub (TrueNAS SCALE) | Feb 2026 |

### Quick References

| Document | Description |
|----------|-------------|
| [**NETWORKING-QUICKREF.md**](NETWORKING-QUICKREF.md) | One-page networking guide |

---

## 📁 Documentation Structure

```
docs/
├── INDEX.md                    # This file
├── AGNI-SERVER.md             # 🔥 Network core docs (Mini PC, Primary DNS)
├── PRIME-SERVER.md            # 🌟 Storage hub docs (TrueNAS, ZFS)
└── NETWORKING-QUICKREF.md     # Quick networking reference
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
| Cloudflare Tunnel | [AGNI-SERVER.md](AGNI-SERVER.md) | Network Stack |
| Split-horizon DNS | [AGNI-SERVER.md](AGNI-SERVER.md) | AdGuard Home (Primary DNS) |
| AdGuard Home Sync | [AGNI-SERVER.md](AGNI-SERVER.md) | AdGuard Home (Primary DNS) |
| Tailscale VPN | [AGNI-SERVER.md](AGNI-SERVER.md) | Tailscale VPN |
| ZFS storage | [PRIME-SERVER.md](PRIME-SERVER.md) | Storage Architecture |
| ZFS scrubs & snapshots | [PRIME-SERVER.md](PRIME-SERVER.md) | Data Integrity & Maintenance |
| SMART tests | [PRIME-SERVER.md](PRIME-SERVER.md) | Data Integrity & Maintenance |
| Media stack (*arr) | [PRIME-SERVER.md](PRIME-SERVER.md) | Media Automation Stack |
| Immich photos | [PRIME-SERVER.md](PRIME-SERVER.md) | Photo Management |
| Audiobookshelf | [PRIME-SERVER.md](PRIME-SERVER.md) | Audiobookshelf |
| Monitoring | [AGNI-SERVER.md](AGNI-SERVER.md) | Monitoring Stack |
| Backups (RClone) | Both server docs | Backup Configuration |

### By Task

| Task | Document | Section |
|------|----------|---------|
| Add new service | [AGNI-SERVER.md](AGNI-SERVER.md) | Caddy configuration |
| Troubleshoot DNS | [NETWORKING-QUICKREF.md](NETWORKING-QUICKREF.md) | Troubleshooting |
| Check service status | [AGNI-SERVER.md](AGNI-SERVER.md) | Maintenance |
| Restore from backup | Server docs | Backup Configuration |
| View container logs | [NETWORKING-QUICKREF.md](NETWORKING-QUICKREF.md) | Common Operations |
| Check ZFS health | [PRIME-SERVER.md](PRIME-SERVER.md) | ZFS Commands |

---

## 🔗 External Resources

### Stack Files

| Location | Contents |
|----------|----------|
| [stacks/agni/](../stacks/agni) | Agni Docker Compose files |
| [stacks/prime/](../stacks/prime) | Prime Docker Compose files |

---

## 📆 Document History

| Date | Change |
|------|--------|
| Feb 2026 | Updated all docs: corrected hardware specs, storage pools, AdGuard DNS roles, added data integrity details |
| Feb 2026 | Created AGNI-SERVER.md, PRIME-SERVER.md, consolidated README.md |
| Jan 2026 | Initial documentation structure |

---

**Maintained by:** Krynet Homelab  
**Repository:** [KryNet-Homelab](https://github.com/kushagrakasbi/KryNet-Homelab)
