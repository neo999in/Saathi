<div align="center">
  <h1>Saathi</h1>
  <img src="assets/app_logo.png" alt="Saathi Logo" width="120" height="120" />
  <br />
  <br />
  <a href="https://github.com/neo999in/Saathi/releases/latest">
    <img src="https://img.shields.io/badge/Download-APK-2D80EC?style=for-the-badge&logo=android" alt="Download APK" />
  </a>
  <br />
  <br />
</div>

---

### 📖 Description

**Saathi** is an AI-powered companion designed for emotional well-being. It provides a safe, private, and culturally-aware space where youth can share their feelings, reflect, and find comfort—anytime, anywhere. Built with empathy at its core, Saathi helps users navigate their emotions through AI-driven conversations, journaling, and mindfulness exercises.

> [!IMPORTANT]
> **Disclaimer**: Saathi is an AI-powered tool for emotional support and self-reflection. It is **not a substitute for professional mental health care, clinical therapy, or medical advice.** If you are in a crisis, please seek professional help immediately.

---

### 📸 Screenshots
<div align="center">
  <img src="assets/screenshots.png" alt="App Screenshots" width="100%" />
  <p><i>One-line features overview:</i></p>
  <ul>
    <li><b>Ask Saathi</b>: Your 24/7 AI companion for empathetic emotional support.</li>
    <li><b>Inner Journal</b>: A private space for your text and voice reflections.</li>
    <li><b>Daily Mind Reset</b>: Center your mind with a 5-minute digital sanctuary.</li>
    <li><b>Theme Toggle</b>: Tailor your experience to match your mood and style.</li>
  </ul>
</div>

---

### ✨ Features
- 🤖 **Anonymous AI Chatbot**: 24/7 multilingual support built with Google Gemini for judgment-free emotional guidance.
- 📓 **Mood Journal**: A private space for text and voice journaling to track and reflect on your emotional journey.
- 🎭 **Generative Storytelling**: Creative coping through personalized AI-generated narratives based on your current feelings.
- 🧘 **Daily Mind Reset**: Guided 5-minute meditation and breathing exercises to help you center yourself.
- 🎮 **Mental Modules**: Interactive drills, cognitive flexibility games, and mental agility exercises.
- 🎨 **Personalized Experience**: Customizable themes and accent colors to create your own digital comfort zone.
- 🔐 **Privacy First**: No personal data collection with strong local persistence for maximum security.

---

### 🛠 Requirements
Before you begin, ensure you have met the following requirements:
* **Flutter SDK**: `^3.8.1` or higher.
* **Dart SDK**: Compatible with the Flutter version.
* **IDE**: [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter/Dart plugins.
* **Platform**: 
    - **Android**: SDK 24 (Android 7.0) or higher.
    - **Physical Device** or **Emulator/Simulator** for testing.

---

### 🛠 Tech Stack
<a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-02569B?labelColor=333333&logo=Flutter&logoColor=02569B" height="40" width="132" align="left"></a>
<a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-0175C2?labelColor=333333&logo=Dart&logoColor=0175C2" height="40" width="118" align="left"></a>
<a href="https://ai.google.dev/"><img src="https://img.shields.io/badge/Google_Gemini-8E75FF?labelColor=333333&logo=GoogleGemini&logoColor=8E75FF" height="40" width="160" align="left"></a>
<a href="https://nodejs.org/"><img src="https://img.shields.io/badge/Node.js-339933?labelColor=333333&logo=nodedotjs&logoColor=339933" height="40" width="130" align="left"></a>
<a href="https://render.com/"><img src="https://img.shields.io/badge/Render-46E3B7?labelColor=333333&logo=render&logoColor=46E3B7" height="40" width="120" align="left"></a>
<br clear="left"/>

- **Key Packages**:
  - `shared_preferences` (Data Persistence)
  - `provider` (State Management)
  - `flutter_sound` & `audioplayers` (Audio Handling)
  - `flutter_tts` (Text-to-Speech)
  - `google_generative_ai` (AI Integration)

---

### 💻 Run Locally
1. Clone the repository:
```bash
git clone https://github.com/neo999in/Saathi.git
```
2. Navigate to the project directory:
```bash
cd Saathi
```
3. Install dependencies:
```bash
flutter pub get
```
4. Run the application:
```bash
flutter run
```

---

### 📂 Folder Structure
```text
lib/
├── main.dart              # Core entry point & Home Dashboard
├── AIChatScreen.dart      # Empathic AI Chatbot interface
├── modules.dart          # Interactive mental health exercises
└── audio_note_player.dart # Custom playback for voice journal entries
```

---

### 📄 License
Released under the [MIT License](LICENSE).

<p align="center">
  [![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)
</p>
