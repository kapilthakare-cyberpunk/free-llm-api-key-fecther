# Free LLM API Key Manager

A cross-platform utility to manage free LLM API keys.

## Platforms

- **macOS**: Native menu bar app (Swift)
- **Android**: Mobile key manager (Kotlin)

## macOS (Swift)

### Build & Run
1. Open in Xcode: `open Package.swift`
2. Or build via command line: `swift build`
3. Run: `.build/debug/FreeLLMKeyManager`

## Android (Kotlin)

### Prerequisites
- Android Studio Hedgehog or newer
- Android SDK API 34
- JDK 17

### Build & Run
1. Open the `android` folder in Android Studio
2. Sync Gradle
3. Run on an emulator or physical device (API 26+)

### Gradle CLI (optional)
```bash
cd android
./gradlew assembleDebug
```

## Features
- View saved API keys per provider
- Copy keys to clipboard
- Open provider login pages
- Store keys locally per platform
