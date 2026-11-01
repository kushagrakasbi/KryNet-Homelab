#!/usr/bin/env bash
# Validate the whole fleet after a power loss, a multi-node restart, or any time the
# question is "is everything actually back?". READ-ONLY apart from touching automounts.
#
# WHY THIS EXISTS
# 🔴 A power cycle's damage is almost never "a container crashed". It is a container that
# FAILED TO START (exit 128, RestartCount=0), and Docker never retries a start failure the
# way it retries an exit. After the 2026-09-26 outage that was seven containers across two
# nodes, all showing a plain "Exited" with nothing restarting them:
#   * Legion booted a kernel with no NVIDIA module  -> every GPU container dead
#   * Agni came up before Prime                     -> an SMB automount failed -> copyparty
# Neither shows up in Gatus as anything but "down", and neither says why.
#
# Works from the work laptop AND the personal Mac: it needs only `ssh agni|prime|legion`,
# never a Portainer token. Prime's containers are read through Agni's Dozzle, which already
# aggregates every node's agent — so a sleeping Mac does not blind it.
#
# HA checks need a long-lived token in $HA_TOKEN or ~/.ha/token; without one they report
# SKIP rather than passing silently.
#
# Usage:  scripts/fleet-validate.sh      exit 0 = healthy, 1 = findings, 2 = something unchecked
set -uo pipefail

FIND=0; UNCHECKED=0
SSH=(ssh -o ConnectTimeout=8 -o BatchMode=yes)
HA_URL="${HA_URL:-http://192.168.0.200:8123}"
section() { printf '\n== %s\n' "$*"; }
ok()   { echo "  ok    $*"; }
bad()  { echo "  FAIL  $*"; FIND=1; }
warn() { echo "  warn  $*"; }
skip() { echo "  SKIP  $*"; UNCHECKED=1; }
on()   { "${SSH[@]}" "$@"; }

section "Nodes — reachable, clock, failed units"
UP=" "
for n in agni prime legion; do
    out=$(on "$n" 'echo "boot=$(uptime -s) ntp=$(timedatectl show -p NTPSynchronized --value 2>/dev/null)"; systemctl --failed --no-legend --plain 2>/dev/null | awk "{print \$1}"' 2>/dev/null) \
        || { bad "$n unreachable over SSH (off the home LAN? node down?)"; continue; }
    UP="$UP$n "
    head=$(echo "$out" | head -1); failed=$(echo "$out" | tail -n +2 | tr '\n' ' ')
    case "$head" in *ntp=yes*) ok "$n $head" ;; *) bad "$n clock not NTP-synchronised: $head" ;; esac
    [ -n "${failed// /}" ] && bad "$n failed systemd units: $failed"
done
reach() { [[ "$UP" == *" $1 "* ]]; }

section "Containers — Agni and Legion (docker inspect)"
AGNI_IDS=""; LEGION_IDS=""
for n in agni legion; do
    reach "$n" || { skip "$n containers"; continue; }
    ids=$(on "$n" 'docker ps -aq' | tr '\n' ' ')
    [ "$n" = agni ] && AGNI_IDS=$ids || LEGION_IDS=$ids
    on "$n" 'docker ps -aq | xargs -r docker inspect -f "{{.Name}}|{{.State.Status}}|{{if .State.Health}}{{.State.Health.Status}}{{end}}|{{.HostConfig.RestartPolicy.Name}}|{{.State.ExitCode}}|{{.RestartCount}}|{{json .State.Error}}"' \
    | python3 -c '
import sys, json
node = sys.argv[1]; bad = 0; n = 0
for line in sys.stdin:
    name, st, health, policy, code, restarts, err = line.rstrip("\n").split("|", 6)
    n += 1; name = name.lstrip("/"); err = json.loads(err or "\"\"")
    if st != "running" and policy in ("always", "unless-stopped"):
        bad += 1
        kind = "START FAILURE (never retried)" if code == "128" and restarts == "0" else "exited"
        print("  FAIL  %s %s: %s exit=%s — %s" % (node, name, kind, code, err.splitlines()[-1][:160] if err else "no error recorded"))
    elif health == "unhealthy":
        bad += 1; print("  FAIL  %s %s: unhealthy" % (node, name))
print("  ok    %s %d containers, %d problems" % (node, n, bad) if not bad else "  ----  %s %d containers, %d problems" % (node, n, bad))
sys.exit(1 if bad else 0)' "$n" || FIND=1
done

section "Containers — Prime (via Agni's Dozzle; no Portainer token needed)"
if reach agni && [ -n "$AGNI_IDS" ] && [ -n "$LEGION_IDS" ]; then
    on agni 'timeout 6 curl -sN http://localhost:8088/api/events/stream 2>/dev/null' \
    | python3 -c '
import sys, json
known = set(sys.argv[1].split()) | set(sys.argv[2].split())
ev = None
for line in sys.stdin:
    line = line.strip()
    if line.startswith("event:"): ev = line[6:].strip()
    elif line.startswith("data:") and ev == "containers-changed":
        hosts = {}
        for c in json.loads(line[5:]): hosts.setdefault(c["host"], []).append(c)
        # Prime = the host whose containers are neither Agni'"'"'s nor Legion'"'"'s.
        prime = [cs for cs in hosts.values() if not any(c["id"][:12] in known for c in cs)]
        if len(prime) != 1:
            print("  SKIP  Prime not identifiable in Dozzle (%d candidate hosts) — is its dozzle-agent up?" % len(prime)); sys.exit(2)
        cs = prime[0]; bad = [c for c in cs if c["state"] != "running" or c.get("health") == "unhealthy"]
        for c in bad: print("  FAIL  prime %s: %s %s" % (c["name"], c["state"], c.get("health", "")))
        print("  %s prime %d containers, %d not running/healthy, %d report healthy" %
              ("ok   " if not bad else "---- ", len(cs), len(bad), sum(c.get("health") == "healthy" for c in cs)))
        sys.exit(1 if bad else 0)
print("  SKIP  Dozzle stream returned no container list"); sys.exit(2)' "$AGNI_IDS" "$LEGION_IDS"
    rc=$?; [ $rc = 1 ] && FIND=1; [ $rc = 2 ] && UNCHECKED=1
else
    skip "Prime containers (needs Agni + Legion container lists first)"
fi

section "Legion GPU — driver loaded, and will it survive the NEXT reboot?"
if reach legion; then
    # 🔴 The driver is the no-dkms flavour: a precompiled module per kernel. unattended-upgrades
    # can install a new kernel without it, and nothing breaks until the next boot.
    on legion '
        if nvidia-smi --query-gpu=name,temperature.gpu --format=csv,noheader >/tmp/.nv 2>&1; then echo "ok    nvidia-smi: $(cat /tmp/.nv)"; else echo "FAIL  nvidia-smi: $(head -1 /tmp/.nv)"; fi; rm -f /tmp/.nv
        has() { dpkg -l "linux-modules-nvidia-*-$1" 2>/dev/null | grep -q "^ii"; }
        run=$(uname -r); new=$(ls /boot/vmlinuz-* | sed "s|/boot/vmlinuz-||" | sort -V | tail -1)
        has "$run" && echo "ok    NVIDIA module installed for running kernel $run" || echo "FAIL  no NVIDIA module for RUNNING kernel $run — fix: sudo apt-get install linux-modules-nvidia-595-server-open-generic, then reboot"
        [ "$new" != "$run" ] && { has "$new" && echo "ok    next-boot kernel $new has its NVIDIA module" || echo "FAIL  next reboot boots $new with NO NVIDIA module — every GPU container will fail to start"; }
        # 🔴 A running container can LOSE the GPU while the host keeps it: any systemctl
        # daemon-reload (every unattended-upgrade) revokes the device unless /dev/char links exist.
        # Seen 2026-09-30 — Ollama, Immich ML and Tdarr fell back to CPU for two days, silently.
        for d in /dev/nvidia0 /dev/nvidiactl /dev/nvidia-uvm /dev/nvidia-modeset /dev/nvidia-uvm-tools; do
            [ -c "$d" ] || continue; mm=$(stat -c "%t:%T" "$d")
            [ -e "/dev/char/$((16#${mm%:*})):$((16#${mm#*:}))" ] || echo "FAIL  $d has no /dev/char link — the next daemon-reload strips the GPU from running containers (udev rule: fleet-health post-outage.md §7)"
        done
        for c in $(docker ps -q); do
            info=$(docker inspect -f "{{.Name}}|{{.HostConfig.Runtime}}|{{json .HostConfig.DeviceRequests}}" "$c")
            case "$info" in *"|nvidia|"*|*gpu*) ;; *) continue ;; esac
            n=${info%%|*}; n=${n#/}
            out=$(docker exec "$c" nvidia-smi -L 2>&1 | head -1)
            case "$out" in "GPU "*) echo "ok    $n sees the GPU" ;;
                *"executable file not found"*|*"not found"*) echo "warn  $n has no nvidia-smi — GPU access unverifiable" ;;
                *) echo "FAIL  $n has LOST the GPU: $out — docker restart $n" ;; esac
        done
        true' | sed 's/^/  /' | tee /tmp/.fv_gpu
    grep -q FAIL /tmp/.fv_gpu && FIND=1; rm -f /tmp/.fv_gpu
else skip "Legion GPU"; fi

section "Remote mounts — touching each (an automount that failed at boot retries on access)"
for n in agni legion; do
    reach "$n" || { skip "$n mounts"; continue; }
    on "$n" 'for t in $(awk "!/^[[:space:]]*#/ && (\$3 ~ /^(cifs|nfs|nfs4)$/) {print \$2}" /etc/fstab); do
        timeout 20 ls "$t" >/dev/null 2>&1; findmnt -n "$t" >/dev/null && echo "ok    '"$n"' $t" || echo "FAIL  '"$n"' $t not mounted"; done' | sed 's/^/  /' | tee /tmp/.fv_mnt
    grep -q FAIL /tmp/.fv_mnt && FIND=1; rm -f /tmp/.fv_mnt
done

section "ZFS on Prime"
if reach prime; then
    on prime 'export PATH=$PATH:/usr/sbin
        s=$(zpool status -x); [ "$s" = "all pools are healthy" ] && echo "ok    $s" || echo "FAIL  $s"
        zpool list -H -o name,cap | while read p c; do [ "${c%\%}" -ge 80 ] && echo "FAIL  $p at $c (ZFS degrades past 80%)" || echo "ok    $p at $c"; done
        # A "reboot" line with no "shutdown" line before it = power was pulled.
        last -x 2>/dev/null | grep -E "^(reboot|shutdown)" | head -2 | awk "NR==1{r=\$1} NR==2{p=\$1} END{if(r==\"reboot\" && p==\"reboot\") print \"warn  last boot was UNCLEAN (power pulled) — consider a scrub from the TrueNAS UI\"}"
        zpool status | awk "/pool:/{p=\$2} /scan: scrub/{sub(/.*scan: scrub /,\"\"); print \"info  \" p \": last scrub \" \$0}"' | sed 's/^/  /' | tee /tmp/.fv_zfs
    grep -q FAIL /tmp/.fv_zfs && FIND=1; rm -f /tmp/.fv_zfs
else skip "ZFS"; fi

section "Gatus, Prometheus, Healthchecks (all read on Agni)"
if reach agni; then
    on agni 'curl -s --max-time 10 http://localhost:3001/api/v1/endpoints/statuses' | python3 -c '
import sys, json
d = json.load(sys.stdin); bad = [e for e in d if e["results"] and not e["results"][-1]["success"]]
for e in bad: print("  FAIL  gatus %s / %s" % (e["group"], e["name"]))
print("  %s gatus %d/%d endpoints passing" % ("ok   " if not bad else "---- ", len(d) - len(bad), len(d)))
sys.exit(1 if bad else 0)' || FIND=1
    on agni "curl -s --max-time 10 'http://localhost:9090/api/v1/query?query=up'" | python3 -c '
import sys, json
r = json.load(sys.stdin)["data"]["result"]; down = [x["metric"] for x in r if x["value"][1] == "0"]
for m in down: print("  FAIL  prometheus target down: %s %s" % (m.get("job"), m.get("instance")))
print("  %s prometheus %d/%d targets up" % ("ok   " if not down else "---- ", len(r) - len(down), len(r)))
sys.exit(1 if down else 0)' || FIND=1
    # 🔴 mode=ro: sqlite3.connect() on a wrong path CREATES an empty file, which is how a
    # stray 0-byte hc.sqlite appeared in /data on 2026-09-27. The real DB is /config/hc.sqlite.
    on agni 'docker exec healthchecks python3 -c "
import sqlite3
c = sqlite3.connect(\"file:/config/hc.sqlite?mode=ro\", uri=True)
for n, s, lp in c.execute(\"select name, status, last_ping from api_check order by name\"):
    print((\"ok   \" if s == \"up\" else \"FAIL \"), \"healthchecks\", n, \"status=\" + s, \"last_ping=\" + str(lp)[:16])
"' | sed 's/^/  /' | tee /tmp/.fv_hc
    if grep -q FAIL /tmp/.fv_hc; then
        FIND=1
        echo "        ⚠️ a backup that ran within minutes of boot can succeed while its ping is lost (see fleet-health)"
    fi
    rm -f /tmp/.fv_hc
else skip "Gatus / Prometheus / Healthchecks"; fi

section "Ingress, DNS, Tailscale"
if reach agni; then
    v=$(on agni 'docker exec caddy caddy validate --config /etc/caddy/Caddyfile 2>&1 | grep -c "Valid configuration"')
    [ "$v" = 1 ] && ok "caddy config valid" || bad "caddy config does NOT validate"
    on agni 'for h in ha.lan.kkasbi.in photos.kkasbi.in hc.krynet.cc; do
        e=$(echo | timeout 5 openssl s_client -connect 127.0.0.1:443 -servername $h 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        [ -z "$e" ] && { echo "FAIL  cert $h unreadable"; continue; }
        d=$(( ($(date -d "$e" +%s) - $(date +%s)) / 86400 )); [ $d -ge 14 ] && echo "ok    cert $h $d days left" || echo "FAIL  cert $h expires in $d days"; done' \
        | sed 's/^/  /' | tee /tmp/.fv_crt
    grep -q FAIL /tmp/.fv_crt && FIND=1; rm -f /tmp/.fv_crt
    on agni 'docker exec tailscale-agni tailscale status --json' | python3 -c '
import sys, json
d = json.load(sys.stdin); want = {"agni-server", "prime-server", "legion-server"}
seen = {d["Self"]["HostName"]: True} | {p["HostName"]: p.get("Online", False) for p in d.get("Peer", {}).values()}
bad = [h for h in sorted(want) if not seen.get(h)]
for h in bad: print("  FAIL  tailscale %s offline" % h)
print("  %s tailscale %d/3 servers online" % ("ok   " if not bad else "---- ", 3 - len(bad)))
sys.exit(1 if bad else 0)' || FIND=1
else skip "Caddy / Tailscale"; fi
if command -v dig >/dev/null; then
    for s in 192.168.0.200 192.168.0.100; do
        a=$(dig +short +time=3 +tries=2 @"$s" photos.lan.kkasbi.in 2>/dev/null | tail -1)
        g=$(dig +short +time=3 +tries=2 @"$s" google.com 2>/dev/null | tail -1)
        [ "$a" = 192.168.0.200 ] && [ -n "$g" ] && ok "dns $s answers (lan -> $a, public ok)" || bad "dns $s: lan='$a' public='$g'"
    done
else skip "dns (no dig on this machine)"; fi

section "Home Assistant"
TOK="${HA_TOKEN:-$(tr -d '[:space:]' < ~/.ha/token 2>/dev/null)}"
if [ -z "$TOK" ]; then
    skip "HA (no \$HA_TOKEN and no ~/.ha/token on this machine)"
elif ! curl -s -o /dev/null --max-time 8 -w '%{http_code}' -H "Authorization: Bearer $TOK" "$HA_URL/api/" | grep -q 200; then
    bad "HA API not answering 200 at $HA_URL"
else
    curl -s --max-time 15 -H "Authorization: Bearer $TOK" "$HA_URL/api/config/config_entries/entry" | python3 -c '
import sys, json
d = json.load(sys.stdin); bad = [e for e in d if e["state"] != "loaded" and not e.get("disabled_by")]
for e in bad: print("  FAIL  ha integration %s / %s: %s" % (e["domain"], e["title"], e["state"]))
print("  %s ha %d/%d integrations loaded" % ("ok   " if not bad else "---- ", len(d) - len(bad), len(d)))
sys.exit(1 if bad else 0)' || FIND=1
    TPL='{% set p = label_entities("protected") %}{{ states.automation | selectattr("state","eq","on") | list | count }}/{{ states.automation | list | count }}|{{ p | count }}|{{ p | reject("is_state","on") | join(",") }}|{{ label_entities("night_off") | select("is_state","unavailable") | join(",") }}'
    r=$(python3 -c 'import json,sys; print(json.dumps({"template": sys.argv[1]}))' "$TPL" \
        | curl -s --max-time 15 -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' -d @- "$HA_URL/api/template")
    IFS='|' read -r autos nprot protoff nightun <<<"$r"
    [ "${autos%/*}" = "${autos#*/}" ] && ok "ha automations on: $autos" || bad "ha automations on: $autos"
    # 🔴 protected = the loads that carry the fleet and the fridge. Any of them off is the finding.
    [ -z "$protoff" ] && ok "ha all $nprot protected loads on" || bad "ha protected load(s) NOT on: $protoff"
    [ -z "$nightun" ] && ok "ha night_off loads all reachable" || warn "ha night_off unavailable: $nightun (an upstream switch may simply be off)"
    # emulated_hue binds host_ip only, so localhost on Agni is refused.
    n=$(on agni 'curl -s --max-time 5 http://192.168.0.200:8080/api/pi/lights' 2>/dev/null | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' 2>/dev/null)
    [ -n "$n" ] && [ "$n" -gt 0 ] && ok "emulated_hue (Alexa bridge) exposes $n devices" || bad "emulated_hue not answering — Alexa voice control is down"
fi

section "Fleet Network Throughput & EasyMesh Backhaul"
if reach agni && reach prime; then
    # Agni (Office) to Prime (Corridor) validates the EasyMesh Ethernet backhaul.
    # Healthy Gigabit negotiates at 1000M Full Duplex (>50 MB/s; typically ~110-115 MB/s).
    # Auto-negotiation failure / degraded cable drops to 10BASE-T (~1.1 MB/s).
    spd_agni=$(on agni 'curl -s --max-time 4 -w "%{speed_download}" -o /dev/null "http://192.168.0.100:8992/downloading?size=10000000"' 2>/dev/null || echo 0)
    spd_agni_mb=$(python3 -c "print(round(float('$spd_agni') / 1000000, 1))" 2>/dev/null || echo 0)
    if python3 -c "import sys; sys.exit(0 if float('$spd_agni') > 50000000 else 1)" 2>/dev/null; then
        ok "Agni -> Prime backhaul throughput: ${spd_agni_mb} MB/s (wire-speed Gigabit)"
    else
        bad "Agni -> Prime backhaul throughput degraded: ${spd_agni_mb} MB/s (<50 MB/s / 400 Mbps) — check EasyMesh link speed / Ethernet backhaul cable"
    fi
else skip "Backhaul throughput check (Agni or Prime unreachable)"; fi

if reach legion && reach prime; then
    spd_legion=$(on legion 'curl -s --max-time 4 -w "%{speed_download}" -o /dev/null "http://192.168.0.100:8992/downloading?size=10000000"' 2>/dev/null || echo 0)
    spd_legion_mb=$(python3 -c "print(round(float('$spd_legion') / 1000000, 1))" 2>/dev/null || echo 0)
    if python3 -c "import sys; sys.exit(0 if float('$spd_legion') > 50000000 else 1)" 2>/dev/null; then
        ok "Legion -> Prime backhaul throughput: ${spd_legion_mb} MB/s (wire-speed Gigabit)"
    else
        bad "Legion -> Prime backhaul throughput degraded: ${spd_legion_mb} MB/s (<50 MB/s / 400 Mbps) — check AX10 switch/port"
    fi
else skip "Legion backhaul throughput check (Legion or Prime unreachable)"; fi

section "Gluetun VPN, Downloader & Request Pipeline"
if reach prime; then
    qb_http=$(curl -s -o /dev/null --max-time 4 -w '%{http_code}' "http://192.168.0.100:8080/")
    if [ "$qb_http" = "200" ] || [ "$qb_http" = "403" ]; then
        ok "qBittorrent WebUI responding through Gluetun (HTTP $qb_http)"
    else
        bad "qBittorrent WebUI not responding through Gluetun (HTTP $qb_http)"
    fi

    seerr_ver=$(curl -s --max-time 4 "http://192.168.0.100:5055/api/v1/status" 2>/dev/null | python3 -c 'import sys, json; print(json.load(sys.stdin).get("version", ""))' 2>/dev/null || echo "")
    if [ -n "$seerr_ver" ]; then
        ok "Seerr API responding through Gluetun (v$seerr_ver)"
    else
        bad "Seerr API not responding through Gluetun (timeout or failure)"
    fi
else skip "Gluetun / qBittorrent / Seerr check (Prime unreachable)"; fi

section "Result"
if [ $FIND = 0 ] && [ $UNCHECKED = 0 ]; then echo "  HEALTHY — every check ran and passed"; exit 0; fi
[ $FIND = 1 ] && echo "  FINDINGS — see FAIL lines above"
[ $UNCHECKED = 1 ] && echo "  INCOMPLETE — SKIP lines above were not checked; do not read them as passing"
[ $FIND = 1 ] && exit 1; exit 2
