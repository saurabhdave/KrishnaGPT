# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

This is an Xcode project (no Package.swift at root). Use Xcode tools or `xcodebuild`.

**Build:**
```bash
xcodebuild -project KrishnaGPT.xcodeproj -scheme KrishnaGPT-Dev -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Run all tests:**
```bash
xcodebuild -project KrishnaGPT.xcodeproj -scheme KrishnaGPT-Dev -destination 'platform=iOS Simulator,name=iPhone 16' test
```

**Run a single test:**
```bash
xcodebuild -project KrishnaGPT.xcodeproj -scheme KrishnaGPT-Dev -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:KrishnaGPTTests/ChatGPTViewModelTests/sendTappedStreamsResponseAndResetsInteractionState test
```

**Schemes:** `KrishnaGPT-Dev`, `KrishnaGPT-Staging`, `KrishnaGPT-Prod` — each sets `APP_ENVIRONMENT` to its respective environment. Use Dev for local development.

**API key:** Create `Configuration/Secrets.xcconfig` from `Configuration/Secrets.xcconfig.template` and set your `OPENAI_API_KEY`. Tests detect `XCTestConfigurationFilePath` to skip the assertion.

## Architecture

SwiftUI + MVVM chat app using OpenAI's Responses API via the `SDOpenAIClient` SPM package (v2.0.0+, requires iOS 18+).

**Dependency flow:**
```
KrishnaGPTApp → AppConfig (reads env vars / Info.plist) → ChatGPTAPI → ChatGPTViewModel → ContentView
```

**Networking boundary:** `ChatNetworking` protocol (defined in `ChatGPTAPI.swift`) is the sole abstraction between the ViewModel and the network layer. `ChatGPTAPI` wraps `SDOpenAIClient.OpenAIClient` (an actor). The ViewModel never imports or references `SDOpenAIClient` directly — it only depends on `ChatNetworking`. Tests use `MockChatService` to substitute the real API. `ChatGPTAPI.init` is throwing because `OpenAIClientConfiguration` validates its inputs.

**Configuration system:** `AppConfig` (enum, no instances) resolves config values with this precedence:
1. Runtime environment variable (`ProcessInfo`) — for API key and APP_ENVIRONMENT
2. Info.plist values (custom keys injected via `$(VARIABLE)` substitution in `KrishnaGPT/Info.plist`, sourced from `.xcconfig` build settings)
3. Hardcoded defaults

Environment selection: runtime `APP_ENVIRONMENT` var > Info.plist `APP_ENVIRONMENT` key > compile-time fallback (Debug=dev, Release=prod).

Config value flow: `Secrets.xcconfig` → env xcconfig (`Dev`/`Prod`) → Xcode build settings → `$(VARIABLE)` substitution in `KrishnaGPT/Info.plist` → `Bundle.main.object(forInfoDictionaryKey:)` in `AppConfig.swift`. Apple-recognized Info.plist keys (display name, orientations, etc.) are auto-generated via `GENERATE_INFOPLIST_FILE = YES` and merged with the custom keys from `Info.plist`.

Xcconfig file structure (`Configuration/` directory):
- `Base.xcconfig` — shared target build settings (bundle ID, deployment target, `INFOPLIST_FILE`, etc.)
- `Dev.xcconfig` — wired to Debug build configuration (APP_ENVIRONMENT=dev, OPENAI_MODEL, OPENAI_TEMPERATURE)
- `Staging.xcconfig` — not currently wired; Staging scheme uses Debug config + runtime env var override
- `Prod.xcconfig` — wired to Release build configuration (APP_ENVIRONMENT=prod, OPENAI_MODEL, OPENAI_TEMPERATURE)
- `Secrets.xcconfig` — gitignored; contains OPENAI_API_KEY; `#include`d by each environment xcconfig
- `Secrets.xcconfig.template` — checked in; copy to create Secrets.xcconfig

**Streaming:** `ChatGPTViewModel.send()` consumes an `AsyncThrowingStream<String, Error>` from the service, appending tokens to the current `MessageRow` in-place by index. The view uses `.equatable()` on `MessageRowView` to minimize re-renders during streaming.

**Language handling:** `LanguageType` enum (6 cases) is passed to the API as an additional instruction string appended to each request, not as a system prompt change. Changing language does not clear history.

## Key Patterns

- All ViewModel methods that touch `@Published` state are `@MainActor`. The ViewModel is `ObservableObject` with `@StateObject` ownership in `KrishnaGPTApp`.
- `ContentView` suppresses auto-scrolling when VoiceOver is running (`UIAccessibility.isVoiceOverRunning`).
- `ScanButton` is a SwiftUI `View` in the navigation toolbar. It wraps a private `UIViewRepresentable` (`CameraKeyInputButton`) that bridges `UIAction.captureTextFromCamera` for live-text camera input.
- Tests use Swift Testing (`@Test`, `#expect`). The test suite is a `@MainActor struct` annotated with `@Suite`. `MockChatService` queues `Result<[String], Error>` values in `streamedResponses` and pops them FIFO on each `sendMessageStream` call.
