# 📋 KryNet Fleet Strategic & Architecture Plans

This directory contains comprehensive architectural plans, security assessments, and infrastructure migration blueprints for the KryNet 3-node homelab cluster (**🔥 Agni**, **🌟 Prime**, **⚡ Legion**).

---

## 🗺️ Active & Proposed Plans

| Date | Category | Plan Document | Status | Summary |
| :--- | :--- | :--- | :--- | :--- |
| **2026-08-23** | **Roadmap & Enhancements** | [**2026-08-FLEET-ROADMAP-AND-ENHANCEMENTS.md**](2026-08-FLEET-ROADMAP-AND-ENHANCEMENTS.md) | 🟡 **ACTIVE BLUEPRINT** | Master roadmap for 3-2-1 Backups & Disaster Recovery, Multi-Node Observability & Mobile Alerting, and Media Pipeline Optimization (Gluetun, Tdarr, Jellystat) |
| **2026-08-23** | **Networking & Security** | [**2026-08-NETWORKING-ARCHITECTURE-PLAN.md**](2026-08-NETWORKING-ARCHITECTURE-PLAN.md) | 🟢 **EXECUTED & VERIFIED** | Comprehensive network audit, Legion Tailscale remediation, Cloudflare/Tailscale CLI & API access integration, and Zero-Trust Private Mesh migration (decommissioned public Cloudflared) |

---

## 🛡️ Planning & Execution Methodology

Every plan in this directory follows KryNet's production engineering standard:
1. **Live State Validation:** Direct audit of all active network sockets, DNS resolvers, and daemon configs across the 3 physical nodes.
2. **Impact & Risk Assessment:** Detailed service-by-service analysis (mobile apps, webhooks, media streaming, auth).
3. **Phased Execution:** Pre-flight backups ➔ Staged rollout ➔ Multi-node verification ➔ Instant rollback strategy.
4. **Agentic Automation:** Providing scriptable CLI and API interfaces for coding agents on Mac and server nodes.
