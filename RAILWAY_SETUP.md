# 🚀 Railway Setup Instructions

## Вариант 1: Через веб-интерфейс Railway (Рекомендуется)

### Шаг 1: Создайте аккаунт на Railway
1. Перейдите на [railway.app](https://railway.app)
2. Нажмите "Start a New Project"
3. Войдите через GitHub

### Шаг 2: Подключите репозиторий
1. Выберите "Deploy from GitHub repo"
2. Найдите ваш репозиторий "Yeet"
3. Выберите папку `Server/` как корневую папку проекта

### Шаг 3: Настройте переменные окружения
В Railway Dashboard → Variables:
```
NODE_ENV=production
PORT=3000
```

### Шаг 4: Деплой
Railway автоматически:
- Обнаружит Dockerfile
- Соберет Docker образ
- Запустит контейнер
- Предоставит URL

## Вариант 2: Через Railway CLI

### Шаг 1: Установите Railway CLI
```bash
# В папке Server/
npm install -g @railway/cli
```

### Шаг 2: Войдите в Railway
```bash
railway login
# Откроется браузер для авторизации
```

### Шаг 3: Инициализируйте проект
```bash
railway init
```

### Шаг 4: Деплой
```bash
railway up
```

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
2. Убедитесь, что Dockerfile корректен
3. Проверьте, что все файлы в папке Server/

### Если API не отвечает:
1. Проверьте URL в Config.plist
2. Убедитесь, что сервер запущен
3. Проверьте CORS настройки

## Готово! 🎉
После успешного деплоя вы можете:
1. Обновить Config.plist с новым URL
2. Собрать iOS приложение
3. Протестировать на устройстве
