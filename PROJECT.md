# Project: Time2Wish Multi-Platform Ecosystem (v1.8.0)

## Architecture
- **Frontend Web & Mobile Native**: Angular 21 application + Ionic Capacitor 7 targeting Android (`frontend/android`) and iOS (`frontend/ios`).
- **Flutter Standalone Mobile Subsystem**: Standalone Flutter 3.44+ application (`mobile_flutter/`) featuring full feature parity: Birthdays CRUD, AI Wishes Generator (5 tones), Contacts Social Graph, Real-Time STOMP Messaging, and Gift Wishlists.
- **Backend API**: Spring Boot 3 with Spring Security (Stateless JWT + Refresh Token Cookie), Spring Data JPA, and STOMP WebSockets.

## Code Layout
- Frontend (Web & Capacitor Native): `d:\formations_personnelles\time2wish-ai\frontend`
- Flutter Mobile App: `d:\formations_personnelles\time2wish-ai\mobile_flutter`
- Backend API: `d:\formations_personnelles\time2wish-ai\backend`

## Key Interface Contracts
- Authentication header: `Authorization: Bearer <token>`
- Birthdays API: `/api/birthdays` (GET, POST, PUT, DELETE)
- AI Generation API: `/api/ai/generate` (POST)
- Contacts API: `/api/contacts` (GET, POST, PUT, DELETE)
- Messaging STOMP WS: `ws://localhost:8080/ws` -> `/topic/conversation/{id}`
