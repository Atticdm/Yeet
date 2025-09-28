# 🚀 Ручной деплой на Railway

## Вариант 1: Через веб-интерфейс Railway (Рекомендуется)

### Шаг 1: Откройте Railway Dashboard
1. Перейдите на [railway.app](https://railway.app)
2. Войдите в свой аккаунт
3. Найдите проект с ID: `9d56f497-921a-4f79-ac92-1a217665d506`

### Шаг 2: Настройте деплой
1. В настройках проекта выберите "Source"
2. Подключите GitHub репозиторий: `Atticdm/Yeet`
3. Установите корневую директорию: `/` (корень проекта)
4. Railway автоматически обнаружит `railway.json` и `Dockerfile`

### Шаг 3: Запустите деплой
1. Нажмите "Deploy" или "Redeploy"
2. Дождитесь завершения сборки
3. Скопируйте URL вашего сервиса

## Вариант 2: Через Railway CLI (если установлен)

```bash
# Установите Railway CLI глобально
npm install -g @railway/cli

# Войдите в Railway
railway login

# Подключитесь к проекту
railway link --project 9d56f497-921a-4f79-ac92-1a217665d506

# Деплой
railway up
```

## Вариант 3: Через GitHub Actions

### Настройте секреты в GitHub:
1. Перейдите в Settings → Secrets and variables → Actions
2. Добавьте секреты:
   - `RAILWAY_TOKEN` - ваш Railway API токен
   - `RAILWAY_SERVICE_ID` - ID вашего сервиса

### Запустите деплой:
1. Перейдите в Actions в вашем GitHub репозитории
2. Выберите "Deploy to Railway"
3. Нажмите "Run workflow"

## После деплоя

### 1. Получите URL
Railway предоставит URL вида:
```
https://your-project-name.up.railway.app
```

### 2. Обновите Config.plist
Замените URL в файле `Config.plist`:
```xml
<key>backendBaseURL</key>
<string>https://your-project-name.up.railway.app</string>
```

### 3. Протестируйте API
```bash
curl -X POST https://your-project-name.up.railway.app/get-video-link \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.instagram.com/reel/test"}'
```

## Troubleshooting

### Если деплой не работает:
1. Проверьте логи в Railway Dashboard
2. Убедитесь, что `railway.json` и `Dockerfile` в корне проекта
3. Проверьте, что все файлы в `Server/` папке

### Если API не отвечает:
1. Проверьте URL в Config.plist
2. Убедитесь, что сервер запущен
3. Проверьте CORS настройки

## Готово! 🎉
После успешного деплоя вы можете:
1. Обновить Config.plist с новым URL
2. Собрать iOS приложение
3. Протестировать на устройстве
