# Uniflow work — Application Desktop Native (Rust + Tauri v2 + React + TypeScript)

<p align="center">
  <img src="public/brand/icon_192.png" alt="Uniflow work Logo" width="110" />
</p>

**Uniflow work** est le poste de commandement académique natif (Windows & Linux) de la plateforme universitaire numérique intelligente **UniFlow**, conçue par le collectif **KERNEL FORGE** pour l'Université de Yaoundé I et l'enseignement supérieur africain.

---

## 🪪 Identité Officielle Microsoft Store (Partner Center)

| Champ Microsoft Partner Center | Valeur Officielle |
| :--- | :--- |
| **Nom de l'application** | `Uniflow work` |
| **Package/Identity/Name** | `KERNELFORGE.Uniflowwork` |
| **Package/Identity/Publisher** | `CN=200A91F7-4B15-441F-9332-83F216885B09` |
| **Package/Properties/PublisherDisplayName** | `KERNEL FORGE` |
| **Nom de la famille de packages (PFN)** | `KERNELFORGE.Uniflowwork_3wyzhk1x8xr0a` |
| **SID du package** | `S-1-15-2-3173161051-1525954667-3862484852-2055131400-1678586278-65818988-3190942280` |
| **ID Store** | `9NGZKFGK98K6` |
| **Lien de protocole vers le Store** | `ms-windows-store://pdp/?productid=9NGZKFGK98K6` |
| **URL du Store web** | [https://apps.microsoft.com/detail/9NGZKFGK98K6](https://apps.microsoft.com/detail/9NGZKFGK98K6) |

---

## 🏗️ Stack Technique & Architecture Native

- **Noyau Système Natif** : **Rust (Edition 2021)** + **Tauri v2** (`src-tauri/`)
  - Commandes IPC `@tauri-apps/api` natives :
    - `get_store_identity()` : Identité officielle Microsoft Store Partner Center (`KERNELFORGE.Uniflowwork`, `9NGZKFGK98K6`).
    - `get_system_diagnostics()` : Télémétrie système temps réel (CPU, RAM, IP locale campus, statut nœud LAN LiveKit, cache offline).
    - `sync_offline_cache(payload)` : Synchronisation Offline-First persistée localement.
    - `start_lan_conference(room_name, course_code)` : Initialisation de session WebRTC/LiveKit LAN Campus sans Internet.
    - `generate_attendance_qr(course_id, session_type)` : Génération cryptographique SHA-256 de QR Codes de présence anti-fraude.
    - `export_report_file(title, format, rows)` : Export natif de PV, relevés de notes et listes de présence en CSV/JSON.
- **Interface Utilisateur** : **React 18 + TypeScript 5 + Tailwind CSS v4 + Vite 6**
- **Backend Cloud & Campus** : **Appwrite Self-Hosted** (`https://vps.kernelforge.codes/v1`, projet `uniflow`, bases `uniflow` et `independant`)

---

## 🖥️ Les 16 Écrans des Planches Desktop + Modules Cahier des Charges

1. **Écran 1 — Fenêtre de Connexion Desktop** (Split-screen `#1E3A8A`, Mascotte Uni, sélecteur de rôle Administrateur / Enseignant / Délégué / Étudiant, connexion Appwrite + accès rapide démo).
2. **Écran 2 — Tableau de bord Principal** (4 KPI cards, évolution des inscriptions, répartition des présences, activité récente, actions rapides).
3. **Écran 3 — Gestion des Étudiants** (Recherche, filtres Filière/Niveau L1-M2/Statut, table complète, export CSV/JSON natif Rust, modal `+ Ajouter un étudiant`).
4. **Écran 4 — Fiche Détaillée Étudiant** (Carte profil + 6 onglets : *Informations*, *Parcours académique*, *Présences*, *Notes & Relevés*, *Emploi du temps*, *Journal d'activité*).
5. **Écran 5 — Gestion des Enseignants** (Grades Pr./Dr./M., départements, UEs attribuées, charge horaire, modal `+ Nouvel enseignant`).
6. **Écran 6 — Arborescence Programmes / Facultés** (Vue split : arbre interactif Faculté des Sciences → Départements → Filières ICT4D/Info/Maths → Niveaux L1–M2 + détails cohortes/UEs).
7. **Écran 7 — Gestion des Unités d'Enseignement (UE)** (Catalogue INF111, INF204, MAT101, ICT301, crédits LMD, heures CM/TD/TP, syllabus).
8. **Écran 8 — Gestion des Salles & Amphithéâtres** (Bascule *Vue Tableau* / *Vue Grille visuelle*, statuts Disponible/Occupée/En maintenance, équipements, réservation).
9. **Écran 9 — Constructeur d'Emploi du Temps** (Grille hebdomadaire Lundi–Samedi 07h30–19h30, détection automatique de conflits de salles, bouton `Auto-générer IA`).
10. **Écran 10 — Suivi des Présences & QR Code** (Générateur QR Code cryptographique Rust SHA-256, appel nominal interactif Présent/Absent/Retard/Excusé, statistiques par département).
11. **Écran 11 — Gestion des Conférences Vidéo En ligne & LAN** (Studio LiveKit Hybride Cloud & LAN Campus sans Internet, grille vidéo, partage d'écran, chat, présence auto, découverte IP LAN Rust).
12. **Écran 12 — Tableau de bord Statistiques & Analytics** (KPIs Direction, taux de réussite par filière, recouvrement scolarité FCFA, charge enseignante).
13. **Écran 13 — Centre de Communications** (4 onglets : *Notifications*, *Messagerie directe*, *Annonces*, *Alertes système*).
14. **Écran 14 — Gestion des Annonces Officielles** (Publication d'annonces ciblées par filière/rôle, épinglage, modal `+ Nouvelle annonce`).
15. **Écran 15 — Paramètres Système & Identité Microsoft Store** (6 onglets dont *Identité Microsoft Store & Système* affichant `KERNELFORGE.Uniflowwork`, `9NGZKFGK98K6`, PFN, SID et diagnostics Rust).
16. **Écran 16 — Profil Utilisateur & Permissions RBAC** (Profil, matrice des permissions RBAC, 2FA, sessions actives Desktop/Mobile/Web).
17. **Modules Complémentaires Cahier des Charges** :
    - **Inscriptions, Paiements Mobile Money (MTN MoMo / Orange Money FCFA) & Bourses**
    - **Correction des Devoirs & Évaluations Enseignant**
    - **Bibliothèque Numérique Z-Library & Gamification (Quêtes & Badges)**
    - **Sentinelle IA (Copilote Académique Edge AI)**
    - **Équipe KERNEL FORGE** (10 membres officiels avec switch interactif **📸 Photos réelles** ⟷ **✨ Avatars Anime**)

---

## 🚀 Développement & Compilation Multi-OS

```bash
# Installer les dépendances
pnpm install

# Lancer en mode développement
pnpm run dev

# Vérifier la compilation TypeScript + Vite et le noyau Rust Tauri
pnpm run build
cargo check --manifest-path src-tauri/Cargo.toml

# Générer les installateurs natifs (.msi, .exe, .deb, .AppImage, .rpm)
pnpm tauri build
```
