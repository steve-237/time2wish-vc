# Time2Wish – Birthday Manager & Reminder 🎂🎉

Time2Wish is a modern and premium web application designed to help you track, organize, and celebrate the birthdays of your social circles (family, friends, colleagues). Featuring an elegant glassmorphism design, interactive sound effects, and advanced management features, it ensures you will never forget a birthday again.

---

## 🛠️ Project Architecture

**Architecture Type:** **Containerized Monolithic REST API with a Standalone SPA (Single Page Application)**.
The project is built on a modern decoupled client-server model communicating via HTTP REST, using secure stateless authentication. It is fully containerized using Docker for seamless deployments.

The system is split into the following layers:

### 1. `backend/` — Spring Boot 3.x & Java 21
*   **Architecture:** Monolithic REST API.
*   **Security:** Stateless JWT authentication with HTTP-Only Refresh Token Cookies and Bearer Access Tokens. See [Authentication Flow](#-authentication--session-management) below.
*   **AI Integration:** Services for Google Gemini (Text generation) and Hugging Face (Image generation).
*   **Task Scheduling:** Cron jobs for daily checks and reminder email dispatches via SMTP.

### 2. `frontend/` — Angular 18+ & Node 20
*   **Architecture:** SPA (Single Page Application) / PWA.
*   **State Management:** Reactive architecture using modern **Angular Signals** instead of RxJS for local state.
*   **Design:** Custom Glassmorphism UI (Vanilla CSS/SCSS) focused on premium aesthetics and animations.
*   **Session Persistence:** Access Token and User Profile stored in `localStorage` for instant session restoration on page reload.
*   **Security:** Auto-logout after 3 minutes of inactivity with user notification.

### 3. `database/` — PostgreSQL 15+
*   **Architecture:** Relational Database.
*   **Migrations:** Managed seamlessly via Flyway scripts (`db/migration`).

### 4. `DevOps & CI/CD` — Docker & GitHub Actions
*   Multi-stage Dockerfiles for both Frontend and Backend to keep images lean.
*   `docker-compose.yml` for unified local/production deployments.
*   Automated CI/CD pipelines via GitHub Actions and GitLab CI configurations.

### Project Structure
```
time2wish-ai/
├── backend/                      # Spring Boot REST API
│   ├── src/main/java/app/time2wish/
│   │   ├── controller/           # REST Controllers (Auth, Birthday, Admin, AI)
│   │   ├── dto/                  # Data Transfer Objects (requests/responses)
│   │   ├── model/                # JPA Entities (User, Birthday, RefreshToken)
│   │   ├── repository/           # Spring Data JPA Repositories
│   │   ├── security/             # JWT Filter, Guard, Config (WebSecurityConfig)
│   │   └── service/              # Business Logic (Gemini, HuggingFace, Email)
│   └── src/main/resources/
│       ├── application.yml       # App configuration (DB, JWT, SMTP, AI keys)
│       └── db/migration/         # Flyway SQL migration scripts (V1 to V8)
├── frontend/                     # Angular 18+ SPA
│   ├── src/app/
│   │   ├── components/           # Reusable UI components (toast, modals, etc.)
│   │   ├── guards/               # Route guards (auth.guard.ts)
│   │   ├── interceptors/         # HTTP interceptors (auth.interceptor.ts)
│   │   ├── models/               # TypeScript interfaces
│   │   ├── pages/                # Page components (login, dashboard, etc.)
│   │   └── services/             # Angular services (auth, birthday, translation)
│   ├── src/environments/         # Environment configs (dev / prod)
│   ├── proxy.conf.json           # Dev proxy (forwards /api to backend:8081)
│   └── angular.json              # Angular CLI configuration
├── .github/workflows/            # GitHub Actions CI/CD pipelines
├── .gitlab-ci.yml                # GitLab CI/CD pipeline (alternative)
├── docker-compose.yml            # Production Docker Compose
├── docker-compose.dev.yml        # Development Docker Compose (DB only)
└── README.md
```

---

## 🔐 Authentication & Session Management

Time2Wish uses a **stateless JWT-based authentication** system. Here is the complete lifecycle of a user session, from login to logout:

### Login Flow
```
┌──────────┐         ┌──────────────┐         ┌──────────────┐
│ Frontend │         │   Backend    │         │  PostgreSQL  │
└────┬─────┘         └──────┬───────┘         └──────┬───────┘
     │  POST /api/auth/login │                       │
     │  {email, password}    │                       │
     │──────────────────────>│                       │
     │                       │  Verify credentials   │
     │                       │──────────────────────>│
     │                       │  User found ✓         │
     │                       │<──────────────────────│
     │                       │                       │
     │                       │  Generate JWT (15min)  │
     │                       │  Generate RefreshToken │
     │                       │  Store RefreshToken ──>│
     │                       │                       │
     │  Response:            │                       │
     │  - JWT in body        │                       │
     │  - RefreshToken in    │                       │
     │    HTTP-Only Cookie   │                       │
     │<──────────────────────│                       │
     │                       │                       │
     │  Store JWT + Profile  │                       │
     │  in localStorage      │                       │
     └──────────────────────────────────────────────────
```

1. **User submits** email + password on the login page.
2. **Backend validates** credentials via `AuthenticationManager` (BCrypt password hashing with 12 rounds).
3. **Backend generates** two tokens:
   - **Access Token (JWT)**: Short-lived, signed with `JWT_SECRET` (HS512 algorithm). Sent in the **response body**.
   - **Refresh Token (UUID)**: Long-lived (30 days), stored in the database (`refresh_tokens` table). Sent as an **HTTP-Only cookie** (`t2w_refresh`).
4. **Frontend stores** the Access Token and User Profile in `localStorage` (`t2w_access_token` and `t2w_user_profile` keys) and updates Angular Signals.

### Authenticated Requests
```
Every API call:
  ┌──────────┐                          ┌──────────────┐
  │ Frontend │  GET /api/birthdays      │   Backend    │
  │          │  Authorization: Bearer   │              │
  │          │  eyJhbGciOiJIUzUxMi...   │              │
  │          │─────────────────────────>│              │
  │          │                          │ AuthTokenFilter
  │          │                          │ validates JWT │
  │          │  200 OK + data           │              │
  │          │<─────────────────────────│              │
  └──────────┘                          └──────────────┘
```

- The `authInterceptor` (Angular HTTP Interceptor) automatically attaches the `Authorization: Bearer <JWT>` header to every outgoing HTTP request.
- The `AuthTokenFilter` (Spring Security filter) intercepts every incoming request, validates the JWT signature and expiration, and sets the `SecurityContext`.

### Page Refresh (Session Persistence)
```
User presses F5:
  ┌──────────────────────────────────────────┐
  │ Angular App Restart                      │
  │                                          │
  │ 1. AuthService constructor:              │
  │    accessToken = localStorage.get(...)   │  ← Instant restore
  │    currentUser = localStorage.get(...)   │  ← Instant restore
  │    isAuthenticated = true ✓              │
  │                                          │
  │ 2. APP_INITIALIZER → refreshSession():   │
  │    POST /api/auth/refresh (background)   │  ← Get fresh token
  │    If success → update token             │
  │    If fail → keep existing token         │
  │                                          │
  │ 3. Auth Guard checks isAuthenticated()   │
  │    → true → Dashboard loads normally ✓   │
  └──────────────────────────────────────────┘
```

- On page reload, the Angular app is destroyed and recreated from scratch.
- The `AuthService` signals are initialized **synchronously** from `localStorage`, so `isAuthenticated()` returns `true` immediately.
- The `APP_INITIALIZER` calls `refreshSession()` in the background to get a fresh JWT, but **does not block** the app if it fails.
- The `authGuard` sees `isAuthenticated() = true` and allows navigation to protected routes.

### Auto-Logout (3 Minutes Inactivity)
```
  ┌─────────────────────────────────────────────┐
  │ App Component (@HostListener)               │
  │                                             │
  │ Listens: mousemove, keydown, click,         │
  │          scroll, touchstart                 │
  │                                             │
  │ On activity → reset 3-min timer             │
  │ On timeout  → logout() + redirect to        │
  │               /login?reason=timeout         │
  │                                             │
  │ Login Page reads ?reason=timeout:            │
  │ → Shows warning toast in user's language    │
  │   (FR/EN/DE)                                │
  └─────────────────────────────────────────────┘
```

### Logout Flow
1. Frontend calls `POST /api/auth/logout`.
2. Backend deletes the Refresh Token from the database and clears the HTTP-Only cookie.
3. Frontend clears `localStorage` (`t2w_access_token` + `t2w_user_profile`) and resets all Signals to `null`.
4. User is redirected to `/login`.

### Security Summary

| Layer | Mechanism | Purpose |
|-------|-----------|---------|
| Password Storage | BCrypt (12 rounds) | Prevents password cracking |
| Access Token | JWT (HS512, short-lived) | Stateless API authentication |
| Refresh Token | UUID in HTTP-Only Cookie | Secure silent token renewal |
| Session Persistence | localStorage (token + profile) | Survives page refresh |
| Inactivity Guard | 3-min idle timer (global `@HostListener`) | Auto-logout protection |
| CORS | Whitelisted origins + `allowCredentials` | Cross-origin protection |
| CSRF | Disabled (stateless JWT, no server-side sessions) | Not applicable |
| XSS | Angular built-in template sanitization | Template injection prevention |

---

## 🚀 Key Features

1.  **Reactive Dashboard:** Clear visualization with stats (total, today, this month, next 30 days) and advanced filters (text search, categories, month).
2.  **Triple View Modes:** Grid mode (polished graphic cards), List mode (professional `Mat-Table` with sorting and pagination), and **Calendar View** (monthly calendar grid showing birthdays).
3.  **AI-Powered Wish Generator:** Generate personalized birthday wishes using Google's Gemini AI, specifying tones (Friendly, Funny, Formal, Poetic) and custom instructions.
4.  **AI Card Generator:** Generate custom birthday card images using Hugging Face's Stable Diffusion API (with graceful fallback when API is unconfigured).
5.  **Custom Message Templates:** A complete template management system to save, edit, and reuse your favorite birthday messages.
6.  **Rich Contact Profiles:** Full contact support with Email, WhatsApp integration, profile image uploads, and customizable age display toggles.
7.  **Data Management:** Easily import and export your birthdays from/to CSV files, or export them to standard yearly recurring iCal `.ics` files for Google Calendar, Outlook, and Apple Calendar.
8.  **Live Toast Alerts:** Non-blocking real-time feedback notifications for all actions (add, update, delete, and import).
9.  **Notification Center (Bell):** Individual profile tracking of action history (adds, updates, deletions) with custom bell-ringing animations.
10. **Native Audio Synthesis:** Melodious sound feedback triggered on success and deletion actions.
11. **Advanced User Profiles:** Dedicated settings page to manage personal information (Name, Bio, Avatar) and securely change passwords.
12. **Interactive Analytics:** Dashboard integrations featuring dynamic Chart.js visualizations (Donut charts for categories, Bar charts for birth months).
13. **Progressive Web App (PWA):** Installable on mobile and desktop devices with offline caching via Angular Service Workers.
14. **SMTP Email Integration:** Automated reminder emails sent out via a real SMTP server integration using Spring Boot Mail.
15. **Astrology & Zodiac:** Automatic calculation and display of Zodiac signs based on birthdates across all dashboard views.
16. **Interests Management:** Seamlessly add and manage tags for personal interests within the contact details to keep track of their hobbies.
17. **AI Gift Generator:** Leverages Google's Gemini AI (with a smart local fallback engine) to generate personalized gift suggestions based on age, gender, category, and interests.
18. **Internationalization (i18n):** Full support for French, English, and German languages with dynamic switching.

---

## 📥 Quick Start Guide

### Prerequisites
*   **Java 21** or higher.
*   **Node.js 18** or higher (with npm).
*   **Docker & Docker Compose** (for the local database).

### 1. Launching the Database
From the project root, launch PostgreSQL in the background:
```bash
docker compose -f docker-compose.dev.yml up -d
```

### 2. Running the Backend
Navigate to the `backend/` directory, configure your JDK path, and run the app:
```bash
cd backend
# On Windows PowerShell:
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"
./mvnw.cmd spring-boot:run

# On Linux/macOS:
export JAVA_HOME=/usr/lib/jvm/java-21
./mvnw spring-boot:run
```
*The backend server will run on port `8081`.*

### 3. Running the Frontend
Navigate to the `frontend/` directory, install dependencies, and start the development server:
```bash
cd frontend
npm install
npm run start
```
*The frontend application will be accessible at `http://localhost:4200`.*

> **Note:** In development, the Angular dev server uses a **proxy** (`proxy.conf.json`) to forward all `/api` requests to the backend on port 8081. This ensures cookies and credentials work seamlessly across ports.

---

## 🌍 Free-Tier Cloud Deployment Guide

Time2Wish is designed to be easily deployable on modern, free-tier Cloud PaaS (Platform as a Service) providers. We utilize a decoupled architecture with the following services:

- **Database:** [Neon.tech](https://neon.tech/) (Serverless PostgreSQL)
- **Backend:** [Render.com](https://render.com/) (Spring Boot Docker Container)
- **Frontend:** [Vercel.com](https://vercel.com/) (Angular SPA)

### Step 1: Database Setup (Neon.tech)
1. Create a free account on [Neon.tech](https://neon.tech/).
2. Create a new PostgreSQL project.
3. Retrieve your connection details (Host, Database Name, User, Password). Note that Neon requires a secure connection, so we append `?sslmode=require` to our JDBC URL via the `DB_OPTIONS` variable.

### Step 2: Backend Deployment (Render.com)
1. Create a free account on [Render.com](https://render.com/).
2. Create a new **Web Service** connected to your GitHub repository.
3. Set the Root Directory to `backend` and Environment to `Docker`.
4. Configure the following **Environment Variables**:
   - `SPRING_PROFILES_ACTIVE` = `prod`
   - `DB_HOST` = `<your-neon-host>`
   - `DB_PORT` = `5432`
   - `DB_NAME` = `<your-neon-database>`
   - `DB_USER` = `<your-neon-user>`
   - `DB_PASSWORD` = `<your-neon-password>`
   - `DB_OPTIONS` = `?sslmode=require`
   - `JWT_SECRET` = `<a-secure-random-string>`
5. Deploy the service and copy your assigned Render URL (e.g., `https://time2wish-backend.onrender.com`).

### Step 3: Frontend Deployment (Vercel.com)
1. In your project code, open `frontend/vercel.json` and ensure the `destination` URL points to your new Render Backend URL.
2. Go to [Vercel.com](https://vercel.com/) and create a new project.
3. Import your GitHub repository, selecting `frontend` as the **Root Directory**.
4. Vercel will automatically detect the Angular framework and configure the build settings.
5. Click **Deploy**. Vercel will handle the routing and proxy your `/api` calls directly to Render, bypassing any CORS issues!

---

### ⚠️ Deployment Troubleshooting & Known Solutions

During deployment, you might encounter the following issues. Here is how we resolved them in this repository:

#### 1. Backend Crash: `StorageException: Could not initialize storage`
- **Problem:** Render runs Docker containers as a non-root user for security. Our backend tries to create an `uploads/` directory on startup, resulting in a permission denied error.
- **Solution:** We modified the backend `Dockerfile` to change directory ownership (`RUN chown -R appuser:appgroup /app`) before switching to the restricted `appuser`.

#### 2. Frontend Build Error: `Conflicting peer dependency` on Vercel
- **Problem:** NPM strict peer dependency resolution fails on Vercel because `@angular/service-worker` version (`21.2.16`) did not perfectly match `@angular/core` (`21.2.13`).
- **Solution:** We manually aligned the versions in `package.json` to `^21.2.13` and regenerated the `package-lock.json`. (Alternative: Add an `.npmrc` file with `legacy-peer-deps=true`).

#### 3. Vercel Deployment Succeeds but shows `404 NOT_FOUND`
- **Problem:** In Angular 17/18 using the new `application` builder, the output directory defaults to `dist/<project-name>/browser`. If Vercel isn't aware of this, it serves the wrong folder.
- **Solution:** We explicitly defined `"outputPath": "dist/frontend"` in `frontend/angular.json`. Alternatively, you can override the **Output Directory** in Vercel's Project Settings to `dist/frontend/browser`.

#### 4. White Screen after Vercel Deployment (JS files failing to load)
- **Problem:** Adding a manual SPA fallback rewrite (`"source": "/(.*)", "destination": "/index.html"`) in `vercel.json` intercepts static Javascript files, causing the browser to download HTML instead of JS.
- **Solution:** We removed the manual SPA rewrite from `vercel.json`. Vercel natively handles SPA routing for Angular automatically, so only the `/api` proxy rewrite is needed.

---

## 📱 How to Install the PWA

Time2Wish is a Progressive Web App (PWA), meaning you can install it like a native app on your phone or computer for a better experience and offline access!

### On Desktop (Chrome / Edge)
1. Open Time2Wish in your browser.
2. Look for the **Install icon** (a monitor with a down arrow) in the right side of your address bar.
3. Click it and select **Install**. The app will now open in its own window and appear in your Start menu/Applications folder.

### On Android (Chrome)
1. Open Time2Wish in Chrome.
2. A banner "Add to Home Screen" might appear at the bottom. If not, tap the **three dots menu** (top right).
3. Select **"Install app"** or **"Add to Home screen"**.

### On iOS (Safari)
1. Open Time2Wish in Safari.
2. Tap the **Share button** (the square with an arrow pointing up) at the bottom of the screen.
3. Scroll down and tap **"Add to Home Screen"**.
4. Tap **Add** in the top right corner. The app icon will now appear on your home screen.

---

## 📝 License
This project is developed for educational and personal management purposes. All rights reserved.
