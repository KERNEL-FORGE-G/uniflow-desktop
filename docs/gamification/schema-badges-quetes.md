# Schéma Appwrite — Système de Gamification UniFlow

## Vue d'ensemble

Le système de gamification UniFlow repose sur **4 collections Appwrite** pour gérer :
- 200 badges organisés en 5 stades (Bronze → Argent → Or → Platine → Diamant)
- ~600 quêtes (quotidiennes, mensuelles, annuelles, permanentes)
- Progression des utilisateurs (XP, niveau, statistiques)
- Historique des récompenses débloquées

**Architecture offline-first** : toutes les collections supportent la synchronisation différée via Appwrite Realtime.

---

## Collections

### 1. `gamification_badges` — Définition des badges

Catalogue des 200 badges disponibles dans UniFlow.

**CollectionId** : `gamification_badges`  
**Permissions** : `['read("any")']` — lecture publique pour tous les utilisateurs  
**DocumentSecurity** : `false` — pas de permissions par document

#### Attributs

| Clé | Type | Taille | Requis | Description |
|-----|------|--------|--------|-------------|
| `badgeId` | string | 64 | ✓ | Identifiant unique (ex: `badge_assidu_bronze`) |
| `name` | string | 128 | ✓ | Nom affiché (ex: "Étudiant Assidu") |
| `category` | enum | — | ✓ | Catégorie : `ATTENDANCE`, `PERFORMANCE`, `COLLABORATION`, `EXPLORATION`, `SPECIAL_EVENT` |
| `tier` | enum | — | ✓ | Stade : `BRONZE`, `SILVER`, `GOLD`, `PLATINUM`, `DIAMOND` |
| `description` | string | 512 | ✓ | Description des critères d'obtention |
| `icon` | string | 128 | ✓ | Chemin vers l'icône (ex: `assets/badges/badge_assidu_bronze.webp`) |
| `colorCode` | string | 7 | ✓ | Couleur hex (ex: `#CD7F32` pour bronze) |
| `xpReward` | integer | — | ✓ | Points XP accordés (50-5000 selon le stade) |
| `criteria` | string | 2000 | ✓ | JSON décrivant les conditions de déblocage |
| `seriesId` | string | 64 | ✓ | Identifiant de série (ex: `assidu` pour lier les 5 stades) |
| `order` | integer | — | ✓ | Ordre d'affichage dans la série |
| `isVisible` | boolean | — | ✓ | Afficher dans la galerie (défaut: `true`) |
| `requiredBadge` | string | 64 | ✗ | Badge pré-requis (pour progression séquentielle) |

#### Index

```javascript
[
  { key: 'idx_badge_id', type: 'unique', attributes: ['badgeId'] },
  { key: 'idx_category', type: 'key', attributes: ['category'] },
  { key: 'idx_series', type: 'key', attributes: ['seriesId', 'order'] }
]
```

#### Exemple de document

```json
{
  "$id": "675a1b2c3d4e5f6g7h8i9j0k",
  "badgeId": "badge_assidu_bronze",
  "name": "Étudiant Assidu — Bronze",
  "category": "ATTENDANCE",
  "tier": "BRONZE",
  "description": "Assister à 10 cours sans absence",
  "icon": "assets/badges/badge_assidu_bronze.webp",
  "colorCode": "#CD7F32",
  "xpReward": 100,
  "criteria": "{\"type\":\"attendance\",\"threshold\":10,\"period\":\"all_time\"}",
  "seriesId": "assidu",
  "order": 1,
  "isVisible": true,
  "requiredBadge": null
}
```

---

### 2. `gamification_quests` — Définition des quêtes

Catalogue des ~600 quêtes (missions) disponibles.

**CollectionId** : `gamification_quests`  
**Permissions** : `['read("any")']`  
**DocumentSecurity** : `false`

#### Attributs

| Clé | Type | Taille | Requis | Description |
|-----|------|--------|--------|-------------|
| `questId` | string | 64 | ✓ | Identifiant unique (ex: `daily_attend_3_classes`) |
| `name` | string | 128 | ✓ | Titre de la quête |
| `description` | string | 512 | ✓ | Description de l'objectif |
| `type` | enum | — | ✓ | Type : `DAILY`, `MONTHLY`, `ANNUAL`, `MILESTONE` |
| `category` | enum | — | ✓ | Même énumération que les badges |
| `objective` | string | 2000 | ✓ | JSON décrivant l'objectif à atteindre |
| `xpReward` | integer | — | ✓ | Points XP (10-1000) |
| `badgeReward` | string | 64 | ✗ | Badge débloqué si complétée (optionnel) |
| `difficulty` | enum | — | ✓ | Difficulté : `EASY`, `MEDIUM`, `HARD`, `EXPERT` |
| `isActive` | boolean | — | ✓ | Quête active (permet de désactiver temporairement) |
| `startDate` | datetime | — | ✗ | Date de début (pour événements spéciaux) |
| `endDate` | datetime | — | ✗ | Date de fin (pour événements spéciaux) |
| `prerequisiteQuest` | string | 64 | ✗ | Quête pré-requise (pour chaînes de quêtes) |
| `rotation` | integer | — | ✗ | Numéro de rotation (1-365 pour quotidiennes) |

#### Index

```javascript
[
  { key: 'idx_quest_id', type: 'unique', attributes: ['questId'] },
  { key: 'idx_type_active', type: 'key', attributes: ['type', 'isActive'] },
  { key: 'idx_rotation', type: 'key', attributes: ['type', 'rotation'] }
]
```

#### Exemple de document

```json
{
  "$id": "675a1b2c3d4e5f6g7h8i9j0k",
  "questId": "daily_attend_3_classes",
  "name": "Marathon du jour",
  "description": "Assister à 3 cours aujourd'hui",
  "type": "DAILY",
  "category": "ATTENDANCE",
  "objective": "{\"type\":\"attendance_count\",\"target\":3,\"period\":\"today\"}",
  "xpReward": 50,
  "badgeReward": null,
  "difficulty": "MEDIUM",
  "isActive": true,
  "startDate": null,
  "endDate": null,
  "prerequisiteQuest": null,
  "rotation": 1
}
```

---

### 3. `gamification_user_progress` — Progression des utilisateurs

Un document **par utilisateur** contenant son niveau, XP total et statistiques globales.

**CollectionId** : `gamification_user_progress`  
**Permissions** : `['create("users")']`  
**DocumentSecurity** : `true` — chaque document porte `read("user:{userId}")`, `update("user:{userId}")`

#### Attributs

| Clé | Type | Taille | Requis | Description |
|-----|------|--------|--------|-------------|
| `userId` | string | 64 | ✓ | Identifiant Appwrite du membre (`users.$id`) |
| `username` | string | 32 | ✓ | Pseudo (dénormalisé pour classements) |
| `level` | integer | — | ✓ | Niveau actuel (1-100) |
| `currentXp` | integer | — | ✓ | XP accumulés pour le niveau actuel |
| `totalXp` | integer | — | ✓ | XP totaux depuis la création du compte |
| `nextLevelXp` | integer | — | ✓ | XP requis pour atteindre le niveau suivant |
| `rank` | string | 32 | ✓ | Titre selon le niveau (ex: "Apprenti", "Expert", "Légende") |
| `unlockedBadgesCount` | integer | — | ✓ | Nombre de badges débloqués |
| `completedQuestsCount` | integer | — | ✓ | Nombre de quêtes terminées |
| `stats` | string | 5000 | ✓ | JSON avec statistiques détaillées (voir ci-dessous) |
| `lastDailyReset` | datetime | — | ✓ | Dernière réinitialisation des quêtes quotidiennes |
| `lastMonthlyReset` | datetime | — | ✓ | Dernière réinitialisation des quêtes mensuelles |
| `currentStreak` | integer | — | ✓ | Série de jours consécutifs actifs |
| `longestStreak` | integer | — | ✓ | Record de série de jours |

#### Structure JSON du champ `stats`

```json
{
  "attendance": {
    "totalClasses": 120,
    "presentCount": 115,
    "lateCount": 3,
    "absentCount": 2,
    "attendanceRate": 95.83
  },
  "academic": {
    "averageGrade": 14.5,
    "coursesCompleted": 8,
    "assignmentsSubmitted": 24,
    "assignmentsOnTime": 22
  },
  "social": {
    "messagesHelped": 15,
    "groupsJoined": 4,
    "resourcesShared": 7
  },
  "exploration": {
    "libraryVisits": 12,
    "coursesViewed": 45,
    "documentsDownloaded": 89
  }
}
```

#### Index

```javascript
[
  { key: 'idx_user_id', type: 'unique', attributes: ['userId'] },
  { key: 'idx_total_xp', type: 'key', attributes: ['totalXp'], orders: ['DESC'] },
  { key: 'idx_level', type: 'key', attributes: ['level'], orders: ['DESC'] }
]
```

---

### 4. `gamification_user_achievements` — Badges et quêtes débloqués

Historique des récompenses obtenues par chaque utilisateur.

**CollectionId** : `gamification_user_achievements`  
**Permissions** : `['create("users")']`  
**DocumentSecurity** : `true`

#### Attributs

| Clé | Type | Taille | Requis | Description |
|-----|------|--------|--------|-------------|
| `userId` | string | 64 | ✓ | Identifiant du membre |
| `achievementType` | enum | — | ✓ | Type : `BADGE` ou `QUEST` |
| `achievementId` | string | 64 | ✓ | ID du badge ou de la quête |
| `achievementName` | string | 128 | ✓ | Nom (dénormalisé pour affichage rapide) |
| `unlockedAt` | datetime | — | ✓ | Date et heure de déblocage |
| `xpAwarded` | integer | — | ✓ | XP reçus lors du déblocage |
| `progress` | string | 1000 | ✗ | JSON de progression (pour quêtes complexes) |
| `isNew` | boolean | — | ✓ | Notification non lue (défaut: `true`) |

#### Index

```javascript
[
  { key: 'idx_user_achievements', type: 'key', attributes: ['userId', 'unlockedAt'], orders: ['ASC', 'DESC'] },
  { key: 'idx_unique_achievement', type: 'unique', attributes: ['userId', 'achievementType', 'achievementId'] },
  { key: 'idx_new_notifications', type: 'key', attributes: ['userId', 'isNew'] }
]
```

---

## Permissions et sécurité

### Stratégie de permissions

| Collection | Collection-level | Document-level | Justification |
|------------|------------------|----------------|---------------|
| `gamification_badges` | `read("any")` | Aucune | Catalogue public consultable par tous |
| `gamification_quests` | `read("any")` | Aucune | Catalogue public consultable par tous |
| `gamification_user_progress` | `create("users")` | `read("user:{userId}")`, `update("user:{userId}")` | Données privées par utilisateur |
| `gamification_user_achievements` | `create("users")` | `read("user:{userId}")`, `update("user:{userId}")` | Historique privé par utilisateur |

### Sécurité côté serveur

Les **Appwrite Functions** valident les débloquages :
- Vérification des critères avant d'accorder un badge
- Calcul de progression basé sur les données académiques réelles
- Prévention du déblocage manuel frauduleux

**Function à créer** : `gamification-progress-tracker`
- Trigger : `databases.*.collections.academic_*.documents.*.create`
- Rôle : Calculer la progression après chaque événement académique

---

## Gestion de la synchronisation offline

### Stratégie de conflit

1. **Progression XP/niveau** : `last-write-wins` avec timestamp
2. **Déblocage de badges** : Validation côté serveur lors de la synchronisation
3. **Quêtes quotidiennes** : Réinitialisation serveur à 00h00 UTC

### Champs de versioning

Chaque document de progression contient :
- `$updatedAt` (Appwrite natif)
- `lastDailyReset` / `lastMonthlyReset` pour détecter les quêtes expirées

---

## Volumétrie et limites

### Estimations de stockage

| Collection | Documents estimés | Taille moyenne | Total |
|------------|-------------------|----------------|-------|
| `gamification_badges` | 200 | 1 KB | 200 KB |
| `gamification_quests` | 600 | 1 KB | 600 KB |
| `gamification_user_progress` | 10 000 utilisateurs | 10 KB | 100 MB |
| `gamification_user_achievements` | 500 000 (50/user) | 500 B | 250 MB |

**Total estimé** : ~350 MB pour 10 000 utilisateurs actifs

### Limites Appwrite Cloud (plan gratuit)

- ✅ **Bases de données** : 1/1 utilisée (réutilisation de `uniflow`)
- ✅ **Collections** : 33 existantes + 4 nouvelles = 37 (limite : 100)
- ✅ **Documents** : ~500K estimés (limite : 1M)
- ✅ **Bande passante** : Lecture majoritaire, synchronisation delta

---

## Calcul du niveau et de l'XP

### Formule de progression

Le XP requis pour le niveau `n` suit une courbe exponentielle :

```javascript
function getXpForLevel(level) {
  const base = 100;
  const exponent = 1.5;
  return Math.floor(base * Math.pow(level, exponent));
}

// Exemples :
// Niveau 1 → 2 : 100 XP
// Niveau 2 → 3 : 282 XP
// Niveau 5 → 6 : 1118 XP
// Niveau 10 → 11 : 3162 XP
// Niveau 50 → 51 : 35355 XP
// Niveau 100 → 101 : 100000 XP
```

### Titres de rang

| Niveau | Titre | XP total cumulé |
|--------|-------|-----------------|
| 1-5 | Novice | 0-1000 |
| 6-10 | Apprenti | 1000-5000 |
| 11-20 | Étudiant | 5000-20000 |
| 21-35 | Érudit | 20000-70000 |
| 36-50 | Expert | 70000-150000 |
| 51-70 | Maître | 150000-350000 |
| 71-90 | Champion | 350000-700000 |
| 91-100 | Légende | 700000-1500000 |

---

## Intégration avec les données académiques existantes

Le système de gamification s'appuie sur les collections existantes :

| Collection académique | Événements déclencheurs | Impact gamification |
|-----------------------|-------------------------|---------------------|
| `academic_schedules` | Cours marqué comme présent | +XP assiduité, progression badge assidu |
| `academic_grades` | Note enregistrée | +XP performance, progression badge major |
| `messages` | Message d'entraide | +XP collaboration, progression badge entraide |
| `academic_library` | Document téléchargé | +XP exploration, progression badge explorateur |
| `events` | Participation événement | +XP spécial, badge événement |

---

## Migration depuis les 6 badges existants

Les badges actuels deviennent le **stade Bronze** de leur série respective :

| Badge existant | Nouvelle série | Stades à créer |
|----------------|----------------|----------------|
| `badge_premier_pas` | `premier_pas` | Argent, Or, Platine, Diamant |
| `badge_assidu` | `assidu` | Argent, Or, Platine, Diamant |
| `badge_ponctuel` | `ponctuel` | Argent, Or, Platine, Diamant |
| `badge_sans_faute` | `sans_faute` | Argent, Or, Platine, Diamant |
| `badge_major` | `major` | Argent, Or, Platine, Diamant |
| `badge_entraide` | `entraide` | Argent, Or, Platine, Diamant |

**Script de migration** : À créer dans `scripts/migrate-legacy-badges.mjs`

---

## Prochaines étapes

1. ✅ **Schéma défini** (ce document)
2. ⏳ Créer `badges-definitions.json` avec les 200 badges
3. ⏳ Créer `quests-definitions.json` avec les 600 quêtes
4. ⏳ Écrire `provision-gamification.mjs`
5. ⏳ Documenter l'algorithme de calcul dans `calcul-progression.md`

---

**Auteur** : Kiro AI  
**Date** : 2024  
**Version** : 1.0  
**Projet** : UniFlow Desktop — Système de gamification
