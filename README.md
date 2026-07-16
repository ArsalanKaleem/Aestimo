<div align="center">

# Aestimo

### Turn your resume into your career copilot.

An AI-powered career assistant built with Flutter. Upload your resume and Aestimo turns it into actionable insights, a resume score, tailored cover letters, interview prep, job matches, an ATS-optimized resume, and a chat that actually knows your background — all grounded in your real experience using Google Gemini.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Hosting-FFCA28?logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/Google-Gemini-8E75B2?logo=googlegemini&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20Windows%20%7C%20Web-2563EB)
![License](https://img.shields.io/badge/License-MIT-3da639)

[Live Demo](https://aestimo-career-copilot.web.app) · [Download (Windows / Android)](https://github.com/ArsalanKaleem/Aestimo/releases) · [Report a Bug](https://github.com/ArsalanKaleem/Aestimo/issues) · [Request a Feature](https://github.com/ArsalanKaleem/Aestimo/issues)

</div>

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Download](#-download)
- [Screenshots](#-screenshots)
- [Tech Stack](#️-tech-stack)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [Deployment](#️-deploy-firebase-hosting)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [Author](#-author)
- [License](#-license)

---

## ✨ Overview

Aestimo reads your resume once and powers every feature from it. There's no manual data entry — upload a PDF, and the app extracts, understands, and uses your experience to help you land your next role.

Every answer, score, and suggestion is grounded in the resume you actually uploaded rather than generic advice, so the output stays specific to your background instead of reading like a template. It runs on **Android, Web, and Windows** from a single Flutter codebase, with Firebase handling authentication and hosting, and Google Gemini powering the AI layer end to end — extraction, scoring, chat, and generation.

Try it instantly in the browser at the live demo link above, or grab a native build from [Releases](https://github.com/ArsalanKaleem/Aestimo/releases) if you'd rather install it on Windows or Android.

## 🚀 Features

- **Resume Upload & Parsing** — drop in a PDF; Gemini extracts and structures the content.
- **Resume Insights** — skills, experience, strengths, and gaps at a glance.
- **Resume Score** — an objective score with concrete, prioritized improvements.
- **ATS Resume** — generate an ATS-optimized version of your resume.
- **AI Chat** — ask anything about your career; every answer is grounded in your resume with sources.
- **Interview Prep** — personalized questions plus a live, interactive mock interview with feedback.
- **Job Match** — live roles ranked against your resume.
- **Cover Letter Generator** — tailored letters written from your background.
- **Secure Auth** — email/password sign-in via Firebase Authentication.
- **Adaptive UI** — a navigation rail on desktop/tablet and a slide-out drawer on mobile.

## 📥 Download

Aestimo runs anywhere without installing anything via the [live web app](https://aestimo-career-copilot.web.app), or you can install a native build:

| Platform | How to get it |
|---|---|
| 🌐 **Web** | Open [aestimo-career-copilot.web.app](https://aestimo-career-copilot.web.app) — nothing to install |
| 🪟 **Windows** | Download the latest installer `.exe` from [**Releases**](https://github.com/ArsalanKaleem/Aestimo/releases) and run it |
| 🤖 **Android** | Download the latest `.apk` from [**Releases**](https://github.com/ArsalanKaleem/Aestimo/releases) and install it |

> Windows Setup and the Android APK aren't code-signed yet, so you may see a SmartScreen or "unknown sources" prompt on first install — this is expected for a self-distributed build. Choose **More info → Run anyway** on Windows, or allow installs from your browser/file manager on Android.

Check the [Releases page](https://github.com/ArsalanKaleem/Aestimo/releases) for release notes, version history, and checksums on each build.

## 📸 Screenshots

### Login

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/login.png" alt="Login Desktop" width="400"> | <img src="screenshots/loginm.png" alt="Login Mobile" width="220"> |

---

### Dashboard

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/dashboard.png" alt="Dashboard Desktop" width="400"> | <img src="screenshots/dashboardm.png" alt="Dashboard Mobile" width="220"> |

---

### Upload Resume

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/upload.png" alt="Upload Resume Desktop" width="400"> | <img src="screenshots/uploadm.png" alt="Upload Resume Mobile" width="220"> |

---

### Resume Insights

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/insights.png" alt="Resume Insights Desktop" width="400"> | <img src="screenshots/insightsm.png" alt="Resume Insights Mobile" width="220"> |

---

### Resume Score

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/resume_score.png" alt="Resume Score Desktop" width="400"> | <img src="screenshots/resume_scorem.png" alt="Resume Score Mobile" width="220"> |

---

### ATS Resume

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/ats_resume.png" alt="ATS Resume Desktop" width="400"> | <img src="screenshots/ats_resumem.png" alt="ATS Resume Mobile" width="220"> |

---

### AI Chat

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/chat.png" alt="AI Chat Desktop" width="400"> | <img src="screenshots/chatm.png" alt="AI Chat Mobile" width="220"> |

---

### Interview Prep

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/interview.png" alt="Interview Prep Desktop" width="400"> | <img src="screenshots/interviewm.png" alt="Interview Prep Mobile" width="220"> |

---

### Job Match

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/jobs.png" alt="Job Match Desktop" width="400"> | <img src="screenshots/jobsm.png" alt="Job Match Mobile" width="220"> |

---

### Cover Letter

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/cover_letter.png" alt="Cover Letter Desktop" width="400"> | <img src="screenshots/cover_letterm.png" alt="Cover Letter Mobile" width="220"> |

---

### About

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/about.png" alt="About Desktop" width="400"> | <img src="screenshots/aboutm.png" alt="About Mobile" width="220"> |

---

### Settings

| Desktop | Mobile |
|----------|---------|
| <img src="screenshots/settings.png" alt="Settings Desktop" width="400"> | <img src="screenshots/settingsm.png" alt="Settings Mobile" width="220"> |

## 🛠️ Tech Stack

| Layer | Tools |
|-------|-------|
| **Framework** | Flutter, Dart |
| **State** | Riverpod |
| **Routing** | GoRouter |
| **AI** | Google Gemini (Generative Language API) |
| **Auth** | Firebase Authentication |
| **Hosting** | Firebase Hosting |
| **Networking** | Dio |
| **Other** | file_picker, url_launcher, flutter_markdown_plus |

## 🏗️ Architecture

Feature-first clean architecture. Each feature owns its `models / data / providers / presentation` layers, so functionality stays isolated and easy to extend without touching unrelated parts of the app.

```
lib/
├── core/            # constants, theme, router, networking, Gemini client, utils
├── features/        # auth, dashboard, upload_resume, insights, rag_chat,
│                    # interview_prep, job_match, cover_letter, resume_score,
│                    # ats_resume, about, settings
├── shared/widgets/  # reusable UI (cards, buttons, shell, drawer, ...)
└── main.dart
```

State is managed with Riverpod providers scoped per feature, navigation runs through GoRouter with a shared responsive shell, and all AI calls flow through a single Gemini client in `core/gemini` so prompting, error handling, and retries live in one place instead of being duplicated across features.

## 🏁 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x
- A [Firebase](https://console.firebase.google.com) project
- A free [Google AI Studio](https://aistudio.google.com) API key

### Setup

```bash
# 1. Clone
git clone https://github.com/ArsalanKaleem/Aestimo.git
cd aestimo

# 2. Install dependencies
flutter pub get

# 3. Connect Firebase (generates lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Run
flutter run                 # mobile
flutter run -d chrome       # web
flutter run -d windows      # windows
```

### Configuration

Add your Gemini API key in `lib/core/constants/app_constants.dart`:

```dart
static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
```

In the Firebase console, enable **Authentication → Sign-in method → Email/Password**.

> ⚠️ **Security note:** the Gemini key is bundled into the client app. Before deploying publicly, restrict it in the Google Cloud console (APIs & Services → Credentials → your key → set an **HTTP referrer / application restriction**) so it can't be reused elsewhere. Never commit the key — pass it at build time with `--dart-define`.

## ☁️ Deploy (Firebase Hosting)

```bash
flutter build web --release --dart-define=GEMINI_API_KEY=your_key
firebase deploy --only hosting
```

Live at **[aestimo-career-copilot.web.app](https://aestimo-career-copilot.web.app)**.

## 🗺️ Roadmap

- [ ] Code-signed Windows and Android builds
- [ ] iOS and macOS support
- [ ] Team/organization accounts for career coaches and recruiters
- [ ] Offline resume parsing fallback
- [ ] Localized UI for non-English resumes

Have an idea that isn't listed? Open a [feature request](https://github.com/ArsalanKaleem/Aestimo/issues).

## 🤝 Contributing

Contributions, issues, and feature requests are welcome.

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a pull request

Please keep PRs focused — one feature or fix per PR makes review much faster.

## 👤 Author

**Arsalan Kaleem** — Flutter Developer

[![GitHub](https://img.shields.io/badge/GitHub-ArsalanKaleem-181717?logo=github)](https://github.com/ArsalanKaleem)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-arsalankaleem-0A66C2?logo=linkedin)](https://www.linkedin.com/in/arsalankaleem)
[![Portfolio](https://img.shields.io/badge/Portfolio-Website-2563EB?logo=googlechrome&logoColor=white)](https://arsalankaleem.github.io/portfolio/)
[![Email](https://img.shields.io/badge/Email-Contact-EA4335?logo=gmail&logoColor=white)](mailto:arsalanabbasi.here@gmail.com)

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.

---

<div align="center">
Made with Flutter 💙 by Arsalan Kaleem
</div>