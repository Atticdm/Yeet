const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { RateLimiterMemory } = require('rate-limiter-flexible');
const { exec } = require('child_process');
const { promisify } = require('util');
const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

const execAsync = promisify(exec);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const rateLimiter = new RateLimiterMemory({
  keyPrefix: 'middleware',
  points: 10, // Number of requests
  duration: 60, // Per 60 seconds
});

const rateLimiterMiddleware = async (req, res, next) => {
  try {
    await rateLimiter.consume(req.ip);
    next();
  } catch (rejInfo) {
    res.status(429).json({
      error: 'Too many requests',
      errorCode: 'ERR_RATE_LIMITED'
    });
  }
};

app.use(rateLimiterMiddleware);

// Cache (in-memory for simplicity, use Redis in production)
const cache = new Map();
const CACHE_TTL = 6 * 60 * 60 * 1000; // 6 hours

// Helper functions
function hashCookies(cookies) {
  if (!cookies || Object.keys(cookies).length === 0) return 'no-auth';
  return crypto.createHash('md5').update(JSON.stringify(cookies)).digest('hex');
}

function getCacheKey(url, authHash) {
  return `${url}_${authHash}`;
}

async function runYtDlp(url, cookies = {}) {
  const tempDir = '/tmp/yeet';
  await fs.mkdir(tempDir, { recursive: true });
  
  // Create cookies file if provided
  let cookiesFile = null;
  if (Object.keys(cookies).length > 0) {
    cookiesFile = path.join(tempDir, `cookies_${Date.now()}.txt`);
    const cookieLines = Object.entries(cookies).map(([name, value]) => 
      `#HttpOnly_.${new URL(url).hostname}\tTRUE\t/\tFALSE\t0\t${name}\t${value}`
    ).join('\n');
    await fs.writeFile(cookiesFile, cookieLines);
  }

  // Build yt-dlp command
  const cmd = [
    'yt-dlp',
    '--no-playlist',
    '--format', 'best[ext=mp4]/best',
    '--get-url',
    '--get-title',
    '--get-duration',
    '--get-thumbnail',
    '--get-filesize',
    ...(cookiesFile ? ['--cookies', cookiesFile] : []),
    url
  ].join(' ');

  try {
    const { stdout, stderr } = await execAsync(cmd, { timeout: 30000 });
    
    // Clean up cookies file
    if (cookiesFile) {
      await fs.unlink(cookiesFile).catch(() => {});
    }

    if (stderr && stderr.includes('login required')) {
      throw new Error('ERR_LOGIN_REQUIRED');
    }

    const lines = stdout.trim().split('\n');
    const result = {
      downloadUrl: lines[0] || null,
      title: lines[1] || 'Unknown Title',
      duration: lines[2] ? parseInt(lines[2]) : null,
      thumbnail: lines[3] || null,
      fileSize: lines[4] ? parseInt(lines[4]) : null
    };

    if (!result.downloadUrl) {
      throw new Error('ERR_DOWNLOAD_FAILED');
    }

    return result;
  } catch (error) {
    // Clean up cookies file on error
    if (cookiesFile) {
      await fs.unlink(cookiesFile).catch(() => {});
    }
    
    if (error.message.includes('ERR_LOGIN_REQUIRED')) {
      throw new Error('ERR_LOGIN_REQUIRED');
    }
    throw error;
  }
}

// Main endpoint
app.post('/get-video-link', async (req, res) => {
  try {
    const { url, user_cookies_json } = req.body;

    if (!url) {
      return res.status(400).json({
        error: 'URL is required',
        errorCode: 'ERR_UNSUPPORTED_URL'
      });
    }

    // Validate URL
    try {
      new URL(url);
    } catch {
      return res.status(400).json({
        error: 'Invalid URL format',
        errorCode: 'ERR_UNSUPPORTED_URL'
      });
    }

    // Check cache
    const authHash = hashCookies(user_cookies_json);
    const cacheKey = getCacheKey(url, authHash);
    const cached = cache.get(cacheKey);
    
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
      return res.json(cached.data);
    }

    // Run yt-dlp
    const result = await runYtDlp(url, user_cookies_json || {});

    // Cache result
    cache.set(cacheKey, {
      data: result,
      timestamp: Date.now()
    });

    res.json(result);

  } catch (error) {
    console.error('Error processing request:', error);

    if (error.message === 'ERR_LOGIN_REQUIRED') {
      return res.status(401).json({
        error: 'Login required for this content',
        errorCode: 'ERR_LOGIN_REQUIRED'
      });
    }

    if (error.message.includes('geo-blocked')) {
      return res.status(403).json({
        error: 'Content is geo-blocked in your region',
        errorCode: 'ERR_GEO_BLOCK'
      });
    }

    res.status(500).json({
      error: 'Download failed',
      errorCode: 'ERR_DOWNLOAD_FAILED'
    });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Clean up old cache entries periodically
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of cache.entries()) {
    if (now - value.timestamp > CACHE_TTL) {
      cache.delete(key);
    }
  }
}, 60 * 60 * 1000); // Every hour

app.listen(PORT, () => {
  console.log(`Yeet backend server running on port ${PORT}`);
});
