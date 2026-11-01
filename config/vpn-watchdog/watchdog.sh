#!/bin/sh
# Restart containers that share the VPN container's network namespace after it bounces,
# and autonomously heal the VPN container if it becomes persistently unhealthy.
#
# WHY THIS EXISTS
# `network_mode: service:gluetun` makes a container live inside gluetun's network
# namespace. When gluetun stops or its WireGuard tunnel drops, that namespace disappears
# and its dependents either die instantly or stall with dead sockets.
# Docker does NOT restart dependents when the namespace returns, and Docker does NOT
# restart unhealthy containers on its own.
#
# This watchdog provides full autonomous self-healing:
# 1. Proactively restarts Gluetun if it stays unhealthy for 3 consecutive checks (re-establishing WireGuard).
# 2. Automatically cascades a restart to all dependent containers (e.g. qbittorrent, seerr)
#    whenever Gluetun bounces, ensuring their network sockets rebind cleanly to tun0.
# 3. Restarts exited or dead dependents once the VPN is healthy.
# 4. Restarts dependent containers if they report 'unhealthy' while the VPN is healthy.
set -eu

VPN="${VPN_CONTAINER:-gluetun}"
INTERVAL="${CHECK_INTERVAL:-30}"
UNHEALTHY_LIMIT="${UNHEALTHY_THRESHOLD:-3}"

log() { echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $*"; }

log "watchdog starting: vpn=$VPN interval=${INTERVAL}s unhealthy_limit=${UNHEALTHY_LIMIT}"

UNHEALTHY_COUNT=0
LAST_VPN_STARTED=""

while true; do
    if ! vpn_id="$(docker inspect -f '{{.Id}}' "$VPN" 2>/dev/null)"; then
        log "WARN $VPN not found; nothing to guard"
        sleep "$INTERVAL"
        continue
    fi

    vpn_state="$(docker inspect -f '{{.State.Status}}' "$VPN" 2>/dev/null || echo unknown)"
    vpn_health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$VPN" 2>/dev/null || echo unknown)"

    if [ "$vpn_state" != "running" ] || { [ "$vpn_health" != "healthy" ] && [ "$vpn_health" != "none" ]; }; then
        UNHEALTHY_COUNT=$((UNHEALTHY_COUNT + 1))
        log "vpn not ready (state=$vpn_state health=$vpn_health fail_count=$UNHEALTHY_COUNT/$UNHEALTHY_LIMIT); waiting"
        
        # If Gluetun is stuck in an unhealthy running state (WireGuard tunnel stalled), restart it
        if [ "$vpn_state" = "running" ] && [ "$UNHEALTHY_COUNT" -ge "$UNHEALTHY_LIMIT" ]; then
            log "HEAL: $VPN has been unhealthy for $UNHEALTHY_COUNT consecutive checks. Restarting $VPN to recover WireGuard handshake..."
            if docker restart "$VPN" >/dev/null 2>&1; then
                log "HEAL: $VPN restart triggered successfully"
            else
                log "ERROR: failed to restart $VPN"
            fi
            UNHEALTHY_COUNT=0
            sleep 15
        fi

        sleep "$INTERVAL"
        continue
    fi

    # VPN is confirmed running and healthy
    UNHEALTHY_COUNT=0
    vpn_started="$(docker inspect -f '{{.State.StartedAt}}' "$VPN" 2>/dev/null || echo '')"

    # Detect if Gluetun was restarted since the last loop
    VPN_BOUNCED=0
    if [ -n "$LAST_VPN_STARTED" ] && [ "$LAST_VPN_STARTED" != "$vpn_started" ]; then
        log "CASCADE: $VPN bounced (started at $vpn_started, previous was $LAST_VPN_STARTED). Cycling dependent network stacks..."
        VPN_BOUNCED=1
    fi
    LAST_VPN_STARTED="$vpn_started"

    for c in $(docker ps -a --format '{{.Names}}'); do
        [ "$c" = "$VPN" ] && continue
        mode="$(docker inspect -f '{{.HostConfig.NetworkMode}}' "$c" 2>/dev/null || echo '')"
        case "$mode" in
            container:*) ;;
            *) continue ;;
        esac

        ref="${mode#container:}"
        if [ "$ref" != "$vpn_id" ]; then
            log "STALE: $c references a $VPN that no longer exists ($(echo "$ref" | cut -c1-12)...); needs stack redeploy"
            continue
        fi

        state="$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo unknown)"
        c_health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$c" 2>/dev/null || echo unknown)"

        # If Gluetun bounced, restart running dependents to refresh sockets on new tun0 interface
        if [ "$VPN_BOUNCED" -eq 1 ] && [ "$state" = "running" ]; then
            log "CASCADE: restarting $c to rebind to fresh $VPN network namespace"
            docker restart "$c" >/dev/null 2>&1 || true
            continue
        fi

        case "$state" in
            running)
                if [ "$c_health" = "unhealthy" ]; then
                    log "RECOVER: $c is reported unhealthy while $VPN is healthy -- restarting $c"
                    docker restart "$c" >/dev/null 2>&1 || true
                fi
                ;;
            exited|dead)
                code="$(docker inspect -f '{{.State.ExitCode}}' "$c" 2>/dev/null || echo '?')"
                log "RECOVER: $c is $state (exit=$code) while $VPN is healthy -- starting"
                if docker start "$c" >/dev/null 2>&1; then
                    log "RECOVER: $c started successfully"
                else
                    log "ERROR: failed to start $c"
                fi
                ;;
            restarting|created)
                ;;
            *)
                log "NOTE: $c in unexpected state '$state'"
                ;;
        esac
    done

    sleep "$INTERVAL"
done
