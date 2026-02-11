/*
 |--------------------------------------------------------------------------
 | Browser-sync config file
 |--------------------------------------------------------------------------
 |
 | For up-to-date information about the options:
 |   http://www.browsersync.io/docs/options/
 |
 */
module.exports = {
  // Serve files from the current directory
  server: {
    baseDir: "./",
    index: "index.html"
  },

  // Watch these files for changes
  files: [
    "*.html",
    "app.js",
    "styles/css/**/*.css",
    "images/**/*"
  ],

  // Port to run the dev server on
  port: 3000,

  // Open browser automatically
  open: true,

  // Don't show the "Connected to BrowserSync" notification
  notify: false,

  // Enable HTTPS (required for WebRTC)
  https: false,

  // UI settings
  ui: {
    port: 3001
  },

  // Middleware to add CORS headers for local development
  middleware: [
    function (req, res, next) {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');
      res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type');
      next();
    }
  ],

  // Proxy settings for mediamtx (when running docker-compose locally)
  // Uncomment if you want to proxy WebRTC requests to local mediamtx
  /*
  proxy: {
    target: "http://localhost:80",
    middleware: [
      function (req, res, next) {
        // Proxy /cam_* requests to mediamtx
        if (req.url.startsWith('/cam_')) {
          req.url = req.url;
        }
        next();
      }
    ]
  },
  */

  // Reload delay
  reloadDelay: 0,

  // Inject CSS changes without reloading
  injectChanges: true,

  // Scroll sync across devices
  ghostMode: {
    clicks: false,
    forms: false,
    scroll: false
  }
};

