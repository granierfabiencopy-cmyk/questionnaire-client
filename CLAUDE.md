# CLAUDE.md

Ce fichier fournit des indications à Claude Code (claude.ai/code) pour travailler dans ce dépôt.

## Présentation du projet

Outil de questionnaire en français pour « Les Bains — Albi » (établissement de bains froids et sauna). Les répondants remplissent un formulaire de 26 questions ; leurs réponses sont stockées dans Supabase et consultables par le propriétaire via un tableau de bord admin protégé par mot de passe.

## Développement

**Lancer en local :**
```bash
npx serve -l 3456 .
```
Sert les fichiers statiques sur `http://localhost:3456`. Aucune étape de build, aucune transpilation — les modifications HTML/CSS/JS sont visibles immédiatement après rechargement.

Il n'existe pas de linter, de suite de tests ni de pipeline de build dans ce projet.

## Architecture

Il s'agit d'un **projet HTML statique pur** (pas de framework, pas de bundler). Toute la logique est incluse en ligne dans deux fichiers HTML autonomes.

### `index.html` — Questionnaire côté répondant

Trois vues séquentielles contrôlées par basculement `display` :
1. **Intro** (`#intro`) — Affichée en premier ; vérifie le `localStorage` pour une session sauvegardée et propose de reprendre.
2. **Questionnaire** (`#questionnaire-view`) — Une carte par question. Les cartes sont construites dynamiquement par `buildCards()` à partir de la structure de données `SECTIONS`, puis affichées/masquées par `showCard(idx)`.
3. **Synthèse** (`#synthese-view`) — Récapitulatif de toutes les réponses, avec options d'envoi par e-mail ou d'impression en PDF.

L'état est maintenu dans deux variables JS : `responses` (un dictionnaire plat `{id: valeur}`) et `currentStep` (entier). À chaque modification, l'état est :
- Écrit dans le `localStorage` sous la clé `questionnaire_cecile`
- Déboncé (2 s) puis envoyé en upsert dans Supabase via `syncToSupabase()`

La saisie vocale utilise l'API navigateur `SpeechRecognition` (français, `fr-FR`) et ajoute le texte transcrit dans le champ actif.

### `admin.html` — Tableau de bord CRM du propriétaire

Protégé par mot de passe (`fabien2026`, vérifié côté client via `sessionStorage`). Charge toutes les lignes de la table Supabase `submissions` et les affiche sous forme de cartes repliables. Permet au propriétaire de :
- Changer le statut d'une soumission (`nouveau` / `en_cours` / `traite`)
- Ajouter des notes en texte libre par soumission
- Filtrer la liste par statut

Le texte des questions est dupliqué en version abrégée dans la constante `SECTIONS` de `admin.html` (à synchroniser manuellement avec `index.html`).

### `setup.sql` — Schéma Supabase

Définit la table `submissions` et les politiques de Row Level Security. À exécuter une seule fois sur le projet Supabase pour initialiser la base. La table utilise `session_id` (UUID stocké dans le `localStorage`) comme clé de conflit unique pour les upserts, ce qui permet aux utilisateurs anonymes de reprendre leur session sans authentification.

### Connexion Supabase

Les deux fichiers HTML partagent la même clé publiable et l'URL de projet codées en dur. Le client JS Supabase est chargé depuis le CDN jsDelivr (`@supabase/supabase-js@2`). Il n'y a pas de code côté serveur.

## Conventions clés

- **Les questions sont définies dans `SECTIONS`** — un tableau de `{name, questions[]}`. Chaque question a `{id, q, hint, type}` où `type` vaut `textarea`, `text` ou `choice`. Les identifiants de questions (`l1`–`l26`) sont les clés dans la map `responses` et dans la colonne `responses` (JSONB) de Supabase.
- **`admin.html` doit refléter les IDs de questions de `index.html`** — la constante `SECTIONS` abrégée dans `admin.html` doit utiliser les mêmes valeurs `id`, sinon les réponses ne s'affichent pas correctement.
- **Pas de `<script src>` ni d'imports de modules** — tout le JavaScript est inline en bas de chaque fichier.
- **Tout le texte de l'interface est en français.**
- **Le déploiement** se fait via Vercel (`.vercel/` est dans le `.gitignore`). Un push sur le dépôt déclenche automatiquement le déploiement.
