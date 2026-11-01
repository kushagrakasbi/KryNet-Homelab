# 🗺️ Overall plan — KryNet home server

**Last updated:** 2026-10-07. Current state and the live queue are in [`HANDOFF.md`](HANDOFF.md); this
file is the *why* behind the order.

## Principles that set the order

1. **Know before you change.** Every change starts from a measurement and ends with one. Most of this
   year's expensive bugs were things that *looked* fine: a green check over a dead function, an empty
   result read as success, a doc that described intent rather than reality.
2. **Data safety, then reachability, then observability, then hygiene, then features.** A broken backup
   outranks a pretty dashboard; an alert that cannot fire outranks a new service.
3. **Reversible by default.** Record the rollback target before acting, change one stack at a time,
   stop on the first failure.
4. **One source of truth per fact.** Repo files are *intent*; the live fleet is *reality*; `drift-check.sh`
   is how the two are reconciled. Docs follow the code, never the other way round.

---

## 1. The fleet in one paragraph

Three nodes on the home LAN: **Agni** (`192.168.0.200`, Ubuntu) is the ingress (Caddy), DNS (AdGuard
primary), Home Assistant, monitoring (Gatus, Prometheus, Grafana, Healthchecks, Gotify) and Portainer
for itself and Legion. **Prime** (`192.168.0.100`, TrueNAS SCALE) holds the ZFS pools (`orion`,
`andromeda`), media (*arr, Jellyfin, Tdarr server), Immich, Paperless, AdGuard secondary and **nucleus**
(personal finance, production data). **Legion** (`192.168.0.150`, a Lenovo laptop running Ubuntu) is
the GPU node (RTX 3060 Laptop, 6 GB): Ollama, LiteLLM, OpenWebUI, Immich ML, Frigate, subgen, Tdarr
node. External access is **Tailscale only** — Cloudflare tunnels are deliberately disabled. Every
service answers on three names: `*.lan.kkasbi.in`, `*.kkasbi.in` and `*.krynet.cc` (the last kept for
mobile-app backward compatibility). Full detail: `AGENTS.md`, `docs/*-SERVER.md`.

---

## 2. Done — and the reason each one mattered

| When | What | Why it mattered | PRs |
|---|---|---|---|
| 2026-09-03 | Smart-home inventory + label contract; Frigate repaired (detect on substream) | Every later smart-home change rests on the label contract | #39–#41 |
| 2026-08 | Fleet audit, 6-phase plan, 12 review tracks | Measured inventory — 70 containers, 49 routes — so work starts from fact | — |
| 2026-09-03 → 21 | **Phase 1 reclaim:** 137 GB of Tdarr scratch + dangling images | `orion` 76 % → 70 %, 540 GB free. Freed only as ZFS snapshots aged out — deleting files freed nothing at first | #42 |
| 2026-09 | **Ghost Portainer stacks** archived then deleted (12) | Phantom stacks made every inventory wrong | #43 |
| 2026-09 | **19 secrets moved out of git**; every reference → `lan.kkasbi.in` | Credentials were literal in committed files (history still needs rotation) | #44–#46 |
| 2026-09-20 | **All three name forms served**; `krynet.cc` kept, `kkasbi.in` primary | Work laptop cannot reach `krynet.cc`; mobile apps still need it | #57 |
| 2026-09 | **Alerting tiered** (8 wake-me / 5 standard / 2 info), canary-proven on Gotify + Discord | A green status page says nothing about whether you'd be told | #50–#52 |
| 2026-09 | **`drift-check.sh`** + stack/file renames so names match | Nothing here is GitOps; repo and live drifted silently both ways | #56 |
| 2026-09 | **`vpn-watchdog`** | `network_mode: service:gluetun` dependents never restart after a start failure | #49 |
| 2026-09 | **Smart home:** 14 → 8 automations, symmetric 23:45/07:00 schedule, Alexa voice presets | The old set was unexplainable in aggregate; two rules could never fire | #47–#48 |
| 2026-09 | **Phase 7: all 7 Tuya devices local** (cloud entry deleted 2026-10-02) | LAN control without the internet; label contract (`protected` 6) intact throughout | #53, #55, #63 |
| 2026-09 | Dashboards rebuilt; everyday entities on tab 1 | Owner request; consolidated 43 cards into 9 sections | #54, #58 |
| 2026-09-20 | **Legion backup dead-man switch** | Legion's backup had been running unmonitored for weeks | #59 |
| 2026-10-02 | **`fleet-validate.sh`** + post-outage runbook | The 2-day outage left 7 containers dead that nothing retried | #60 |
| 2026-10-03 | **Gatus: Frigate, GPU-driver body check, Legion thermals**; `drift-check` masks secrets | Each gap had been silent; the thermal alert fired for real on 10-05 | #61 |
| 2026-10-03 | **GPU stays attached to containers**; Frigate paused; `FRIGATE_` placeholder bug fixed | Containers had silently fallen back to the CPU; Legion pinned at 100 °C | #62 |
| 2026-10-03 | Frigate camera credentials → stack env (byte-identical round-trip proven) | Credentials were inline in a config file | #62 |
| 2026-10-03 | Backup ping UUIDs → stack env on all three nodes | A ping UUID can fake "backup OK" | #64 |
| 2026-10-03 | Healthchecks on Prime's monitoring containers (F8 partial) | Unchecked containers can be dead while "running" | #65 |
| 2026-10-02 | 55 merged branches deleted | Hygiene | — |
| 2026-10-07 | pCloud token re-authorized (owner) — all three backups `up` again | Every off-site backup had failed on 2026-10-05 | — |

---

## 3. Backlog, in priority order

**P0 — broken right now** (all owner-side; see `HANDOFF.md` §3)

| Item | Why first |
|---|---|
| **Power-cycle the Wifi Socket** | Off the LAN since 2026-10-06; two `night_off` loads unreachable |
| **Install the two staged Legion files** (`sudo`) | Without the udev rule the next reboot + upgrade silently takes the GPU from every container again |
| **Physically inspect Legion's cooling** | CPU 73–84 °C at idle; software causes are already removed |

**P1 — next, agent-doable unless marked**

| Item | Why | Notes |
|---|---|---|
| **First restore test** | A backup is a hypothesis until restored — never done on this fleet | Restore one app config + one DB to a scratch path; verify by row count. `backup-dr` skill |
| **Gatus external dead-man** | `Gatus (Self)` catches degraded, not dead; if Agni dies nothing alerts | Recommended: a cloud healthchecks.io check, pinged every 5 min from Prime only while Agni's Gatus `/health` is UP. Also catches house-wide power/internet loss. Owner creates the check |
| **Schedule `drift-check.sh`** | Drift is only seen when someone remembers | Recommended: `launchd` on the personal Mac (tokens already there; missed runs fire on wake), result pinged to Healthchecks so silence is visible. Alternatives considered: token on Agni (rejected — puts root-on-Prime on Agni); token-free read of Portainer's on-disk stacks (possible, larger rewrite) |
| **Memory limits** | Only Prometheus/nucleus/Tdarr node are capped; one leak can take a node | Needs owner "yes" — [rollout plan below](#memory-limits-rollout) |
| **Item-9 drift decisions** | Keeps `drift-check` at zero so a new drift is noticed | Caddy: repo → live. Legion Tailscale: live → repo |
| Rotate credentials (owner) | 19 literals in git history incl. both Portainer tokens; the Frigate RTSP password leaked into a transcript | History is permanent; rotation is the only fix |

**P2 — worth doing**

| Item | Why |
|---|---|
| **Frigate GPU detector** (TensorRT/ONNX) before resuming detection | CPU detection cost 58 % of a core on a machine that overheats; the `stable-tensorrt` image is already deployed |
| **`subgen` duty cycle** | It ran 13.5 h flat-out; give it a night window or a concurrency cap before resuming |
| Pin `:latest` images (51) | Rollback needs an identifiable previous image. Owner deferred this |
| F8 remainder | 5 Prime containers have no healthcheck; 3 cannot have one (no tools / TrueNAS-managed / outcome-monitored) |
| ZFS scrub after the hard power loss | Pools are clean; a scrub confirms it. TrueNAS UI only |
| `*.krynet.cc` resolves to Agni's Tailscale IP | A plain LAN device without Tailscale cannot use that name |
| Vaultwarden `DOMAIN`, `JELLYFIN_PublishedServerUrl` still `krynet.cc` | Single-valued; changing `DOMAIN` can invalidate registered passkeys — test first |
| AdGuard DNS rewrites are inert | Resolution is public Cloudflare DNS; fixing it changes resolution for every client at once |

**P3 — hygiene and polish**

Delete the 3 leftover branches and `dashboard-main.yaml` (owner OK pending) · homepage visual refresh +
a subgen tile · camera firmware `.30`/`.87` (owner) · WAN-outage test (owner) · monthly
`bill_units`/`bill_amount` (owner).

---

## 4. Review tracks (from the 2026-08 audit)

| Track | Status |
|---|---|
| T1 Smart home | ✅ done (Phase 7 closed 2026-10-02) |
| T2 HA reliability | ⬜ not started |
| T3 Frigate | ✅ done — now **paused** for thermals; GPU detector is P2 |
| T4 Networking / Cloudflare / Tailscale | ⬜ not started (domain work done; DNS rewrites P2) |
| T5 Media pipeline | ⬜ not started |
| T6 Backups / snapshots / pCloud | ◐ dead-man switches done; pCloud re-auth done 2026-10-07; **restore test P1** |
| T7 Observability | ⬜ not started (Gatus/alerting covered under T10) |
| T8 AI stack | ⬜ not started |
| T9 Immich | ⬜ not started |
| T10 Alerting / Gatus / Caddy | ◐ tiering, canaries, new probes done; external dead-man P1 |
| T11 Homepage | ⬜ not started |
| T12 Portainer / Docker hygiene | ◐ ghost stacks, drift-check, healthchecks (partial) done; limits + pinning open |

Each track's original brief (inventory + paste-in prompt) is in the owner's planning notes, not this
repo. If you start one, write its findings into `PROGRESS.md` and its decisions into this file.

**nucleus** (the finance app) is a separate repo with its own `AGENTS.md` and plan — not tracked here.

---

## 5. Decisions already made — do not re-litigate

| Decision | Reason |
|---|---|
| External access is **Tailscale only**; Cloudflare tunnels disabled | Owner's security choice |
| `krynet.cc` stays alongside `kkasbi.in` | Mobile apps still use it |
| **HA owns schedules; Alexa owns voice** | Alexa's time-based routines were deleted by the owner |
| **Eight automations, deliberately** | Six were cut for being unexplainable; a muted detector is worse than none |
| No presence/away automations | Only one household phone is in HA |
| Kernel/NVIDIA **hold**, not DKMS, on Legion | Keeps Ubuntu's prebuilt modules; kernel and driver move together, by hand |
| Frigate cameras paused | Owner: "I don't want my Legion dying" |
| `docker system prune -a` forbidden | It deletes every rollback target |
| Handoff docs live **in this repo** (`docs/handoff/`) | The owner works from two machines; a doc only one machine can see is not a handoff |

---

## Memory-limits rollout

**Status: planned, dry-run done 2026-10-03, awaiting owner "yes".** Re-run the dry run before applying —
peaks move, and the four stacks that were skipped for open PRs (#62, #64, #65) are now in sync with
`main` and become eligible.

**Sizing rule:** `mem_limit = max(1.5 × 30-day peak, peak + 256 MiB, 128 MiB)`, rounded up to 64 MiB.
**2.5×** for services where an OOM-kill does real damage (databases, Redis/Valkey, Home Assistant,
Immich, Jellyfin, Tdarr, ML/inference, Frigate, Prometheus). Peak = `max_over_time(
container_memory_working_set_bytes[30d])` from cAdvisor in Prometheus. Existing limits are kept.
**Ollama is overridden to 6 GB**: its observed peak only reflects models that fit in VRAM, and a larger
model offloads layers to system RAM.

**Guards, per stack:** live content must equal `main`'s file (normalised) · no service may be running an
image older than its tag now points to (a recreate would silently upgrade it) · after the PUT, every
container of the stack must be running, healthy where it has a check, and show the limit in
`docker inspect` — **first failure: roll that stack back and stop.**

**Order:** Legion → Prime (DNS stack last) → Agni (AdGuard last, after Prime's DNS is verified, so DNS is
never down on both). **Caddy is never part of a bulk change.**

| Node | Stack (id) | Service → proposed `mem_limit` (30-day peak) |
|---|---|---|
| prime | immich (9) | `immich_server` 6336m (peak 2514m, critical) · `immich_redis` 384m (peak 122m, critical) · `immich_postgres` 2304m (peak 910m, critical) · `immich_power_tools` 320m (peak 57m) |
| prime | media-stack (49) | `gluetun` 384m (peak 78m) · `qbittorrent` 384m (peak 103m) · `sabnzbd` 512m (peak 194m) · `flaresolverr` 1024m (peak 641m) · `prowlarr` 640m (peak 334m) · `sonarr` 512m (peak 215m) · `radarr` 640m (peak 330m) · `bazarr` 1856m (peak 1206m) · `recyclarr` 320m (peak 15m) · `jellyfin` 1984m (peak 775m, critical) · `seerr` 576m (peak 283m) · `whisparr` 448m (peak 130m) · `tdarr-server` 768m (peak 305m, critical) |
| prime | dns-stack (57) | `adguardhome` 640m (peak 352m) |
| prime | freshrss (61) | `freshrss` 320m (peak 48m) |
| prime | paperless-ngx (62) | `paperless_valkey` 320m (peak 17m, critical) · `paperless-webserver` 896m (peak 587m) |
| prime | speedtest-stack (64) | `openspeedtest` 320m (peak 19m) · `speedtest-tracker` 448m (peak 165m) |
| prime | audiobookshelf-stack (69) | `audiobookshelf` 448m (peak 136m) |
| prime | jellystat (70) | `jellystat-db` 448m (peak 133m, critical) · `jellystat` 576m (peak 259m) |
| prime | vpn-watchdog (73) | `vpn-watchdog` 320m (peak 23m) |
| agni | adguard-stack (6) | `adguardhome` 640m (peak 330m) · `adguardhome-sync` 320m (peak 61m) |
| agni | tailscale-stack (7) | `tailscale-agni` 384m (peak 105m) |
| agni | openspeedtest (8) | `openspeedtest` 320m (peak 20m) |
| agni | homeassistant (9) | `homeassistant` 3200m (peak 1259m, critical) · `matter-server` 448m (peak 151m) |
| agni | monitoring-stack (12) | `gotify` 320m (peak 53m) · `gatus` 320m (peak 45m) · `healthchecks` 640m (peak 347m) · `grafana` 768m (peak 470m) · `node-exporter` 320m (peak 30m) · `cadvisor` 1152m (peak 729m) · `dozzle` 384m (peak 93m) |
| agni | copyparty-stack (14) | `copyparty` 320m (peak 56m) |
| agni | dashboard-stack (18) | `homepage` 512m (peak 255m) |
| agni | vaultwarden-stack (19) | `vaultwarden` 384m (peak 83m) |
| legion | ai-stack (22) | `ollama` 6144m (peak 873m — overridden: partial CPU offload of models > 6 GB VRAM) · `litellm` 5568m (peak 3704m) · `openwebui` 1536m (peak 1008m) |
| legion | immich-ml (23) | `immich_machine_learning` 13824m (peak 5515m, critical) |
| legion | tdarr-node (24) | `tdarr-node-legion` 832m (peak 318m, critical) |
| legion | monitoring-sensors (28) | `node_exporter_legion` 320m (peak 29m) · `cadvisor_legion` 1536m (peak 1007m) · `dozzle-agent` 384m (peak 69m) · `nvidia_gpu_exporter_legion` 320m (peak 27m) |
| legion | rclone-stack (29) | `backup-legion` 576m (peak 258m) |
| legion | subgen (31) | `subgen` 3456m (peak 2274m) |

**Skipped by the guards on 2026-10-03:** `prime/rclone-stack` (live != main (open PR or drift)) · `prime/monitoring-sensor` (live != main (open PR or drift)) · `agni/caddy-stack` (live != main (open PR or drift)) · `agni/rclone-stack` (live != main (open PR or drift)) · `legion/tailscale` (live != main (open PR or drift)) · `legion/frigate` (live != main (open PR or drift))


On Legion the limits sum to more than its RAM; that is expected — limits are per-container ceilings
against a runaway, not reservations.
