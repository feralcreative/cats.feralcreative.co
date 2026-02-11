# AI Agent Primer: cats.feralcreative.co

**Project Status:** 🚧 **PRE-DEVELOPMENT** - Architecture not yet determined
**Last Updated:** 2025-02-10
**Domain:** https://cats.feralcreative.co

---

## 🔒 SECRETS REFERENCE GUIDE

### 1. Cloudflare API Credentials

**Location:** `.env` (gitignored, copy from `.env.example`)

- `CLOUDFLARE_API_TOKEN` → Not yet configured (API token for cache purging)
- `CLOUDFLARE_ZONE_ID` → Not yet configured (Zone ID for cats.feralcreative.co)

**How to get:**

1. Visit https://dash.cloudflare.com/profile/api-tokens
2. Create token with `Zone.Cache Purge` scope
3. Get Zone ID from Cloudflare dashboard for cats.feralcreative.co domain

### 2. SSH Access to NAS

**Location:** `deploy.config` (lines 34-36)

- NAS User: `ziad`
- NAS Host: `nas.feralcreative.co`
- SSH Port: `337**` (5 digits, defined in deploy.config line 36)

**SSH Key:** Auto-detected from `~/.ssh/` (looks for keys matching `*nas*` or `*synology*`)

### 3. .gitignore Requirements

**Critical files to keep gitignored:**

- `.env` - Contains Cloudflare API credentials
- `*.env` - All environment files
- `.DS_Store` - macOS system files
- `node_modules/` - Dependencies (if Node.js is used)

---

## PROJECT OVERVIEW

### Purpose

Stream video from four TP-Link cameras to a web application at https://cats.feralcreative.co

### Current Status

- ✅ Deployment infrastructure complete
- ✅ Application architecture **DETERMINED**
- ✅ Camera integration **IMPLEMENTED**
- ✅ Frontend **BUILT**
- ✅ Backend **BUILT** (mediamtx)

### Architecture Decisions

1. **Technology stack** - Static HTML/CSS/JS + mediamtx media server
2. **Streaming protocol** - WebRTC (primary) with HLS fallback
3. **Camera integration method** - RTSP to WebRTC/HLS conversion via mediamtx
4. **Frontend framework** - Vanilla JavaScript (no framework needed)
5. **Backend requirements** - mediamtx for stream conversion, nginx for static files

---

## ARCHITECTURE & STRUCTURE

### Directory Tree

```
cats.feralcreative.co/
├── .augment/                    # Symlinked from /Users/ziad/www/_vscode/.augment
│   ├── rules/                   # AI agent rules and guidelines
│   └── template/                # Reusable project templates
├── _AI_AGENT_PRIMER.md          # This file
├── _DEPLOYMENT_SETUP_COMPLETE.md # Deployment setup summary
├── _NOTES.md                    # Project notes
├── _TASKS/                      # Task tracking
│   ├── cloudflare-cache-purge-deployment.md
│   └── deployment-setup-checklist.md
├── _archive/                    # Archived files (gitignored)
├── data/                        # Application data (empty, purpose TBD)
├── deploy.config                # Deployment configuration
├── .env.example                 # Environment variables template
├── .env                         # Environment variables (gitignored, not created yet)
├── docs/                        # Documentation
│   ├── DEPLOYMENT.md            # Deployment guide
│   ├── DEPLOYMENT_SCRIPTS_OVERVIEW.md  # Deployment system architecture
│   └── SYNOLOGY_DEPLOYMENT.md   # Synology-specific deployment info
├── images/                      # Static images (empty)
├── styles/                      # SCSS/CSS files
│   ├── css/                     # Compiled CSS (gitignored)
│   └── scss/                    # SCSS source files
├── utils/                       # Utility scripts
│   └── deploy/                  # Deployment scripts
│       ├── deploy.sh            # Main deployment script
│       ├── deploy-utils.sh      # Container management utilities
│       ├── prod.sh              # Production deployment wrapper
│       ├── stage.sh             # Staging deployment wrapper
│       ├── QUICK_REFERENCE.md   # Quick command reference
│       └── README.md            # Deployment documentation
├── Dockerfile                   # NOT YET CREATED - Docker build instructions
├── docker-compose.yml           # NOT YET CREATED - Container orchestration
├── README.md                    # Project README
└── template.zip                 # Unknown purpose

```

### Entry Points

- **Frontend:** `index.html` - Main SPA with 4-camera grid
- **JavaScript:** `app.js` - WebRTC client using WHEP protocol
- **Styles:** `styles/scss/main.scss` - Compiled to `styles/css/main.css`

### Technology Stack

**DETERMINED - Simple Static Site + Media Server**

- **Frontend:** Vanilla HTML/CSS/JavaScript
- **Media Server:** mediamtx (RTSP to WebRTC/HLS converter)
- **Web Server:** nginx (serves static files and proxies WebRTC)
- **Cameras:** 4x TP-Link Tapo C211 (RTSP streams)
- **Deployment:** Docker Compose (2 containers: nginx + mediamtx)

---

## DEPLOYMENT

### Deployment Target

- **Platform:** Synology NAS DS1525+
- **Host:** nas.feralcreative.co
- **SSH Port:** 33725 (obfuscated as `337**`)
- **Deploy Path:** `/volume1/web/cats.feralcreative.co`
- **Docker Platform:** `linux/amd64` (NAS compatibility)

### Deployment Workflow

#### Production Deployment (Alfred Workflow Compatible)

```bash
# User types in Alfred: ./utils/deploy/.sh
# Then adds "prod" before .sh:
./utils/deploy/prod.sh
```

**What happens:**

1. `prod.sh` sets `DEPLOY_ENV="production"`
2. Calls `deploy.sh` with production environment
3. `deploy.sh` reads `deploy.config` and detects environment
4. Uses production settings:
   - Domain: `cats.feralcreative.co`
   - Container: `cats`
   - Image: `cats:latest`

#### Staging Deployment (Optional, Not Used)

```bash
./utils/deploy/stage.sh
```

**What happens:**

1. `stage.sh` sets `DEPLOY_ENV="staging"`
2. Uses staging settings:
   - Domain: `stage.cats.feralcreative.co`
   - Container: `cats-stage`
   - Image: `cats:stage`

#### Deployment Steps (Automated by deploy.sh)

**File:** `utils/deploy/deploy.sh` (422 lines)

1. **Pre-build Hook** (optional, line ~52-60)
   - Runs custom script before Docker build
   - Not configured yet

2. **Docker Build** (line ~100-150)

   ```bash
   docker build --platform linux/amd64 -t IMAGE_NAME .
   ```

3. **Image Transfer** (line ~150-200)

   ```bash
   docker save IMAGE_NAME | ssh -p SSH_PORT NAS_USER@NAS_HOST \
     "docker load"
   ```

4. **Container Deployment** (line ~200-300)
   - SSH into NAS
   - Stop old container
   - Remove old container
   - Start new container
   - Verify health

5. **Cloudflare Cache Purge** (line ~300-350)

   ```bash
   curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/purge_cache" \
     -H "Authorization: Bearer API_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'
   ```

6. **Post-deploy Hook** (optional, line ~350-400)
   - Runs custom script after deployment
   - Not configured yet

### Environment Variables

**File:** `.env` (not created yet, copy from `.env.example`)

```bash
# Cloudflare Configuration
CLOUDFLARE_API_TOKEN=API_TOKEN
CLOUDFLARE_ZONE_ID=ZONE_ID

# SSH Configuration (optional - auto-detected)
# SSH_KEY_PATH=/path/to/ssh/key

# NAS Configuration (optional - overrides deploy.config)
# NAS_SSH_PORT=33725
```

### Configuration Files

**File:** `deploy.config` (60 lines)

Key configuration (lines 7-31):

```bash
# Environment detection
DEPLOY_ENV="${DEPLOY_ENV:-production}"

# Production
PROD_DOMAIN="cats.feralcreative.co"
PROD_CONTAINER_NAME="cats"
PROD_IMAGE_NAME="cats:latest"

# Staging (not used)
STAGE_DOMAIN="stage.cats.feralcreative.co"
STAGE_CONTAINER_NAME="cats-stage"
STAGE_IMAGE_NAME="cats:stage"

# Active config based on environment
if [ "$DEPLOY_ENV" = "staging" ]; then
    DOMAIN="$STAGE_DOMAIN"
    CONTAINER_NAME="$STAGE_CONTAINER_NAME"
    IMAGE_NAME="$STAGE_IMAGE_NAME"
else
    DOMAIN="$PROD_DOMAIN"
    CONTAINER_NAME="$PROD_CONTAINER_NAME"
    IMAGE_NAME="$PROD_IMAGE_NAME"
fi
```

NAS configuration (lines 34-38):

```bash
NAS_USER="ziad"
NAS_HOST="nas.feralcreative.co"
NAS_SSH_PORT="${NAS_SSH_PORT:-33725}"
NAS_DEPLOY_BASE="/volume1/web"
NAS_DEPLOY_PATH="${NAS_DEPLOY_BASE}/${DOMAIN}"
```

### Container Management Utilities

**File:** `utils/deploy/deploy-utils.sh`

Available commands:

```bash
./utils/deploy/deploy-utils.sh logs      # View container logs
./utils/deploy/deploy-utils.sh status    # Check container status
./utils/deploy/deploy-utils.sh restart   # Restart container
./utils/deploy/deploy-utils.sh stop      # Stop container
./utils/deploy/deploy-utils.sh start     # Start container
./utils/deploy/deploy-utils.sh shell     # SSH into container
./utils/deploy/deploy-utils.sh backup    # Backup container data
./utils/deploy/deploy-utils.sh restore   # Restore container data
./utils/deploy/deploy-utils.sh update-data  # Update data files
```

---

## FRONTEND

**STATUS:** Not yet implemented

**Pending Decisions:**

- Framework choice (React, Vue, vanilla JS, etc.)
- UI/UX design for 4-camera grid layout
- Video player implementation
- Responsive design requirements
- Browser compatibility targets

**Likely Requirements:**

- Display 4 camera streams simultaneously
- Grid or tabbed layout
- Stream controls (play, pause, quality selection)
- Possibly live/recorded toggle
- Mobile-responsive design

---

## BACKEND

**STATUS:** Not yet implemented

**Pending Decisions:**

- Backend language/framework
- Stream proxy vs. direct camera access
- Authentication requirements (public vs. private)
- Recording/storage strategy
- API design (if needed)

**Likely Requirements:**

- Camera stream integration (4x TP-Link cameras)
- Stream transcoding/proxying (if needed)
- Possibly recording management
- Health monitoring
- Error handling and logging

---

## CAMERA INTEGRATION

**STATUS:** ✅ Implemented

**Camera Details:**

- **Camera Count:** 4
- **Camera Brand:** TP-Link
- **Camera Models:** Tapo C211
- **Network:** 192.168.1.0/24 (static IPs)

**Camera Configuration:**

| Camera | Name  | IP Address    | RTSP URL (High)                            | RTSP URL (Low)                             |
| ------ | ----- | ------------- | ------------------------------------------ | ------------------------------------------ |
| 1      | LEFT  | 192.168.1.201 | rtsp://user:pass@192.168.1.201:554/stream1 | rtsp://user:pass@192.168.1.201:554/stream2 |
| 2      | RIGHT | 192.168.1.202 | rtsp://user:pass@192.168.1.202:554/stream1 | rtsp://user:pass@192.168.1.202:554/stream2 |
| 3      | TOP   | 192.168.1.203 | rtsp://user:pass@192.168.1.203:554/stream1 | rtsp://user:pass@192.168.1.203:554/stream2 |
| 4      | OTHER | 192.168.1.204 | rtsp://user:pass@192.168.1.204:554/stream1 | rtsp://user:pass@192.168.1.204:554/stream2 |

**Implementation Decisions:**

1. **Stream Protocol:** RTSP from cameras → WebRTC to browser (with HLS fallback)
2. **Integration Method:** mediamtx converts RTSP to WebRTC/HLS
3. **Authentication:** Camera accounts created in Tapo app
4. **Stream Quality:** High quality (stream1) by default, low quality (stream2) available

**Setup Requirements:**

1. Create camera account in Tapo app (Settings > Advanced Settings > Camera Account)
2. Configure credentials in `.env` file
3. Ensure cameras are accessible from NAS on 192.168.1.0/24 network
4. mediamtx connects to cameras via RTSP and serves WebRTC/HLS to browser

---

## DEVELOPMENT WORKFLOW

### Initial Setup (When Architecture is Determined)

1. **Clone repository:**

   ```bash
   git clone <repo-url> cats.feralcreative.co
   cd cats.feralcreative.co
   ```

2. **Symlink .augment folder:**

   ```bash
   ln -s /Users/ziad/www/_vscode/.augment .augment
   ```

3. **Set up environment:**

   ```bash
   cp .env.example .env
   # Edit .env with Cloudflare credentials
   ```

4. **Create Dockerfile and docker-compose.yml** (based on chosen tech stack)

5. **Develop application** (TBD based on architecture)

6. **Test locally:**

   ```bash
   docker-compose up
   ```

7. **Deploy to production:**
   ```bash
   ./utils/deploy/prod.sh
   ```

### Testing Approach

**NOT YET DETERMINED**

Will depend on chosen technology stack:

- Unit tests (Jest, pytest, Go testing, etc.)
- Integration tests
- E2E tests (Playwright, Cypress, etc.)
- Stream testing (verify camera feeds work)

### Debugging Techniques

**Local Development:**

- Docker logs: `docker-compose logs -f`
- Container shell: `docker-compose exec <service> sh`

**Production (NAS):**

- View logs: `./utils/deploy/deploy-utils.sh logs`
- Container status: `./utils/deploy/deploy-utils.sh status`
- SSH into container: `./utils/deploy/deploy-utils.sh shell`
- SSH into NAS: `ssh -p 33725 ziad@nas.feralcreative.co`

---

## ARCHITECTURAL DECISIONS

### Why Synology NAS Deployment?

**Decision:** Deploy to Synology NAS instead of cloud hosting

**Rationale:**

- User already owns NAS hardware (DS1525+)
- No recurring cloud hosting costs
- Local network access to cameras (lower latency)
- Full control over infrastructure
- Sufficient resources for video streaming

**Trade-offs:**

- Limited by NAS hardware specs
- Requires home internet upload bandwidth
- No auto-scaling
- Manual infrastructure management

### Why Docker?

**Decision:** Use Docker for containerization

**Rationale:**

- Consistent environment (dev/prod parity)
- Easy deployment and rollback
- Isolation from NAS system
- Portable across different hosts
- Synology has native Docker support

### Why Alfred Workflow for Deployment?

**Decision:** Create `prod.sh` and `stage.sh` wrappers for Alfred snippet

**Rationale:**

- User's existing workflow: types `./utils/deploy/.sh` in Alfred
- Cursor positioned before `.sh` to type "prod" or "stage"
- Maintains muscle memory and efficiency
- Simple, predictable deployment command

**Implementation:**

- `prod.sh` sets `DEPLOY_ENV=production` and calls `deploy.sh`
- `stage.sh` sets `DEPLOY_ENV=staging` and calls `deploy.sh`
- `deploy.sh` reads environment and uses appropriate config

### Why Environment-Based Configuration?

**Decision:** Use `DEPLOY_ENV` variable instead of separate scripts

**Rationale:**

- Single deployment script (`deploy.sh`) for all environments
- Configuration-driven (not code-driven)
- Easy to add new environments
- Reduces code duplication
- Clearer separation of concerns

---

## CRITICAL ISSUES

### 1. Application Not Yet Built

**Status:** 🚨 **BLOCKING**

**Impact:** Cannot deploy until application exists

**Next Steps:**

1. Determine technology stack
2. Design camera integration approach
3. Create Dockerfile
4. Create docker-compose.yml
5. Build application

### 2. Cloudflare Credentials Not Configured

**Status:** ⚠️ **Required for deployment**

**Impact:** Cache purging will fail during deployment

**Workaround:** Deployment will complete but cache won't be purged

**Fix:**

1. Create `.env` from `.env.example`
2. Add Cloudflare API token and zone ID
3. Verify with test deployment

### 3. Camera Details Unknown

**Status:** ⚠️ **Required for implementation**

**Impact:** Cannot integrate cameras without:

- Camera IP addresses
- Authentication credentials
- Stream URLs/protocols
- Camera capabilities

**Next Steps:**

1. Document camera models
2. Access camera admin interfaces
3. Determine stream URLs
4. Test stream accessibility

---

## DEBUGGING

### Common Problems and Solutions

**Problem:** Deployment fails with "deploy.config not found"
**Solution:** Ensure you're running from project root, not `utils/deploy/`

**Problem:** SSH connection fails
**Solution:**

1. Verify SSH key exists: `ls ~/.ssh/*nas* ~/.ssh/*synology*`
2. Test SSH: `ssh -p 33725 ziad@nas.feralcreative.co`
3. Check SSH config in `~/.ssh/config`

**Problem:** Docker build fails
**Solution:**

1. Ensure Dockerfile exists
2. Check Docker is running: `docker ps`
3. Review build logs for errors

**Problem:** Cloudflare cache purge fails
**Solution:**

1. Verify `.env` exists with credentials
2. Test API token: `curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer YOUR_TOKEN"`
3. Verify zone ID is correct

### Log Locations

**Local Development:**

- Docker logs: `docker-compose logs`
- Application logs: Depends on app implementation

**Production (NAS):**

- Container logs: `./utils/deploy/deploy-utils.sh logs`
- NAS system logs: `/var/log/` on NAS
- Docker logs on NAS: `ssh -p 33725 ziad@nas.feralcreative.co "docker logs cats"`

### Health Check Procedures

**Local:**

```bash
docker-compose ps                    # Check container status
docker-compose logs -f               # Follow logs
curl http://localhost:PORT           # Test application (port TBD)
```

**Production:**

```bash
./utils/deploy/deploy-utils.sh status   # Container status
./utils/deploy/deploy-utils.sh logs     # View logs
curl https://cats.feralcreative.co       # Test live site
```

---

## NEXT STEPS

### Immediate Priorities

1. **Determine Architecture** 🚨 **CRITICAL**
   - Choose technology stack
   - Design system architecture
   - Document decisions in this file

2. **Camera Research** 🚨 **CRITICAL**
   - Document camera models
   - Find stream URLs
   - Test camera accessibility
   - Determine authentication method

3. **Create Docker Files** ⚠️ **HIGH**
   - Create `Dockerfile` based on chosen stack
   - Create `docker-compose.yml` with appropriate config
   - Test local Docker build

4. **Configure Cloudflare** ⚠️ **HIGH**
   - Create `.env` from `.env.example`
   - Add API token and zone ID
   - Test cache purging

5. **Build MVP** 📋 **MEDIUM**
   - Implement basic camera streaming
   - Create simple frontend
   - Test end-to-end flow

### Feature Roadmap

**Phase 1: MVP (Minimum Viable Product)**

- [ ] Display 4 camera streams
- [ ] Basic grid layout
- [ ] Live streaming only
- [ ] No authentication

**Phase 2: Enhanced Features**

- [ ] Recording/playback capability
- [ ] Stream quality selection
- [ ] Mobile-responsive design
- [ ] Error handling and retry logic

**Phase 3: Advanced Features**

- [ ] Motion detection alerts
- [ ] Timeline scrubbing
- [ ] Multi-user access
- [ ] Authentication/authorization

### Documentation Gaps

- [ ] Camera specifications and configuration
- [ ] Technology stack decision rationale
- [ ] API documentation (when backend is built)
- [ ] Frontend component documentation
- [ ] Deployment troubleshooting guide
- [ ] Performance benchmarks
- [ ] Security considerations

---

## QUICK REFERENCE

### Essential Commands

```bash
# Deployment
./utils/deploy/prod.sh              # Deploy to production
./utils/deploy/stage.sh             # Deploy to staging (not used)

# Container Management
./utils/deploy/deploy-utils.sh logs      # View logs
./utils/deploy/deploy-utils.sh status    # Check status
./utils/deploy/deploy-utils.sh restart   # Restart container

# Local Development (when app exists)
docker-compose up                   # Start local environment
docker-compose down                 # Stop local environment
docker-compose logs -f              # Follow logs

# SSH Access
ssh -p 33725 ziad@nas.feralcreative.co   # SSH into NAS
```

### Important Files

- `deploy.config` - Deployment configuration
- `.env` - Environment variables (create from `.env.example`)
- `Dockerfile` - Docker build instructions (not created yet)
- `docker-compose.yml` - Container orchestration (not created yet)
- `utils/deploy/deploy.sh` - Main deployment script
- `docs/DEPLOYMENT.md` - Deployment guide

### Important URLs

- **Production:** https://cats.feralcreative.co
- **Staging:** https://stage.cats.feralcreative.co (not used)
- **Cloudflare Dashboard:** https://dash.cloudflare.com
- **Cloudflare API Tokens:** https://dash.cloudflare.com/profile/api-tokens

---

**END OF PRIMER**

_This document will be updated as architectural decisions are made and the application is built._
