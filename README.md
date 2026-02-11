# Cat Cams - cats.feralcreative.co

Live streaming web application displaying four TP-Link Tapo C211 cameras monitoring Feral Creative's cats.

## Tech Stack

- **Frontend:** Vanilla HTML/CSS/JavaScript
- **Streaming:** WebRTC (WHEP protocol) with HLS fallback
- **Media Server:** mediamtx (RTSP to WebRTC/HLS converter)
- **Web Server:** nginx
- **Deployment:** Docker Compose on Synology NAS

## Quick Start

### Install Dependencies

```bash
npm install
```

### Local Development

**Option 1: Frontend Development (BrowserSync)**

For working on HTML/CSS/JS without camera streams:

```bash
npm run dev              # Start dev server on http://localhost:3000
npm run watch:css        # Watch and compile SCSS files
npm run dev:all          # Run both dev server and SCSS watcher
```

BrowserSync features:

- Live reload on file changes
- Auto-inject CSS changes without page reload
- UI dashboard on http://localhost:3001

**Option 2: Full Stack (Docker Compose)**

For testing with actual camera streams:

```bash
# Set up environment
cp .env.example .env
# Edit .env with camera credentials

# Start containers
docker-compose up

# Access at http://localhost:80
```

### Deployment

Deploy to production:

```bash
./utils/deploy/prod.sh
```

## Project Structure

```text
cats.feralcreative.co/
├── index.html              # Main HTML file
├── app.js                  # WebRTC client (WHEP protocol)
├── styles/
│   ├── scss/              # SCSS source files
│   └── css/               # Compiled CSS (gitignored)
├── images/                # Static images
├── mediamtx.yml           # MediaMTX configuration
├── nginx.conf             # Nginx configuration
├── docker-compose.yml     # Container orchestration
├── Dockerfile             # Nginx container build
└── utils/deploy/          # Deployment scripts
```

## Camera Configuration

4 TP-Link Tapo C211 cameras on static IPs:

| Camera | Name  | IP Address    |
| ------ | ----- | ------------- |
| 1      | LEFT  | 192.168.1.201 |
| 2      | RIGHT | 192.168.1.202 |
| 3      | TOP   | 192.168.1.203 |
| 4      | OTHER | 192.168.1.204 |

## Future Roadmap

- Google Auth whitelist for access
- ONVIF Controls for Advanced Features whitelist users

## Documentation

- **[\_AI_AGENT_PRIMER.md](_AI_AGENT_PRIMER.md)** - Complete project documentation
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Deployment guide
- **[utils/deploy/README.md](utils/deploy/README.md)** - Deployment scripts documentation

## License

MIT License - See LICENSE file for details
