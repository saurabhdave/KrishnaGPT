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
- SPM dependency: `SDOpenAIClientKit` v2.0.0+ (typed `APIKey`, `OpenAIModel`, `HistoryTrimmingStrategy`)
- Swift Testing (`@Test`, `#expect`, `@Suite`)

```swift
.package(url: "https://github.com/saurabhdave/SDOpenAIClientKit.git", from: "2.0.0")
```

## Requirements

- Xcode 16+
- iOS 18+
- OpenAI API key from https://openai.com/api

## Setup

1. Open `KrishnaGPT.xcodeproj` in Xcode.
2. Copy `Configuration/Secrets.xcconfig.template` to `Configuration/Secrets.xcconfig` and set your OpenAI API key:
   ```
   OPENAI_API_KEY = sk-proj-your-key-here
   ```
   `Secrets.xcconfig` is gitignored and will never be committed.
3. Select a shared scheme:
   - `KrishnaGPT-Dev` (Debug, `APP_ENVIRONMENT=dev`)
   - `KrishnaGPT-Staging` (Debug + runtime override, `APP_ENVIRONMENT=staging`)
   - `KrishnaGPT-Prod` (Release, `APP_ENVIRONMENT=prod`)
4. Build and run.

## Configuration

Configuration is managed through `.xcconfig` files in the [`Configuration/`](Configuration/) directory and read at runtime by [`AppConfig.swift`](KrishnaGPT/AppConfig/AppConfig.swift).

### Config value flow

```
Secrets.xcconfig → Dev/Prod.xcconfig → Xcode build settings → $(VARIABLE) in Info.plist → AppConfig.swift
```

### Xcconfig files

| File | Purpose |
|------|---------|
| [`Base.xcconfig`](Configuration/Base.xcconfig) | Shared target build settings (bundle ID, deployment target, `INFOPLIST_FILE`, etc.) |
| [`Dev.xcconfig`](Configuration/Dev.xcconfig) | Wired to Debug config (`APP_ENVIRONMENT=dev`, model, temperature) |
| [`Staging.xcconfig`](Configuration/Staging.xcconfig) | Not wired; Staging scheme overrides via runtime env var |
| [`Prod.xcconfig`](Configuration/Prod.xcconfig) | Wired to Release config (`APP_ENVIRONMENT=prod`, model, temperature) |
| `Secrets.xcconfig` | Gitignored; holds `OPENAI_API_KEY`; `#include`d by Dev/Staging/Prod |
| [`Secrets.xcconfig.template`](Configuration/Secrets.xcconfig.template) | Checked in; copy to create `Secrets.xcconfig` |

### Resolution precedence

`AppConfig` resolves each value in this order:

1. **Runtime env var** (`ProcessInfo`) — for API key and `APP_ENVIRONMENT` (useful for CI/scheme overrides)
2. **Info.plist** — custom keys injected via `$(VARIABLE)` substitution from xcconfig build settings
3. **Hardcoded defaults** — `gpt-5.4-mini`, temperature `0.5`, empty API key

Environment selection: runtime `APP_ENVIRONMENT` > Info.plist `APP_ENVIRONMENT` > compile-time fallback (Debug=dev, Release=prod).

### Config keys

| Key | Default | Source |
|-----|---------|--------|
| `OPENAI_API_KEY` | (empty) | `Secrets.xcconfig` |
| `OPENAI_MODEL` | `gpt-5.4-mini` | `Dev.xcconfig` / `Prod.xcconfig` |
| `OPENAI_TEMPERATURE` | `0.5` | `Dev.xcconfig` / `Prod.xcconfig` |
| `APP_ENVIRONMENT` | `dev` or `prod` | `Dev.xcconfig` / `Prod.xcconfig` |

## Architecture

- [`KrishnaGPT/App/KrishnaGPTApp.swift`](KrishnaGPT/App/KrishnaGPTApp.swift) initializes the API client using `AppConfig`. `ChatGPTAPI` init is throwing (validated by `OpenAIClientConfiguration`).
- [`KrishnaGPT/Networking/ChatGPTAPI.swift`](KrishnaGPT/Networking/ChatGPTAPI.swift) conforms to a `ChatNetworking` protocol and wraps `SDOpenAIClient.OpenAIClient` (an actor). Uses typed `APIKey`, `OpenAIModel`, and `HistoryTrimmingStrategy`.
- [`KrishnaGPT/ViewModel/ChatGPTViewModel.swift`](KrishnaGPT/ViewModel/ChatGPTViewModel.swift) depends on `ChatNetworking` (not a concrete API type), owns conversation language state, and handles streaming UI updates.
- [`KrishnaGPT/View/ContentView.swift`](KrishnaGPT/View/ContentView.swift) renders chat and language selection.
- Tests use [Swift Testing](https://developer.apple.com/documentation/testing/) with `@Suite` and `@Test` macros, `#expect` assertions, and `@MainActor` isolation.

## AI Skills Used

Accessibility improvements in this project were guided by the
[`apple-accessibility-advisor`](https://github.com/saurabhdave/aiagents/tree/main/skills/apple-accessibility-advisor)
skill from
[saurabhdave/aiagents](https://github.com/saurabhdave/aiagents).

The skill-driven pass improved VoiceOver behavior, reduced duplicate announcements,
improved control semantics, and strengthened touch target/accessibility consistency
across key chat UI components.

## How it works

User input + selected language instruction is sent to OpenAI Responses API via `SDOpenAIClientKit`.  
Tokens are streamed back and rendered incrementally in the chat UI.
