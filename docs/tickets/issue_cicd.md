## Description
Automate testing and release packaging for the Flutter mobile application:
- Run `flutter analyze` and `flutter test` on push/pull request.
- Build release web bundle and publish to GitHub Pages / hosting.
- Build signed Android APK and attach as a GitHub Release download artifact.

## Deliverables
- GitHub Actions workflow at `.github/workflows/mobile-ci.yml`
- Automated artifact upload for APK and Web
