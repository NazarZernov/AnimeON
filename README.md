# AnimeOnNative

Нативный мультиплатформенный MVP на SwiftUI для iPhone, iPad и macOS, визуально вдохновлённый [animeon.su](https://animeon.su) и построенный без `WebView` как основного UI.

## Что внутри

- `SwiftUI` + `MVVM`
- общий код для iOS, iPadOS и macOS
- `NetworkClient` + `RemoteAnimeService`
- `MockAnimeService` + JSON bundle resources
- adapter-слой для быстрого переключения между `mock`, `remote` и `hybrid`
- `AVKit` player c autoplay next episode, resume playback и offline download cache
- image loading через отдельный `ImagePipeline` с in-memory cache
- loading / error / empty states

## Структура проекта

```text
AnimeOnNative/
├── AnimeOnNative.xcodeproj
├── AnimeOnNative/
│   ├── App/
│   ├── Core/
│   │   ├── Extensions/
│   │   ├── Infrastructure/
│   │   └── Theme/
│   ├── Models/
│   ├── Networking/
│   ├── Resources/
│   │   └── Assets.xcassets/
│   ├── SampleData/
│   ├── Services/
│   │   ├── Adapters/
│   │   ├── Images/
│   │   └── Playback/
│   ├── ViewModels/
│   └── Views/
│       ├── Catalog/
│       ├── Components/
│       ├── Detail/
│       ├── Home/
│       ├── News/
│       ├── Premium/
│       ├── Profile/
│       ├── Random/
│       ├── Schedule/
│       └── Updates/
└── README.md
```

## Запуск

1. Открой `AnimeOnNative.xcodeproj`.
2. Для iPhone/iPad выбери схему `AnimeOnNative iOS`.
3. Для macOS выбери схему `AnimeOnNative macOS`.
4. Запусти на `iPhone`, `iPad` или `My Mac`.


)
```



`hybrid` полезен, когда backend ещё не полностью готов: приложение сначала попробует live API, а при ошибке уйдёт в mock JSON.

## Что можно быстро расширить

- авторизация через реальные токены и secure storage
- полноэкранный episode selector и season picker
- background downloads с progress indicator
- sync watchlist / history между устройствами
- отдельный news adapter под Telegram/CMS, если backend не отдаёт новости напрямую
