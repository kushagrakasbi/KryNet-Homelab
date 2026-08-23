#!/bin/bash

# KryNet-Agni Deployment Script
# This script sets up the Docker stack on Agni (192.168.0.200)

set -e  # Exit on error

echo "🚀 KryNet-Agni Deployment Script"
echo "================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on the correct machine
CURRENT_IP=$(hostname -I | awk '{print $1}')
if [[ "$CURRENT_IP" != "192.168.0.200" ]]; then
    echo -e "${YELLOW}⚠️  Warning: This script is designed for Agni (192.168.0.200)${NC}"
    echo -e "${YELLOW}   Current IP: $CURRENT_IP${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Define base directory
BASE_DIR="/home/agni/apps/docker"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_STACK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/stacks/agni"

echo "📂 Base directory: $BASE_DIR"
echo "📦 Stack files directory: $REPO_STACK_DIR"
echo ""

# Step 1: Create directory structure
echo "Step 1: Creating directory structure..."
mkdir -p "$BASE_DIR"/{caddy,adguard,ha,tailscale}
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Step 2: Copy stack files
echo "Step 2: Copying stack files..."
cp "$REPO_STACK_DIR/docker-compose.yml" "$BASE_DIR/"
cp "$REPO_STACK_DIR/Dockerfile" "$BASE_DIR/caddy/"
cp "$REPO_STACK_DIR/Caddyfile" "$BASE_DIR/caddy/"
echo -e "${GREEN}✓ Stack files copied${NC}"
echo ""

# Step 3: Setup environment file
echo "Step 3: Setting up environment file..."
if [ -f "$BASE_DIR/.env" ]; then
    echo -e "${YELLOW}⚠️  .env file already exists, skipping...${NC}"
else
    cp "$REPO_STACK_DIR/.env.example" "$BASE_DIR/.env"
    echo -e "${YELLOW}⚠️  Please edit $BASE_DIR/.env with your credentials${NC}"
    echo ""
    read -p "Press Enter to edit .env now, or Ctrl+C to exit and edit manually..."
    ${EDITOR:-nano} "$BASE_DIR/.env"
fi
echo ""

# Step 4: Check if data directories exist
echo "Step 4: Checking migrated data..."
if [ -d "$BASE_DIR/adguard/conf" ] && [ -f "$BASE_DIR/adguard/conf/AdGuardHome.yaml" ]; then
    echo -e "${GREEN}✓ AdGuard config found${NC}"
else
    echo -e "${RED}✗ AdGuard config not found at $BASE_DIR/adguard/conf${NC}"
    echo "  Please migrate data from Prime first!"
fi

if [ -d "$BASE_DIR/ha/config" ] && [ -d "$BASE_DIR/ha/config/.storage" ]; then
    echo -e "${GREEN}✓ Home Assistant config found${NC}"
else
    echo -e "${RED}✗ Home Assistant config not found at $BASE_DIR/ha/config${NC}"
    echo "  Please migrate data from Prime first!"
fi

if [ -d "$BASE_DIR/caddy/data" ]; then
    echo -e "${GREEN}✓ Caddy data directory found${NC}"
else
    echo -e "${YELLOW}⚠️  Caddy data directory not found (will be created on first run)${NC}"
    mkdir -p "$BASE_DIR/caddy/data"
fi
echo ""

# Step 5: Update AdGuard port
echo "Step 5: Updating AdGuard web UI port to 3000..."
ADGUARD_CONFIG="$BASE_DIR/adguard/conf/AdGuardHome.yaml"
if [ -f "$ADGUARD_CONFIG" ]; then
    # Backup original
    cp "$ADGUARD_CONFIG" "$ADGUARD_CONFIG.backup"
    
    # Update port (this is a simple sed, might need manual verification)
    if grep -q "address: 0.0.0.0:80" "$ADGUARD_CONFIG"; then
        sed -i 's/address: 0.0.0.0:80/address: 0.0.0.0:3000/g' "$ADGUARD_CONFIG"
        echo -e "${GREEN}✓ AdGuard port updated to 3000${NC}"
    elif grep -q "address: 0.0.0.0:3000" "$ADGUARD_CONFIG"; then
        echo -e "${GREEN}✓ AdGuard already configured for port 3000${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not automatically update AdGuard port${NC}"
        echo "  Please manually edit: $ADGUARD_CONFIG"
        echo "  Change 'address:' under 'http:' section to '0.0.0.0:3000'"
    fi
else
    echo -e "${YELLOW}⚠️  AdGuard config not found, skipping port update${NC}"
fi
echo ""

# Step 6: Build Caddy image
echo "Step 6: Building Caddy image with Cloudflare DNS plugin..."
cd "$BASE_DIR"
if docker compose build caddy; then
    echo -e "${GREEN}✓ Caddy image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build Caddy image${NC}"
    exit 1
fi
echo ""

# Step 7: Launch the stack
echo "Step 7: Launching the stack..."
read -p "Ready to start the stack? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker compose up -d
    echo -e "${GREEN}✓ Stack launched!${NC}"
    echo ""
    
    # Wait a few seconds for containers to start
    sleep 5
    
    # Show status
    echo "📊 Container Status:"
    docker compose ps
    echo ""
    
    echo "🎉 Deployment Complete!"
    echo ""
    echo "Access your services:"
    echo "  • Portainer:       https://192.168.0.200:9443"
    echo "  • AdGuard Home:    http://192.168.0.200:3000"
    echo "  • Home Assistant:  http://192.168.0.200:8123"
    echo ""
    echo "View logs with: docker compose logs -f"
    echo ""
    echo "Next steps:"
    echo "  1. Update router DNS to point to 192.168.0.200"
    echo "  2. Test domain resolution (e.g., ha.krynet.cc)"
    echo "  3. Update Cloudflare Tunnel to point to Agni"
    echo "  4. Monitor logs for 24 hours"
else
    echo -e "${YELLOW}Skipped stack launch. Run manually with:${NC}"
    echo "  cd $BASE_DIR && docker compose up -d"
fi
