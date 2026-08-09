# Time2Wish - System Documentation

This document provides a comprehensive technical overview of the Time2Wish platform. It is designed for developers, architects, and DevOps engineers to understand the system's underlying architecture, data models, and integrations.

---

## 1. High-Level Architecture

Time2Wish is built on a **Containerized Monolithic REST API** decoupled from a **Single Page Application (SPA)**.

### Technology Stack
*   **Frontend:** Angular 18+ (Standalone Components, Signals, RxJS)
*   **Backend:** Java 21, Spring Boot 3.x (Spring Web, Spring Security, Spring Data JPA, Spring WebSocket)
*   **Database:** PostgreSQL 15+ (Relational Database)
*   **Containerization:** Docker & Docker Compose
*   **Real-time Protocol:** STOMP over WebSockets (SockJS fallback)
*   **Styling:** Native CSS/SCSS with custom Glassmorphism UI (No Tailwind/Bootstrap)

---

## 2. Core Modules & Subsystems

### A. Authentication & Authorization (Stateless JWT)
- **Engine:** Spring Security with BCrypt password hashing.
- **Tokens:** Short-lived **Access Tokens (JWT)** sent in headers, and long-lived **Refresh Tokens (UUID)** stored in HTTP-Only secure cookies.
- **Roles:** `ROLE_USER`, `ROLE_ADMIN`, `ROLE_SUPERADMIN`.
- **Session Restoration:** Angular relies on `localStorage` to immediately restore the session and uses `APP_INITIALIZER` to transparently refresh the JWT in the background.

### B. Birthday & Contact Engine
- **Models:** `Birthday`, `Contact`, `User`.
- **Logic:** Users track birthdays. The `Birthday` entity supports detailed metadata (date, relationship, tags, astrology sign).
- **Reminders:** Spring `@Scheduled` cron jobs calculate remaining days and dispatch SMTP emails via `JavaMailSender`.

### C. Generative AI Module (Zero-Config)
- **Integration:** The platform uses **Pollinations.ai** via REST template calls in `AiService.java`.
- **Text Generation (Wishes & Gifts):** Prompts are constructed dynamically based on the contact's age, relationship, and interests.
- **Image Generation (E-Cards):** Generates bespoke, customized image URLs based on user descriptive prompts.
- **Limitations:** Backend rate-limiting via `PlanType` (BASIC, PLUS, PREMIUM) restricts API calls to conserve resources. `WishCoins` are deducted per action.

### D. Collaborative & Real-Time Hub
- **STOMP WebSockets:** Facilitated by `spring-boot-starter-websocket`.
- **Channels:**
  - `/topic/user.{id}.contacts` (Private push notifications)
  - `/topic/conversation/{id}` (Group and 1-to-1 live chats)
- **Security:** WebSocket handshakes bypass standard HTTP filters; security is enforced via a custom `ChannelInterceptor` that extracts the JWT from the `CONNECT` frame.

### E. The Shared "Public" Experience (Secret Links)
- **Secret Keys:** Birthdays generate unique UUID-based `secretKey` strings. Unauthenticated users (Guests) use this URL to access a specific birthday.
- **Anonymity:** Guests are tracked via a transient `sessionId` (stored in their local browser) to allow them to upvote/downvote gifts (`GiftVote`) and claim party tasks (`PartyTask`) without creating an account.

---

## 3. Database Schema Overview

The database is managed via **Flyway** migrations. Here are the core entities:

### Identity & Access
*   `users`: Base user entity (Email, Password, PlanType, WishCoins balance).
*   `refresh_tokens`: Maps to users for stateless session renewal.

### Social Graph
*   `birthdays`: Core event entity tied to a User. Contains date, location, and metadata.
*   `contacts` / `contact_status`: Manages social connections and friend requests between platform users.

### Collaborative Organization
*   `gifts`: Items suggested (by AI) or manually added to a birthday.
*   `gift_votes`: Guest interactions (Upvote/Downvote) on a specific gift.
*   `fundraisers` / `pledges`: Crowdfunding pools ("Cagnottes") linked to a gift, tracking guest financial promises.
*   `party_tasks`: To-do list items (e.g., "Bring Drinks") created by the organizer and claimed by guests via the shared link.

### Real-Time & Engagement
*   `conversations` / `messages` / `conversation_members`: Models for STOMP chat groups.
*   `memory_items`: Digital guestbook entries (photos, text) left by guests.
*   `ecard_signatures`: Digital signatures added by guests to the communal E-Card.

---

## 4. State Management & Frontend Architecture

The Angular 18 frontend abandons legacy paradigms in favor of modern APIs:

*   **Signals for State:** `WritableSignal<T>` is used extensively across components (e.g., `BirthdayService`, `AuthService`) replacing `BehaviorSubject` for synchronous UI updates and fine-grained reactivity.
*   **Standalone Components:** No `ngModules`. Every component imports precisely what it needs.
*   **Internationalization (i18n):** 
    - The platform uses a custom, lightweight Translation Service (`t9n`).
    - The `T9nService` uses Signals to store the current language (`fr`, `en`, `de`).
    - The structural `TranslationPipe` (`| t`) reacts instantly to language changes.
    - Fallback mechanisms handle missing translations gracefully.
*   **UI/UX:**
    - Custom CSS Custom Properties (`var(--primary-blue)`) define the theme.
    - Extensive use of `backdrop-filter: blur()` for Glassmorphism.
    - Animations handled via native CSS transitions and keyframes (`@keyframes pulse`, `fade-in`).

---

## 5. Security & Rate Limiting

### Subscription Tiers (Quotas)
- **BASIC:** Limited contacts, 1 AI Wish per week, no AI Gifts.
- **PLUS:** Unlocked contacts, 1 AI Gift per month.
- **PREMIUM:** Unlimited access.
- *Implementation:* Evaluated in the Backend Controller layer before executing the AI Service logic.

### API Security
- **CORS:** explicitly configured in `WebSecurityConfig` to allow credentials (cookies) and specific headers.
- **Method Security:** `@PreAuthorize("hasRole('ADMIN')")` secures the Command Center.
- **Resource Ownership:** All endpoints fetching data (e.g., `/api/birthdays/{id}`) explicitly verify that the authenticated `Principal` is the owner or an authorized guest.

---

## 6. DevOps & Deployment

- **Containerization:** The frontend relies on Nginx within its Docker container, and the backend relies on an embedded Tomcat server.
- **CI/CD:** Multi-stage GitHub Actions workflows handle automatic testing (Maven `test`, Node `npm test`) and deployment triggering.
- **Cloud Providers:** Neon.tech (DB), Render (Backend API), Vercel (Frontend UI).

---

## 7. Mobile Subsystem (Android, iOS & Browser Device Preview)

Time2Wish features a native cross-platform mobile architecture built with **Ionic Capacitor 7**, reusing 100% of the Angular 21 Standalone frontend components, Signals, i18n, Glassmorphism design, and STOMP WebSockets.

### Native Platforms
- **Android Target (`frontend/android`)**: Native Gradle project configured with `minSdkVersion 24`, `targetSdkVersion 34`, and Android permissions (`INTERNET`, `VIBRATE`, `CAMERA`, `READ_EXTERNAL_STORAGE`, `POST_NOTIFICATIONS`).
- **iOS Target (`frontend/ios`)**: Native Xcode Workspace (`App.xcworkspace`) targeting iOS 14+.

### Native Plugins & Browser Fallbacks (`NativeFallbackService`)
The mobile subsystem includes a unified cross-platform service (`NativeFallbackService`) that seamlessly routes native capabilities when running on mobile devices or provides web browser fallbacks when tested in DevTools Mobile View:
- **Haptics (`@capacitor/haptics`)**: Micro-vibration feedback on native mobile; falls back to `navigator.vibrate`.
- **Camera (`@capacitor/camera`)**: Photo capture/pick for memory items; falls back to HTML5 file input.
- **Share Sheet (`@capacitor/share`)**: Native share sheet for secret birthday links; falls back to Web Share API or Clipboard.
- **Notifications (`@capacitor/local-notifications`)**: Native local birthday reminders; falls back to HTML5 Notification API.

### Build & Compilation Commands
- **Angular Mobile Build**: `npm run build:mobile` (generates `dist/frontend/browser`)
- **Capacitor Sync**: `npm run cap:sync` (synchronizes assets and native plugins into `android/` and `ios/`)
- **Android APK Build**: `npm run build:apk` (compiles `frontend/android/app/build/outputs/apk/debug/app-debug.apk`)

*This documentation is continually updated alongside system migrations and major architectural changes.*
