#!/usr/bin/env bash
# ==============================================================================
# KryNet Tailscale Management Helper for Workstation & Fleet Agents
# ==============================================================================
set -eo pipefail

TAILSCALE_CLI="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
[ -x "$TAILSCALE_CLI" ] || TAILSCALE_CLI="tailscale"

usage() {
    echo "Usage: $0 {status|devices|ping <host>|authkey|help}"
    echo "  status         - Show local Tailscale connection status"
    echo "  devices        - List all active devices in the Tailnet via REST API"
    echo "  ping <host>    - Ping a specific Tailscale host"
    echo "  authkey        - Generate a new pre-authenticated key via REST API"
    exit 1
}

cmd="${1:-status}"

check_token() {
    if [ -z "$TAILSCALE_API_KEY" ]; then
        if [ -f "$HOME/.tailscale/token" ]; then
            TAILSCALE_API_KEY="$(cat "$HOME/.tailscale/token")"
        fi
    fi
}

case "$cmd" in
    status)
        "$TAILSCALE_CLI" status
        ;;
    devices)
        check_token
        if [ -n "$TAILSCALE_API_KEY" ]; then
            curl -s -H "Authorization: Bearer $TAILSCALE_API_KEY" \
                "https://api.tailscale.com/api/v2/tailnet/-/devices" | jq '.devices[] | {hostname: .hostname, ip: .addresses[0], os: .os, authorized: .authorized}'
        else
            "$TAILSCALE_CLI" status
        fi
        ;;
    ping)
        target="${2:-agni-server}"
        "$TAILSCALE_CLI" ping "$target"
        ;;
    authkey)
        check_token
        if [ -z "$TAILSCALE_API_KEY" ]; then
            echo "Error: TAILSCALE_API_KEY must be set in environment or in ~/.tailscale/token" >&2
            exit 1
        fi
        curl -s -X POST -H "Authorization: Bearer $TAILSCALE_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"capabilities": {"devices": {"create": {"reusable": false, "ephemeral": false, "tags": ["tag:server"]}}}}' \
            "https://api.tailscale.com/api/v2/tailnet/-/keys" | jq .
        ;;
    *)
        usage
        ;;
esac
