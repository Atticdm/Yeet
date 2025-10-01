#!/bin/bash

# 🚀 Скрипт быстрого восстановления проекта Yeet
# Использование: ./QUICK_RESTORE.sh

echo "🔧 Восстанавливаем критичные файлы проекта Yeet..."

# 1. Создаем Config.plist
echo "📝 Создаем Config.plist..."
mkdir -p Sources/Shared
cat > Sources/Shared/Config.plist << 'EOF'
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

# 2. Создаем Yeet.entitlements
echo "📝 Создаем Yeet.entitlements..."
mkdir -p Sources/YeetApp
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

# 3. Создаем YeetShareExtension.entitlements
echo "📝 Создаем YeetShareExtension.entitlements..."
mkdir -p Sources/YeetShareExtension
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
        <string>$(AppIdentifierPrefix)com.atticdm.Yeet.share</string>
    </array>
</dict>
</plist>
EOF

echo "✅ Все файлы созданы!"
echo ""
echo "🔄 Перегенерируем проект Xcode..."
rm -rf Yeet.xcodeproj
xcodegen generate

echo ""
echo "✅ Готово! Проект восстановлен."
echo ""
echo "📱 Следующие шаги:"
echo "1. Откройте Yeet.xcodeproj в Xcode"
echo "2. Проверьте 'Signing & Capabilities' для обоих таргетов"
echo "3. Clean Build Folder (⌘+Shift+K)"
echo "4. Build & Run (⌘+R)"
echo ""
echo "📋 Проверьте, что включены:"
echo "   ✓ App Groups: group.com.atticdm.Yeet"
echo "   ✓ Keychain Sharing"
echo ""
echo "🚀 Удачи!"

