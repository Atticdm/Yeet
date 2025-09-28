#!/bin/bash

# Script to fix entitlements and Config.plist if they get cleared
echo "🔧 Fixing entitlements, capabilities, and Config.plist..."

# Ensure Config.plist exists
if [ ! -f "Config.plist" ]; then
    echo "📝 Creating Config.plist..."
    cat > Config.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>backendBaseURL</key>
    <string>https://yeet-production-dddc.up.railway.app</string>
    <key>metadataPath</key>
    <string>/get-video-link</string>
    <key>appGroupIdentifier</key>
    <string>group.com.atticdm.Yeet</string>
    <key>keychainService</key>
    <string>com.atticdm.Yeet.cookies</string>
    <key>keychainAccessGroup</key>
    <string>com.atticdm.Yeet</string>
    <key>backgroundSessionIdentifier</key>
    <string>com.atticdm.Yeet.background</string>
    <key>assumedAverageThroughput</key>
    <real>1572864.0</real>
    <key>longDownloadThreshold</key>
    <real>15.0</real>
    <key>supportedServices</key>
    <array>
        <string>instagram</string>
        <string>youtube</string>
        <string>tiktok</string>
    </array>
</dict>
</plist>
EOF
    echo "✅ Config.plist created!"
fi

# Fix main app entitlements with full capabilities
cat > Sources/YeetApp/Yeet.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.atticdm.Yeet</string>
    </array>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.atticdm.Yeet</string>
    </array>
</dict>
</plist>
EOF

# Fix share extension entitlements with full capabilities
cat > Sources/YeetShareExtension/YeetShareExtension.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.atticdm.Yeet</string>
    </array>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.atticdm.Yeet</string>
    </array>
</dict>
</plist>
EOF

echo "✅ Entitlements fixed with full capabilities!"
echo "🔄 Regenerating Xcode project with SystemCapabilities..."

# Regenerate project
rm -rf Yeet.xcodeproj
xcodegen generate

echo "✅ Done! Open Yeet.xcodeproj and test the app."
echo "📝 Remember to set your DEVELOPMENT_TEAM in project.yml!"
