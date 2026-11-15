# 🍏 Guide d'Installation iOS pour Time2Wish (iPhone & iPad)

> **Existe-t-il une version iOS de l'application Time2Wish ?**  
> **OUI !** Time2Wish a été conçue pour iOS dès son architecture. Le code source intègre les cibles natives iOS (`Runner.xcworkspace`) ainsi qu'une version Progressive Web App (PWA) optimisée pour Safari iOS.

Ce guide détaille les **3 méthodes d'installation** sur iPhone, de la plus simple et immédiate (sans Mac ni compte payant) à l'installation native et la distribution TestFlight.

---

## 📊 Tableau comparatif des méthodes

| Critère | Méthode 1 : PWA Safari (Recommandée) | Méthode 2 : Xcode Sideloading | Méthode 3 : TestFlight / App Store |
| :--- | :--- | :--- | :--- |
| **Matériel requis** | N'importe quel iPhone | Mac avec Xcode | Compte Apple Developer (99\$/an) |
| **Temps d'installation** | **30 secondes** | ~10 minutes | Déploiement CI / Distribution |
| **Coût** | **Gratuit** | **Gratuit** | 99\$/an |
| **Expérience** | Plein écran natif (sans barre Safari) | Application native 100% | Application native 100% |
| **Mode Hors-Ligne** | ✅ Oui (Service Worker + Cache) | ✅ Oui (Stockage Local) | ✅ Oui (Stockage Local) |
| **Mises à jour** | Instantanées & automatiques | Recompilation nécessaire (7j gratuit) | Automatiques via TestFlight |

---

## 🚀 Méthode 1 : Installation instantanée PWA (Recommandée & Sans Mac)

Cette méthode ne nécessite **aucun ordinateur**, **aucun compte développeur** et prend moins d'une minute.

### 📱 Étapes sur votre iPhone :

1. **Ouvrez Safari** sur votre iPhone (veillez à utiliser Safari et non un autre navigateur pour l'installation).
2. **Accédez à l'URL de Time2Wish** :
   - En environnement déployé : `https://time2wish.app` (ou l'URL de votre serveur staging).
   - En développement local : connectez votre iPhone au même réseau Wi-Fi que votre PC/serveur, puis ouvrez `http://<ADRESSE_IP_DU_PC>:8085`.
3. **Appuyez sur le bouton de partage** :
   - Il s'agit de l'icône carrée avec une flèche pointant vers le haut (**📤**) située dans la barre d'outils en bas de Safari.
4. **Faites défiler le menu et sélectionnez :**
   - **« Sur l’écran d’accueil »** (*Add to Home Screen* / icône avec un `+`).
5. **Confirmez l'ajout :**
   - Le nom proposé est `Time2Wish` avec l'icône officielle de l'application.
   - Appuyez sur **« Ajouter »** en haut à droite.
6. **Lancement de l'application :**
   - L'icône Time2Wish apparaît désormais sur l'écran d'accueil de votre iPhone à côté de vos autres applications.
   - Touchez-la : l'application s'ouvre en **mode plein écran autonome** (sans barre d'adresse ni boutons de navigation du navigateur).
   - Elle dispose de la gestion du cache hors-ligne, des retours haptiques et de la mémorisation de session.

---

## 🛠️ Méthode 2 : Installation Native via Xcode (Pour Développeurs & Mac)

Si vous disposez d'un Mac et souhaitez installer le binaire natif compilé directement sur votre iPhone.

### 📋 Prérequis :
- Un ordinateur Mac avec macOS Ventura ou Sonoma.
- **Xcode 15+** installé via le Mac App Store.
- **Flutter SDK** (version 3.44+ ou 3.50+).
- **CocoaPods** (`sudo gem install cocoapods` ou `brew install cocoapods`).
- Un câble USB Lightning / USB-C pour relier l'iPhone au Mac.
- Un identifiant Apple gratuit (Apple ID).

### ⚙️ Procédure étape par étape :

1. **Cloner le projet et préparer les dépendances :**
   ```bash
   git clone git@github.com:steve-237/time2wish-vc.git
   cd time2wish-vc/mobile_flutter
   flutter pub get
   ```

2. **Installer les Pods iOS :**
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. **Ouvrir le projet dans Xcode :**
   ```bash
   open ios/Runner.xcworkspace
   ```
   > ⚠️ **Important :** Ouvrez toujours le fichier `.xcworkspace` et non `.xcodeproj`.

4. **Configurer la signature (Signing) :**
   - Dans le volet de gauche de Xcode, cliquez sur le projet **Runner** tout en haut.
   - Sélectionnez la cible **Runner** > onglet **Signing & Capabilities**.
   - Cochez **Automatically manage signing**.
   - Dans le menu déroulant **Team**, connectez votre compte Apple personnel (*Add an Account...*).
   - Modifiez si nécessaire le *Bundle Identifier* (ex: `com.votre-nom.time2wish`) pour qu'il soit unique à votre compte.

5. **Connecter l'iPhone et lancer le déploiement :**
   - Branchez votre iPhone au Mac via câble USB.
   - Sur l'iPhone, déverrouillez l'écran et touchez **« Faire confiance à cet ordinateur »**.
   - En haut de Xcode, sélectionnez votre iPhone comme appareil de destination (à la place d'un simulateur).
   - Cliquez sur le bouton **Play (▶️)** de Xcode ou exécutez dans votre terminal :
     ```bash
     flutter run -d <Nom-ou-ID-de-votre-iPhone>
     ```

6. **Autoriser le profil de développement sur l'iPhone :**
   - Lors du premier lancement, iOS bloquera l'exécution pour des raisons de sécurité.
   - Sur votre iPhone, ouvrez **Réglages** > **Général** > **VPN et gestion des appareils**.
   - Touchez votre identifiant Apple dans la liste des applications de développement.
   - Touchez **« Faire confiance à [Votre Nom / Email] »** et confirmez.
   - Ouvrez Time2Wish : l'application native s'exécute avec les performances maximales !

---

## ☁️ Méthode 3 : Distribution TestFlight & App Store

Pour distribuer l'application à des testeurs externes ou sur l'App Store sans connexion physique.

### 📋 Prérequis :
- Compte **Apple Developer Program** actif (99\$/an).
- Certificats de distribution et Profils de Provisioning créés sur [Apple Developer Console](https://developer.apple.com).
- Enregistrement de l'application sur [App Store Connect](https://appstoreconnect.apple.com).

### 🚀 Étapes de publication :

1. **Générer l'archive IPA :**
   ```bash
   cd mobile_flutter
   flutter build ipa --release
   ```
   L'archive est générée dans `build/ios/archive/Runner.xcarchive` et l'IPA dans `build/ios/ipa/`.

2. **Téléversement sur App Store Connect :**
   - Soit via l'application Mac **Transporter** en glissant-déposant le fichier `.ipa`.
   - Soit en ligne de commande :
     ```bash
     xcrun altool --upload-app --type ios -f build/ios/ipa/time2wish_mobile.ipa --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
     ```

3. **Invitation des testeurs TestFlight :**
   - Rendez-vous sur [App Store Connect](https://appstoreconnect.apple.com) > **Apps** > **Time2Wish** > **TestFlight**.
   - Ajoutez des groupes de tests internes ou générez un lien public TestFlight.
   - Les testeurs installent l'application officielle **TestFlight** depuis l'App Store sur leur iPhone et cliquent sur le lien d'invitation pour installer Time2Wish d'un simple toucher.

---

## 💡 Astuces & Dépannage

- **L'icône ne s'affiche pas sur l'écran d'accueil Safari :**  
  Vérifiez que le fichier `apple-touch-icon.png` est bien accessible à la racine du projet web/mobile et que la balise `<link rel="apple-touch-icon" href="icons/Icon-192.png">` est présente dans `index.html`.
- **Mode hors-ligne sur iPhone :**  
  Time2Wish intègre un cache local et un Service Worker. Même sans réseau 4G/5G/Wi-Fi, vos anniversaires enregistrés, le calcul d'âge, les signes astrologiques et l'accès par code PIN restent 100% fonctionnels.
