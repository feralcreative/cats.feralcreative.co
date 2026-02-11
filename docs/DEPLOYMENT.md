# Deployment Guide

This document describes how to deploy the cats.feralcreative.co application to the Synology NAS.

## Prerequisites

- Docker installed locally
- SSH access to nas.feralcreative.co
- Cloudflare API credentials (for cache purging)

## Initial Setup

### 1. Configure Environment Variables

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env` and add your Cloudflare credentials:

```env
CLOUDFLARE_API_TOKEN=your_api_token_here
CLOUDFLARE_ZONE_ID=your_zone_id_here
```

### 2. Review Deployment Configuration

The deployment configuration is in `deploy.config` at the project root. Review and adjust if needed:

- Project name: `cats`
- Domain: `cats.feralcreative.co`
- NAS deploy path: `/volume1/web/cats.feralcreative.co`

### 3. Ensure Docker Files Exist

Make sure you have:
- `Dockerfile` in the project root
- `docker-compose.yml` in the project root (optional but recommended)

## Deployment

### Deploy to Production

Run the deployment script:

```bash
./utils/deploy/deploy.sh
```

This will:
1. Load environment variables from `.env`
2. Check SSH connection to NAS
3. Run any pre-build hooks (if configured)
4. Build the Docker image locally
5. Transfer the image to the NAS
6. Load the image on the NAS
7. Create necessary directories on the NAS
8. Transfer data files (if configured)
9. Transfer docker-compose.yml
10. Deploy the container
11. Verify the deployment
12. Run any post-deploy hooks (if configured)
13. Purge Cloudflare cache
14. Show container status

## Managing the Deployment

### View Logs

```bash
./utils/deploy/deploy-utils.sh logs
```

### Check Container Status

```bash
./utils/deploy/deploy-utils.sh status
```

### Restart Container

```bash
./utils/deploy/deploy-utils.sh restart
```

### Stop Container

```bash
./utils/deploy/deploy-utils.sh stop
```

### Start Container

```bash
./utils/deploy/deploy-utils.sh start
```

### Open Shell in Container

```bash
./utils/deploy/deploy-utils.sh shell
```

### Backup Data Directory

```bash
./utils/deploy/deploy-utils.sh backup
```

This creates a timestamped backup file: `cats-backup-YYYYMMDD-HHMMSS.tar.gz`

### Restore from Backup

```bash
./utils/deploy/deploy-utils.sh restore cats-backup-20240101-120000.tar.gz
```

### Sync Local Data to NAS

```bash
./utils/deploy/deploy-utils.sh update-data ./data
```

## Deployment Hooks

### Pre-Build Hook

If you need to run tasks before building the Docker image (e.g., compile assets, fetch data), create a pre-build hook:

1. Create the hook script:
   ```bash
   mkdir -p utils/deploy/hooks
   touch utils/deploy/hooks/pre-build.sh
   chmod +x utils/deploy/hooks/pre-build.sh
   ```

2. Add your commands to the script

3. Enable it in `deploy.config`:
   ```bash
   PRE_BUILD_HOOK="utils/deploy/hooks/pre-build.sh"
   ```

### Post-Deploy Hook

If you need to run tasks after deployment (e.g., warm caches, send notifications), create a post-deploy hook:

1. Create the hook script:
   ```bash
   mkdir -p utils/deploy/hooks
   touch utils/deploy/hooks/post-deploy.sh
   chmod +x utils/deploy/hooks/post-deploy.sh
   ```

2. Add your commands to the script

3. Enable it in `deploy.config`:
   ```bash
   POST_DEPLOY_HOOK="utils/deploy/hooks/post-deploy.sh"
   ```

## Troubleshooting

### SSH Connection Fails

- Verify your SSH key is added to the NAS: `~/.ssh/authorized_keys`
- Check the SSH port in `deploy.config` (default: 33725)
- Test manually: `ssh -p 33725 ziad@nas.feralcreative.co`

### Docker Build Fails

- Check that `Dockerfile` exists and is valid
- Ensure all required files are present
- Verify Docker is running locally

### Container Won't Start

- Check logs: `./utils/deploy/deploy-utils.sh logs`
- Verify `docker-compose.yml` configuration
- Check for port conflicts on the NAS
- Ensure all required environment variables are set

### Cloudflare Cache Not Purging

- Verify `CLOUDFLARE_API_TOKEN` is set in `.env`
- Verify `CLOUDFLARE_ZONE_ID` is set in `.env`
- Check that the API token has "Zone.Cache Purge" permission
- The deployment will continue even if cache purge fails

## Application Access

After successful deployment, the application will be available at:

**https://cats.feralcreative.co**

## Notes

- The deployment script uses SSH certificate authentication
- Images are built for `linux/amd64` platform (compatible with Synology NAS)
- Container logs are stored in `/volume1/web/cats.feralcreative.co/logs`
- Application data is stored in `/volume1/web/cats.feralcreative.co/data`

