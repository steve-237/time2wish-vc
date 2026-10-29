## Description
Integrate the Spring Boot AI Gift and Wish Suggestion endpoints into the Flutter mobile application, enabling users to generate tailored birthday wishes and receive smart gift suggestions based on age, interests, and budget directly from mobile screens.

## Scope & Acceptance Criteria
- [ ] Inspect and connect backend AI endpoints (`/api/ai/suggest-gifts`, `/api/ai/generate-wish`)
- [ ] Implement `AiService` in `mobile_flutter/lib/core/services/ai_service.dart` with offline fallback
- [ ] Add AI generation dialog/sheet in `BirthdayDetailScreen` or `PartyDetailScreen`
- [ ] Allow one-click copying and sharing of AI generated messages
- [ ] Add unit tests in `mobile_flutter/test/ai_service_test.dart`
