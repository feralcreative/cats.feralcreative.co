# Deployment Scripts Overview

This document provides an overview of the deployment script system created for this project.

## What Was Created

### For the Cats Project

1. **`deploy.config`** - Project-specific configuration
   - Located in project root
   - Contains all cats project settings (domain, NAS paths, etc.)

2. **`utils/deploy/deploy.sh`** - Main deployment script
   - Builds and deploys Docker containers to NAS
   - Handles SSH authentication
   - Transfers files and manages containers
   - Purges Cloudflare cache

3. **`utils/deploy/deploy-utils.sh`** - Container management utilities
   - View logs, check status, restart containers
   - Backup and restore data
   - Open shell in container

4. **`.env.example`** - Environment variables template
   - Cloudflare API credentials
   - SSH configuration
   - Application-specific variables

5. **`docs/DEPLOYMENT.md`** - Deployment guide for this project

### Generic Templates (for Future Projects)

Located in `.augment/template/`:

1. **`deploy.config.template`** - Generic configuration template (needs customization)
2. **`.env.template`** - Generic environment variables template (needs customization)
3. **`Dockerfile`** - Sample Dockerfile with multiple examples (ready to customize)
4. **`docker-compose.yml`** - Sample docker-compose configuration (ready to customize)
5. **`utils/deploy/deploy.sh`** - Generic deployment script (ready to use)
6. **`utils/deploy/deploy-utils.sh`** - Generic utilities script (ready to use)
7. **`utils/deploy/README.md`** - Complete documentation for using the templates

## How It Works

### Deployment Flow

```
1. Load .env file (Cloudflare credentials, etc.)
2. Load deploy.config (project settings)
3. Check SSH connection to NAS
4. Run pre-build hook (optional)
5. Build Docker image locally
6. Save image as tar.gz
7. Transfer image to NAS via SSH
8. Load image on NAS
9. Create directories on NAS
10. Transfer data files (optional)
11. Transfer docker-compose.yml
12. Deploy container (docker-compose up)
13. Verify container is running
14. Run post-deploy hook (optional)
15. Purge Cloudflare cache
16. Show container status
```

### Configuration System

The scripts use a two-tier configuration system:

1. **`deploy.config`** - Project-specific settings
   - Project name, domain, NAS paths
   - Container names, image names
   - Custom directories, data files
   - Hook scripts

2. **`.env`** - Sensitive credentials and environment variables
   - Cloudflare API token and zone ID
   - SSH key path (optional)
   - Application environment variables

This separation keeps sensitive data out of version control while allowing project settings to be committed.

### Hook System

The scripts support optional hooks for custom build/deploy steps:

- **Pre-build hook**: Runs before Docker build
  - Generate assets
  - Compile code
  - Fetch external data
- **Post-deploy hook**: Runs after container deployment
  - Run database migrations
  - Warm caches
  - Send notifications

## Using Templates for New Projects

### Quick Setup

```bash
# 1. Copy templates from .augment/template to new project
cp .augment/template/deploy.config.template deploy.config
cp .augment/template/.env.template .env.example
cp .augment/template/Dockerfile Dockerfile
cp .augment/template/docker-compose.yml docker-compose.yml

# 2. Copy deployment scripts
mkdir -p utils/deploy
cp .augment/template/utils/deploy/deploy.sh utils/deploy/deploy.sh
cp .augment/template/utils/deploy/deploy-utils.sh utils/deploy/deploy-utils.sh
cp .augment/template/utils/deploy/README.md utils/deploy/README.md

# 3. Scripts are already executable, but verify
chmod +x utils/deploy/deploy.sh utils/deploy/deploy-utils.sh

# 4. Customize deploy.config
# Edit PROJECT_NAME, DOMAIN, etc.

# 5. Set up environment
cp .env.example .env
# Edit .env with your credentials

# 6. Customize Dockerfile and docker-compose.yml for your app

# 7. Deploy
./utils/deploy/deploy.sh
```

### Customization Points

1. **Project Settings** (`deploy.config`)
   - Change project name and domain
   - Adjust NAS paths if needed
   - Add custom directories
   - Specify data files to transfer

2. **Environment Variables** (`.env`)
   - Add Cloudflare credentials
   - Add application-specific variables
   - Override SSH settings if needed

3. **Docker Configuration**
   - Create/customize `Dockerfile`
   - Create/customize `docker-compose.yml`
   - Use provided templates as starting points

4. **Hooks** (optional)
   - Create pre-build hook for build-time tasks
   - Create post-deploy hook for deployment tasks

## Key Features

### Automated Deployment

- One command deploys entire application
- Handles all steps from build to verification
- Automatic error handling and rollback

### SSH Key Management

- Auto-detects SSH keys in standard locations
- Supports SSH agent
- Allows manual key specification

### Cloudflare Integration

- Automatic cache purging after deployment
- Optional (skips if credentials not provided)
- Non-blocking (deployment continues if purge fails)

### Container Management

- Easy access to logs and status
- Simple restart/stop/start commands
- Backup and restore functionality
- Shell access for debugging

### Flexibility

- Hook system for custom build/deploy steps
- Configurable data file transfers
- Custom directory creation
- Environment variable support

## File Structure

```
project-root/
├── deploy.config                    # Project configuration
├── .env                             # Environment variables (not in git)
├── .env.example                     # Environment template
├── Dockerfile                       # Docker build instructions
├── docker-compose.yml               # Container orchestration
├── docs/
│   ├── DEPLOYMENT.md               # Project deployment guide
│   └── DEPLOYMENT_SCRIPTS_OVERVIEW.md  # This file
├── utils/
│   └── deploy/
│       ├── deploy.sh               # Main deployment script
│       ├── deploy-utils.sh         # Management utilities
│       ├── README.md               # Deployment documentation
│       └── hooks/                  # Optional hook scripts
│           ├── pre-build.sh
│           └── post-deploy.sh
└── .augment/
    └── template/                   # Generic templates for new projects
        ├── deploy.config.template
        ├── .env.template
        ├── Dockerfile
        ├── docker-compose.yml
        └── utils/
            └── deploy/
                ├── deploy.sh
                ├── deploy-utils.sh
                └── README.md
```

## Benefits

1. **Consistency**: Same deployment process across all projects
2. **Reusability**: Templates can be copied to any new project
3. **Maintainability**: Centralized deployment logic
4. **Flexibility**: Hooks and configuration allow customization
5. **Safety**: Automatic verification and error handling
6. **Convenience**: One command deployment, easy management

## Next Steps for Cats Project

1. Create `Dockerfile` for the cats application
2. Create `docker-compose.yml` with appropriate configuration
3. Copy `.env.example` to `.env` and add Cloudflare credentials
4. Test deployment: `./utils/deploy/deploy.sh`
5. Set up any needed hooks for camera stream processing
