# UniFlow Desktop — Suite Académique Native Flutter

Application de bureau officielle UniFlow développée par **KERNEL FORGE**, conçue pour les grands écrans (Linux, Windows, macOS) avec une architecture 100% Flutter natif.

---

## ✨ Fonctionnalités Majeures

### 1. 🎥 Service de Visioconférence Local Embarqué (`LocalVisioServer`)
- **Serveur autonome en Dart natif** : démarre automatiquement sur `http://localhost:7890` (et sur l'adresse IP du réseau local).
- **Accès sans application** : toute personne sans l'application UniFlow (invité, étudiant ou enseignant sur smartphone, tablette ou PC) peut rejoindre l'amphi virtuel directement via son navigateur web (Chrome, Firefox, Safari) en ouvrant le lien ou en scannant le **QR Code** généré à l'écran.
- **WebRTC P2P Direct** : transmission vidéo HD, audio clair, chat en direct et partage d'écran sans dépendance à un service cloud tiers.

### 2. 🧠 Copilote d'Études Uni propulsé par GROQ
- Inférence IA ultra-rapide connectée à l'API GROQ.
- Modèles haute intelligence (`openai/gpt-oss-120b`) et vitesse instantanée (`qwen/qwen3.8-27b`).
- Réponses académiques contextualisées pour l'Université de Yaoundé I.

### 3. 📚 Bibliothèque Numérique Exclusive Z-Library
- Recherche et téléchargement de manuels de cours via l'API officielle Z-Library.
- Ouvrages de référence en Algorithmique, Cryptographie, Bases de Données, Réseaux et IA.

### 4. 🗓️ Emploi du Temps Hebdomadaire & Bento Dashboard
- Grille interactive Lundi – Samedi pour la Faculté des Sciences.
- Détection des cours en direct et calcul des crédits ECTS / volume horaire semestriel.

---

## 🚀 Démarrage & Compilation

### Dépendances et analyse
```bash
flutter pub get
flutter analyze
```

### Lancement en mode développement
```bash
flutter run -d linux   # sur Linux
flutter run -d windows # sur Windows
flutter run -d macos   # sur macOS
```

### Compilation des binaires
```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

---

*Développé avec excellence par l'équipe KERNEL FORGE pour l'Université de Yaoundé I.*
