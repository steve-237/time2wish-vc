# 🔑 Time2Wish — Development & Production Credentials Reference

This document provides a comprehensive reference of all environment URLs, API endpoints, and authentication credentials for both Development and Production environments across Web and Mobile applications.

---

## 🌐 Environment URLs & Service Endpoints

### 🛠️ Local Development Environment
| Subsystem | Service / App | Local Access URL |
|---|---|---|
| **Web Frontend** | Angular 21 Single Page Application | `http://localhost:4200` |
| **Backend API** | Spring Boot 3 + PostgreSQL | `http://localhost:8081` |
| **Flutter Mobile Web** | Standalone Flutter 3.44 Mobile App | `http://localhost:8085` |
| **Database** | PostgreSQL 16.14 (Port 5433) | `jdbc:postgresql://localhost:5433/time2wish` |
| **WebSockets** | STOMP Messaging & Admin Telemetry | `ws://localhost:8081/ws` |

### 🚀 Production Cloud Environment
| Subsystem | Host Provider | Production Access URL |
|---|---|---|
| **Web Application** | Vercel Cloud | `https://time2wish.vercel.app` |
| **Backend REST API** | Render Cloud | `https://time2wish-backend.onrender.com/api` |
| **Production Database** | Render PostgreSQL | Internal SSL Managed Database |
| **WebSocket Broker** | Render WebSockets | `wss://time2wish-backend.onrender.com/ws` |

---

## 👤 User Accounts & Login Credentials

### 🛡️ 1. Super Administrator Account
Used for full administrative control, system telemetry, and platform management.

*   **Email:** `superadmin@time2wish.com`
*   **Password:** `password123`
*   **Role:** `ROLE_SUPERADMIN`
*   **Subscription Plan:** `PRO` *(Unlimited AI Wishes & Gifts)*
*   **WishCoins Balance:** Unlimited / System Refill
*   **Admin Panel Route:** `/admin`
*   **Privileges:**
    *   Access to real-time WebSocket log streamer terminal.
    *   System-wide Emergency Kill Switches (AI Wishes, AI Images, Chat, Crowdfunding).
    *   Live user telemetry & connected session counter.
    *   Ghost Login (One-click user impersonation mode).
    *   One-click PostgreSQL database JSON snapshot exporter.

---

### 🎂 2. Standard Demo User Account
Used for end-user testing, birthday tracking, wishlists, and social features.

*   **Email:** `demo@time2wish.com`
*   **Password:** `password`
*   **Role:** `ROLE_USER`
*   **Subscription Plan:** `BASIC`
*   **WishCoins Balance:** 5 WishCoins (refreshes daily upon login)
*   **Dashboard Route:** `/dashboard`
*   **Privileges & Features:**
    *   Birthday countdown tracking & custom contact lists.
    *   Shared Party Organizer to-do lists & guest assignments.
    *   Community gift wishlist voting (Up/Down democratic selection).
    *   Crowdfunding pledges ("Cagnottes") & real-time chat room.
    *   Google Contacts & Google Calendar OAuth sync.

---

## 📱 Mobile Applications (Android / iOS / Flutter)

### 📲 Standalone Flutter Native App (`mobile_flutter/`)
*   **Dev Web Preview:** `http://localhost:8085`
*   **Prefilled Credentials:** `demo@time2wish.com` / `password`
*   **Offline Mode:** Automated offline fallback allowing full UI testing when backend server is unavailable.

### 📱 Angular 21 + Ionic Capacitor 7 App (`frontend/`)
*   **Android Binary:** `frontend/android/app/build/outputs/apk/debug/app-debug.apk`
*   **iOS Workspace:** `frontend/ios/App/App.xcworkspace`
*   **Browser Mobile Preview:** Chrome DevTools Mobile View (`F12` -> `Ctrl + Shift + M`) on `http://localhost:4200`.

---

> [!IMPORTANT]
> Keep this file updated whenever adding new roles, changing default passwords in `DataInitializer.java`, or updating production deployment URLs.
