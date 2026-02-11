#!/bin/bash

################################################################################
# Deployment Utilities
# Helper commands for managing the deployed container
################################################################################

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load configuration
if [ ! -f "$PROJECT_ROOT/deploy.config" ]; then
    echo "ERROR: deploy.config not found in project root"
    exit 1
fi

source "$PROJECT_ROOT/deploy.config"

# Derived configuration
NAS_SSH_HOST="${NAS_USER}@${NAS_HOST}"
NAS_SSH_PORT="${NAS_SSH_PORT:-33725}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
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

get_ssh_key() {
    if [ -z "$SSH_KEY_PATH" ]; then
        if [ -f "$HOME/.ssh/id_ed25519" ]; then
            SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
        elif [ -f "$HOME/.ssh/id_rsa" ]; then
            SSH_KEY_PATH="$HOME/.ssh/id_rsa"
        elif ssh-add -l > /dev/null 2>&1; then
            USE_SSH_AGENT=1
            return
        else
            log_error "No SSH key found"
            exit 1
        fi
    fi
}

cmd_logs() {
    get_ssh_key
    local ssh_cmd=$(get_ssh_cmd)
    log_info "Fetching container logs..."
    $ssh_cmd "$NAS_SSH_HOST" "/usr/local/bin/docker logs -f $CONTAINER_NAME"
}

cmd_status() {
    get_ssh_key
    local ssh_cmd=$(get_ssh_cmd)
    log_info "Container status:"
    $ssh_cmd "$NAS_SSH_HOST" << EOF
/usr/local/bin/docker ps | grep $CONTAINER_NAME || echo "Container not running"
EOF
}

cmd_restart() {
    get_ssh_key
    local ssh_cmd=$(get_ssh_cmd)
    log_info "Restarting container..."
    $ssh_cmd "$NAS_SSH_HOST" << EOF
cd $NAS_DEPLOY_PATH
/usr/local/bin/docker-compose restart
EOF
    log_success "Container restarted"
}

cmd_stop() {
    get_ssh_key
    local ssh_cmd=$(get_ssh_cmd)
    log_info "Stopping container..."
    $ssh_cmd "$NAS_SSH_HOST" << EOF
cd $NAS_DEPLOY_PATH
/usr/local/bin/docker-compose down
EOF
    log_success "Container stopped"
}

cmd_start() {
    get_ssh_key
    local ssh_cmd=$(get_ssh_cmd)
    log_info "Starting container..."
    $ssh_cmd "$NAS_SSH_HOST" << EOF
cd $NAS_DEPLOY_PATH
/usr/local/bin/docker-compose up -d
EOF
    log_success "Container started"
}

cmd_shell() {
    get_ssh_key
    local ssh_cmd=$(get_ssh_cmd)
    log_info "Opening shell in container..."
    $ssh_cmd -t "$NAS_SSH_HOST" "/usr/local/bin/docker exec -it $CONTAINER_NAME /bin/sh"
}

cmd_backup() {
    get_ssh_key
    local ssh_cmd=$(get_ssh_cmd)
    local scp_cmd=$(get_scp_cmd)
    local backup_file="${PROJECT_NAME}-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    log_info "Creating backup: $backup_file"
    $ssh_cmd "$NAS_SSH_HOST" "tar -czf /tmp/$backup_file -C ${NAS_DEPLOY_BASE} ${DOMAIN}/data"
    log_info "Downloading backup..."
    $scp_cmd "${NAS_SSH_HOST}:/tmp/$backup_file" "./$backup_file"
    $ssh_cmd "$NAS_SSH_HOST" "rm /tmp/$backup_file"
    log_success "Backup saved to: $backup_file"
}

cmd_restore() {
    if [ -z "$1" ]; then
        log_error "Usage: $0 restore <backup-file>"
        exit 1
    fi

    if [ ! -f "$1" ]; then
        log_error "Backup file not found: $1"
        exit 1
    fi

    get_ssh_key
    local ssh_cmd=$(get_ssh_cmd)
    local scp_cmd=$(get_scp_cmd)
    local backup_file=$(basename "$1")
    log_info "Uploading backup..."
    $scp_cmd "$1" "${NAS_SSH_HOST}:/tmp/$backup_file"

    log_info "Restoring backup..."
    $ssh_cmd "$NAS_SSH_HOST" << EOF
cd ${NAS_DEPLOY_BASE}
tar -xzf /tmp/$backup_file
rm /tmp/$backup_file
EOF

    log_success "Backup restored"
}

cmd_update_data() {
    if [ -z "$1" ]; then
        log_error "Usage: $0 update-data <local-data-directory>"
        exit 1
    fi

    if [ ! -d "$1" ]; then
        log_error "Directory not found: $1"
        exit 1
    fi

    get_ssh_key
    log_info "Syncing data directory..."
    rsync -avz -e "ssh -p $NAS_SSH_PORT $([ -n "$SSH_KEY_PATH" ] && echo "-i $SSH_KEY_PATH")" "$1/" "${NAS_SSH_HOST}:${NAS_DEPLOY_PATH}/data/"
    log_success "Data synced"
}

cmd_help() {
    cat << EOF
Deployment Utilities for ${PROJECT_NAME}

Usage: $0 <command> [options]

Commands:
  logs              Follow container logs
  status            Show container status
  restart           Restart the container
  stop              Stop the container
  start             Start the container
  shell             Open shell in container
  backup            Backup data directory
  restore <file>    Restore from backup file
  update-data <dir> Sync local data directory to NAS
  help              Show this help message

Environment Variables:
  SSH_KEY_PATH      Path to SSH private key (default: ~/.ssh/id_ed25519 or ~/.ssh/id_rsa)
  NAS_SSH_PORT      SSH port for NAS (default: 33725)

Examples:
  $0 logs
  $0 backup
  $0 restore ${PROJECT_NAME}-backup-20240101-120000.tar.gz
  $0 update-data ./data
  SSH_KEY_PATH=/path/to/key $0 status

EOF
}

# Main
case "${1:-help}" in
    logs)
        cmd_logs
        ;;
    status)
        cmd_status
        ;;
    restart)
        cmd_restart
        ;;
    stop)
        cmd_stop
        ;;
    start)
        cmd_start
        ;;
    shell)
        cmd_shell
        ;;
    backup)
        cmd_backup
        ;;
    restore)
        cmd_restore "$2"
        ;;
    update-data)
        cmd_update_data "$2"
        ;;
    help)
        cmd_help
        ;;
    *)
        log_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
