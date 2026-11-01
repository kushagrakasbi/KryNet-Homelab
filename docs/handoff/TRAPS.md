# 🪤 Traps — readings that lied

Every row below produced a **false conclusion** on this fleet and cost real time. Read once per session.
Format: *what you see* → *what is true* → *what to do*. Add a row when you hit a new one.

## Fleet and Docker

| You see | Truth | Do |
|---|---|---|
| `ssh prime docker ps` prints nothing | Docker on Prime needs `sudo` (password). Prime has ~37 containers | Portainer API, or Agni's Dozzle stream (`fleet-validate.sh` does this) |
| `zpool: sudo: a password is required` | `zpool`/`zfs` are just not on `truenas_admin`'s PATH | `export PATH=$PATH:/usr/sbin` |
| Container `Exited (128)`, `RestartCount=0`, "restart: unless-stopped" | It **failed to start**; Docker never retries a start failure | Read `State.Error`; fix the cause; `docker start` |
| `State.FinishedAt` = failure time | It is the previous **stop**; a start failure has no timestamp | Don't build a timeline from it |
| `network_mode: service:X` dependent down for a day | Dependent failed to start when X restarted | `vpn-watchdog` handles gluetun's; anything new needs the same |
| `docker system df` RECLAIMABLE 58 GB | Counts unused *tagged* images = your rollback targets | Size with `docker images -f dangling=true`; measure with `df -h /`. Never `system prune -a` |
| Deleted 132 GB, pool free space unchanged | ZFS snapshots still reference the blocks | Check `usedbydataset` vs `usedbysnapshots`; space returns as snapshots expire |
| A probe says a port is closed | The image lacked `nc` — absence of a tool, not of a service | Test the tool exists first |
| `docker exec gatus cat …` returns nothing | Gatus image has no shell | Read the host bind mount |
| Merged a stack PR, nothing changed | Stacks are not git-backed | Push via Portainer API; confirm with `drift-check.sh` |
| `sqlite3.connect(path)` → "no such table" | It **created** an empty DB at a wrong path | Always `file:…?mode=ro`, `uri=True` |
| `ls -la /a /b` — first block is `/a` | `ls` sorts its operands | List one directory at a time |
| A shell pipeline that should print, printed nothing, exit 0 | `ssh` inside `$(…)` swallowed the heredoc meant for the next command | `ssh -n` in command substitutions; treat silence as failure |
| `date -d` error inside `ssh "…$(date -d …)"` | `$(…)` expanded locally on macOS (BSD date) | Compute timestamps locally, or single-quote the remote command |

## GPU / Legion

| You see | Truth | Do |
|---|---|---|
| Host `nvidia-smi` fine, Prometheus GPU target `up` | Containers may have **lost the GPU** (`NVML: Unknown Error`) after any `daemon-reload`; the exporter answers 200 with no GPU metrics | `fleet-validate.sh` checks inside each container; the udev rule prevents it |
| All GPU containers dead after a reboot | New kernel without its precompiled NVIDIA module (no-dkms driver) | Install `linux-modules-nvidia-…-generic`; the kernel hold prevents recurrence |
| `echo 4 > …/fan_mode` succeeded | This model ignores it; reads back 0 | Cooling is physical, not a sysfs knob |
| Legion's clock is 5.5 h off | Legion is UTC, the others IST | `timedatectl` says synchronised |

## Home Assistant

| You see | Truth | Do |
|---|---|---|
| `check_config` exit 0 | It **warns** and still exits 0 on a duplicate key; the entity silently did not exist | grep the output for `WARNING` |
| Template sensor reference resolves to nothing | entity_id is slugified from the NAME (`Sub-metered` → `sub_metered`) | Keep names hyphen-free; read the real id |
| `integration_entities("tuya")` = 0 | Disabled entities never load into the state machine | Read `.storage/core.config_entries` / registries |
| Two devices with the same name | Cloud and local copies share `name`; only `name_by_user` differs | **Select by device id** — never delete by name |
| `docker logs homeassistant` empty | HA logs to `/config/home-assistant.log` | Read the file |
| `curl localhost:8080` on Agni refused | `emulated_hue` binds `host_ip: 192.168.0.200` only | Use the LAN IP |
| emulated_hue down right after a restart | It binds ~70–90 s late | Poll before concluding |
| A device `unavailable` | Its **upstream switch** may be off (TV Backlight sits behind TV Mains) | Read the power tree in `SMART-HOME-DEVICE-INVENTORY.md` §1 first |
| A state change with no `parent_id`, no `user_id` | Came from outside HA automations (Tapo app, button, Alexa via emulated_hue) | Ask the owner before "fixing" it |
| Tuya mapping by name looked right | Cloud names were assigned by function | Match by **datapoint index** |

## Frigate

| You see | Truth | Do |
|---|---|---|
| `{CAM_KIDS_USER}` placeholder in config | Frigate substitutes **only `FRIGATE_*`** variables; others reach the camera literally | Name them `FRIGATE_…` |
| Frigate config drift: `version: 0.17` vs `0.17-0` | Frigate rewrites the version stamp on start | Keep the migrated form in the repo |
| `latest.jpg` identical for every camera | Cameras are paused — it is the placeholder | Expected while `enabled: false` |

## Backups / Healthchecks

| You see | Truth | Do |
|---|---|---|
| Check `down`, last ping recent | The job **reported failure** (`/fail`) — read its log | e.g. 2026-10-05: pCloud token revoked |
| Check `down`, backup log says `SUCCESS` | Ping lost — e.g. sent before Tailscale was up | Ping LAN names (`hc.lan.kkasbi.in`) |
| Durations like `2.4e+07h` | Stored in **microseconds** | Divide by 3.6e9 |
| `last_start` set | Run in progress — cleared on success | Not broken |
| `rclone … --ignore-errors` succeeded | Run completed; not every file necessarily copied | Read `Errors:` in the log |

## Git / GitHub / process

| You see | Truth | Do |
|---|---|---|
| A stacked PR "merged" | GitHub merged it into its base branch, not `main` (#45) | Never stack PRs |
| Repo looks drifted from the fleet | Local `main` was stale (sleeping Mac) | `git fetch` first — GitHub fetch works from both machines |
| A command naming the torrent client is blocked | Work-laptop DLP blocks that name | Do that step from the personal Mac or hand it to the owner — never obfuscate |
| A doc says "verified" | It was verified *then* | Re-measure anything you rely on |
