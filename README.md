# KrishnaGPT

A SwiftUI iOS app that channels the wisdom of Lord Krishna from the Bhagavad Gita. Ask any question and receive a response grounded in Vedic philosophy — with verse citations — in your language of choice.

[![Swift](https://img.shields.io/badge/Swift-5.0-orange)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-18%2B-blue)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-16%2B-blue)](https://developer.apple.com/xcode/)
[![OpenAI](https://img.shields.io/badge/OpenAI-Responses%20API-green)](https://platform.openai.com)

**Watch the demo:** [YouTube Short](https://www.youtube.com/shorts/3f2n_mS1DTs)

---

## Screenshots

<p>
  <img src="https://github.com/user-attachments/assets/54667ce0-c639-4177-a89d-07a2b0d51194" width="18%"/>
  <img src="https://github.com/user-attachments/assets/08f29c05-3e18-45a9-a84a-69f79692b514" width="18%"/>
  <img src="https://github.com/user-attachments/assets/5b3083f7-1b41-4aff-ba56-63324699c480" width="18%"/>
  <img src="https://github.com/user-attachments/assets/be18d556-c8bc-4523-af72-a38ba10a1206" width="18%"/>
  <img src="https://github.com/user-attachments/assets/ef749f55-e81c-4b96-82b0-6b0ff612da98" width="18%"/>
</p>

---

## Features

- **Streaming responses** — tokens appear in real time as Krishna speaks
- **Verse citations** — every response references the relevant Bhagavad Gita chapter and verse
- **6 languages** — English, Hindi, French, German, Mandarin, Spanish
- **Camera text input** — scan physical text with your iPhone camera to ask questions about it
- **Conversation history** — context is preserved across the session (trimmed at 16K chars / 100 items)
- **Accessible** — full VoiceOver support, reduced-motion respect, semantic grouping

---

## Requirements

- Xcode 16+
- iOS 18+
- OpenAI API key — [get one here](https://platform.openai.com/api-keys)

---

## Setup

1. Clone the repo and open `KrishnaGPT.xcodeproj` in Xcode.
2. Copy the secrets template and add your API key:
   ```bash
   cp Configuration/Secrets.xcconfig.template Configuration/Secrets.xcconfig
   ```
   Then edit `Configuration/Secrets.xcconfig`:
   ```
   OPENAI_API_KEY = sk-proj-your-key-here
   ```
   This file is gitignored and will never be committed.
3. Select the **`KrishnaGPT-Dev`** scheme and run on a simulator or device.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI + MVVM |
| Networking | [SDOpenAIClientKit](https://github.com/saurabhdave/SDOpenAIClientKit) v2.0.0 (SPM) |
| API | OpenAI Responses API (streaming) |
| Tests | Swift Testing (`@Test`, `#expect`, `@Suite`) |
| Config | `.xcconfig` files + `AppConfig` 3-tier resolution |
| Minimum OS | iOS 18 |

---

## Architecture

```
KrishnaGPTApp
  └── AppConfig          ← resolves API key, model, environment
        └── ChatGPTAPI   ← implements ChatNetworking protocol, wraps SDOpenAIClient
              └── ChatGPTViewModel   ← @MainActor ObservableObject, owns chat state
                    └── ContentView  ← renders streaming chat UI
```

**Key design decisions:**

- `ChatNetworking` protocol is the only boundary between the ViewModel and the network layer — the ViewModel never imports `SDOpenAIClient` directly. This makes unit testing straightforward via `MockChatService`.
- `AppConfig` resolves config with three-tier precedence: runtime env var → Info.plist (injected from xcconfig) → hardcoded default. This means CI pipelines can inject keys without touching build settings.
- Streaming tokens are appended to `MessageRow.responseText` in-place by array index. `MessageRowView` implements `Equatable` and is wrapped with `.equatable()` to minimize re-renders during streaming.
- Language is sent as a per-request instruction string — not a system prompt change — so switching languages mid-conversation preserves history.

---

## Configuration

Config flows from xcconfig files through Xcode build settings into `Info.plist` via `$(VARIABLE)` substitution, then is read at runtime by `AppConfig.swift`.

```
Secrets.xcconfig
  └── Dev.xcconfig / Prod.xcconfig
        └── Xcode build settings
              └── $(VARIABLE) in Info.plist
                    └── AppConfig.swift (runtime)
```

**Schemes:**

| Scheme | Build Config | Environment |
|--------|-------------|-------------|
| `KrishnaGPT-Dev` | Debug | `APP_ENVIRONMENT=dev` |
| `KrishnaGPT-Staging` | Debug | runtime env var override |
| `KrishnaGPT-Prod` | Release | `APP_ENVIRONMENT=prod` |

**Config keys** (`Dev.xcconfig` / `Prod.xcconfig`):

| Key | Default |
|-----|---------|
| `OPENAI_API_KEY` | *(empty — set in Secrets.xcconfig)* |
| `OPENAI_MODEL` | `gpt-4.1-mini` |
| `OPENAI_TEMPERATURE` | `0.5` |
| `APP_ENVIRONMENT` | `dev` / `prod` |

---

## AI Skills Used

Accessibility improvements were guided by the [`apple-accessibility-advisor`](https://github.com/saurabhdave/aiagents/tree/main/skills/apple-accessibility-advisor) skill from [saurabhdave/aiagents](https://github.com/saurabhdave/aiagents).

The skill-driven pass improved VoiceOver behavior, added missing accessibility labels and hints, reduced duplicate announcements, and strengthened touch-target consistency across chat UI components.
