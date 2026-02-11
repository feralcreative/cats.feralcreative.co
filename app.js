// Camera configuration
const cameras = ['left', 'right', 'top', 'other'];
const whepClients = {};

// Initialize all cameras
async function initCameras() {
    for (const camera of cameras) {
        await connectCamera(camera);
    }
}

// Connect to a single camera using WHEP
async function connectCamera(camera) {
    const videoElement = document.getElementById(`video-${camera}`);
    const statusElement = document.getElementById(`status-${camera}`);
    const loadingElement = document.getElementById(`loading-${camera}`);
    const errorElement = document.getElementById(`error-${camera}`);

    try {
        // Show loading state
        loadingElement.style.display = 'flex';
        errorElement.style.display = 'none';
        statusElement.textContent = 'Connecting...';
        statusElement.className = 'status connecting';

        // Create WHEP client
        const whepUrl = `/cam_${camera}/whep`;
        
        // Use WHEP Web Client
        const pc = new RTCPeerConnection({
            iceServers: [
                { urls: 'stun:stun.l.google.com:19302' }
            ]
        });

        // Add transceiver for receiving video
        pc.addTransceiver('video', { direction: 'recvonly' });
        pc.addTransceiver('audio', { direction: 'recvonly' });

        // Handle incoming tracks
        pc.ontrack = (event) => {
            console.log(`[${camera}] Received track:`, event.track.kind);
            if (event.track.kind === 'video') {
                videoElement.srcObject = event.streams[0];
                loadingElement.style.display = 'none';
                statusElement.textContent = 'Connected';
                statusElement.className = 'status connected';
            }
        };

        // Handle connection state changes
        pc.onconnectionstatechange = () => {
            console.log(`[${camera}] Connection state:`, pc.connectionState);
            
            if (pc.connectionState === 'connected') {
                loadingElement.style.display = 'none';
                statusElement.textContent = 'Connected';
                statusElement.className = 'status connected';
            } else if (pc.connectionState === 'disconnected' || pc.connectionState === 'failed') {
                statusElement.textContent = 'Disconnected';
                statusElement.className = 'status disconnected';
                errorElement.style.display = 'flex';
                loadingElement.style.display = 'none';
            }
        };

        // Create offer
        const offer = await pc.createOffer();
        await pc.setLocalDescription(offer);

        // Send offer to WHEP endpoint
        const response = await fetch(whepUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/sdp'
            },
            body: offer.sdp
        });

        if (!response.ok) {
            throw new Error(`WHEP request failed: ${response.status}`);
        }

        // Get answer from server
        const answer = await response.text();
        await pc.setRemoteDescription({
            type: 'answer',
            sdp: answer
        });

        // Store the peer connection
        whepClients[camera] = pc;

        console.log(`[${camera}] Successfully connected via WHEP`);

    } catch (error) {
        console.error(`[${camera}] Connection error:`, error);
        statusElement.textContent = 'Error';
        statusElement.className = 'status error';
        loadingElement.style.display = 'none';
        errorElement.style.display = 'flex';
        
        // Try HLS fallback after 2 seconds
        setTimeout(() => tryHLSFallback(camera), 2000);
    }
}

// Fallback to HLS if WebRTC fails
async function tryHLSFallback(camera) {
    const videoElement = document.getElementById(`video-${camera}`);
    const statusElement = document.getElementById(`status-${camera}`);
    
    console.log(`[${camera}] Trying HLS fallback...`);
    
    if (videoElement.canPlayType('application/vnd.apple.mpegurl')) {
        // Native HLS support (Safari)
        videoElement.src = `/cam_${camera}/index.m3u8`;
        statusElement.textContent = 'HLS Mode';
        statusElement.className = 'status connected';
    } else if (typeof Hls !== 'undefined') {
        // Use hls.js for other browsers
        const hls = new Hls();
        hls.loadSource(`/cam_${camera}/index.m3u8`);
        hls.attachMedia(videoElement);
        statusElement.textContent = 'HLS Mode';
        statusElement.className = 'status connected';
    } else {
        console.error(`[${camera}] HLS not supported`);
    }
}

// Reconnect a camera
async function reconnect(camera) {
    console.log(`[${camera}] Reconnecting...`);
    
    // Close existing connection
    if (whepClients[camera]) {
        whepClients[camera].close();
        delete whepClients[camera];
    }
    
    // Reconnect
    await connectCamera(camera);
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    console.log('Initializing cat cams...');
    initCameras();
});

// Reconnect on visibility change (when tab becomes visible again)
document.addEventListener('visibilitychange', () => {
    if (!document.hidden) {
        console.log('Page visible again, checking connections...');
        cameras.forEach(camera => {
            const pc = whepClients[camera];
            if (!pc || pc.connectionState !== 'connected') {
                reconnect(camera);
            }
        });
    }
});

