<div align="center">

# Aestimo

### Turn your resume into your career copilot.

An AI-powered career assistant built with Flutter. Upload your resume and Aestimo turns it into actionable insights, a resume score, tailored cover letters, interview prep, job matches, an ATS-optimized resume, and a chat that actually knows your background — all grounded in your real experience using Google Gemini.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Hosting-FFCA28?logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/Google-Gemini-8E75B2?logo=googlegemini&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-3da639)

[Live Demo](https://careergpt-abbasi.web.app) · [Report a Bug](https://github.com/ArsalanKaleem/Aestimo/issues) · [Request a Feature](https://github.com/ArsalanKaleem/Aestimo/issues)

</div>

---

## ✨ Overview

Aestimo reads your resume once and powers every feature from it. There's no manual data entry — upload a PDF, and the app extracts, understands, and uses your experience to help you land your next role. It runs on Android, Web, and Windows from a single Flutter codebase.

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

## 📸 Screenshots

> Add your images to a `screenshots/` folder in the project root using the filenames below.

### Login
![Login](screenshots/login.png)

### Dashboard
![Dashboard](screenshots/dashboard.png)

### Upload Resume
![Upload Resume](screenshots/upload.png)

### Resume Insights
![Resume Insights](screenshots/insights.png)

### Resume Score
![Resume Score](screenshots/resume_score.png)

### ATS Resume
![ATS Resume](screenshots/ats_resume.png)

### AI Chat
![AI Chat](screenshots/chat.png)

### Interview Prep
![Interview Prep](screenshots/interview.png)

### Job Match
![Job Match](screenshots/jobs.png)

### Cover Letter
![Cover Letter](screenshots/cover_letter.png)

### About
![About](screenshots/about.png)

## 🛠️ Tech Stack

| Layer | Tools |
|-------|-------|
| **Framework** | Flutter, Dart |
| **State** | Riverpod |
| **Routing** | GoRouter |
| **AI** | Google Gemini (Generative Language API) |
| **Auth** | Firebase Authentication |
| **Networking** | Dio |
| **Other** | file_picker, url_launcher, flutter_markdown_plus |

## 🏗️ Architecture

Feature-first clean architecture. Each feature owns its `models / data / providers / presentation` layers.

```
lib/
├── core/            # constants, theme, router, networking, Gemini client, utils
├── features/        # auth, dashboard, upload_resume, insights, rag_chat,
│                    # interview_prep, job_match, cover_letter, resume_score,
│                    # ats_resume, about, settings
├── shared/widgets/  # reusable UI (cards, buttons, shell, drawer, ...)
└── main.dart
```

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

Live at **[careergpt-abbasi.web.app](https://careergpt-abbasi.web.app)**.

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
