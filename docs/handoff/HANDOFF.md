# 🔁 Agent handoff — start here

**Last verified:** 2026-10-07 ~07:00 UTC, from the work laptop. Every figure below was measured then,
not carried forward.
**Updated by:** the agent that last touched the fleet. **If you change anything, update this file
before you stop.** Rule and checklist: the `session-handoff` skill.

This folder is the single place where the *state of the work* lives:

| File | What it holds | Update when |
|---|---|---|
| **`HANDOFF.md`** (this) | Current state, open incidents, what is waiting on whom | every milestone, and before you stop |
| [`PLAN.md`](PLAN.md) | The overall plan: what is done, what is left, in what order, and **why** | priorities change or an item lands |
| [`PROGRESS.md`](PROGRESS.md) | Dated log, newest first: what was done and how it was verified | every milestone |
| [`RESUME-PROMPT.md`](RESUME-PROMPT.md) | A paste-in prompt that gets a fresh agent going | the "do next" list changes |
| [`TRAPS.md`](TRAPS.md) | Things that produced a **false reading** and cost real time | you hit a new one |

Evergreen contracts live elsewhere and outrank this folder for their subject:
`AGENTS.md` (fleet rules), `docs/SMART-HOME-DEVICE-INVENTORY.md` (smart-home contract),
`.agents/skills/*` (how-to).

---

## 1. Read order for a fresh agent

1. **This file** — sections 2–5 are the state and the queue.
2. [`TRAPS.md`](TRAPS.md) — 10 minutes now saves an hour later.
3. `AGENTS.md` — especially *Where you are working from*, which decides what is possible at all.
4. [`PLAN.md`](PLAN.md) — only when picking the next item.
5. The skill for the area you touch (`fleet-health`, `portainer-ops`, `homeassistant-ops`,
   `backup-dr`, `caddy-proxy`, `krynet-fleet`, `personal-transfer`, `session-handoff`).

**First command, always** — from the repo root, on either machine:

```bash
scripts/fleet-validate.sh      # ~10 s, read-only. 0 healthy / 1 findings / 2 something unchecked
```

Compare its output with section 2. Anything new is either your first task or a correction to this file.

---

## 2. State of the fleet (verified 2026-11-01)

| | State |
|---|---|
| Containers | Agni **20/20** · Prime **39/39** (33 report healthy) · Legion **14/14** |
| Gatus | **45/45** — all probes passing green |
| ZFS | all pools `ONLINE`, 0 errors; `orion` 74 %, `andromeda` 29 % |
| GPU (Legion) | driver loaded on kernel `7.0.0-34`; all GPU containers can see RTX 3060 |
| Backhaul Throughput | Agni ↔ Prime **115.1 MB/s**, Legion ↔ Prime **114.8 MB/s** (wire-speed Gigabit) |
| VPN & Downloaders | Gluetun Singapore WireGuard active with 25s keepalive; `vpn-watchdog` auto-healing active; qBittorrent & Seerr responding |
| Audiobook Stack | Audiobookshelf active (`abs.lan.kkasbi.in`), Chaptarr active (`chaptarr.lan.kkasbi.in`), Libation headless loop active |
| Home Assistant | 5/8 automations on · `protected` 6/6 on · 46/49 integrations loaded · emulated_hue exposes 13 devices |
| Backups | all three Healthchecks `up`, pinged 2026-11-01 |
| DNS / ingress / Tailscale | both AdGuards answer · Caddy config valid · 3/3 servers on the tailnet |
| Homepage | Rebuilt with Jellyfin v2 widget (157 Movies, 17 Series, 2,075 Episodes), Chaptarr, and fresh tiles |

---

## 3. 🔴 Open incidents — handle these first

### 3.1 Wifi Socket is off the network (since 2026-10-06 20:34 UTC)

`switch.wifi_socket_vaku` and `switch.wifi_socket_usb` are `unavailable`; `192.168.0.17` answers neither
ping nor TCP 6668 (`tuya_local` error 905). It has dropped off before and a power-cycle fixed it; the
cause is unconfirmed. **Owner: power-cycle the socket**, then confirm both entities return in HA. Vaku
powers the desk speakers' charger — its relay state while offline is unknown.

✅ *The pCloud token incident of 2026-10-05 is resolved* — all three backup checks `up` with pings on
2026-10-07 and no `Revoked` errors in 48 h of logs (`PROGRESS.md`). Procedure kept in `backup-dr`.

### 3.2 Legion runs hot — chronic, and partly hardware

- **History:** CPU package 95–100 °C every day since at least Sep 11. Two software causes were found
  and fixed on 2026-10-02: GPU containers had silently lost the GPU and were running on the CPU, and
  Frigate's decoders held the GPU at full power (cameras now paused).
- **2026-10-05:** the new Gatus alert fired. Cause: `subgen` (Whisper subtitles) ran a 13.5 h GPU job —
  the backlog from the days it had no GPU. **`subgen` was stopped at 14:45 UTC**; resume with
  `ssh legion docker start subgen` once the machine is cooler or the owner says so.
- **2026-10-07:** CPU 69 °C at load 0.29 with `subgen` still stopped (`fleet-validate` reports it as
  `exited 137` — that is the deliberate stop, not a crash).
- **Still unexplained by software:** CPU 69–84 °C at load ~0.2–0.5. That points at airflow — vents,
  fans, dust, lid. **Owner: physically inspect Legion.** `fan_mode` cannot be changed on this model
  (a write of 4 is accepted and reads back 0).

### 3.3 Legion `sudo` — two staged files still not installed

Both are already on Legion in `/tmp`; one command installs them (owner — `sudo` needs a password):

```bash
ssh -t legion 'sudo install -m 644 /tmp/51kernel-hold-for-nvidia /etc/apt/apt.conf.d/ && sudo install -m 644 /tmp/71-nvidia-dev-char.rules /etc/udev/rules.d/ && sudo systemctl daemon-reload && rm /tmp/51kernel-hold-for-nvidia /tmp/71-nvidia-dev-char.rules'
```

- `51kernel-hold-for-nvidia` — stops `unattended-upgrade` moving the kernel or NVIDIA driver on its own
  (on 2026-09-25 it moved the kernel without the module; the next boot had no GPU).
- `71-nvidia-dev-char.rules` — without it, the next reboot **plus** any package upgrade cuts every
  running GPU container off the GPU again (`Failed to initialize NVML: Unknown Error`).
- 🔴 **If `/tmp` was cleared by a reboot, the files are gone** — recreate them from
  `fleet-health/reference/post-outage.md` §1 and §7.
- After installing: run `fleet-validate.sh` — every GPU container must still say `sees the GPU`. That
  `daemon-reload` *is* the regression test.

---

## 4. Waiting on the owner — do not proceed without an explicit "yes"

| # | Decision | Recommendation | Ready to run |
|---|---|---|---|
| 1 | **Memory limits** on 45 services in 24 stacks | Yes — plan, sizing rule, order and guards in [`PLAN.md`](PLAN.md#memory-limits-rollout) | Dry run done 2026-10-03; re-run it first (data moves) |
| 2 | `agni/caddy-stack` drift (live inline `environment:` vs repo `env_file:`) | **Change the repo to match live**; do not redeploy the single ingress for a cosmetic difference | repo-only edit |
| 3 | `legion/tailscale` drift (repo adds healthcheck + log rotation) | **Apply the repo version** — a few seconds of Tailscale downtime on Legion | Portainer PUT |
| 4 | Delete 3 leftover GitHub branches (`chore/pr-workflow-connectivity-test`, `feat/media-pipeline-automation`, `fix/homepage-ha-widget-token`) | Yes — content is on `main` except a subgen homepage tile | GitHub API |
| 5 | Delete `config/ha/dashboards/dashboard-main.yaml` | Yes — no `lovelace:` block registers it; nobody can open it | repo-only |
| 6 | Resume Frigate detect + record | When Legion's cooling is fixed: delete the three `enabled: false` lines | edit live config + restart |
| 7 | Resume `subgen` | After §3.2 | `docker start subgen` |

Also owner-only, no decision needed: §3.1 Wifi Socket power-cycle · §3.3 Legion `sudo` · rotate the credentials
in git history (both Portainer tokens first — root-equivalent on every node) and the Frigate RTSP
password that leaked into a transcript · camera firmware on `.30`/`.87` · WAN-outage test · nucleus
September import · re-enter `bill_units`/`bill_amount` monthly.

---

## 5. What to do next (agent work, no owner input needed)

In order — rationale for each in [`PLAN.md`](PLAN.md):

1. Re-run `fleet-validate.sh`; reconcile with §2–3.
2. The **first restore test** — backups are healthy again, but a backup is a hypothesis until it has
   been restored, and that has never been done here (`backup-dr` skill).
3. Gatus can't detect its own death — add an external dead-man (see PLAN P1).
4. Schedule `drift-check.sh` on the personal Mac via `launchd` (see PLAN P1).
5. Review tracks never started: T2, T4, T5, T7, T8, T9, T11 (PLAN §4).

---

## 6. Where things are

### Machines

| Machine | Path | Role for the agent |
|---|---|---|
| **Personal Mac** (`personal-mac`, `192.168.0.49`) | `~/Projects/home-server` | Holds the Portainer tokens and pushes to GitHub. **Sleeps** — then SSH times out while ping still answers |
| Work laptop | `~/Work/Repos/personal/home-server` | Can SSH the fleet on the home LAN; **cannot** push or reach `*.krynet.cc` |

**Mac facts verified 2026-10-07:** SSH to all three nodes ✅ · `python3`, `dig` ✅ · **no `~/.ha/token`**
(so `fleet-validate.sh` SKIPs the HA section there until the owner creates one) · **no `.claude/skills`
links yet** — run `scripts/link-skills.sh` after pulling · git identity is the owner's personal address.

Capability table: `AGENTS.md` → *Where you are working from*. 🔴 **On the personal Mac you push directly**
— the `personal-transfer` skill is for the work laptop only.

### Portainer stacks (id → name)

| Endpoint | Instance | Stacks |
|---|---|---|
| **2** Prime | `https://portainer.lan.kkasbi.in` (`prime_token`) | 9 immich · 39 tailscale · 49 media-stack · 57 dns-stack · 61 freshrss · 62 paperless-ngx · 64 speedtest-stack · 67 rclone-stack · 68 monitoring-sensor · 69 audiobookshelf-stack · 70 jellystat · 72 nucleus · 73 vpn-watchdog |
| **4** Agni | `https://portainer2.lan.kkasbi.in` (`agni_token`) | 6 adguard-stack · 7 tailscale-stack · 8 openspeedtest · 9 homeassistant · 11 caddy-stack · 12 monitoring-stack · 14 copyparty-stack · 15 rclone-stack · 18 dashboard-stack · 19 vaultwarden-stack |
| **6** Legion | same as Agni (agent) | 22 ai-stack · 23 immich-ml · 24 tdarr-node · 26 tailscale · 28 monitoring-sensors · 29 rclone-stack · 30 frigate · 31 subgen |

🔴 **Stacks are NOT git-backed.** Portainer holds its own copy; merging a PR changes nothing until the
content is pushed through the API. Diff afterwards with `drift-check.sh`.

### Live files that are not stacks

| What | Where |
|---|---|
| Caddyfile | `agni:/home/agni/apps/docker/caddy/Caddyfile` (validate before reload — `caddy-proxy` skill) |
| Gatus config | `agni:/home/agni/apps/docker/gatus/config/config.yaml` — **hot-reloads**; Gatus image has no shell |
| HA config | `agni:/home/agni/apps/docker/ha/config/` — `check_config` exits 0 on warnings, grep `WARNING` |
| Frigate config | `legion:/home/legion/apps/docker/frigate/config/config.yml` — credentials come from stack env |
| Healthchecks DB | `healthchecks:/config/hc.sqlite` — open with `?mode=ro` only |

### Backups taken during recent work (keep until the next milestone, then delete)

| Taken | Where | Of what |
|---|---|---|
| 2026-10-02 | `agni:/home/agni/ha-storage-backup-20261002T123701-pre-tuya-delete/` | HA registries before the Tuya delete (row-counted: 50 entries / 1077 entities / 60 devices) |
| 2026-10-02 | `legion:…/frigate/config/config.yml.bak-20261002T070027-pre-thermal` | Frigate config before the camera pause |
| 2026-10-03 | `legion:…/frigate/config/config.yml.bak-20261003T054353-pre-credmove` + `…/frigate/stack30.bak-20261003T054353.yml` | Frigate config + stack before the credential move — **contain camera credentials, mode 600** |

---

## 7. Rules that are easy to forget mid-task

- **Commit identity: never the work address.** The work laptop's global identity IS a work address, so
  its clone carries a local override (`25898035+kushagrakasbi@users.noreply.github.com`); the Mac's clone
  uses the owner's personal address (13 commits already). Check `git config --local user.email` before
  the first commit on any machine.
- **One branch per task, cut fresh off `main`. Never stack PRs** — GitHub does not retarget a PR when its
  base merges, and `main` silently misses it (happened with #45).
- **Production-warning block + explicit "yes"** before any destructive or bulk change (`AGENTS.md`).
- **No credentials in the repo, docs or chat** — env refs and placeholders only; read tokens into a
  variable, never to a file, never echoed.
- **Update this folder before you stop.** A session that ends without it forces the next agent to
  re-derive — and re-derive wrongly.
