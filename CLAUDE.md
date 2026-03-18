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

**API key:** Set `OPENAI_API_KEY` in Scheme > Run > Environment Variables. Tests detect `XCTestConfigurationFilePath` to skip the assertion.

## Architecture

SwiftUI + MVVM chat app using OpenAI's Responses API via the `SDOpenAIClient` SPM package (v2.0.0+, requires iOS 18+).

**Dependency flow:**
```
KrishnaGPTApp → AppConfig (reads env/plist) → ChatGPTAPI → ChatGPTViewModel → ContentView
```

**Networking boundary:** `ChatNetworking` protocol (defined in `ChatGPTAPI.swift`) is the sole abstraction between the ViewModel and the network layer. `ChatGPTAPI` wraps `SDOpenAIClient.OpenAIClient` (an actor). The ViewModel never imports or references `SDOpenAIClient` directly — it only depends on `ChatNetworking`. Tests use `MockChatService` to substitute the real API. `ChatGPTAPI.init` is throwing because `OpenAIClientConfiguration` validates its inputs.

**Configuration system:** `AppConfig` (enum, no instances) resolves config values with this precedence:
1. Runtime environment variable (`ProcessInfo`)
2. Environment-specific plist (`Config.dev.plist`, `Config.staging.plist`, `Config.prod.plist`)
3. Fallback plist (`Config.plist`)
4. Hardcoded defaults

Environment selection: runtime `APP_ENVIRONMENT` var > Info.plist `APP_ENVIRONMENT` key > compile-time fallback (Debug=dev, Release=prod).

**Streaming:** `ChatGPTViewModel.send()` consumes an `AsyncThrowingStream<String, Error>` from the service, appending tokens to the current `MessageRow` in-place by index. The view uses `.equatable()` on `MessageRowView` to minimize re-renders during streaming.

**Language handling:** `LanguageType` enum (6 cases) is passed to the API as an additional instruction string appended to each request, not as a system prompt change. Changing language does not clear history.

## Key Patterns

- All ViewModel methods that touch `@Published` state are `@MainActor`. The ViewModel is `ObservableObject` with `@StateObject` ownership in `KrishnaGPTApp`.
- `ContentView` suppresses auto-scrolling when VoiceOver is running (`UIAccessibility.isVoiceOverRunning`).
- `ScanButton` uses `UIViewRepresentable` wrapping `UIAction.captureTextFromCamera` for live-text camera input.
- Tests use Swift Testing (`@Test`, `#expect`). The test suite is a `@MainActor struct` annotated with `@Suite`. `MockChatService` queues `Result<[String], Error>` values in `streamedResponses` and pops them FIFO on each `sendMessageStream` call.
