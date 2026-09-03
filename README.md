<h1 align="center">
  <br>
  ⊙ Physiqo
  <br>
</h1>

<h4 align="center">A Premium, Offline-First, AI-Powered Fitness & Bodybuilding Coach</h4>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-v3.12.2+-02569B?logo=flutter&logoColor=white" alt="Flutter Version">
  </a>
  <a href="https://github.com/yourusername/physiqo/releases">
    <img src="https://img.shields.io/badge/Release-v1.0.0-blue?logo=github&logoColor=white" alt="Release Version">
  </a>
  <a href="https://github.com/yourusername/physiqo/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License">
  </a>
  <a href="#-architecture--tech-stack">
    <img src="https://img.shields.io/badge/Architecture-Serverless-success" alt="Serverless">
  </a>
  <a href="#-multilingual--localization">
    <img src="https://img.shields.io/badge/Languages-11%20Supported-orange" alt="Languages">
  </a>
</p>

<p align="center">
  <strong>Physiqo</strong> is a production-grade, privacy-first mobile application built to redefine personal fitness training. Combining an uncompromising cinematic dark UI with cutting-edge, bring-your-own-key (BYOK) AI integrations, Physiqo delivers a world-class coaching experience completely on-device.
</p>

<p align="center">
  <a href="#-see-physiqo-in-action">Media</a> •
  <a href="#-core-features">Features</a> •
  <a href="#-architecture--tech-stack">Architecture</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-contributing">Contributing</a>
</p>

---

## 📸 See Physiqo in Action

*Experience the fluid, cinematic design and powerful AI integrations directly on your device.*

<div align="center">

| 🏋️‍♂️ App in Action | ⚙️ AI Provider Setup |
| :---: | :---: |
| <img src="assets/images/app_demo.gif" width="250"/> | <img src="assets/images/ai_setup.gif" width="250"/> |

</div>

---

## ⚡ Core Features

### 🎬 Cinematic Dark Design System
Physiqo rejects the chaotic, neon-heavy interfaces of modern fitness apps. We engineered a strictly enforced, premium dark theme utilizing precise hex design tokens (Deep Backgrounds: `#1C1C1E`, Active Surfaces: `#2A2A2C`, Primary Accents: `#FF6B2C`). 
- **Zero Bloom/Glow:** A clean, focused, flat design aesthetic.
- **RTL-Native Layouts:** Dynamic widget tree mirroring to ensure flawless Right-to-Left formatting.

### 🛡 100% Serverless & Offline-First (BYOK)
Your health data is yours. Physiqo operates entirely without centralized databases. 
- **Bring Your Own Key:** Direct integration with OpenAI, Anthropic, and Google Gemini APIs.
- **Bank-Grade Encryption:** All API keys and health profiles are secured locally using `FlutterSecureStorage`.
- **Zero Telemetry:** No tracking, no hidden analytics, no server-side bottlenecks.

### 🧠 Dynamic AI Coaching & Vision Analysis
More than just a workout tracker, Physiqo acts as a highly specialized personal trainer.
- **Postural Vision Analysis:** Capture your physique using the device camera. The AI processes visual data to detect spinal alignment, muscle imbalances, and weak points.
- **Injury Profiling:** Input joint pain or previous injuries. The orchestration engine dynamically parses your workout plan to eliminate high-risk movements, swapping them for joint-friendly alternatives.
- **Real-Time Rest Calculations:** AI determines optimal rest periods based on your real-time fatigue and workout intensity.

### 🌍 Seamless Multilingual Architecture
Built for a global audience from day one. Instantly hot-swap between **11 fullly supported languages**:
*English, Persian (Farsi), Chinese (Mandarin), Hindi, Spanish, Arabic, French, Bengali, Portuguese, Russian, and Urdu.*
- Integrated automated formatting for Metric/Imperial units and complex RTL/LTR layout transitions.

---

## 🏗 Architecture & Tech Stack

Physiqo is built on a scalable, modular architecture designed for high performance and maintainability.

- **Frontend Framework:** Flutter / Dart
- **State Management & Routing:** Standardized declarative architecture.
- **Storage Layer:** 
  - `FlutterSecureStorage` (AES encryption for sensitive API Keys)
  - `SharedPreferences` (Stateful app configuration)
- **AI Integration Layer:** Abstracted generic interfaces allowing seamless context-building and payload formatting for multiple LLM providers (GPT-4o, Claude 3.5 Sonnet, Gemini 1.5 Pro).
- **Localization Engine:** Custom L10N pipeline capable of dynamic, on-the-fly language parsing.

---

## 🚀 Getting Started

Follow these instructions to build and run the project on your local machine for development and testing.

### Prerequisites
- **Flutter SDK:** Version `3.12.2` or higher.
- **Android Studio / Xcode:** For Android and iOS compilation.
- **Active AI API Key:** You will need an API key from OpenAI, Anthropic, or Google to unlock the AI coaching features.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/physiqo.git
   cd physiqo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   Connect your physical device or launch an emulator, then run:
   ```bash
   flutter run
   ```

### Building for Production
To generate a production-ready release artifact:
```bash
# For Android (APK)
flutter build apk --release

# For Android (AppBundle - Play Store)
flutter build appbundle --release

# For iOS
flutter build ipa --release
```

---

## 🤝 Contributing

We believe in open, collaborative development. Whether you are a human developer or an AI coding assistant, your contributions to Physiqo are welcome.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

*Please read our [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on coding standards, our global token optimization protocols, and our strict design rules.*

---

## 📝 License

Distributed under the Apache License 2.0. See `LICENSE` for more information.

---
<p align="center">
  <i>Designed with precision. Built for performance.</i>
</p>
