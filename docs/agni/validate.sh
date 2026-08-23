#!/bin/bash

# KryNet-Agni Pre-Deployment Validation Script
# Run this script BEFORE deploying to verify everything is ready

set -e

echo "🔍 KryNet-Agni Pre-Deployment Validation"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to check
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

check_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "1. System Information"
echo "---------------------"
check_info "Hostname: $(hostname)"
check_info "IP Address: $(hostname -I | awk '{print $1}')"
check_info "OS: $(lsb_release -d | cut -f2)"
check_info "Kernel: $(uname -r)"
echo ""

echo "2. Network Configuration"
echo "------------------------"
CURRENT_IP=$(hostname -I | awk '{print $1}')
if [[ "$CURRENT_IP" == "192.168.0.200" ]]; then
    check_pass "IP address is 192.168.0.200"
else
    check_warn "IP address is $CURRENT_IP (expected 192.168.0.200)"
fi

# Check if we can reach Prime
if ping -c 1 192.168.0.100 &> /dev/null; then
    check_pass "Can reach Prime (192.168.0.100)"
else
    check_fail "Cannot reach Prime (192.168.0.100)"
fi

# Check internet connectivity
if ping -c 1 1.1.1.1 &> /dev/null; then
    check_pass "Internet connectivity OK"
else
    check_fail "No internet connectivity"
fi
echo ""

echo "3. Docker Installation"
echo "----------------------"
if command -v docker &> /dev/null; then
    check_pass "Docker is installed"
    check_info "Version: $(docker --version)"
else
    check_fail "Docker is not installed"
fi

if command -v docker compose &> /dev/null; then
    check_pass "Docker Compose is installed"
    check_info "Version: $(docker compose version)"
else
    check_fail "Docker Compose is not installed"
fi

# Check if Docker daemon is running
if docker ps &> /dev/null; then
    check_pass "Docker daemon is running"
else
    check_fail "Docker daemon is not running"
fi
echo ""

echo "4. Port Availability"
echo "--------------------"
check_ports() {
    local port=$1
    local service=$2
    if sudo ss -tulpn | grep ":$port " &> /dev/null; then
        check_warn "Port $port is already in use (needed for $service)"
    else
        check_pass "Port $port is available ($service)"
    fi
}

check_ports 53 "AdGuard DNS"
check_ports 80 "Caddy HTTP"
check_ports 443 "Caddy HTTPS"
check_ports 3000 "AdGuard WebUI"
check_ports 8123 "Home Assistant"
check_ports 9443 "Portainer"
echo ""

echo "5. Directory Structure"
echo "----------------------"
BASE_DIR="/home/agni/apps/docker"

if [ -d "$BASE_DIR" ]; then
    check_pass "Base directory exists: $BASE_DIR"
else
    check_warn "Base directory does not exist: $BASE_DIR (will be created)"
fi

# Check for migrated data
if [ -d "$BASE_DIR/adguard/conf" ] && [ -f "$BASE_DIR/adguard/conf/AdGuardHome.yaml" ]; then
    check_pass "AdGuard config found"
else
    check_fail "AdGuard config not found at $BASE_DIR/adguard/conf"
fi

if [ -d "$BASE_DIR/ha/config" ]; then
    check_pass "Home Assistant config directory found"
    if [ -d "$BASE_DIR/ha/config/.storage" ]; then
        check_pass "Home Assistant .storage directory found"
    else
        check_warn "Home Assistant .storage directory not found"
    fi
else
    check_fail "Home Assistant config not found at $BASE_DIR/ha/config"
fi

if [ -d "$BASE_DIR/caddy" ]; then
    check_pass "Caddy directory exists"
    if [ -d "$BASE_DIR/caddy/data" ]; then
        check_pass "Caddy data directory found (SSL certs)"
    else
        check_warn "Caddy data directory not found (will be created)"
    fi
else
    check_warn "Caddy directory not found (will be created)"
fi
echo ""

echo "6. Environment Variables"
echo "------------------------"
if [ -f "$BASE_DIR/.env" ]; then
    check_pass ".env file exists"
    
    # Check for required variables
    if grep -q "CLOUDFLARE_API_TOKEN=" "$BASE_DIR/.env"; then
        if grep -q "CLOUDFLARE_API_TOKEN=your_" "$BASE_DIR/.env"; then
            check_warn "CLOUDFLARE_API_TOKEN not set (still placeholder)"
        else
            check_pass "CLOUDFLARE_API_TOKEN is set"
        fi
    else
        check_fail "CLOUDFLARE_API_TOKEN not found in .env"
    fi
    
    if grep -q "TS_AUTHKEY=" "$BASE_DIR/.env"; then
        if grep -q "TS_AUTHKEY=your_" "$BASE_DIR/.env"; then
            check_warn "TS_AUTHKEY not set (still placeholder)"
        else
            check_pass "TS_AUTHKEY is set"
        fi
    else
        check_fail "TS_AUTHKEY not found in .env"
    fi
else
    check_fail ".env file not found at $BASE_DIR/.env"
fi
echo ""

echo "7. Stack Files"
echo "--------------"
if [ -f "$BASE_DIR/docker-compose.yml" ]; then
    check_pass "docker-compose.yml exists"
else
    check_fail "docker-compose.yml not found"
fi

if [ -f "$BASE_DIR/caddy/Dockerfile" ]; then
    check_pass "Caddy Dockerfile exists"
else
    check_fail "Caddy Dockerfile not found"
fi

if [ -f "$BASE_DIR/caddy/Caddyfile" ]; then
    check_pass "Caddyfile exists"
else
    check_fail "Caddyfile not found"
fi
echo ""

echo "8. Disk Space"
echo "-------------"
AVAILABLE=$(df -h "$HOME" | awk 'NR==2 {print $4}')
check_info "Available space in $HOME: $AVAILABLE"

AVAILABLE_GB=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_GB" -gt 10 ]; then
    check_pass "Sufficient disk space (>10GB available)"
else
    check_warn "Low disk space (<10GB available)"
fi
echo ""

echo "9. Memory"
echo "---------"
TOTAL_MEM=$(free -h | awk 'NR==2 {print $2}')
AVAILABLE_MEM=$(free -h | awk 'NR==2 {print $7}')
check_info "Total memory: $TOTAL_MEM"
check_info "Available memory: $AVAILABLE_MEM"

AVAILABLE_MEM_GB=$(free -g | awk 'NR==2 {print $7}')
if [ "$AVAILABLE_MEM_GB" -gt 2 ]; then
    check_pass "Sufficient memory (>2GB available)"
else
    check_warn "Low memory (<2GB available)"
fi
echo ""

echo "10. DNS Resolution Test"
echo "-----------------------"
# Test if we can resolve domains (using Cloudflare DNS)
if nslookup krynet.cc 1.1.1.1 &> /dev/null; then
    check_pass "Can resolve external domains"
else
    check_warn "Cannot resolve external domains"
fi
echo ""

echo "========================================="
echo "Validation Summary"
echo "========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Ready to deploy.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: cd $BASE_DIR && ./deploy.sh"
    echo "  2. Or manually: docker compose build caddy && docker compose up -d"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found.${NC}"
    echo ""
    echo "You can proceed with deployment, but review the warnings above."
    echo ""
    echo "Next steps:"
    echo "  1. Address warnings if possible"
    echo "  2. Run: cd $BASE_DIR && ./deploy.sh"
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found.${NC}"
    echo ""
    echo "Please fix the errors above before deploying."
    echo ""
    echo "Common fixes:"
    echo "  • Install Docker: curl -fsSL https://get.docker.com | sh"
    echo "  • Create .env file: cp .env.example .env && nano .env"
    echo "  • Migrate data from Prime (see MIGRATION.md)"
    exit 1
fi
