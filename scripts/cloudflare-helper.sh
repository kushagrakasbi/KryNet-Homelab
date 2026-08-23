#!/usr/bin/env bash
# ==============================================================================
# KryNet Cloudflare Management Helper for Workstation & Fleet Agents
# ==============================================================================
set -eo pipefail

usage() {
    echo "Usage: $0 {zones|dns <zone_name>|tunnels|verify-ssl <domain>|help}"
    echo "  zones                 - List all Cloudflare zones"
    echo "  dns <zone_name>       - List DNS records for a zone (default: krynet.cc)"
    echo "  tunnels               - List active Cloudflare Tunnels"
    echo "  verify-ssl <domain>   - Verify SSL certificate and response for a domain"
    exit 1
}

cmd="${1:-zones}"

check_token() {
    if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
        if [ -f "$HOME/.cloudflare/token" ]; then
            CLOUDFLARE_API_TOKEN="$(cat "$HOME/.cloudflare/token")"
        else
            echo "Error: CLOUDFLARE_API_TOKEN must be set in environment or in ~/.cloudflare/token" >&2
            exit 1
        fi
    fi
}

get_account_id() {
    if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
        CLOUDFLARE_ACCOUNT_ID=$(curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            "https://api.cloudflare.com/client/v4/zones" | jq -r '.result[0].account.id')
    fi
}

case "$cmd" in
    zones)
        check_token
        curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            "https://api.cloudflare.com/client/v4/zones" | jq '.result[] | {id: .id, name: .name, status: .status}'
        ;;
    dns)
        check_token
        zone_name="${2:-krynet.cc}"
        zone_id=$(curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            "https://api.cloudflare.com/client/v4/zones?name=$zone_name" | jq -r '.result[0].id')
        if [ -z "$zone_id" ] || [ "$zone_id" = "null" ]; then
            echo "Zone '$zone_name' not found." >&2
            exit 1
        fi
        curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" | jq '.result[] | {type: .type, name: .name, content: .content, proxied: .proxied}'
        ;;
    tunnels)
        check_token
        get_account_id
        if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ "$CLOUDFLARE_ACCOUNT_ID" = "null" ]; then
            echo "Error: Could not determine Cloudflare Account ID." >&2
            exit 1
        fi
        curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel" | jq '.result[] | {id: .id, name: .name, status: .status, created_at: .created_at, connections: [.connections[]?.colo_name]}'
        ;;
    verify-ssl)
        domain="${2:-photos.krynet.cc}"
        curl -s -I "https://$domain" | head -n 10
        ;;
    *)
        usage
        ;;
esac
