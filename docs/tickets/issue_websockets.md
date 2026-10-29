## Description
Integrate real-time messaging on the Flutter mobile client to match the Angular web app:
- Connect mobile client to Spring Boot STOMP WebSockets endpoint `/ws`.
- Subscribe to `/topic/messages/{conversationId}` for instantaneous message arrival.
- Provide live typing indicators, delivery receipts, and unread badge increments.

## Deliverables
- `WebSocketService` on Flutter mobile
- Live chat screen with real-time bidirectional messaging
