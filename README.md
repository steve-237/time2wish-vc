# Time2Wish – Birthday Manager & Reminder 🎂🎉

Time2Wish est une application web moderne et premium conçue pour vous aider à suivre, organiser et célébrer les anniversaires de vos cercles sociaux (famille, amis, collègues). Dotée d'un design élégant (glassmorphism), de retours sonores interactifs et de fonctionnalités de gestion avancées, elle vous garantit de ne plus jamais oublier un anniversaire.

---

## 🛠️ Architecture du Projet

Le projet est divisé en deux parties distinctes :

*   **`backend/` (Spring Boot 3.x & PostgreSQL) :**
    *   API REST sécurisée (JWT, rafraîchissement par cookies HTTP-only).
    *   Gestion de base de données PostgreSQL.
    *   Planificateur de tâches automatisé pour la vérification quotidienne et l'envoi de courriels de rappel.
*   **`frontend/` (Angular 18+ & Angular Material) :**
    *   Interface utilisateur moderne et animée (Design Glassmorphism).
    *   Gestion réactive de l'état via les **Angular Signals**.
    *   Synthesizer Audio natif pour les retours sonores.
    *   Internationalisation (Français, Anglais, Allemand).

---

## 🚀 Fonctionnalités Clés

1.  **Dashboard Réactif :** Visualisation claire avec statistiques (total, aujourd'hui, ce mois-ci, 30 prochains jours) et filtres avancés (recherche textuelle, catégories, mois).
2.  **Double Affichage :** Mode grille (cartes graphiques soignées) et mode liste (table professionnelle `Mat-Table` avec tri et pagination).
3.  **Centre de Notifications (Cloche) :** Suivi individuel par profil de l'historique de vos actions (ajouts, modifications, suppressions d'anniversaires) et alertes de rappels.
4.  **Synthèse Audio Native :** Effets sonores mélodieux déclenchés lors des actions (succès à l'ajout, son de suppression).
5.  **Internationalisation (i18n) :** Traduction instantanée de toute l'application.

---

## 📥 Guide de Démarrage Rapide

### Prérequis
*   **Java 21** ou supérieur.
*   **Node.js 18** ou supérieur (avec npm).
*   **Docker & Docker Compose** (pour la base de données locale).

### 1. Lancement de la Base de Données
Depuis la racine du projet, lancez PostgreSQL en arrière-plan :
```bash
docker compose -f docker-compose.dev.yml up -d
```

### 2. Démarrage du Backend
Rendez-vous dans le répertoire `backend/`, compilez et lancez l'application :
```bash
cd backend
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"  # Sur Windows
./mvnw.cmd spring-boot:run
```
*Le serveur backend démarrera sur le port `8081`.*

### 3. Démarrage du Frontend
Rendez-vous dans le répertoire `frontend/`, installez les dépendances et démarrez le serveur :
```bash
cd frontend
npm install
npm run start
```
*L'application sera accessible sur `http://localhost:4200`.*

---

## 📝 Licence
Ce projet est développé à des fins éducatives et de gestion personnelle. Tous droits réservés.
