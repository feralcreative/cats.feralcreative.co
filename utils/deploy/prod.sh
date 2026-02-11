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
