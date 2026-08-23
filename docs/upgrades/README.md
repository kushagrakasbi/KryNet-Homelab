# 🚀 KryNet Fleet Upgrades & Enhancements History

This directory documents all major version upgrades, database engine migrations, and system enhancements executed across the KryNet 3-node homelab fleet (**🔥 Agni**, **🌟 Prime**, **⚡ Legion**).

---

## 📜 Upgrade History & Changelogs

| Date | Target Node(s) | Upgrade / Migration | Key Changes | Document |
| :--- | :--- | :--- | :--- | :--- |
| **2026-08-23** | 🌟 Prime, ⚡ Legion | **Immich v2 ➔ v3 Upgrade** | Shift from `pgvecto.rs` to **VectorChord** (`vchord.so` + `pgvector`), 87k CLIP + 173k Face vectors reindexed, ValKey 8, Power Tools `latest`, Legion CUDA ML offload | [**2026-08-IMMICH-V3-UPGRADE.md**](2026-08-IMMICH-V3-UPGRADE.md) |
| **2026-08-23** | 🔥 Agni, 🌟 Prime, ⚡ Legion | **3-Node Redesign & Hardware Realignment** | Decommissioned old NUC, provisioned Legion (Ubuntu Server 26.04 Headless + RTX 3060 CUDA), migrated Ingress to Agni Caddy, centralized observability | [**../HOME-SERVER-REDESIGN.md**](../HOME-SERVER-REDESIGN.md) |

---

## 🛡️ Production Upgrade Standard Operating Procedures (SOP)

For all future service and database upgrades:
1. **Application-Level Backup:** Always generate a compressed dump (`pg_dump`, export script, etc.) before making stack changes.
2. **Storage-Level Atomic Snapshot:** Take TrueNAS ZFS atomic dataset snapshots (`midclt call zfs.snapshot.create ...`) on affected datasets.
3. **Stack Configuration Backup:** Back up existing `docker-compose.yml` and `stack.env` before modifying Portainer stacks.
4. **Zero-Downtime / Low-Downtime Execution:** Manage lifecycle strictly via **Portainer Stacks** and verify health using multi-node observability tools (Gatus, Prometheus, cAdvisor).
