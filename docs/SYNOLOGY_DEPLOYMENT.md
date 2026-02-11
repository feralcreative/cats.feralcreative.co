# Synology NAS Deployment Guide

This guide covers deploying the application to a Synology NAS using Docker.

## Prerequisites

1. Synology NAS with Docker package installed
2. SSH access (optional, for command-line operations)
3. Domain/subdomain configured (for HTTPS)
4. Google Cloud OAuth credentials configured for production URL

## Build and Export Docker Image

### Option 1: Build on Local Machine

```bash
# Build the Docker image
npm run docker:build

# Export to tar.gz file
docker save template-feralcreative:latest | gzip > template-feralcreative.tar.gz
```

### Option 2: Build on NAS (if SSH available)

```bash
# SSH into NAS
ssh admin@your-nas-ip

# Navigate to project directory
cd /volume1/docker/template-feralcreative

# Build directly on NAS
docker build -t template-feralcreative:latest .
```

## Transfer Image to NAS

1. Open **File Station** on your Synology NAS
2. Navigate to `/docker` folder (or create it)
3. Upload `template-feralcreative.tar.gz`

## Import Docker Image

1. Open **Docker** package on Synology
2. Go to **Image** tab
3. Click **Add** → **Add from File**
4. Select the uploaded `.tar.gz` file
5. Wait for import to complete

## Create Container

1. In Docker, go to **Image** tab
2. Select `template-feralcreative:latest`
3. Click **Launch**
4. Configure container:

### General Settings

- Container Name: `template-feralcreative`
- Enable auto-restart: ✓

### Port Settings

- Local Port: `12345`
- Container Port: `12345`
- Type: TCP

### Environment Variables

Add each variable from `.env.production`:

- `NODE_ENV` = `production`
- `PORT` = `12345`
- `SESSION_SECRET` = `your_secret`
- `GOOGLE_CLIENT_ID` = `your_client_id`
- `GOOGLE_CLIENT_SECRET` = `your_client_secret`
- `GOOGLE_SHEETS_ID` = `your_sheet_id`
- `GOOGLE_CALLBACK_URL` = `https://your-domain.com/auth/google/callback`
- `CLIENT_URL` = `https://your-domain.com`

5. Click **Apply** to create and start the container

## Configure Reverse Proxy (HTTPS)

1. Go to **Control Panel** → **Login Portal** → **Advanced**
2. Click **Reverse Proxy**
3. Click **Create**
4. Configure:
   - Description: `Template App`
   - Source:
     - Protocol: HTTPS
     - Hostname: `template.feralcreative.dev`
     - Port: 443
   - Destination:
     - Protocol: HTTP
     - Hostname: `localhost`
     - Port: 12345
5. Click **Custom Header** → **Create** → **WebSocket**
6. Save

## Verify Deployment

1. Open `https://template.feralcreative.dev` in browser
2. Verify the app loads
3. Test Google OAuth login
4. Verify data operations work

## Updating the Application

1. Build new Docker image locally
2. Export and transfer to NAS
3. In Docker:
   - Stop the running container
   - Delete the container (settings will be lost)
   - Delete the old image
   - Import new image
   - Create new container with same settings

### Quick Update Script (SSH)

```bash
# On local machine
npm run docker:build
docker save template-feralcreative:latest | gzip > template-feralcreative.tar.gz
scp template-feralcreative.tar.gz admin@nas-ip:/volume1/docker/

# On NAS via SSH
docker stop template-feralcreative
docker rm template-feralcreative
docker rmi template-feralcreative:latest
docker load < /volume1/docker/template-feralcreative.tar.gz
# Then recreate container via Docker UI or docker run command
```

## Troubleshooting

### Container won't start

- Check Docker logs: Container → Details → Log
- Verify all environment variables are set
- Check port 12345 is not in use

### OAuth not working

- Verify GOOGLE_CALLBACK_URL matches Google Cloud Console
- Check CLIENT_URL is correct
- Ensure HTTPS is properly configured

### Can't access from internet

- Check reverse proxy configuration
- Verify firewall allows port 443
- Check DNS is pointing to NAS
