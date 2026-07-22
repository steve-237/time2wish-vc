# 🚀 Roadmap & Planification des Sprints : Time2Wish Premium

Ce document détaille la stratégie d'implémentation, découpée en **5 Sprints** agiles, pour les nouvelles fonctionnalités majeures demandées. L'ordre des sprints a été pensé pour maximiser la création de valeur rapide (Quick Wins) avant d'attaquer les intégrations complexes (OAuth2 / Stockage Vidéo).

## User Review Required

> [!IMPORTANT]
> **Stockage Vidéo (Sprint 4)** : Les vidéos (même courtes) prennent beaucoup d'espace. Pour l'instant, notre base de données Neon (PostgreSQL) ne peut pas stocker efficacement des fichiers vidéos lourds. M'autorisez-vous à intégrer un service de stockage Cloud type **AWS S3**, **Cloudinary**, ou **Supabase Storage** (ils ont des plans gratuits) pour héberger ces vidéos ?
>
> **API E-commerce (Sprint 3)** : L'API officielle d'Amazon (PAAPI) nécessite un compte partenaire validé avec des ventes actives. En attendant, préférez-vous que l'on génère de simples **liens de recherche Amazon affiliés** (qui redirigent vers les résultats de recherche) ou que l'on utilise une API tierce (type Rainforest API) pour récupérer de vraies images et prix ?

---

## 🏃 Sprint 1 : 💌 Déballage Virtuel d'E-Card (Interactive Unwrapping)
*Objectif : Créer un "Wow Effect" instantané avec une expérience frontend immersive lors de l'ouverture d'un lien secret.*

**Backend :**
- [ ] Ajouter un booléen `isOpened` sur l'entité `Birthday` ou `ECard` pour déclencher l'animation une seule fois lors de la première ouverture par le destinataire.

**Frontend (UI/UX) :**
- [ ] Créer le composant autonome `virtual-envelope.component.ts`.
- [ ] Implémenter le design CSS 3D de l'enveloppe (Rabat, texture papier, ombre dynamique).
- [ ] Ajouter les interactions tactiles (Swipe up pour ouvrir / Cliquez pour déchirer).
- [ ] Intégrer la librairie `canvas-confetti` pour déclencher une pluie de confettis à l'ouverture.
- [ ] Transition fluide (Fade out) de l'enveloppe vers le "Livre d'Or" (Guestbook).

---

## 🏃 Sprint 2 : 🃏 Le "Tinder" du Cadeau (Mini-jeu collaboratif)
*Objectif : Gamifier le choix du cadeau commun en introduisant une interface de vote par balayage (Swipe).*

**Backend :**
- [ ] Étendre l'entité `GiftVote` pour supporter un vote "Tinder" (Swipe Right = +1, Swipe Left = -1) lié à un `sessionId` (anonyme).
- [ ] Créer un endpoint `GET /api/birthdays/{id}/gifts/tinder` pour distribuer les cartes de cadeaux non encore votées par l'utilisateur.
- [ ] Créer un endpoint pour soumettre le résultat d'un Swipe.
- [ ] Créer un algorithme de classement (Score dynamique = Upvotes - Downvotes).

**Frontend (UI/UX) :**
- [ ] Créer le composant `tinder-cards.component.ts`.
- [ ] Intégrer une mécanique de "Swipe" (via CSS Transforms ou Hammer.js).
- [ ] Animer l'interface : Vert (J'aime) au swipe droit, Rouge (Je passe) au swipe gauche.
- [ ] Page de résultats (Podium) : Afficher en direct les 3 cadeaux ayant le meilleur score de la communauté.

---

## 🏃 Sprint 3 : 🛍️ E-commerce & Affiliation en 1 Clic
*Objectif : Rendre les suggestions d'IA actionnables et générer des revenus passifs via l'affiliation.*

**Backend :**
- [ ] Modifier l'entité `AppSetting` ou le panneau d'administration pour configurer votre `AFFILIATE_TAG` global.
- [ ] Modifier l'IA (ou le service de cadeaux) pour parser le nom du produit généré.
- [ ] Créer un service `AffiliationService` qui construit des liens formatés dynamiquement : `https://www.amazon.fr/s?k=[Nom+Du+Cadeau]&tag=[VotreTag]`.
- [ ] (Optionnel) Si API tierce validée : Endpoint de récupération de prix et d'image en temps réel.

**Frontend (UI/UX) :**
- [ ] Redesigner la carte `GiftCard` pour intégrer un grand bouton "Acheter ce cadeau".
- [ ] Ajouter un tag dynamique (ex: "Prix estimé: ~45€" généré par l'IA ou via API).
- [ ] Afficher un disclaimer légal discret "(Lien affilié)".

---

## 🏃 Sprint 4 : 📹 Capsule Temporelle Vidéo
*Objectif : Permettre la capture et le stockage de vidéos directement dans l'application web.*

**Backend :**
- [ ] Configurer un client Cloud Storage (AWS S3, Cloudinary).
- [ ] Créer un endpoint `/api/media/upload-url` (Presigned URL) pour permettre au Frontend d'uploader la vidéo directement sur le cloud sans saturer notre serveur.
- [ ] Mettre à jour l'entité `MemoryItem` (Livre d'or) pour supporter le type `VIDEO`.

**Frontend (UI/UX) :**
- [ ] Intégrer l'API Web native `MediaRecorder`.
- [ ] Créer l'interface de capture vidéo : Bouton "Enregistrer", "Stop", "Prévisualiser", "Recommencer".
- [ ] Gérer les permissions navigateur (Caméra/Micro).
- [ ] Intégrer le composant lecteur vidéo HTML5 `<video>` dans le composant du Livre d'Or.

---

## 🏃 Sprint 5 : 🔄 Synchronisation Bi-directionnelle Google
*Objectif : Automatiser la gestion des dates via le protocole OAuth2 et l'API Google.*

**Backend :**
- [ ] Implémenter le flux **OAuth2 Authorization Code Grant** (Google Sign-In).
- [ ] Stocker le `google_access_token` et `google_refresh_token` de l'utilisateur (Chiffrés dans la BDD).
- [ ] Intégrer la **Google People API** (pour importer les dates de naissance des contacts).
- [ ] Intégrer la **Google Calendar API** (pour créer/modifier/supprimer les événements d'anniversaires directement dans l'agenda de l'utilisateur).
- [ ] Configurer un Webhook (Push Notification Google) pour écouter les changements côté Google et mettre à jour Time2Wish.

**Frontend (UI/UX) :**
- [ ] Créer la page "Intégrations" dans les Paramètres Utilisateur.
- [ ] Ajouter le bouton de connexion "Lier mon compte Google".
- [ ] Gérer l'UI de feedback lors de la première synchronisation de masse (Barre de chargement : "Synchronisation de 42 contacts...").

---

## Vérification

Pour chaque sprint, la phase de vérification inclura :
- L'écriture de tests End-to-End (E2E) si nécessaire.
- Le déploiement sur l'environnement de *Staging*.
- Une validation fonctionnelle et UX sur navigateur de bureau et mobile (les swipes et la caméra nécessitant une bonne gestion du tactile).
