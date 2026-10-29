## Description
Recompile the Android installable binary containing all features including the recently integrated STOMP WebSockets real-time chat module and update release tag to `v1.9.1-mobile`.

## Scope & Acceptance Criteria
- [ ] Run `flutter build apk --debug` with clean compilation
- [ ] Deliver APK to `dist-mobile/Time2Wish-debug.apk`
- [ ] Validate APK size, checksum, and verify no missing dependencies
- [ ] Create annotated Git release tag `v1.9.1-mobile` and push to remote origin
