#!/usr/bin/env bash
# ==============================================================================
# KryNet Portainer API Helper for Workstation & Autonomous Fleet Agents
# ==============================================================================
# Supports:
#   - Agni Master Portainer (https://portainer2.krynet.cc) -> Manages Agni (local) & Legion (agent)
#   - Prime Portainer (https://portainer.krynet.cc) -> Manages Prime (local)
# ==============================================================================
set -eo pipefail

AGNI_PORTAINER_URL="${PORTAINER_AGNI_URL:-https://portainer2.krynet.cc}"
PRIME_PORTAINER_URL="${PORTAINER_PRIME_URL:-https://portainer.krynet.cc}"

usage() {
    echo "Usage: $0 <command> [arguments...]"
    echo ""
    echo "Commands:"
    echo "  environments [agni|prime]                               - List environments on Agni or Prime Portainer"
    echo "  stacks [agni|prime|legion|all]                          - List stacks deployed on target node"
    echo "  get-stack <node> <stack_name>                           - Retrieve stack compose YAML and details"
    echo "  deploy <node> <stack_name> <compose_file> [env_file]    - Deploy or update a stack from local file"
    echo "  redeploy <node> <stack_name>                            - Repull images and redeploy an existing stack"
    echo "  stop <node> <stack_name>                                - Stop a stack"
    echo "  start <node> <stack_name>                               - Start a stack"
    echo "  containers <node>                                       - List all containers on target node"
    echo ""
    echo "Target Nodes: agni, prime, legion"
    exit 1
}

load_tokens() {
    if [ -z "$PORTAINER_AGNI_TOKEN" ] && [ -f "$HOME/.portainer/agni_token" ]; then
        PORTAINER_AGNI_TOKEN="$(cat "$HOME/.portainer/agni_token" | tr -d '[:space:]')"
    fi
    if [ -z "$PORTAINER_PRIME_TOKEN" ] && [ -f "$HOME/.portainer/prime_token" ]; then
        PORTAINER_PRIME_TOKEN="$(cat "$HOME/.portainer/prime_token" | tr -d '[:space:]')"
    fi
}

# Resolve Portainer Base URL, Auth Token, and Endpoint ID for a target node
resolve_node() {
    local target_node="$1"
    load_tokens

    case "$target_node" in
        agni)
            if [ -z "$PORTAINER_AGNI_TOKEN" ]; then
                echo "Error: PORTAINER_AGNI_TOKEN not found in env or ~/.portainer/agni_token" >&2
                exit 1
            fi
            API_URL="$AGNI_PORTAINER_URL"
            API_TOKEN="$PORTAINER_AGNI_TOKEN"
            ENDPOINT_ID=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/endpoints" | jq -r '.[] | select(.Name | test("local|agni"; "i")) | .Id' | head -n 1)
            [ -n "$ENDPOINT_ID" ] || ENDPOINT_ID=1
            ;;
        legion)
            if [ -z "$PORTAINER_AGNI_TOKEN" ]; then
                echo "Error: PORTAINER_AGNI_TOKEN not found in env or ~/.portainer/agni_token" >&2
                exit 1
            fi
            API_URL="$AGNI_PORTAINER_URL"
            API_TOKEN="$PORTAINER_AGNI_TOKEN"
            ENDPOINT_ID=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/endpoints" | jq -r '.[] | select(.Name | test("legion"; "i")) | .Id' | head -n 1)
            if [ -z "$ENDPOINT_ID" ] || [ "$ENDPOINT_ID" = "null" ]; then
                echo "Error: Legion endpoint not found on Agni Portainer ($API_URL/api/endpoints)" >&2
                exit 1
            fi
            ;;
        prime)
            if [ -z "$PORTAINER_PRIME_TOKEN" ]; then
                echo "Error: PORTAINER_PRIME_TOKEN not found in env or ~/.portainer/prime_token" >&2
                exit 1
            fi
            API_URL="$PRIME_PORTAINER_URL"
            API_TOKEN="$PORTAINER_PRIME_TOKEN"
            ENDPOINT_ID=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/endpoints" | jq -r '.[0].Id')
            [ -n "$ENDPOINT_ID" ] || ENDPOINT_ID=2
            ;;
        *)
            echo "Error: Unknown node '$target_node'. Must be agni, prime, or legion." >&2
            exit 1
            ;;
    esac
}

cmd="${1:-help}"

case "$cmd" in
    environments)
        load_tokens
        target="${2:-all}"
        if [ "$target" = "agni" ] || [ "$target" = "all" ]; then
            if [ -n "$PORTAINER_AGNI_TOKEN" ]; then
                echo "=== Agni Master Portainer ($AGNI_PORTAINER_URL) Environments ==="
                curl -k -s -H "X-API-Key: $PORTAINER_AGNI_TOKEN" "$AGNI_PORTAINER_URL/api/endpoints" | jq '.[] | {id: .Id, name: .Name, type: .Type, status: .Status, url: .URL}'
            fi
        fi
        if [ "$target" = "prime" ] || [ "$target" = "all" ]; then
            if [ -n "$PORTAINER_PRIME_TOKEN" ]; then
                echo "=== Prime Portainer ($PRIME_PORTAINER_URL) Environments ==="
                curl -k -s -H "X-API-Key: $PORTAINER_PRIME_TOKEN" "$PRIME_PORTAINER_URL/api/endpoints" | jq '.[] | {id: .Id, name: .Name, type: .Type, status: .Status, url: .URL}'
            fi
        fi
        ;;

    stacks)
        target="${2:-all}"
        load_tokens
        if [ "$target" = "all" ]; then
            $0 stacks agni
            echo ""
            $0 stacks legion
            echo ""
            $0 stacks prime
        else
            resolve_node "$target"
            echo "=== Stacks on $target (Endpoint ID: $ENDPOINT_ID) ==="
            curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks" | jq --argjson ep "$ENDPOINT_ID" \
                '.[] | select(.EndpointId == $ep) | {id: .Id, name: .Name, status: (if .Status == 1 then "running" else "stopped" end), updated_at: .UpdateDate}'
        fi
        ;;

    get-stack)
        target_node="${2:-}"
        stack_name="${3:-}"
        [ -n "$target_node" ] && [ -n "$stack_name" ] || usage
        resolve_node "$target_node"
        
        stack_id=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks" | jq --argjson ep "$ENDPOINT_ID" --arg name "$stack_name" \
            '.[] | select(.EndpointId == $ep and .Name == $name) | .Id')
        
        if [ -z "$stack_id" ] || [ "$stack_id" = "null" ]; then
            echo "Stack '$stack_name' not found on node '$target_node'." >&2
            exit 1
        fi
        
        curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks/$stack_id/file" | jq -r .StackFileContent
        ;;

    deploy)
        target_node="${2:-}"
        stack_name="${3:-}"
        compose_file="${4:-}"
        env_file="${5:-}"
        [ -n "$target_node" ] && [ -n "$stack_name" ] && [ -f "$compose_file" ] || usage
        resolve_node "$target_node"

        stack_content=$(cat "$compose_file")
        
        # Build env array
        env_json="[]"
        if [ -n "$env_file" ] && [ -f "$env_file" ]; then
            env_json=$(grep -v '^#' "$env_file" | grep '=' | jq -R -s 'split("\n") | map(select(length > 0)) | map(split("=") | {name: .[0], value: .[1:] | join("=")})')
        fi

        # Check if stack already exists
        existing_stack_id=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks" | jq --argjson ep "$ENDPOINT_ID" --arg name "$stack_name" \
            '.[] | select(.EndpointId == $ep and .Name == $name) | .Id')

        if [ -n "$existing_stack_id" ] && [ "$existing_stack_id" != "null" ]; then
            echo "Stack '$stack_name' (ID: $existing_stack_id) exists on $target_node. Updating stack..."
            payload=$(jq -n \
                --arg content "$stack_content" \
                --argjson envs "$env_json" \
                '{stackFileContent: $content, env: $envs, prune: true, pullImage: true}')
            
            response=$(curl -k -s -X PUT -H "X-API-Key: $API_TOKEN" -H "Content-Type: application/json" \
                "$API_URL/api/stacks/$existing_stack_id?endpointId=$ENDPOINT_ID" -d "$payload")
            echo "$response" | jq '{id: .Id, name: .Name, status: .Status}' 2>/dev/null || echo "$response"
        else
            echo "Creating new stack '$stack_name' on $target_node (Endpoint: $ENDPOINT_ID)..."
            payload=$(jq -n \
                --arg name "$stack_name" \
                --arg content "$stack_content" \
                --argjson envs "$env_json" \
                '{name: $name, stackFileContent: $content, env: $envs}')
            
            response=$(curl -k -s -X POST -H "X-API-Key: $API_TOKEN" -H "Content-Type: application/json" \
                "$API_URL/api/stacks/create/standalone/string?endpointId=$ENDPOINT_ID" -d "$payload")
            echo "$response" | jq '{id: .Id, name: .Name, status: .Status}' 2>/dev/null || echo "$response"
        fi
        ;;

    redeploy)
        target_node="${2:-}"
        stack_name="${3:-}"
        [ -n "$target_node" ] && [ -n "$stack_name" ] || usage
        resolve_node "$target_node"

        stack_info=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks" | jq --argjson ep "$ENDPOINT_ID" --arg name "$stack_name" \
            '.[] | select(.EndpointId == $ep and .Name == $name)')
        stack_id=$(echo "$stack_info" | jq -r .Id)

        if [ -z "$stack_id" ] || [ "$stack_id" = "null" ]; then
            echo "Stack '$stack_name' not found on node '$target_node'." >&2
            exit 1
        fi

        stack_content=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks/$stack_id/file" | jq -r .StackFileContent)
        stack_env=$(echo "$stack_info" | jq .Env)
        [ "$stack_env" != "null" ] || stack_env="[]"

        echo "Redeploying stack '$stack_name' (ID: $stack_id) on $target_node with pullImage: true..."
        payload=$(jq -n \
            --arg content "$stack_content" \
            --argjson envs "$stack_env" \
            '{stackFileContent: $content, env: $envs, prune: true, pullImage: true}')
        
        response=$(curl -k -s -X PUT -H "X-API-Key: $API_TOKEN" -H "Content-Type: application/json" \
            "$API_URL/api/stacks/$stack_id?endpointId=$ENDPOINT_ID" -d "$payload")
        echo "$response" | jq '{id: .Id, name: .Name, status: .Status}' 2>/dev/null || echo "$response"
        ;;

    stop)
        target_node="${2:-}"
        stack_name="${3:-}"
        [ -n "$target_node" ] && [ -n "$stack_name" ] || usage
        resolve_node "$target_node"

        stack_id=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks" | jq --argjson ep "$ENDPOINT_ID" --arg name "$stack_name" \
            '.[] | select(.EndpointId == $ep and .Name == $name) | .Id')
        
        if [ -z "$stack_id" ] || [ "$stack_id" = "null" ]; then
            echo "Stack '$stack_name' not found on node '$target_node'." >&2
            exit 1
        fi
        
        curl -k -s -X POST -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks/$stack_id/stop?endpointId=$ENDPOINT_ID" | jq .
        ;;

    start)
        target_node="${2:-}"
        stack_name="${3:-}"
        [ -n "$target_node" ] && [ -n "$stack_name" ] || usage
        resolve_node "$target_node"

        stack_id=$(curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks" | jq --argjson ep "$ENDPOINT_ID" --arg name "$stack_name" \
            '.[] | select(.EndpointId == $ep and .Name == $name) | .Id')
        
        if [ -z "$stack_id" ] || [ "$stack_id" = "null" ]; then
            echo "Stack '$stack_name' not found on node '$target_node'." >&2
            exit 1
        fi
        
        curl -k -s -X POST -H "X-API-Key: $API_TOKEN" "$API_URL/api/stacks/$stack_id/start?endpointId=$ENDPOINT_ID" | jq .
        ;;

    containers)
        target_node="${2:-}"
        [ -n "$target_node" ] || usage
        resolve_node "$target_node"

        echo "=== Containers on $target_node (Endpoint ID: $ENDPOINT_ID) ==="
        curl -k -s -H "X-API-Key: $API_TOKEN" "$API_URL/api/endpoints/$ENDPOINT_ID/docker/containers/json?all=true" | jq \
            '.[] | {name: .Names[0], image: .Image, state: .State, status: .Status, ports: [.Ports[]? | select(.PublicPort != null) | "\(.PublicPort):\(.PrivatePort)"]}'
        ;;

    *)
        usage
        ;;
esac
