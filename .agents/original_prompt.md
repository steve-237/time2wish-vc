## 2026-06-06T23:14:42Z

# Teamwork Project Prompt — Draft

> Status: Launched
> Goal: Craft prompt → get user approval → delegate to teamwork_preview

Construire un tableau de bord Administrateur sécurisé (Admin Panel) pour Time2Wish. Ce panel permettra au propriétaire de l'application de visualiser les statistiques globales (nombre d'utilisateurs, anniversaires enregistrés) et de gérer les comptes utilisateurs (liste, suppression, modification de mot de passe).

Working directory: d:\formations_personnelles\time2wish-ai
Integrity mode: demo

## Requirements

### R1. Interface d'Administration Séparée
Créer une interface Angular distincte de l'application client principale (layout séparé) dédiée uniquement à l'administration de Time2Wish.

### R2. Gestion des Rôles (Spring Security)
Implémenter un véritable système de rôles (`ROLE_USER`, `ROLE_ADMIN`) dans le backend Spring Boot via Spring Security. Sécuriser les routes API d'administration.

### R3. Périmètre d'Action de l'Administrateur
Permettre à l'administrateur de lister les utilisateurs, voir les statistiques globales, bloquer/supprimer des comptes, et modifier le mot de passe d'un utilisateur.

### R4. Tests Automatisés (Front & Back)
Toujours écrire des tests automatisés pour chaque nouvelle fonctionnalité ajoutée, aussi bien côté Frontend (Angular/Jasmine) que côté Backend (Spring Boot/JUnit).

### R5. Qualité du Code et Principes SOLID
Respecter rigoureusement les principes de génie logiciel (SOLID, Clean Architecture, DRY). Le code produit doit être clair, modulaire, hautement évolutif et facile à maintenir.

## Acceptance Criteria

### 1. Sécurité et Rôles
- [ ] Une requête vers `/api/admin/*` avec le token d'un utilisateur normal (`ROLE_USER`) doit renvoyer une erreur HTTP 403 Forbidden.
- [ ] Une requête vers `/api/admin/*` avec le token d'un administrateur (`ROLE_ADMIN`) doit renvoyer HTTP 200 OK.

### 2. Actions Administrateur
- [ ] L'API doit posséder un endpoint fonctionnel permettant à un admin de supprimer un utilisateur, vérifiable via un test unitaire ou d'intégration.
- [ ] L'API doit posséder un endpoint fonctionnel permettant à un admin de modifier le mot de passe d'un utilisateur sans connaître l'ancien.

### 3. Couverture de Tests
- [ ] La commande `mvn test` côté backend doit passer à 100% sans aucune erreur.
- [ ] La commande `npm test` (ou `ng test`) côté frontend doit passer avec succès pour les nouveaux composants créés.
