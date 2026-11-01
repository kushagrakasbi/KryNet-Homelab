# After a power outage — validating the fleet

Measured on the **2026-09-26 outage** (~2 days, all three nodes restarted by hand on Sep 27). Every
failure below happened that day; none was visible from Gatus as more than "down".

```bash
scripts/fleet-validate.sh     # ~10 s, read-only, exit 0 healthy / 1 findings / 2 unchecked
```

Run it from either machine. It needs only `ssh agni|prime|legion` — **not** the Portainer token,
so it works while the personal Mac is asleep. HA checks need `$HA_TOKEN` or `~/.ha/token`
(present on the work laptop); without one they print `SKIP` and the script exits 2, never 0.

---

## 🔴 The rule behind almost every failure

**A container that fails to START is never retried.** `restart: unless-stopped` covers a process that
*exits*; it does nothing for a start that errors before the process exists. The signature is
unmistakable once you look for it:

```
State.ExitCode = 128   RestartCount = 0   State.Error = "failed to create task for container: …"
```

`docker ps` shows only `Exited (128) 2 hours ago`. The *reason* is in `State.Error`, which is exactly
what `fleet-validate.sh` prints. The same trap as `network_mode: service:X` (AGENTS.md) — a different
cause, the same missing retry.

⚠️ **`State.FinishedAt` is the last STOP, not the failure time.** On a start failure it keeps the
previous run's timestamp. Reading it as "failing since then" put the outage timeline a day wrong.

---

## Failure classes — signature → cause → fix

### 1. Every GPU container on Legion dead — `nvml error: driver not loaded`

**Cause:** Legion runs the **no-dkms** NVIDIA driver: a precompiled module *per kernel*
(`linux-modules-nvidia-595-server-open-<kernel>`). `unattended-upgrade` installed kernel `7.0.0-34`
on 2026-09-25 but not its module, which was published separately. Nothing broke until the next boot —
which the outage supplied — and then Frigate, Ollama, Immich ML, subgen, the Tdarr node and the GPU
exporter all failed to start.

**Check:** `fleet-validate.sh`'s GPU section also flags the **next** boot: an installed kernel newer
than the running one with no module for it means the next reboot breaks the GPU. That is the check
that would have caught this two days early.

**Fix** (needs `sudo`, which needs a password on Legion — owner runs it):

```bash
ssh -t legion 'sudo apt-get install -y linux-modules-nvidia-595-server-open-generic && sudo reboot'
# after it returns:
ssh legion 'nvidia-smi --query-gpu=name,temperature.gpu --format=csv,noheader'
ssh legion 'docker start frigate ollama immich_machine_learning subgen tdarr-node-legion nvidia_gpu_exporter_legion'
```

Reboot rather than `modprobe`: the point is to prove the next boot works, not just this one.

### 2. A container on Agni fails with `mount src=/mnt/remote/… no such device`

**Cause:** boot ORDER. Agni's SMB shares from Prime are `x-systemd.automount`, mounted on first access.
Agni booted ~8 min before Prime, Docker started copyparty, its bind mount triggered the automount,
Prime was not serving yet, the mount failed — and per the rule above the container was never retried.

**Fix:** touching the path re-triggers the automount; then start the container. No sudo needed.

```bash
ssh agni 'ls /mnt/remote/andromeda-apps >/dev/null && findmnt -n /mnt/remote/andromeda-apps && docker start copyparty'
```

`fleet-validate.sh` touches every CIFS/NFS mount in `/etc/fstab` on Agni and Legion, which heals the
mount but **not** the container — re-run it after `docker start`. Legion's NFS mount uses `bg` and
retried by itself.

### 3. A Healthchecks check is DOWN but the backup actually succeeded

**Cause:** the backup loop runs once at container start. On Prime that was ~3 min after boot, the
`rclone` syncs finished, and the ping to `https://hc.krynet.cc` was lost — that name resolves to Agni's
**Tailscale** IP, which was not routable yet. `wget -q` fails silently and the loop sleeps 12 h, so the
check stays red all night over a good backup.

**Check the outcome, not the check** — Prime's logs via Dozzle (below), look for `Healthcheck: SUCCESS`.
**Fix for good:** ping `hc.lan.kkasbi.in` (LAN, no Tailscale dependency). That is already the repo's
intent — the "cosmetic" rclone ping-URL drift in `drift-check.sh` is this bug.

### 4. A smart plug or bulb is `unavailable` and its MAC is not on the LAN

After a ping sweep from Agni, a device whose MAC is absent from `ip neigh` did not rejoin Wi-Fi
(2026-09-27: the PS5 P116M). HA cannot fix that. **Power-cycle it physically.** Sweep first — a device
that merely moved IP shows its MAC at a new address:

```bash
ssh agni 'for i in $(seq 1 254); do ping -c1 -W1 192.168.0.$i >/dev/null 2>&1 & done; wait; ip neigh | grep -i <mac>'
```

Tuya devices: `scripts/tuya-discover.py` (defaults to 45 s — killing it early prints **nothing**, which
reads as "no devices"). Not every protocol version broadcasts; cross-check with HA before concluding.

### 5. A device is `unavailable` because its UPSTREAM switch is off

Not a fault. TV Backlight sits behind TV Mains in the power tree
(`docs/SMART-HOME-DEVICE-INVENTORY.md` §1). **Read the tree before chasing a device.** A state change
with no `context.parent_id` and no `user_id` came from outside HA's automations — the Tapo app, the
button, or Alexa via `emulated_hue`.

### 6. ZFS after a hard power loss

`last -x` shows `reboot` with no `shutdown` before it. ZFS is copy-on-write, so the pools come back
`ONLINE` — confirm `zpool status -x` says `all pools are healthy`. A scrub from the TrueNAS UI is
reasonable but not urgent; it cannot be run from here (`sudo`).

### 7. A GPU container is RUNNING but has lost the GPU — `Failed to initialize NVML: Unknown Error`

**Not a power-cycle failure — a quiet one that follows any package upgrade.** `systemctl
daemon-reload`, which every `unattended-upgrade` triggers, makes systemd re-apply device rules to
running containers. Under the `systemd` cgroup driver it drops any NVIDIA device node that has no
`/dev/char/<major>:<minor>` link — and those links live in tmpfs, so a reboot deletes them and nothing
recreated them. On 2026-09-30 Ollama, Immich ML, subgen and the Tdarr node lost the GPU and **fell back
to the CPU for two days**, while the host's `nvidia-smi` and Prometheus's `up` both stayed green.

**Signature:** `docker exec <c> nvidia-smi -L` → `Failed to initialize NVML: Unknown Error`, while the
host's own `nvidia-smi` works. `fleet-validate.sh` checks every GPU container and every link.

**Fix now:** `docker restart <container>` (restarting re-creates the links as a side effect).
**Fix for good** (NVIDIA's documented workaround; owner, `sudo`):

```bash
# /etc/udev/rules.d/71-nvidia-dev-char.rules
ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="/usr/bin/nvidia-ctk system create-dev-char-symlinks --create-all"
```

**Verify:** `sudo systemctl daemon-reload`, then re-run `fleet-validate.sh` — every container must still
see the GPU. That reload IS the regression test.

---

## Reading Prime without a Portainer token

Agni's Dozzle aggregates every node's agent, and its API needs no auth on the LAN side:

```bash
# container states for all hosts — the script's Prime section parses this
ssh agni 'timeout 6 curl -sN http://localhost:8088/api/events/stream' | grep -A1 'event: containers-changed'

# a container's full log history — host id and container id come from the stream above
ssh agni 'curl -s "http://localhost:8088/api/hosts/<host-id>/containers/<id>/logs?stdout=1&stderr=1&everything"'
```

⚠️ Dozzle names hosts only by UUID. Identify Prime as the host whose container IDs match neither
Agni's nor Legion's (`docker ps -aq` over SSH) — no hard-coded names to rot.
⚠️ Without `&everything` the logs endpoint returns **HTTP 200 with an empty body** for a quiet
container — an empty answer that looks like "no logs".

---

## Traps met while validating — each produced a false reading

| Probe | What it said | Truth |
|---|---|---|
| `sqlite3.connect("/data/hc.sqlite")` | "no such table" | **Created** a 0-byte file; the DB is `/config/hc.sqlite`. Always `file:…?mode=ro` |
| `ls -la /data /config` | DB is in `/data` | `ls` **sorts its operands** — the first block was `/config` |
| `docker logs homeassistant` | no errors | HA logs to `/config/home-assistant.log`, not stdout |
| `curl localhost:8080` on Agni | Alexa bridge down | `emulated_hue` binds `host_ip: 192.168.0.200` only |
| `State.FinishedAt` | failing since Sep 26 | last **stop**; the start failure has no timestamp of its own |
| Legion `date` | clock 5.5 h behind | Legion is **UTC**, the others IST — `timedatectl` says synchronised |
