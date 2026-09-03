# Contributing to Physiqo (CONTRIBUTING.md)

Thank you for contributing to Physiqo! Whether you are a human developer or an AI coding assistant, this document outlines the workflow and principles required to keep the project premium, fast, and secure.

---

## 1. Setup Guide

Ensure your development machine is prepared:
1. **Flutter SDK:** Install stable Flutter SDK `^3.12.2` or later.
2. **Device Setup:** Connect a physical device or launch an emulator (Android/iOS).
3. **Design Rules (Optional):** Check [AGENTS.md](AGENTS.md) for design tokens, screen references, and strict UI rules.

To run the application:
```bash
# Fetch package dependencies
flutter pub get

# Launch on connected device
flutter run
```

---

## 2. Coding Guidelines

To maintain the premium quality of the app, follow these strict rules:

### A. UI Design & Tokens
* **No Drop Shadows or Bloom Effects:** Only flat solid colors are allowed. Colors must be mapped from `AppTheme` (e.g. background: `#1C1C1E`, surface: `#2A2A2C`, primary: `#FF6B2C`).
* **Card Borders:** Standard borders must be exactly 1px `#3A3A3C` with a `12px` border radius (`AppTheme.radiusMd`). Active states must use `#FF6B2C`.

### B. Translation & Layout Safety
* **11-Language Layout Auditing:** Always ensure your layout is compatible with RTL (Persian, Arabic, Urdu) and long translated text blocks (Russian, Hindi, Bengali).
* **Docked Action Buttons:** Keep primary buttons (like Next, Save) docked at the bottom of screens, out of scrollable lists, to optimize UX.
* **Always Wrap Row Labels:** Row labels (`Text`) positioned alongside icons or button widgets **must** be wrapped in `Expanded` or `Flexible` to prevent horizontal layout overflows.

### C. Security & Secrets
* **Zero Hardcoded Secrets:** Never hardcode credentials, API keys, or private endpoints in the codebase.
* **On-Device Storage:** Read and write all developer API keys using `FlutterSecureStorage` securely. Do not sync credentials to cloud storage.

---

## 3. Pull Request Checklist

Before submitting a Pull Request, run the local diagnostics:
```bash
# Code formatting check
flutter format lib/

# Static analysis validation (Ensure zero compile errors)
flutter analyze

# Execute automated tests
flutter test
```
