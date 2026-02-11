# Deployment Quick Reference

## Cats Project - Quick Commands

### Deploy to Production
```bash
./utils/deploy/deploy.sh
```

### View Logs
```bash
./utils/deploy/deploy-utils.sh logs
```

### Check Status
```bash
./utils/deploy/deploy-utils.sh status
```

### Restart Container
```bash
./utils/deploy/deploy-utils.sh restart
```

### Backup Data
```bash
./utils/deploy/deploy-utils.sh backup
```

### All Available Commands
```bash
./utils/deploy/deploy-utils.sh help
```

---

## Setting Up a New Project

### 1. Copy Templates
```bash
# From this project's templates directory
cp utils/deploy/templates/deploy.sh.template utils/deploy/deploy.sh
cp utils/deploy/templates/deploy-utils.sh.template utils/deploy/deploy-utils.sh
cp utils/deploy/templates/deploy.config.template deploy.config
cp utils/deploy/templates/.env.template .env.example

# Make executable
chmod +x utils/deploy/deploy.sh utils/deploy/deploy-utils.sh
```

### 2. Configure
```bash
# Edit deploy.config - set project name, domain, etc.
nano deploy.config

# Create .env from example
cp .env.example .env

# Add your Cloudflare credentials to .env
nano .env
```

### 3. Create Docker Files
```bash
# Use templates as starting points
cp utils/deploy/templates/Dockerfile.template Dockerfile
cp utils/deploy/templates/docker-compose.yml.template docker-compose.yml

# Customize for your project
nano Dockerfile
nano docker-compose.yml
```

### 4. Deploy
```bash
./utils/deploy/deploy.sh
```

---

## Configuration Files

### deploy.config (Project Settings)
- `PROJECT_NAME` - Container/image name
- `DOMAIN` - Your domain
- `NAS_USER` - SSH username
- `NAS_HOST` - NAS hostname
- `NAS_SSH_PORT` - SSH port (default: 33725)
- `PRE_BUILD_HOOK` - Script to run before build
- `POST_DEPLOY_HOOK` - Script to run after deploy
- `DATA_FILES` - Files to transfer to NAS
- `CUSTOM_DIRS` - Directories to create on NAS

### .env (Credentials & Environment)
- `CLOUDFLARE_API_TOKEN` - For cache purging
- `CLOUDFLARE_ZONE_ID` - For cache purging
- `SSH_KEY_PATH` - Override SSH key location
- Add any app-specific variables here

---

## Troubleshooting

### SSH Connection Issues
```bash
# Test SSH manually
ssh -p 33725 ziad@nas.feralcreative.co

# Check SSH key
ls -la ~/.ssh/id_ed25519

# Add key to agent
ssh-add ~/.ssh/id_ed25519
```

### Docker Build Issues
```bash
# Test build locally
docker build -t test .

# Check Dockerfile exists
ls -la Dockerfile
```

### Container Issues
```bash
# View logs
./utils/deploy/deploy-utils.sh logs

# Check status
./utils/deploy/deploy-utils.sh status

# Open shell in container
./utils/deploy/deploy-utils.sh shell

# Check on NAS directly
ssh -p 33725 ziad@nas.feralcreative.co
docker ps
docker logs cats
```

### Cloudflare Cache Issues
```bash
# Check .env has credentials
cat .env | grep CLOUDFLARE

# Test API token manually
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## File Locations on NAS

- **Deploy Path**: `/volume1/web/cats.feralcreative.co/`
- **Data**: `/volume1/web/cats.feralcreative.co/data/`
- **Logs**: `/volume1/web/cats.feralcreative.co/logs/`
- **Docker Compose**: `/volume1/web/cats.feralcreative.co/docker-compose.yml`

---

## Useful Docker Commands (on NAS)

```bash
# SSH into NAS
ssh -p 33725 ziad@nas.feralcreative.co

# View all containers
docker ps -a

# View logs
docker logs cats

# Follow logs
docker logs -f cats

# Restart container
cd /volume1/web/cats.feralcreative.co
docker-compose restart

# Stop container
docker-compose down

# Start container
docker-compose up -d

# View images
docker images

# Remove old images
docker image prune -a
```

