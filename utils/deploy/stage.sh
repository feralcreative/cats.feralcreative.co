#!/bin/bash

################################################################################
# Staging Deployment Wrapper
# Deploys to staging environment
################################################################################

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set environment
export DEPLOY_ENV="staging"

# Run the main deployment script
exec "$SCRIPT_DIR/deploy.sh" "$@"

