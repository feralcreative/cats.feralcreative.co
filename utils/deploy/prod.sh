#!/bin/bash

################################################################################
# Production Deployment Wrapper
# Deploys to production environment
################################################################################

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set environment
export DEPLOY_ENV="production"

# Run the main deployment script
exec "$SCRIPT_DIR/deploy.sh" "$@"

# Configuration
NAS_USER="ziad"
NAS_HOST="nas.feralcreative.co"
NAS_SSH_PORT="${NAS_SSH_PORT:-33725}"
NAS_SSH_HOST="${NAS_USER}@${NAS_HOST}"
NAS_DEPLOY_PATH="/volume1/web/househunt.ezzat.com"
CONTAINER_NAME="househunt"
IMAGE_NAME="househunt:latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

get_ssh_cmd() {
    local cmd="ssh -p $NAS_SSH_PORT"
    if [ -z "$USE_SSH_AGENT" ] && [ -n "$SSH_KEY_PATH" ]; then
        cmd="$cmd -i $SSH_KEY_PATH"
    fi
    echo "$cmd"
}

get_scp_cmd() {
    local cmd="scp -P $NAS_SSH_PORT"
    if [ -z "$USE_SSH_AGENT" ] && [ -n "$SSH_KEY_PATH" ]; then
        cmd="$cmd -i $SSH_KEY_PATH"
    fi
    echo "$cmd"
}

check_ssh_key() {
    log_info "Checking for SSH certificate..."

    # If SSH_KEY_PATH is set, use it
    if [ -n "$SSH_KEY_PATH" ]; then
        if [ ! -f "$SSH_KEY_PATH" ]; then
            log_error "SSH key not found at: $SSH_KEY_PATH"
            exit 1
        fi
        log_success "SSH key found: $SSH_KEY_PATH"
        return
    fi

    # Try common locations
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
        log_success "SSH key found: $SSH_KEY_PATH"
        return
    elif [ -f "$HOME/.ssh/id_rsa" ]; then
        SSH_KEY_PATH="$HOME/.ssh/id_rsa"
        log_success "SSH key found: $SSH_KEY_PATH"
        return
    fi

    # Check if SSH agent has keys
    if ssh-add -l > /dev/null 2>&1; then
        log_success "Using SSH agent for authentication"
        USE_SSH_AGENT=1
        return
    fi

    log_error "No SSH key found. Please provide SSH_KEY_PATH environment variable or add keys to SSH agent."
    log_info "Usage: SSH_KEY_PATH=/path/to/key ./deploy.sh"
    exit 1
}

test_ssh_connection() {
    log_info "Testing SSH connection to ${NAS_SSH_HOST}:${NAS_SSH_PORT}..."

    local ssh_cmd=$(get_ssh_cmd)

    if $ssh_cmd -o ConnectTimeout=5 "$NAS_SSH_HOST" "echo 'SSH connection successful'" > /dev/null 2>&1; then
        log_success "SSH connection successful"
    else
        log_error "Failed to connect to ${NAS_SSH_HOST}:${NAS_SSH_PORT}"
        log_info "Make sure your SSH key is added to the NAS authorized_keys"
        exit 1
    fi
}

generate_data_files() {
    log_info "Generating POI and property JSON files from Google Sheets..."

    # Check if Node.js is available
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js to continue."
        exit 1
    fi

    # Check if server dependencies are installed
    if [ ! -d "server/node_modules" ]; then
        log_info "Installing server dependencies..."
        cd server && npm install && cd ..
    fi

    # Check if Google credentials exist
    if [ ! -f "data/service-account.json" ]; then
        log_error "Google service account credentials not found at data/service-account.json"
        log_info "Please ensure the credentials file exists before deploying"
        exit 1
    fi

    # Generate POI data
    log_info "Fetching POI data from Google Sheets..."
    if node utils/poi-update-json.js --gzip; then
        log_success "POI data generated: data/poi.json.gz"
    else
        log_error "Failed to generate POI data. Check the error output above."
        exit 1
    fi

    # Generate property data
    log_info "Fetching property data from Google Sheets..."
    if node utils/property-update-json.js --gzip; then
        log_success "Property data generated: data/properties.json.gz"
    else
        log_error "Failed to generate property data. Check the error output above."
        exit 1
    fi

    log_success "All data files generated successfully"
}

build_image() {
    log_info "Building Docker image locally..."

    if docker build --platform linux/amd64 -t "$IMAGE_NAME" .; then
        log_success "Docker image built successfully"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

save_and_transfer_image() {
    log_info "Saving Docker image to tar.gz..."

    local temp_file="/tmp/househunt-$(date +%s).tar.gz"

    if docker save "$IMAGE_NAME" | gzip > "$temp_file"; then
        log_success "Image saved to $temp_file"
    else
        log_error "Failed to save Docker image"
        exit 1
    fi

    log_info "Transferring image to NAS (this may take a few minutes)..."

    local ssh_cmd=$(get_ssh_cmd)

    # Ensure deploy path and subdirectories exist on NAS
    $ssh_cmd "$NAS_SSH_HOST" "mkdir -p ${NAS_DEPLOY_PATH}/data ${NAS_DEPLOY_PATH}/logs" || true

    # Use deploy path for temporary storage
    local nas_temp_file="${NAS_DEPLOY_PATH}/househunt.tar.gz"

    # Transfer using cat and ssh pipe (more reliable than scp)
    if cat "$temp_file" | $ssh_cmd "$NAS_SSH_HOST" "cat > ${nas_temp_file}"; then
        log_success "Image transferred successfully"
    else
        log_error "Failed to transfer image to NAS"
        rm -f "$temp_file"
        exit 1
    fi

    rm -f "$temp_file"
}

load_image_on_nas() {
    log_info "Loading Docker image on NAS..."

    local ssh_cmd=$(get_ssh_cmd)
    local nas_temp_file="${NAS_DEPLOY_PATH}/househunt.tar.gz"

    if $ssh_cmd "$NAS_SSH_HOST" "/usr/local/bin/docker load < ${nas_temp_file} && rm ${nas_temp_file}"; then
        log_success "Docker image loaded on NAS"
    else
        log_error "Failed to load Docker image on NAS"
        exit 1
    fi
}

prepare_nas_directories() {
    log_info "Preparing NAS directories..."

    local ssh_cmd=$(get_ssh_cmd)

    $ssh_cmd "$NAS_SSH_HOST" << 'EOF'
mkdir -p /volume1/web/househunt.ezzat.com/data
mkdir -p /volume1/web/househunt.ezzat.com/logs
chmod 755 /volume1/web/househunt.ezzat.com
chmod 755 /volume1/web/househunt.ezzat.com/data
chmod 755 /volume1/web/househunt.ezzat.com/logs
EOF

    log_success "NAS directories prepared"
}

check_credentials() {
    log_info "Checking for credentials on NAS..."

    local ssh_cmd=$(get_ssh_cmd)

    # Check service-account.json
    if $ssh_cmd "$NAS_SSH_HOST" "[ -f ${NAS_DEPLOY_PATH}/data/service-account.json ]"; then
        log_success "service-account.json found"
    else
        log_warning "service-account.json not found at ${NAS_DEPLOY_PATH}/data/"
        log_info "Please ensure you copy service-account.json to the data directory before starting the container"
    fi

    # Check oauth-client-secret.json
    if $ssh_cmd "$NAS_SSH_HOST" "[ -f ${NAS_DEPLOY_PATH}/data/oauth-client-secret.json ]"; then
        log_success "oauth-client-secret.json found"
    else
        log_warning "oauth-client-secret.json not found, transferring..."
        if [ -f "data/oauth-client-secret.json" ]; then
            cat data/oauth-client-secret.json | $ssh_cmd "$NAS_SSH_HOST" "cat > ${NAS_DEPLOY_PATH}/data/oauth-client-secret.json"
            log_success "oauth-client-secret.json transferred"
        else
            log_error "oauth-client-secret.json not found locally at data/oauth-client-secret.json"
            exit 1
        fi
    fi
}

transfer_data_files() {
    log_info "Transferring POI and property data files to NAS..."

    local ssh_cmd=$(get_ssh_cmd)

    # Transfer poi.json.gz
    if [ -f "data/poi.json.gz" ]; then
        log_info "Transferring poi.json.gz..."
        if cat data/poi.json.gz | $ssh_cmd "$NAS_SSH_HOST" "cat > ${NAS_DEPLOY_PATH}/data/poi.json.gz"; then
            log_success "poi.json.gz transferred"
        else
            log_error "Failed to transfer poi.json.gz"
            exit 1
        fi
    else
        log_error "poi.json.gz not found locally at data/poi.json.gz"
        exit 1
    fi

    # Transfer properties.json.gz
    if [ -f "data/properties.json.gz" ]; then
        log_info "Transferring properties.json.gz..."
        if cat data/properties.json.gz | $ssh_cmd "$NAS_SSH_HOST" "cat > ${NAS_DEPLOY_PATH}/data/properties.json.gz"; then
            log_success "properties.json.gz transferred"
        else
            log_error "Failed to transfer properties.json.gz"
            exit 1
        fi
    else
        log_error "properties.json.gz not found locally at data/properties.json.gz"
        exit 1
    fi

    log_success "Data files transferred successfully"
}

transfer_compose_file() {
    log_info "Transferring docker-compose.yml to NAS..."

    local ssh_cmd=$(get_ssh_cmd)

    # Use cat and ssh pipe instead of scp (more reliable on NAS)
    if cat docker-compose.yml | $ssh_cmd "$NAS_SSH_HOST" "cat > ${NAS_DEPLOY_PATH}/docker-compose.yml"; then
        log_success "docker-compose.yml transferred"
    else
        log_error "Failed to transfer docker-compose.yml"
        exit 1
    fi
}

deploy_container() {
    log_info "Deploying container on NAS..."

    local ssh_cmd=$(get_ssh_cmd)

    $ssh_cmd "$NAS_SSH_HOST" << EOF
cd ${NAS_DEPLOY_PATH}
/usr/local/bin/docker-compose down || true
/usr/local/bin/docker-compose up -d
EOF

    log_success "Container deployed"
}

verify_deployment() {
    log_info "Verifying deployment..."

    sleep 3

    local ssh_cmd=$(get_ssh_cmd)

    if $ssh_cmd "$NAS_SSH_HOST" "/usr/local/bin/docker ps | grep -q $CONTAINER_NAME"; then
        log_success "Container is running"
    else
        log_error "Container failed to start"
        log_info "Checking logs..."
        $ssh_cmd "$NAS_SSH_HOST" "/usr/local/bin/docker logs $CONTAINER_NAME" || true
        exit 1
    fi
}

purge_cloudflare_cache() {
    log_info "Checking for Cloudflare credentials..."

    # Check if .env file exists
    if [ ! -f .env ]; then
        log_warning "No .env file found - skipping Cloudflare cache purge"
        return 0
    fi

    # Load environment variables from .env
    export $(cat .env | grep -v '^#' | xargs)

    # Check for Cloudflare credentials
    if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ]; then
        log_warning "CLOUDFLARE_API_TOKEN or CLOUDFLARE_ZONE_ID not set in .env"
        log_info "Skipping Cloudflare cache purge"
        log_info "Add these to your .env file to enable automatic cache purging:"
        log_info "  CLOUDFLARE_API_TOKEN=your_api_token"
        log_info "  CLOUDFLARE_ZONE_ID=your_zone_id"
        return 0
    fi

    log_info "Purging Cloudflare cache..."

    PURGE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/purge_cache" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{"purge_everything":true}')

    # Check if purge was successful (handle both "success":true and "success": true)
    if echo "$PURGE_RESPONSE" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
        log_success "Cloudflare cache purged successfully"
    else
        log_error "Failed to purge Cloudflare cache"
        log_info "Response: $PURGE_RESPONSE"
        log_warning "You may need to manually purge the cache in Cloudflare dashboard"
        # Don't exit - cache purge failure shouldn't stop deployment
    fi
}

show_status() {
    log_info "Checking container status..."

    local ssh_cmd=$(get_ssh_cmd)

    $ssh_cmd "$NAS_SSH_HOST" << EOF
echo "=== Container Status ==="
/usr/local/bin/docker ps | grep $CONTAINER_NAME || echo "Container not running"
echo ""
echo "=== Recent Logs ==="
/usr/local/bin/docker logs --tail 20 $CONTAINER_NAME
EOF
}

################################################################################
# Main Deployment Flow
################################################################################

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Househunt Docker Deployment to Synology NAS            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Deployment Configuration:"
    log_info "  NAS User: $NAS_USER"
    log_info "  NAS Host: $NAS_HOST"
    log_info "  Deploy Path: $NAS_DEPLOY_PATH"
    log_info "  Container: $CONTAINER_NAME"
    echo ""
    
    # Step 1: Check SSH key
    check_ssh_key

    # Step 2: Test SSH connection
    test_ssh_connection

    # Step 3: Generate data files from Google Sheets
    generate_data_files

    # Step 4: Build image locally
    build_image

    # Step 5: Save and transfer image
    save_and_transfer_image

    # Step 6: Load image on NAS
    load_image_on_nas

    # Step 7: Prepare NAS directories
    prepare_nas_directories

    # Step 8: Check credentials
    check_credentials

    # Step 9: Transfer data files (POI and properties)
    transfer_data_files

    # Step 10: Transfer docker-compose.yml
    transfer_compose_file

    # Step 11: Deploy container
    deploy_container

    # Step 12: Verify deployment
    verify_deployment

    # Step 13: Purge Cloudflare cache
    purge_cloudflare_cache

    # Step 14: Show status
    show_status

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    DEPLOYMENT COMPLETE                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Application is running at: http://${NAS_HOST}:6197"
    log_info "Authentication: Google OAuth (whitelisted emails only)"
    echo ""
}

# Run main function
main "$@"
