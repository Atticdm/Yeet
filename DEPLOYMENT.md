# 🚀 Deployment Guide for Yeet iOS App

## Prerequisites

- Xcode 15+ installed
- iOS Developer Account (for device testing)
- Railway account (for backend)
- Git repository

## Step 1: Deploy Backend to Railway

### 1.1 Create Railway Project
1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your Yeet repository
5. Choose "Deploy from a folder" → select `Server/` folder

### 1.2 Configure Railway
Railway will automatically detect the Dockerfile and deploy. The backend will be available at:
```
https://your-project-name.up.railway.app
```

### 1.3 Test Backend
```bash
curl -X POST https://your-project-name.up.railway.app/get-video-link \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.instagram.com/reel/example"}'
```

## Step 2: Configure iOS App

### 2.1 Update Backend URL
Edit `Config.plist`:
```xml
<key>backendBaseURL</key>
<string>https://your-project-name.up.railway.app</string>
```

### 2.2 Configure Bundle Identifiers
In Xcode, update these identifiers to match your Apple Developer account:
- **Main App**: `com.yourname.Yeet`
- **Share Extension**: `com.yourname.Yeet.share`

### 2.3 Configure App Groups
Update entitlements files:
- `Sources/YeetApp/Yeet.entitlements`
- `Sources/YeetShareExtension/YeetShareExtension.entitlements`

Change the App Group identifier:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourname.Yeet</string>
</array>
```

### 2.4 Update project.yml
```yaml
settings:
  base:
    PRODUCT_BUNDLE_IDENTIFIER: com.yourname.Yeet
    # ... other settings
```

## Step 3: Build and Deploy

### 3.1 Generate Xcode Project
```bash
# Install XcodeGen if not installed
brew install xcodegen

# Generate project
xcodegen generate
```

### 3.2 Open in Xcode
```bash
open Yeet.xcodeproj
```

### 3.3 Configure Signing
1. Select your development team
2. Update Bundle Identifiers
3. Enable App Groups capability
4. Configure Keychain Sharing

### 3.4 Build for Device
1. Connect iPhone via USB
2. Select your device in Xcode
3. Build and Run (⌘+R)

## Step 4: Test the App

### 4.1 Enable Share Extension
1. Open any app with video (Instagram, YouTube, etc.)
2. Tap Share button
3. Scroll to "More" → "Edit"
4. Enable "Yeet" extension

### 4.2 Test Video Download
1. Share a video link using Yeet
2. Verify download works
3. Test with private content (requires login)

## Troubleshooting

### Backend Issues
- Check Railway logs for errors
- Verify yt-dlp is working: `yt-dlp --version`
- Test API endpoint manually

### iOS Issues
- Check Bundle Identifiers match everywhere
- Verify App Groups are configured
- Check Keychain Access Groups
- Ensure proper signing certificates

### Common Errors
- **"Extension context missing"**: Check Share Extension configuration
- **"Backend configuration missing"**: Verify Config.plist has correct URL
- **"Login required"**: Test authentication flow

## Production Considerations

### Security
- Use HTTPS for all communications
- Implement proper rate limiting
- Add authentication for backend
- Secure cookie storage

### Performance
- Implement Redis caching
- Add CDN for static assets
- Monitor backend performance
- Optimize video processing

### Monitoring
- Set up Railway monitoring
- Add error tracking (Sentry)
- Monitor API usage
- Track user analytics

## Next Steps

1. **Test thoroughly** on different devices
2. **Submit to App Store** (if desired)
3. **Monitor usage** and performance
4. **Iterate** based on user feedback

---

**Need help?** Check the logs in Railway dashboard and Xcode console for detailed error messages.
