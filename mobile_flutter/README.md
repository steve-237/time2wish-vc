# 📱 Time2Wish Mobile (Flutter)

Application mobile officielle de **Time2Wish** développée avec Flutter & Dart, proposant un design glassmorphism premium, la gestion complète des anniversaires, les souhaits personnalisés par IA, le mode hors-ligne avec code PIN, et le calcul astrologique cosmique.

---

## 🍏 Installation sur iOS (iPhone & iPad)

Pour installer et utiliser l'application sur un appareil Apple iOS, consultez notre guide détaillé :
👉 **[Guide d'Installation iOS (PWA, Xcode et TestFlight)](../docs/IOS_INSTALLATION_GUIDE.md)**

*   **Méthode instantanée (PWA Safari) :** Ouvrez Safari, touchez le bouton Partager 📤 puis *« Sur l’écran d’accueil »*. Plein écran, gratuit, 30 secondes chrono !
*   **Méthode native (Xcode) :** Pour les développeurs avec macOS, compilation directe via `Runner.xcworkspace`.
*   **Distribution TestFlight :** Pour les tests bêta et déploiement App Store.

---

## 🤖 Installation sur Android

*   Téléchargez l'APK généré automatiquement par GitHub Actions CI dans l'onglet **Actions** > **Mobile CI/CD** > artefact `time2wish-mobile-apk`.
*   Activez l'installation des sources inconnues et installez l'APK directement sur votre téléphone Android.

---

## 💻 Démarrage en Développement Local

```bash
# Récupérer les dépendances
flutter pub get

# Lancer en mode Web (sur le port 8085)
flutter run -d chrome --web-port 8085

# Exécuter les tests unitaires et widgets
flutter test
```
