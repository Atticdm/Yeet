# 🚀 Настройка проекта Yeet

## ⚠️ ВАЖНО: Настройка Team ID

Перед запуском приложения необходимо настроить ваш Apple Developer Team ID:

### 1. Найдите ваш Team ID:
- Откройте [Apple Developer Portal](https://developer.apple.com/account/)
- Перейдите в "Membership" → "Team ID"
- Скопируйте ваш Team ID (например: `A1B2C3D4E5`)

### 2. Обновите project.yml:
```bash
# Откройте project.yml и замените:
DEVELOPMENT_TEAM: ЗАМЕНИ_НА_СВОЙ_TEAM_ID
# На:
DEVELOPMENT_TEAM: A1B2C3D4E5  # Ваш реальный Team ID
```

### 3. Перегенерируйте проект:
```bash
rm -rf Yeet.xcodeproj
xcodegen generate
```

## 🔧 Исправление проблем

### Если entitlements снова очистились:
```bash
./fix-entitlements.sh
```

### Если Config.plist не найден:
- Убедитесь, что `Config.plist` находится в корне проекта
- Проверьте, что он добавлен в `project.yml` как ресурс

## 📱 Запуск приложения

1. Откройте `Yeet.xcodeproj` в Xcode
2. Выберите ваше устройство или симулятор
3. Нажмите ⌘+R для запуска

## 🐛 Отладка

### Проверьте в Xcode:
- **Signing & Capabilities** → App Groups должен быть включен
- **Signing & Capabilities** → Keychain Sharing должен быть включен
- **Build Settings** → Development Team должен быть установлен

### Логи в консоли:
- ✅ `Config.plist loaded from bundle` - Config.plist найден
- ❌ `client is not entitled` - проблема с entitlements
- ❌ `Config.plist not found` - проблема с ресурсами

## 🎯 Ожидаемый результат

После правильной настройки:
- ✅ Приложение запускается без ошибок
- ✅ Share Extension работает
- ✅ Login flow работает
- ✅ Config.plist загружается корректно
- ✅ App Groups и Keychain доступны
