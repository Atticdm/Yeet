# Serverless Function Contract (Placeholder)

This backend encapsulates `yt-dlp` logic and returns a direct downloadable URL for a given video page URL.

- Endpoint: `POST /get-video-link`
- Request JSON:
  ```json
  { "url": "https://instagram.com/reel/..." }
  ```
- Success JSON:
  ```json
  { "downloadUrl": "https://.../video.mp4" }
  ```
- Error JSON:
  ```json
  { "error": "Unsupported URL or download failed." }
  ```

Notes
- Implement with Railway/Vercel/Lambda. Reuse provider logic from getsocialvideobot to resolve best downloadable format.
- Add appropriate CORS if calling from app if needed (iOS app typically not restricted).
- Consider rate limiting and auth if required.

