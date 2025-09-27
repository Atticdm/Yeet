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
   xcodegen generate
3) Открой `Yeet.xcodeproj` в Xcode.
4) Поставь уникальные Bundle Identifier’ы для App и Extension, укажи свою команду разработки (Signing & Capabilities).
5) Собери и запусти на устройстве/симуляторе.

## Ограничения/заметки
- Укажи `backendBaseURL` в `Sources/Shared/AppConfig.swift`, чтобы использовать существующий веб‑бэкенд (например Railway `getsocialvideobot`). Без него скачивание работает только с прямыми `.mp4` ссылками.
- Share Extension показывает компактную SwiftUI‑вью с прогрессом, а после скачивания автоматически открывает системный `UIActivityViewController`.
- Временные файлы сохраняются в `Library/Caches/YeetTemp` и удаляются после закрытия финального шаринга/ошибки.

## Дальшие шаги
- Реализовать серверless endpoint согласно `Server/README.md` (возвращает прямой `downloadUrl` и `title`).
- Расширить обработку ошибок/повторную попытку, добавить аналитику.
- Добавить настройки в главное приложение (например, переключение бэкенда, очистка кеша).

