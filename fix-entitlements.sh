#!/bin/bash

# Script to fix entitlements if they get cleared
echo "🔧 Fixing entitlements and capabilities..."

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
