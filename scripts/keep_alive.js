/**
 * 💓 Time2Wish Render Backend Keep-Alive Daemon Script
 *
 * This script continuously pings the production Spring Boot backend
 * (https://time2wish-backend.onrender.com/api/public/health) every 5 minutes
 * to prevent free Render cloud containers from going to sleep / spinning down.
 *
 * Usage:
 *   node scripts/keep_alive.js
 */

const https = require('https');
const http = require('http');

// Target Production Backend Health URL (or environment override)
const PRIMARY_URL = process.env.RENDER_HEALTH_URL || 'https://time2wish-backend.onrender.com/api/public/health';
const FALLBACK_URL = 'https://time2wish-backend.onrender.com/api/auth/login';
const PING_INTERVAL_MS = parseInt(process.env.PING_INTERVAL_MS || '300000', 10); // 5 minutes

console.log("=================================================");
console.log("💓 TIME2WISH BACKEND KEEP-ALIVE DAEMON STARTED");
console.log(`🎯 Primary URL:      ${PRIMARY_URL}`);
console.log(`⏱️ Ping Frequency:   Every ${PING_INTERVAL_MS / 1000} seconds (${PING_INTERVAL_MS / 60000} min)`);
console.log("=================================================\n");

function sendHttpRequest(targetUrl) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    const isHttps = targetUrl.startsWith('https');
    const client = isHttps ? https : http;

    const req = client.get(targetUrl, { timeout: 15000 }, (res) => {
      let rawData = '';
      res.on('data', chunk => rawData += chunk);
      res.on('end', () => {
        const durationMs = Date.now() - startTime;
        resolve({ statusCode: res.statusCode, durationMs, url: targetUrl });
      });
    });

    req.on('error', err => reject(err));
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Timeout after 15s'));
    });
  });
}

async function pingBackend() {
  const timestamp = new Date().toISOString();

  try {
    const res = await sendHttpRequest(PRIMARY_URL);
    console.log(`[${timestamp}] 💓 KEEP-ALIVE OK | ${res.url} | HTTP ${res.statusCode} | Duration: ${res.durationMs}ms`);
  } catch (err1) {
    // Try fallback endpoint
    try {
      const res2 = await sendHttpRequest(FALLBACK_URL);
      console.log(`[${timestamp}] 💓 KEEP-ALIVE OK (Fallback) | ${res2.url} | HTTP ${res2.statusCode} | Duration: ${res2.durationMs}ms`);
    } catch (err2) {
      console.error(`[${timestamp}] ❌ KEEP-ALIVE ERROR: ${err1.message} | Fallback: ${err2.message}`);
    }
  }
}

// Initial immediate ping upon script start
pingBackend();

// Set recurring interval
setInterval(pingBackend, PING_INTERVAL_MS);
