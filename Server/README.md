# Serverless Function Contract (Caching + Metadata + Authentication)

Backend encapsulates `yt-dlp` and exposes cached direct-download metadata for a given video URL with optional user authentication support.

## API Endpoint

- **Endpoint**: `POST /get-video-link`
- **Content-Type**: `application/json`

## Request Format

```json
{
  "url": "https://instagram.com/reel/...",
  "user_cookies_json": {
    "sessionid": "abc123...",
    "csrftoken": "def456...",
    "ds_user_id": "789012..."
  }
}
```

**Parameters:**
- `url` (required): The video URL to process
- `user_cookies_json` (optional): User authentication cookies as key-value pairs

## Success Response

```json
{
  "downloadUrl": "https://.../video.mp4",
  "title": "Funny Cat Video",
  "fileSize": 15728640,
  "duration": 180,
  "thumbnail": "https://.../thumb.jpg"
}
```

**Response Fields:**
- `downloadUrl`: Direct download URL for the video file
- `title`: Video title (sanitized for filename use)
- `fileSize`: File size in bytes (useful for estimating transfer time)
- `duration`: Video duration in seconds (optional)
- `thumbnail`: Thumbnail/preview image URL (optional)

## Error Response

```json
{
  "error": "Login required for this content",
  "errorCode": "ERR_LOGIN_REQUIRED"
}
```

**Error Codes:**
- `ERR_LOGIN_REQUIRED`: User authentication is required for this content
- `ERR_GEO_BLOCK`: Content is geo-blocked in the user's region
- `ERR_RATE_LIMITED`: Rate limit exceeded
- `ERR_UNSUPPORTED_URL`: URL format is not supported
- `ERR_DOWNLOAD_FAILED`: Video download failed
- `ERR_INVALID_COOKIES`: Provided cookies are invalid or expired

## Caching Strategy

- **Recommended**: Redis / Upstash / in-memory with TTL (~1–6h)
- **Cache Key**: Canonical URL + user authentication hash (if cookies provided)
- **Flow**: Check cache → return immediately if hit → otherwise run yt-dlp with user cookies → store result → return payload
- **Invalidation**: Consider invalidating when yt-dlp returns expiring links; store expiry timestamp and refresh when stale

## Implementation Notes

### Backend Requirements
- Reuse provider logic from getsocialvideobot to resolve formats and gather metadata
- Support user authentication by passing cookies to yt-dlp
- Handle different platforms (Instagram, YouTube, TikTok) with appropriate cookie formats
- Implement proper error handling for authentication failures

### Security Considerations
- Validate and sanitize user-provided cookies
- Implement rate limiting per IP and per user
- Add CORS headers if exposing publicly
- Log authentication attempts for monitoring

### Performance
- Cache results based on URL + authentication state
- Use background processing for large downloads
- Implement proper timeout handling
- Monitor yt-dlp performance and memory usage

### Error Handling
- Return structured error codes for different failure scenarios
- Provide helpful error messages for debugging
- Implement retry logic for transient failures
- Log errors for monitoring and debugging

## Deployment Instructions

### Railway Deployment

1. **Create Railway Account**
   - Go to [railway.app](https://railway.app)
   - Sign up with GitHub account
   - Connect your repository

2. **Deploy Backend**
   ```bash
   # In the Server/ directory
   railway login
   railway init
   railway up
   ```

3. **Environment Variables** (set in Railway dashboard)
   - `NODE_ENV=production`
   - `PORT=3000` (auto-set by Railway)

4. **Update iOS App Configuration**
   - Update `Config.plist` with your Railway URL:
   ```xml
   <key>backendBaseURL</key>
   <string>https://your-app-name.up.railway.app</string>
   ```

### Local Development

```bash
cd Server/
npm install
npm start
```

### Testing the API

```bash
curl -X POST https://your-app-name.up.railway.app/get-video-link \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.instagram.com/reel/example"}'
```

## Example Implementation (Node.js)

The complete server implementation is in `server.js` with:
- Express.js framework
- yt-dlp integration
- Rate limiting
- Caching
- Error handling
- CORS support
