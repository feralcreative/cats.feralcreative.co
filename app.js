// Camera configuration
const cameras = ["left", "right", "top", "other"];
const whepClients = {};

// Initialize all cameras
async function initializeCameras() {
  console.log("Initializing cat cams...");
  for (const camera of cameras) {
    await connectCamera(camera);
  }
}

// Connect to a single camera using HLS
async function connectCamera(camera) {
  const videoElement = document.getElementById(`video-${camera}`);
  const statusElement = document.getElementById(`status-${camera}`);
  const loadingElement = document.getElementById(`loading-${camera}`);
  const errorElement = document.getElementById(`error-${camera}`);

  try {
    // Show loading state
    loadingElement.style.display = "flex";
    errorElement.style.display = "none";
    statusElement.textContent = "Connecting...";
    statusElement.className = "status connecting";

    // Use HLS streaming
    await tryHLSFallback(camera);
  } catch (error) {
    console.error(`[${camera}] Connection error:`, error);
    statusElement.textContent = "Error";
    statusElement.className = "status error";
    loadingElement.style.display = "none";
    errorElement.style.display = "flex";
  }
}

// Use HLS streaming
async function tryHLSFallback(camera) {
  const videoElement = document.getElementById(`video-${camera}`);
  const statusElement = document.getElementById(`status-${camera}`);
  const loadingElement = document.getElementById(`loading-${camera}`);
  const errorElement = document.getElementById(`error-${camera}`);

  console.log(`[${camera}] Starting HLS stream...`);

  if (videoElement.canPlayType("application/vnd.apple.mpegurl")) {
    // Native HLS support (Safari)
    videoElement.src = `/cam_${camera}/video1_stream.m3u8`;
    videoElement.addEventListener("loadedmetadata", () => {
      loadingElement.style.display = "none";
      statusElement.textContent = "Connected";
      statusElement.className = "status connected";
    });
    videoElement.addEventListener("error", () => {
      loadingElement.style.display = "none";
      errorElement.style.display = "flex";
      statusElement.textContent = "Error";
      statusElement.className = "status error";
    });
    videoElement.play();
  } else if (typeof Hls !== "undefined") {
    // Use hls.js for other browsers
    const hls = new Hls({
      maxLiveSyncPlaybackRate: 1.5,
    });

    hls.on(Hls.Events.MANIFEST_PARSED, () => {
      loadingElement.style.display = "none";
      statusElement.textContent = "Connected";
      statusElement.className = "status connected";
      videoElement.play();
    });

    hls.on(Hls.Events.ERROR, (event, data) => {
      if (data.fatal) {
        console.error(`[${camera}] HLS error:`, data);
        loadingElement.style.display = "none";
        errorElement.style.display = "flex";
        statusElement.textContent = "Error";
        statusElement.className = "status error";
      }
    });

    hls.loadSource(`/cam_${camera}/video1_stream.m3u8`);
    hls.attachMedia(videoElement);

    // Store HLS instance for cleanup
    whepClients[camera] = hls;
  } else {
    console.error(`[${camera}] HLS not supported`);
    loadingElement.style.display = "none";
    errorElement.style.display = "flex";
    statusElement.textContent = "Error";
    statusElement.className = "status error";
  }
}

// Reconnect a camera
async function reconnect(camera) {
  console.log(`[${camera}] Reconnecting...`);

  // Close existing connection
  if (whepClients[camera]) {
    if (typeof whepClients[camera].destroy === "function") {
      // HLS.js instance
      whepClients[camera].destroy();
    } else if (typeof whepClients[camera].close === "function") {
      // RTCPeerConnection instance
      whepClients[camera].close();
    }
    delete whepClients[camera];
  }

  // Reconnect
  await connectCamera(camera);
}

// Note: Camera initialization is now handled by auth.js
// Cameras will only initialize after successful authentication

// Reconnect on visibility change (when tab becomes visible again)
document.addEventListener("visibilitychange", () => {
  if (!document.hidden) {
    console.log("Page visible again, checking connections...");
    cameras.forEach((camera) => {
      const pc = whepClients[camera];
      if (!pc || pc.connectionState !== "connected") {
        reconnect(camera);
      }
    });
  }
});
