# Serverless Function Contract (Caching + Metadata)

Backend encapsulates `yt-dlp` and exposes cached direct-download metadata for a given video URL.

- Endpoint: `POST /get-video-link`
- Request JSON:
  ```json
  { "url": "https://instagram.com/reel/..." }
  ```
- Success JSON:
  ```json
  {
    "downloadUrl": "https://.../video.mp4",
    "title": "Funny Cat Video",
    "fileSize": 15728640,
    "duration": 180,
    "thumbnail": "https://.../thumb.jpg"
  }
  ```
  - `fileSize` in bytes (useful for estimating transfer time)
  - `duration` in seconds (optional, helps with UI hints)
  - `thumbnail` optional, generated via yt-dlp (fallback to null)
- Error JSON:
  ```json
  { "error": "Unsupported URL or download failed." }
  ```

Caching Strategy
- Recommended: Redis / Upstash / in-memory with TTL (~1–6h). Keyed by canonical URL/id.
- Flow: check cache → return immediately if hit → otherwise run yt-dlp, store result (including link expiry where applicable), return payload.
- Consider invalidating when yt-dlp returns expiring links; store expiry timestamp and refresh when stale.

Implementation Notes
- Reuse provider logic from getsocialvideobot to resolve formats and gather metadata (`title`, `duration`, `thumbnails`, `filesize_approx`).
- Expose CORS if needed (mobile native usually fine).
- Add rate limiting/auth if exposing publicly.
- Provide structured error codes (e.g., `ERR_GEO_BLOCK`, `ERR_LOGIN_REQUIRED`).
