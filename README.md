# Yeet (iOS + Share Extension)

Yeet — минимальное iOS‑приложение со Share Extension. Цель: принимать URL из системного шитра Share, получать прямую ссылку на видео через бэкенд (с `yt-dlp`), скачивать во временную папку и сразу открывать системный шитр для пересылки файла (WhatsApp, Telegram и т.п.).

## Структура
- App Target: `Yeet` (SwiftUI)
- Extension Target: `YeetShareExtension` (Share Extension)
- Общая логика: `Sources/Shared/VideoDownloader.swift`
- Серверный каркас: `Server/README.md` (контракт API)
- Конфиг сборки: `project.yml` (XcodeGen)

## Быстрый старт
1) Установи XcodeGen (если нет):
   brew install xcodegen
2) Сгенерируй проект:
   cd /Users/attic/Yeet && xcodegen generate
3) Открой `Yeet.xcodeproj` в Xcode.
4) Поставь уникальные Bundle Identifier’ы для App и Extension, укажи свою команду разработки (Signing & Capabilities).
5) Собери и запусти на устройстве/симуляторе.

## Ограничения/заметки
- В `VideoDownloader.fetchDirectDownloadURL` сейчас мок (возвращает исходный URL). Позже он будет вызывать серверную функцию (Railway/Vercel/Lambda) с `yt-dlp` логикой (см. `Server/README.md`).
- Расшаривание идёт через `UIActivityViewController`; файл удаляется после закрытия шитра.
- Для теста можно расшарить любой HTTPS‑URL из Safari/Instagram/YouTube.

## Дальшие шаги
- Реализовать реальный вызов серверной функции.
- Добавить прогресс‑индикатор скачивания и обработку ошибок.
- Настроить App Groups/Background Modes (не обязательно на первом этапе).

