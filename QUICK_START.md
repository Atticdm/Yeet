# 🚀 Быстрый старт Yeet

## ✅ Что уже готово:
- ✅ iOS приложение полностью настроено
- ✅ Backend код готов
- ✅ Локальный сервер работает
- ✅ Все файлы на месте

## 🎯 Следующие шаги (5 минут):

### 1. Деплой бэкенда на Railway
1. Откройте [railway.app](https://railway.app)
2. Нажмите "Start a New Project"
3. Войдите через GitHub
4. Выберите "Deploy from GitHub repo"
5. Найдите репозиторий "Yeet"
6. Выберите папку `Server/` как корневую
7. Нажмите "Deploy"

### 2. Получите URL
После деплоя Railway покажет URL вида:
```
https://your-project-name.up.railway.app
```

### 3. Обновите приложение
Откройте файл `Config.plist` и замените URL:
```xml
<key>backendBaseURL</key>
<string>https://your-project-name.up.railway.app</string>
```

### 4. Соберите iOS приложение
```bash
# Генерируйте Xcode проект
xcodegen generate

# Откройте в Xcode
open Yeet.xcodeproj
```

### 5. Настройте в Xcode
1. Выберите свою команду разработки
2. Обновите Bundle Identifier
3. Подключите iPhone
4. Нажмите ⌘+R для сборки

## 🧪 Тестирование

### Проверьте бэкенд:
```bash
curl -X POST https://your-project-name.up.railway.app/get-video-link \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.instagram.com/reel/test"}'
```

### Проверьте iOS приложение:
1. Откройте Instagram/YouTube
2. Поделитесь видео
3. Выберите "Yeet"
4. Проверьте загрузку

## 🎉 Готово!

Ваше приложение готово к использованию!

---
**Нужна помощь?** Проверьте логи в Railway Dashboard и Xcode Console.
