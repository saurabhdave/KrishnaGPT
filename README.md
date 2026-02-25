# KrishnaGPT SwiftUI iOS App

KrishnaGPT is a SwiftUI + MVVM iOS app inspired by the Bhagavad Gita.  
It answers in a spiritual and conversational style and supports 6 languages:
English, Hindi, French, German, Mandarin, and Spanish.

### App video
https://www.youtube.com/shorts/3f2n_mS1DTs

<img src="https://user-images.githubusercontent.com/7702191/217727798-66866075-82ab-40bb-bc20-0861d69b4724.jpg" width="15%"></img>
<img src="https://user-images.githubusercontent.com/7702191/217727725-7cc3a52a-1554-4d5d-9477-6f9194559fdd.jpg" width="15%"></img>
<img src="https://user-images.githubusercontent.com/7702191/217727743-badb8f8b-a34d-4671-8d28-d45b57d7b940.jpg" width="15%"></img>
<img src="https://user-images.githubusercontent.com/7702191/217727778-1255cab8-3e07-4424-9906-3d81df556346.jpg" width="15%"></img>
<img src="https://user-images.githubusercontent.com/7702191/217727789-04ae3de6-1f7a-401b-8276-11510b3ff8dd.jpg" width="15%"></img>

## Tech stack

- SwiftUI + MVVM
- OpenAI Responses API
- Streaming responses in UI
- SPM dependency: `SDOpenAIClientKit`

```swift
.package(url: "https://github.com/saurabhdave/SDOpenAIClientKit.git", branch: "main")
```

## Requirements

- Xcode 14+
- iOS 15+
- OpenAI API key from https://openai.com/api

## Setup

1. Open `KrishnaGPT.xcodeproj` in Xcode.
2. Update [`KrishnaGPT/App/Config.plist`](KrishnaGPT/App/Config.plist).
3. Build and run the `KrishnaGPT` scheme.

## Configuration

Configuration is read by [`KrishnaGPT/App/AppConfig.swift`](KrishnaGPT/App/AppConfig.swift) from `Config.plist`.

Supported keys:

- `OPENAI_API_KEY` (required)
- `OPENAI_MODEL` (optional, default: `gpt-4.1-mini`)
- `OPENAI_SYSTEM_PROMPT` (optional, app default prompt used if missing)
- `OPENAI_TEMPERATURE` (optional, default: `0.5`)

Example:

```xml
<key>OPENAI_API_KEY</key>
<string>sk-...</string>
<key>OPENAI_MODEL</key>
<string>gpt-4.1-mini</string>
<key>OPENAI_SYSTEM_PROMPT</key>
<string>You are Krishna...</string>
<key>OPENAI_TEMPERATURE</key>
<real>0.5</real>
```

## Architecture

- [`KrishnaGPT/App/KrishnaGPTApp.swift`](KrishnaGPT/App/KrishnaGPTApp.swift) initializes the API client using `AppConfig`.
- [`KrishnaGPT/Networking/ChatGPTAPI.swift`](KrishnaGPT/Networking/ChatGPTAPI.swift) is a thin wrapper over `SDOpenAIClient` (`OpenAIClient`).
- [`KrishnaGPT/ViewModel/ChatGPTViewModel.swift`](KrishnaGPT/ViewModel/ChatGPTViewModel.swift) handles streaming state and UI updates.
- [`KrishnaGPT/View/ContentView.swift`](KrishnaGPT/View/ContentView.swift) renders chat and language selection.

## How it works

User input + selected language instruction is sent to OpenAI Responses API via `SDOpenAIClientKit`.  
Tokens are streamed back and rendered incrementally in the chat UI.
