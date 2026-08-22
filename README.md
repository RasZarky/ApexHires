# 🚀 ApexHires

**A production-grade job recruitment platform** — Streamlined clone of LinkedIn's recruitment ecosystem focusing exclusively on job matching, candidate tracking, and recruitment messaging.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-blue" alt="Platforms">
</p>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Environment Variables Setup](#-environment-variables-setup)
- [Push Notifications Setup](#-push-notifications-setup-supabase-edge-function)
- [Setup Guide](#-setup-guide)
- [Running the App](#️-running-the-app)
- [Deployment](#-deployment)
- [Design System](#-design-system)
- [Security](#-security)
- [Dependencies](#-dependencies)

---

## 🎯 Overview

ApexHires strips out social feeds, post creation, and public networking to focus on what matters: **connecting the right talent with the right jobs**.

| Role | Platform | Capabilities |
|------|----------|-------------|
| **Job Seeker** | Mobile (iOS/Android) | Search/filter jobs, build profile, 1-click Easy Apply, track applications, message recruiters |
| **Recruiter** | Mobile (iOS/Android) | Post/edit/pause/close jobs, screening questions, candidate pipeline, view resumes, message applicants |
| **Super Admin** | Web | Dashboard with charts, user management, job moderation, application overview, admin management |

> **Web users** are automatically directed to the Admin Panel. Mobile users see the job seeker or recruiter experience.

---

## ✨ Features

### Job Seeker (Mobile)

- 🔍 **Smart Job Search** — Filter by title, location, job type, experience level
- 📝 **Easy Apply** — One-click application with auto-filled profile data
- ❓ **Screening Questions** — Answer recruiter-defined questions during application
- 📊 **Application Tracker** — Real-time status tracking with visual pipeline (Applied → Shortlisted → Interviewing → Hired)
- 💬 **Messaging** — Real-time chat with recruiters after application, with job title context for each chat
- 👤 **Profile Builder** — Structured profile with experience, education, skills, and PDF resume upload
- 🔔 **Push Notifications** — Get notified when your application status changes, new messages, and admin actions
- 🛑 **Verification Overlay** — Non-dismissible alert with animated timeline when recruiter account is pending verification, with instant refresh button

### Recruiter (Mobile)

- 📋 **Job Posting** — Multi-step wizard (Basic Info → Requirements → Screening Questions)
- 👥 **Candidate Pipeline** — Kanban-style status management with dropdown controls
- 📄 **Resume Viewer** — Access candidate resumes and full profiles
- 📌 **Internal Notes** — Private notes on each candidate
- 💬 **Direct Messaging** — 1-on-1 chat with applicants, with job title context
- 📈 **Dashboard** — Quick stats: active jobs, new applicants, shortlisted count
- 🔔 **Push Notifications** — Get notified when candidates apply, admin actions, and new messages
- ✅ **Verification Status** — Visual pipeline showing verification progress with refresh button

### Super Admin (Web)

- 📊 **System Metrics** — Real-time user, job, application, and chat counts with live streaming data
- 📈 **Analytics Charts** — Applications by status (pie), application trend (bar chart, last 7 days), users by role (pie)
- 👤 **User Management** — Search, filter by role, verify recruiters, block users with responsive table/card layout
- 🛡️ **Job Moderation** — Pause, reactivate, or remove listings with confirmation dialogs
- 📋 **Applications Overview** — Platform-wide application stats with status filter chips
- 👥 **Admin Management** — Create new admin accounts with email/password
- 🔔 **Notification Center** — View all system notifications, application updates, and unread messages
- 📱 **Fully Responsive** — Sidebar navigation on desktop, bottom nav on mobile, adaptive table/card layouts
- 🎯 **Max-width Layout** — Dashboard content capped at 1200px on large screens

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **State Management** | Provider |
| **Backend** | Firebase Suite |
| **Authentication** | Firebase Auth (Email/Password + Google Sign-In) |
| **Database** | Cloud Firestore |
| **File Storage** | Supabase (free tier — avatars, resumes, logos) |
| **Push Notifications** | OneSignal (free tier) via Supabase Edge Functions |
| **In-App Notifications** | Firestore `notifications` collection |
| **Charts** | fl_chart |
| **Design System** | Custom Material3 theme with Inter typography |

---

## 🏗 Architecture

The project follows **feature-first clean architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation                         │
│   Screens (UI)  ←→  Providers (State)  ←→  Models (Data)  │
├─────────────────────────────────────────────────────────────┤
│                         Services                            │
│   AuthService  │  FirestoreService  │  StorageService  │   │
│              NotificationService  │  Supabase Edge Fn      │
├─────────────────────────────────────────────────────────────┤
│                        Firebase                             │
│   Auth  │  Firestore  │  FCM     │  OneSignal  │  Supabase │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
apex_hires/
├── lib/
│   ├── main.dart                              # Entry point + routing
│   ├── firebase_options.dart                  # Firebase config (env vars)
│   │
│   ├── core/
│   │   ├── theme/app_theme.dart               # Design system (colors, typography)
│   │   ├── constants/app_constants.dart       # App-wide constants
│   │   └── widgets/common_widgets.dart        # Reusable UI components
│   │
│   ├── models/
│   │   ├── user_model.dart                    # User, SeekerProfile, RecruiterProfile
│   │   ├── job_model.dart                     # Job, SalaryRange, ScreeningQuestion
│   │   ├── application_model.dart             # Application, ScreeningAnswer
│   │   └── chat_model.dart                    # Chat, Message
│   │
│   ├── services/
│   │   ├── auth_service.dart                  # Auth (email + Google)
│   │   ├── firestore_service.dart             # CRUD for all collections
│   │   ├── supabase_storage_service.dart      # File uploads (Supabase)
│   │   └── notification_service.dart          # OneSignal + in-app notifications
│   │
│   └── features/
│       ├── auth/                              # Auth, splash, welcome, notifications, settings
│       ├── jobs/                              # Job seeker experience (search, detail, tracker)
│       ├── applications/                      # Application tracking + Easy Apply
│       ├── recruiter/                         # Recruiter experience (post, candidates, my jobs)
│       ├── chat/                              # Real-time messaging
│       └── admin/                             # Super Admin (web) — dashboard, users, jobs, apps
│
├── supabase/
│   └── functions/
│       └── send-notification/                 # Edge Function for push notifications
│           └── index.ts
│
├── .env.example                               # Environment variable template
├── .env                                       # Your actual env vars (git-ignored)
├── firebase.json                              # Firebase hosting + cache-busting config
├── firestore.rules                            # Security rules
└── firestore.indexes.json                     # Composite indexes
```

---

## 🗄 Database Schema

### Collections Overview

```
users/
  └── uid (document)
        ├── email, role, full_name, phone_number, avatar_url
        ├── seeker_profile: { headline, bio, location, resume_url, resume_name, skills[], experience[], education[] }
        └── recruiter_profile: { company_name, company_website, designation, is_verified }

jobs/
  └── job_id (document)
        ├── recruiter_id, company_name, title, description, location
        ├── job_type, experience_level, salary_range: { min, max, currency }
        ├── skills_required[], screening_questions[]
        ├── status, applications_count

applications/
  └── application_id (document)
        ├── job_id, job_title, recruiter_id, seeker_id
        ├── seeker_name, seeker_avatar, resume_url
        ├── status, screening_answers[], internal_notes

chats/
  └── chat_id (document)
        ├── application_id, job_id, participants[]
        ├── last_message, last_message_time, unread_count
        └── messages/ (subcollection)
              └── message_id (document)
                    ├── sender_id, receiver_id, text, is_read, created_at

notifications/
  └── (auto-id document)
        ├── user_id, title, body, type, data{}, read, created_at
```

### Notification Types

| Type | Trigger | Recipient |
|------|---------|-----------|
| `new_application` | Seeker applies to a job | Recruiter |
| `application_status_changed` | Recruiter changes application status | Seeker |
| `recruiter_verified` | Admin verifies a recruiter | Recruiter |
| `recruiter_unverified` | Admin removes verification | Recruiter |
| `user_blocked` | Admin blocks a user | User |
| `job_removed` | Admin removes a job listing | Recruiter |
| `job_paused` | Admin pauses a job listing | Recruiter |
| `job_reactivated` | Admin reactivates a paused job | Recruiter |

---

## 🔐 Environment Variables Setup

**All API keys and secrets are stored in environment variables — never in code.**

### Quick Start

```bash
cd apex_hires

# 1. Copy the template
cp .env.example .env

# 2. Fill in your actual values in .env
#    (Get keys from Firebase Console, OneSignal, Supabase)

# 3. Run the app
flutter run --dart-define-from-file=.env
```

### Required Variables

| Variable | Where to get it |
|----------|----------------|
| `FIREBASE_ANDROID_API_KEY` | Firebase Console → Project Settings → Android app |
| `FIREBASE_ANDROID_APP_ID` | Firebase Console → Project Settings → Android app |
| `FIREBASE_IOS_API_KEY` | Firebase Console → Project Settings → iOS app |
| `FIREBASE_IOS_APP_ID` | Firebase Console → Project Settings → iOS app |
| `FIREBASE_WEB_API_KEY` | Firebase Console → Project Settings → Web app |
| `FIREBASE_WEB_APP_ID` | Firebase Console → Project Settings → Web app |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase Console → Project Settings → Cloud Messaging |
| `FIREBASE_PROJECT_ID` | Firebase Console → Project Settings → General |
| `FIREBASE_STORAGE_BUCKET` | Firebase Console → Project Settings → Storage |
| `FIREBASE_AUTH_DOMAIN` | Firebase Console → Project Settings → Authentication |
| `FIREBASE_MEASUREMENT_ID` | Firebase Console → Project Settings → Analytics (optional) |
| `ONESIGNAL_APP_ID` | [OneSignal](https://onesignal.com) → Settings → Keys & IDs |
| `SUPABASE_URL` | [Supabase](https://supabase.com) → Settings → API → Project URL |
| `SUPABASE_SERVICE_KEY` | [Supabase](https://supabase.com) → Settings → API → service_role key |

### Security

- `.env` is **git-ignored** — never committed to version control
- `.env.example` is committed as a template for other developers
- `firebase_options.dart` uses `--dart-define` — no hardcoded keys
- OneSignal and Supabase keys are read from environment at build time
- OneSignal REST API key is stored as a Supabase secret (server-side only)

---

## 🔔 Push Notifications Setup (Supabase Edge Function)

Push notifications are sent via a **Supabase Edge Function** that calls the OneSignal REST API server-side. This avoids CORS issues and keeps your API key secure.

### How It Works

```
Flutter App → Firestore (in-app notifications)
           → Supabase Edge Function → OneSignal REST API → Push to device
```

1. Flutter app writes notification to Firestore (for the in-app notification center)
2. Flutter app calls the Edge Function via `supabase.functions.invoke()`
3. Edge Function calls OneSignal REST API server-side using the user's external ID
4. OneSignal delivers the push notification to the user's device

### Setup

```bash
# 1. Install Supabase CLI
npm install -g supabase

# 2. Login to Supabase
supabase login

# 3. Link your project
#    Find your project ref in Supabase Dashboard → Settings → General
supabase link --project-ref YOUR_PROJECT_REF

# 4. Set OneSignal secrets (stored securely on Supabase, NOT in .env)
supabase secrets set ONESIGNAL_APP_ID=your_onesignal_app_id
supabase secrets set ONESIGNAL_REST_API_KEY=your_rest_api_key

# 5. Deploy the Edge Function
cd apex_hires
supabase functions deploy send-notification
```

### Required OneSignal Keys

- `ONESIGNAL_APP_ID` → [OneSignal Dashboard](https://onesignal.com) → Settings → Keys & IDs
- `ONESIGNAL_REST_API_KEY` → OneSignal Dashboard → Settings → Keys & IDs (use the **REST API Key**, not the User Auth Key)

---

## 🚀 Setup Guide

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10+)
- [Dart SDK](https://dart.dev/get-dart) (3.10+)
- [Node.js](https://nodejs.org) (for Supabase CLI)
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`
- A [Firebase](https://console.firebase.google.com) account

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Add project"** → name it `ApexHires` → Create Project

### Step 2: Register Apps

**Android:**
1. Project Settings → Add App → Android
2. Package name: `com.apexhires.apex_hires`
3. Download `google-services.json` → place in `android/app/`

**iOS:**
1. Project Settings → Add App → iOS
2. Bundle ID: `com.apexhires.apexHires`
3. Download `GoogleService-Info.plist` → place in `ios/Runner/`

**Web:**
1. Project Settings → Add App → Web

### Step 3: Enable Firebase Services

In Firebase Console, enable:

| Service | Path | Settings |
|---------|------|----------|
| **Authentication** | Build → Authentication → Sign-in method | Enable **Email/Password** + **Google** |
| **Firestore** | Build → Firestore Database → Create | Start in **test mode**, choose region |

### Step 4: Set Up Environment Variables

```bash
cd apex_hires
cp .env.example .env
# Edit .env with your actual API keys from Firebase Console
```

### Step 5: Install Dependencies

```bash
flutter pub get
```

### Step 6: Deploy Backend Rules

```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes
```

### Step 7: Set Up Push Notifications

```bash
# Follow the Push Notifications Setup section above
```

---

## ▶️ Running the App

### Mobile (Android/iOS)

```bash
# Ensure a device/emulator is connected
flutter devices

# Run on Android
flutter run -d android --dart-define-from-file=.env

# Run on iOS (macOS only)
flutter run -d ios --dart-define-from-file=.env
```

### Web (Admin Panel)

```bash
# Run on web
flutter run -d chrome --web-port=8080 --dart-define-from-file=.env

# When accessed on web, the admin login page appears by default
# Admins are routed directly to the dashboard on subsequent visits
```

### Create First Admin User

1. Sign up as a **Recruiter** in the app
2. Go to Firebase Console → Firestore → `users` collection
3. Find your user document, change `role` field to `"admin"`
4. Re-login — Admin Panel is now accessible
5. Or use the **"Add Admin"** button in the admin sidebar (desktop) or FAB (mobile) to create new admin accounts

---

## 🚢 Deployment

### Build APK (Android)

```bash
flutter build apk --release --dart-define-from-file=.env
# Output: build/app/outputs/flutter-apk/app-release.apk

# Or build App Bundle (recommended for Play Store)
flutter build appbundle --release --dart-define-from-file=.env
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build iOS

```bash
flutter build ios --release --dart-define-from-file=.env
```

### Firebase Hosting (Web)

The app is configured for Firebase Hosting with **cache-busting headers** so users always get the latest version without needing to clear their browser cache.

```bash
# Build for web
flutter build web --release --dart-define-from-file=.env

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

**How cache-busting works:**
- `index.html`, `flutter_bootstrap.js`, `main.dart.js`, and `manifest.json` are served with `Cache-Control: no-cache, no-store, must-revalidate`
- Every deploy forces browsers to fetch the latest HTML and bootstrap script
- The bootstrap script then loads the correct versioned `main.dart.js`
- Users never need to manually clear their browser cache

### Firebase Backend

```bash
# Deploy everything
firebase deploy

# Or deploy individually
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## 🎨 Design System

| Token | Value | Usage |
|-------|-------|-------|
| **Primary (Apex Blue)** | `#0A66C2` | Buttons, links, active states |
| **Accent** | `#8B5CF6` | Secondary accent, highlights |
| **Dark Neutral** | `#0F172A` | Headings, primary text |
| **Secondary Text** | `#475569` | Descriptions, body text |
| **Light Text** | `#94A3B8` | Captions, timestamps |
| **Background** | `#F8FAFC` | Page backgrounds |
| **Surface** | `#FFFFFF` | Cards, dialogs |
| **Divider** | `#E2E8F0` | Borders, separators |

### Pipeline Status Colors

| Status | Color | Hex |
|--------|-------|-----|
| Applied | 🔵 Blue | `#3B82F6` |
| Shortlisted | 🟣 Purple | `#8B5CF6` |
| Interviewing | 🟡 Amber | `#F59E0B` |
| Hired | 🟢 Green | `#10B981` |
| Rejected | 🔴 Red | `#EF4444` |

### Responsive Breakpoints

| Breakpoint | Layout |
|-----------|--------|
| **< 700px** | Mobile — bottom nav, stacked cards, compact layouts |
| **700px – 899px** | Tablet — 2-column metric grid, expanded cards |
| **≥ 900px** | Desktop — sidebar nav, 4-column metrics row, max-width 1200px |
| **< 320px** | Small mobile — salary drops to own line, stacked elements |

---

## 🔐 Security

- **All API keys** are stored in environment variables (`.env`), never in source code
- **`.env`** is git-ignored — never committed to version control
- **OneSignal REST API key** is stored as a Supabase secret (server-side only)
- **Firestore Rules** enforce role-based access at the database level
- **Supabase Edge Functions** handle push notification delivery server-side

Key security rules:
- Seekers can only read/update their own profile and applications
- Recruiters can only manage their own jobs and view applications for those jobs
- Only admins can verify/block users and moderate content
- Chat participants can only access their own conversations
- Unverified recruiters see a non-dismissible overlay preventing job posting

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Authentication (Email/Password + Google) |
| `cloud_firestore` | Database |
| `firebase_messaging` | Push notification registration |
| `provider` | State management |
| `google_sign_in` | Google OAuth |
| `onesignal_flutter` | Push notification SDK + user tagging |
| `supabase_flutter` | File storage + Edge Function calls |
| `fl_chart` | Dashboard analytics charts (pie, bar) |
| `google_fonts` | Inter typography |
| `cached_network_image` | Image caching |
| `shimmer` | Loading skeletons |
| `image_picker` | Camera/gallery access |
| `file_picker` | File selection (resume upload) |
| `uuid` | Unique ID generation |
| `intl` | Date formatting |
| `share_plus` | Sharing content |
| `url_launcher` | Opening URLs |

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

<p align="center">
  Built with ❤️ using Flutter & Firebase
</p>
