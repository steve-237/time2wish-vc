# Time2Wish – Birthday Manager & Reminder 🎂🎉

Time2Wish is a modern and premium web application designed to help you track, organize, and celebrate the birthdays of your social circles (family, friends, colleagues). Featuring an elegant glassmorphism design, interactive sound effects, and advanced management features, it ensures you will never forget a birthday again.

---

## 🛠️ Project Architecture

The project is split into two distinct parts:

*   **`backend/` (Spring Boot 3.x & PostgreSQL):**
    *   Secure REST API (JWT, refresh via HTTP-only cookies).
    *   PostgreSQL database management.
    *   Automated task scheduler for daily checks and reminder email dispatches.
*   **`frontend/` (Angular 18+ & Angular Material):**
    *   Modern and animated user interface (Glassmorphism design).
    *   Reactive state management using **Angular Signals**.
    *   Native Audio Synthesizer for sound feedback.
    *   Internationalization support (French, English, German).

---

## 🚀 Key Features

1.  **Reactive Dashboard:** Clear visualization with stats (total, today, this month, next 30 days) and advanced filters (text search, categories, month).
2.  **Triple View Modes:** Grid mode (polished graphic cards), List mode (professional `Mat-Table` with sorting and pagination), and **Calendar View** (monthly calendar grid showing birthdays).
3.  **AI-Powered Wish Generator:** Generate personalized birthday wishes using Google's Gemini AI, specifying tones (Friendly, Funny, Formal, Poetic) and custom instructions.
4.  **Custom Message Templates:** A complete template management system to save, edit, and reuse your favorite birthday messages.
5.  **Rich Contact Profiles:** Full contact support with Email, WhatsApp integration, profile image uploads, and customizable age display toggles.
6.  **Data Management:** Easily import and export your birthdays from/to CSV files, or export them to standard yearly recurring iCal `.ics` files for Google Calendar, Outlook, and Apple Calendar.
7.  **Live Toast Alerts:** Non-blocking real-time feedback notifications for all actions (add, update, delete, and import).
8.  **Notification Center (Bell):** Individual profile tracking of action history (adds, updates, deletions) with custom bell-ringing animations.
9.  **Native Audio Synthesis:** Melodious sound feedback triggered on success and deletion actions.
10. **Advanced User Profiles:** Dedicated settings page to manage personal information (Name, Bio, Avatar) and securely change passwords.
11. **Interactive Analytics:** Dashboard integrations featuring dynamic Chart.js visualizations (Donut charts for categories, Bar charts for birth months).
12. **Progressive Web App (PWA):** Installable on mobile and desktop devices with offline caching via Angular Service Workers.
13. **SMTP Email Integration:** Automated reminder emails sent out via a real SMTP server integration using Spring Boot Mail.
14. **Astrology & Zodiac:** Automatic calculation and display of Zodiac signs based on birthdates across all dashboard views.

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
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"  # On Windows
./mvnw.cmd spring-boot:run
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

---

## 📝 License
This project is developed for educational and personal management purposes. All rights reserved.
