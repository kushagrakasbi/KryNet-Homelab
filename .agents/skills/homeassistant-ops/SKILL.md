---
name: homeassistant-ops
description: Programmatic Home Assistant fleet operations, entity telemetry, service execution, device onboarding, and zero-downtime YAML validation on Agni (192.168.0.200). Use whenever inspecting smart home state, executing automations, or adding/modifying devices, templates, and dashboards.
---

# 🏡 KryNet Home Assistant Operations Skill

This skill provides comprehensive operational guidelines, CLI tools, configuration patterns, and device onboarding runbooks for managing the **Home Assistant** instance on **🔥 Agni** (`192.168.0.200`).

## ✍️ Writing or changing an automation → read this first

**[`reference/automation-authoring.md`](reference/automation-authoring.md)** — the recipe book:
the label rule, the copy→`check_config`→reload workflow, reload-vs-restart, five automation
patterns, the traps that have each cost real time, and the HA-vs-Alexa split.

### The live automation set — EIGHT, deliberately

| # | Automation | Fires | Does |
|---|---|---|---|
| 1 | `guard_protected_switch_off` | a `protected` entity goes off | **alerts only** |
| 2 | `alert_protected_unavailable` | `protected` unreachable 15 min | alerts |
| 3 | `alert_camera_down_6h` | Hall/Kids camera down 6 h | alerts |
| 4 | `fridge_failure_sentinel` | Fridge < 1 W for 30 min while on | alerts |
| 5 | `night_cut_night_off` | **23:45** | off: `night_off` (8 loads) |
| 6 | `late_night_cut` | **01:00**, or when the TV goes off before 07:00 | off: `late_night_off` (TV Mains) |
| 7 | `morning_restore_all` | **07:00** | on: both night labels, TV backlight re-asserted |
| 8 | `tv_backlight_follows_tv` | TV power crosses 60 W | backlight on 35% / off |

Plus two **scripts** for manual use, exposed to Alexa as *Goodnight* and *Good Morning*:
`script.goodnight_all_off`, `script.good_morning_all_on`.

🔴 **Keep it at eight.** Six automations were deleted on 2026-09-06 because they were
unexplainable in aggregate: two presence rules that could never fire, a charger cutoff whose
`numeric_state` trigger never crossed its threshold, a duplicate 04:00 charger cut, and two
alert detectors that false-fired and got muted. **A muted detector is worse than none** — it
reads as working. Before adding one, ask what it would have caught this year.

## 🔗 Source → this skill

| Feeds this skill | Sync when |
|---|---|
| `scripts/ha-helper.sh` | its subcommands change |
| `config/ha/` | entities, templates or dashboards are restructured |

When any of those change, re-read this skill and update it in the same PR.
Reverse check: `grep -l "<changed-file>" .agents/skills/*/SKILL.md`


---

## 🗺️ System Topology & Endpoints

| Resource | Target | Path / Protocol |
| :--- | :--- | :--- |
| **Ingress Proxy** | `https://ha.lan.kkasbi.in` | Caddy reverse proxy on Agni (:8123) |
| **Direct Local LAN** | `http://192.168.0.200:8123` | Direct HTTP access |
| **Config Base Path** | `/home/agni/apps/docker/ha/config` | Mounted into container at `/config` |
| **WebRTC Stream Proxy** | `http://192.168.0.200:1984` / `:8555` | `go2rtc` stream engine |
| **Repository Config Source** | `config/ha/` | Tracked in `home-server` Git repo |

---

## 🛠️ CLI Automation Tooling: `scripts/ha-helper.sh`

Always use [`scripts/ha-helper.sh`](../../../scripts/ha-helper.sh) from the repository root for all diagnostic and operational tasks.

### 1. Health & Core System Status
```bash
# Check REST API health, core version, instance state, and SQLite DB size:
./scripts/ha-helper.sh status
```

### 2. Live Appliance Power & Energy Telemetry (INR / ₹)
```bash
# Summarize active power (W), today's kWh, monthly kWh, and voltage across smart plugs:
./scripts/ha-helper.sh energy
```

### 3. Camera Stream Diagnostics
```bash
# Inspect RTSP decoding, go2rtc WebRTC readiness, and Wi-Fi signal levels:
./scripts/ha-helper.sh cameras
```

### 4. Family Presence & Gateway Bandwidth
```bash
# Check smartphone Wi-Fi association and Archer BE400 WAN speed:
./scripts/ha-helper.sh presence
```

### 5. Entity Queries & State Inspection
```bash
# List all entities in a specific domain (e.g. switch, light, sensor, automation):
./scripts/ha-helper.sh entities switch
./scripts/ha-helper.sh entities light
./scripts/ha-helper.sh entities automation

# Query full JSON attributes of an entity:
./scripts/ha-helper.sh state sensor.krynet_today_electricity_cost
./scripts/ha-helper.sh state binary_sensor.anyone_home
```

### 6. Programmatic Service Execution
```bash
# Turn on/off or toggle a switch:
./scripts/ha-helper.sh call-service switch toggle '{"entity_id": "switch.office_plug"}'

# Trigger an Alexa TTS announcement across all Echo speakers:
./scripts/ha-helper.sh call-service notify all_alexa_speakers_announce '{"message": "Fleet update completed.", "data": {"type": "announce"}}'

# Trigger a scene:
./scripts/ha-helper.sh call-service scene turn_on '{"entity_id": "scene.relax_unwind"}'
```

### 7. Zero-Downtime Validation & YAML Reload
```bash
# Validate YAML configuration without restarting:
./scripts/ha-helper.sh validate

# Trigger instant zero-downtime YAML reload for all domains:
./scripts/ha-helper.sh reload

# Restart Home Assistant container gracefully:
./scripts/ha-helper.sh restart
```

---

## 🔌 Device Onboarding & Scaling Runbook (For Future Agent Sessions)

When the user requests adding new smart home hardware, follow these standardized patterns:

### 1. Adding New TP-Link Tapo P110/P115 Smart Plugs
1. Ensure the plug has a static DHCP reservation in Archer BE400 router and "Third-Party Compatibility" enabled in the Tapo app.
2. Home Assistant core `tplink` integration discovers it via local KLAP AES protocol.
3. Update `config/ha/configuration.yaml` template sensors:
   - Add new plug wattage to `sensor.krynet_total_plug_power`.
   - Add new plug energy to `sensor.krynet_today_total_energy` and `sensor.krynet_today_electricity_cost`.
4. Update `scripts/ha-helper.sh` array `PLUGS=(...)` to include the new plug slug.
5. Add dial gauge to `config/ha/dashboards/krynet-hub.yaml` under the Energy Hub view.
6. Validate with `./scripts/ha-helper.sh validate` and reload with `./scripts/ha-helper.sh reload`.

### 2. Adding New WiZ Tunable RGBW Bulbs
1. Assign static IP in Archer BE400 router.
2. Core `wiz` integration discovers the bulb over local UDP port 38899.
3. Add bulb entity to `adaptive_lighting:` in `config/ha/configuration.yaml` to include it in circadian daylight cycles.
4. Add virtual energy metering under `powercalc: sensors:` in `config/ha/configuration.yaml`.
5. Sync config to Agni and reload.

### 3. Adding New PTZ RTSP Cameras
1. Assign static DHCP reservation in Archer BE400 router.
2. In `config/ha/go2rtc.yaml` on Agni, define primary 1080p stream (`/stream1`):
   ```yaml
   streams:
     new_camera:
       - rtsp://user:password@<IP>:554/stream1
       - "ffmpeg:new_camera#audio=opus"
   ```
3. In `config/frigate/config.yml` on Legion, add stream under `go2rtc: streams:` and define roles (`record` and `detect`) referencing `rtsp://127.0.0.1:8554/<camera_name>` (respects the 2-connection Tapo hardware limit).
4. Add a prominent 16:9 widescreen picture-glance card to `config/ha/dashboards/krynet-hub.yaml` under Home Cockpit.

---

## 🛡️ Critical Architectural Rules for Home Assistant
1. **Never commit raw passwords to Git:** Reference passwords via `secrets.yaml` on Agni or environment variables.
2. **Never add deprecated `http:` block in `configuration.yaml`:** Reverse proxy trusted proxies are maintained in `.storage/http`.
3. **Always use modern `powercalc.sensors` syntax:** Do NOT declare powercalc sensors under `sensor: - platform: powercalc`.
4. **Preserve User Dashboards:** The dedicated dashboard for agent enhancements is **`KryNet Hub`** (`/krynet-hub` / `config/ha/dashboards/krynet-hub.yaml`). Do NOT overwrite the user's manual `lovelace.dashboard_main`.
5. **Power-Cycle & Physical Switch-Off Resilience:**
   - Always use `continue_on_error: true` on service call actions so automations don't break when devices are turned off at the wall.
   - Guard alert automations with `condition: template: "{{ states('sensor....') not in ['unavailable', 'unknown', 'none'] }}"` to prevent false alarms.
   - Always pipe template sensor numbers with `| float(0)` so offline plugs/sensors safely default to 0 without breaking totals or financial cost calculations.
   - Set `standby_power: 0` for smart bulbs in Powercalc so physically unpowered bulbs contribute 0W.
6. **Disaster Recovery & Snapshots:**
   - Run `./scripts/ha-helper.sh backup` before making large architectural modifications.
   - Verified snapshots are saved as portable `.tar.gz` archives in `/home/agni/apps/docker/ha/backups/`.
   - Restoration procedures are detailed in [`docs/HOME-ASSISTANT-DISASTER-RECOVERY-AND-MIGRATION-RUNBOOK.md`](../../../docs/HOME-ASSISTANT-DISASTER-RECOVERY-AND-MIGRATION-RUNBOOK.md).
7. **Always validate before reloading:** Run `./scripts/ha-helper.sh validate` before triggering `./scripts/ha-helper.sh reload`.
8. **Target LABELS, never entity lists** in any automation that switches several things —
   `target: {label_id: night_off}`. An entity list goes stale silently; a label makes an omitted
   device visible. And delete a label when its last consumer goes: `away_off` was retired this
   way. Contract: [`docs/SMART-HOME-DEVICE-INVENTORY.md`](../../../docs/SMART-HOME-DEVICE-INVENTORY.md) §4.
9. **Never switch anything `protected`** — alert instead. The schedules cannot reach a server
   because they target different labels; keep that structural guarantee intact.
10. **If you cut loads at night, write the restore in the same change.** Seven were cut at 23:30
   and only two restored, so five latched off for weeks. Asymmetry is the commonest defect here.
11. **Reference Documentation:** Read [`docs/HOME-ASSISTANT-DEVICE-RESILIENCE-GUIDE.md`](../../../docs/HOME-ASSISTANT-DEVICE-RESILIENCE-GUIDE.md) for full architectural patterns across Tapo, WiZ, Tuya, and Amazon Echo.
