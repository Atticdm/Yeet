const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    message: 'Yeet backend is running!'
  });
});

// Simple test endpoint
app.post('/get-video-link', (req, res) => {
  const { url, user_cookies_json } = req.body;
  
  console.log('Received request:', { url, hasCookies: !!user_cookies_json });
  
  // Mock response for testing
  res.json({
    downloadUrl: `https://example.com/video.mp4?url=${encodeURIComponent(url)}`,
    title: 'Test Video',
    fileSize: 1024000,
    duration: 60,
    thumbnail: 'https://via.placeholder.com/300x200'
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Yeet backend server running on port ${PORT}`);
  console.log(`📱 Health check: http://localhost:${PORT}/health`);
  console.log(`🔗 API endpoint: http://localhost:${PORT}/get-video-link`);
});
