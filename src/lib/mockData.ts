export type UserRole = 'Administrateur' | 'Enseignant' | 'Délégué' | 'Étudiant';

export interface StudentRecord {
  id: string;
  matricule: string;
  nom: string;
  prenom: string;
  email: string;
  telephone: string;
  filiere: string;
  departement: string;
  niveau: 'L1' | 'L2' | 'L3' | 'M1' | 'M2';
  moyenne: number;
  creditsValides: number;
  creditsTotaux: number;
  presencePct: number;
  statut: 'Actif' | 'Boursier' | 'En attente quitus' | 'Suspendu';
  quitusPaye: number;
  quitusTotal: number;
  dateNaissance: string;
  lieuNaissance: string;
  photo: string;
  notes: {
    code: string;
    intitule: string;
    cc: number;
    tp: number;
    sn: number;
    finale: number;
    credits: number;
    mention: string;
  }[];
}

export interface TeacherRecord {
  id: string;
  matricule: string;
  grade: 'Pr.' | 'Dr.' | 'M.' | 'Mme';
  nomComplet: string;
  email: string;
  telephone: string;
  departement: string;
  specialite: string;
  ues: string[];
  heuresEffectuees: number;
  heuresPrevues: number;
  statut: 'Permanent' | 'Vacataire' | 'Missionnaire';
  bureau: string;
}

export interface UERecord {
  code: string;
  intitule: string;
  departement: string;
  filiere: string;
  niveau: 'L1' | 'L2' | 'L3' | 'M1' | 'M2';
  semestre: 'S1' | 'S2' | 'S3' | 'S4' | 'S5' | 'S6';
  credits: number;
  heuresCM: number;
  heuresTD: number;
  heuresTP: number;
  enseignant: string;
  inscrits: number;
  tauxReussite: number;
  syllabus: string;
}

export interface RoomRecord {
  id: string;
  code: string;
  nom: string;
  type: 'Amphithéâtre' | 'Salle TD' | 'Laboratoire TP' | 'Salle Hybride LiveKit';
  batiment: string;
  capacite: number;
  statut: 'Disponible' | 'Occupée' | 'En maintenance';
  coursActuel?: string;
  enseignantActuel?: string;
  equipements: string[];
  lanNodeIp: string;
}

export interface ScheduleSlot {
  id: string;
  jour: 'Lundi' | 'Mardi' | 'Mercredi' | 'Jeudi' | 'Vendredi' | 'Samedi';
  heureDebut: string;
  heureFin: string;
  ueCode: string;
  ueTitre: string;
  type: 'CM' | 'TD' | 'TP' | 'Examen';
  salle: string;
  enseignant: string;
  filiere: string;
  niveau: string;
  conflit?: string;
}

export interface ConferenceRoom {
  id: string;
  titre: string;
  ueCode: string;
  enseignant: string;
  mode: 'LAN Campus (Hors-ligne)' | 'Cloud Hybride (VPS)';
  participants: number;
  maxParticipants: number;
  statut: 'En direct' | 'Planifiée' | 'Terminée';
  horaire: string;
  salleRelais: string;
  enregistrementActif: boolean;
}

export interface AnnouncementItem {
  id: string;
  titre: string;
  categorie: 'Rectorat' | 'Décanat Sciences' | 'Département Info' | 'Scolarité & Bourses' | 'Urgence Campus';
  cible: string;
  auteur: string;
  date: string;
  epingle: boolean;
  publie: boolean;
  vues: number;
  contenu: string;
}

export interface TeamMember {
  id: string;
  rank: string;
  name: string;
  role: string;
  subTeam: string;
  email: string;
  github: string;
  portfolio?: string;
  isFounder?: boolean;
  photoUrl: string;
  avatarAnimeUrl: string;
  badges: string[];
  bio: string;
  skills: { label: string; score: number }[];
}

export const INITIAL_STUDENTS: StudentRecord[] = [
  {
    id: 'stu-01',
    matricule: '23U2458',
    nom: 'NGHOMSI FEUKOUO',
    prenom: 'Ravel',
    email: 'ravel.nghomsi@facsciences-uy1.cm',
    telephone: '+237 694 11 22 33',
    filiere: 'ICT4D',
    departement: 'Informatique',
    niveau: 'L3',
    moyenne: 17.45,
    creditsValides: 180,
    creditsTotaux: 180,
    presencePct: 98.4,
    statut: 'Boursier',
    quitusPaye: 50000,
    quitusTotal: 50000,
    dateNaissance: '14/03/2003',
    lieuNaissance: 'Yaoundé, Cameroun',
    photo: '/team/ravel.jpg',
    notes: [
      { code: 'ICT301', intitule: 'Architecture Systèmes Distribués & Cloud', cc: 18.0, tp: 19.0, sn: 17.5, finale: 18.0, credits: 6, mention: 'Excellent (A+)' },
      { code: 'INF304', intitule: 'Génie Logiciel & DevSecOps', cc: 17.0, tp: 18.5, sn: 16.5, finale: 17.1, credits: 6, mention: 'Très Bien (A)' },
      { code: 'ICT305', intitule: 'Intelligence Artificielle & Edge Computing', cc: 16.5, tp: 18.0, sn: 17.0, finale: 17.2, credits: 6, mention: 'Très Bien (A)' },
      { code: 'INF308', intitule: 'Sécurité des Réseaux & Cryptographie', cc: 17.5, tp: 17.0, sn: 18.0, finale: 17.6, credits: 6, mention: 'Très Bien (A)' },
    ],
  },
  {
    id: 'stu-02',
    matricule: '23U2512',
    nom: 'HASSANE YOUSSOUF',
    prenom: 'Oumar',
    email: 'hassane.oumar@facsciences-uy1.cm',
    telephone: '+237 690 45 78 12',
    filiere: 'Informatique Fondamentale',
    departement: 'Informatique',
    niveau: 'L3',
    moyenne: 16.8,
    creditsValides: 180,
    creditsTotaux: 180,
    presencePct: 96.0,
    statut: 'Boursier',
    quitusPaye: 50000,
    quitusTotal: 50000,
    dateNaissance: '22/07/2002',
    lieuNaissance: 'Ngaoundéré, Cameroun',
    photo: '/team/hassane.jpg',
    notes: [
      { code: 'INF301', intitule: 'Systèmes d’Exploitation Avancés & Noyaux', cc: 17.5, tp: 18.0, sn: 16.5, finale: 17.1, credits: 6, mention: 'Très Bien (A)' },
      { code: 'INF302', intitule: 'Compilation & Langages Formels', cc: 16.0, tp: 17.0, sn: 16.5, finale: 16.5, credits: 6, mention: 'Très Bien (A)' },
    ],
  },
  {
    id: 'stu-03',
    matricule: '23U2609',
    nom: 'FEBNCHAK',
    prenom: 'Sandra Borelle',
    email: 'sandra.febnchak@facsciences-uy1.cm',
    telephone: '+237 677 88 99 10',
    filiere: 'ICT4D',
    departement: 'Informatique',
    niveau: 'L3',
    moyenne: 16.4,
    creditsValides: 180,
    creditsTotaux: 180,
    presencePct: 95.5,
    statut: 'Actif',
    quitusPaye: 50000,
    quitusTotal: 50000,
    dateNaissance: '09/11/2003',
    lieuNaissance: 'Douala, Cameroun',
    photo: '/team/sandra.jpg',
    notes: [
      { code: 'ICT302', intitule: 'Interfaces Humain-Machine & Mobile Cross-Platform', cc: 18.0, tp: 17.5, sn: 16.0, finale: 16.9, credits: 6, mention: 'Très Bien (A)' },
    ],
  },
  {
    id: 'stu-04',
    matricule: '23U2781',
    nom: 'MELI',
    prenom: 'William',
    email: 'william.meli@facsciences-uy1.cm',
    telephone: '+237 655 32 19 84',
    filiere: 'Réseaux & Cybersécurité',
    departement: 'Informatique',
    niveau: 'M1',
    moyenne: 16.15,
    creditsValides: 60,
    creditsTotaux: 60,
    presencePct: 94.2,
    statut: 'Actif',
    quitusPaye: 50000,
    quitusTotal: 50000,
    dateNaissance: '19/04/2002',
    lieuNaissance: 'Bafoussam, Cameroun',
    photo: '/team/william.jpg',
    notes: [
      { code: 'SEC401', intitule: 'Audit Sécurité & Pentesting Réseaux', cc: 16.5, tp: 17.5, sn: 15.8, finale: 16.4, credits: 6, mention: 'Très Bien (A)' },
    ],
  },
  {
    id: 'stu-05',
    matricule: '24U1104',
    nom: 'MOKAM ZUNE',
    prenom: 'Ange Gabrielle',
    email: 'gabrielle.mokam@facsciences-uy1.cm',
    telephone: '+237 698 74 51 23',
    filiere: 'ICT4D',
    departement: 'Informatique',
    niveau: 'L3',
    moyenne: 16.25,
    creditsValides: 180,
    creditsTotaux: 180,
    presencePct: 96.8,
    statut: 'Boursier',
    quitusPaye: 50000,
    quitusTotal: 50000,
    dateNaissance: '05/08/2003',
    lieuNaissance: 'Yaoundé, Cameroun',
    photo: '/team/mokam.jpg',
    notes: [
      { code: 'ICT303', intitule: 'Architecture API REST, BaaS & Fintech Mobile Money', cc: 17.0, tp: 17.5, sn: 16.0, finale: 16.6, credits: 6, mention: 'Très Bien (A)' },
    ],
  },
  {
    id: 'stu-06',
    matricule: '24U1298',
    nom: 'ALIYATOU RACHID',
    prenom: 'Oumou Tourab',
    email: 'oumou.aliyatou@facsciences-uy1.cm',
    telephone: '+237 691 20 33 44',
    filiere: 'Informatique Fondamentale',
    departement: 'Informatique',
    niveau: 'L2',
    moyenne: 15.7,
    creditsValides: 120,
    creditsTotaux: 120,
    presencePct: 93.5,
    statut: 'Actif',
    quitusPaye: 50000,
    quitusTotal: 50000,
    dateNaissance: '12/01/2004',
    lieuNaissance: 'Garoua, Cameroun',
    photo: '/team/aliya.jpg',
    notes: [
      { code: 'INF204', intitule: 'Structures de Données & Algorithmique Avancée', cc: 16.0, tp: 16.5, sn: 15.5, finale: 15.9, credits: 6, mention: 'Bien (B+)' },
    ],
  },
  {
    id: 'stu-07',
    matricule: '24U1450',
    nom: 'MANDENG',
    prenom: 'Judith Oceanne',
    email: 'judith.mandeng@facsciences-uy1.cm',
    telephone: '+237 674 15 26 37',
    filiere: 'ICT4D',
    departement: 'Informatique',
    niveau: 'L2',
    moyenne: 15.4,
    creditsValides: 114,
    creditsTotaux: 120,
    presencePct: 91.0,
    statut: 'Actif',
    quitusPaye: 25000,
    quitusTotal: 50000,
    dateNaissance: '28/09/2004',
    lieuNaissance: 'Edéa, Cameroun',
    photo: '/team/judith.jpg',
    notes: [
      { code: 'ICT202', intitule: 'Développement Mobile & UX Design', cc: 15.5, tp: 16.0, sn: 15.0, finale: 15.4, credits: 6, mention: 'Bien (B+)' },
    ],
  },
  {
    id: 'stu-08',
    matricule: '24U1612',
    nom: 'SINENG KENGNI',
    prenom: 'Juvénal',
    email: 'juvenal.sineng@facsciences-uy1.cm',
    telephone: '+237 651 89 42 70',
    filiere: 'Mathématiques & Applications',
    departement: 'Mathématiques',
    niveau: 'L3',
    moyenne: 15.85,
    creditsValides: 180,
    creditsTotaux: 180,
    presencePct: 94.0,
    statut: 'Actif',
    quitusPaye: 50000,
    quitusTotal: 50000,
    dateNaissance: '03/06/2003',
    lieuNaissance: 'Dschang, Cameroun',
    photo: '/team/juvenal.jpg',
    notes: [
      { code: 'MAT301', intitule: 'Analyse Numérique & Optimisation', cc: 16.0, tp: 16.5, sn: 15.5, finale: 15.85, credits: 6, mention: 'Bien (B+)' },
    ],
  },
  {
    id: 'stu-09',
    matricule: '25U0891',
    nom: 'TESSOH PEKAM',
    prenom: 'Marcel',
    email: 'marcel.tessoh@facsciences-uy1.cm',
    telephone: '+237 680 12 45 78',
    filiere: 'ICT4D',
    departement: 'Informatique',
    niveau: 'L1',
    moyenne: 14.9,
    creditsValides: 60,
    creditsTotaux: 60,
    presencePct: 89.5,
    statut: 'En attente quitus',
    quitusPaye: 25000,
    quitusTotal: 50000,
    dateNaissance: '17/12/2005',
    lieuNaissance: 'Yaoundé, Cameroun',
    photo: '/team/marcel.jpg',
    notes: [
      { code: 'INF111', intitule: 'Algorithmique & Programmation Structurée C', cc: 15.0, tp: 15.5, sn: 14.5, finale: 14.9, credits: 6, mention: 'Bien (B)' },
    ],
  },
  {
    id: 'stu-10',
    matricule: '23U2990',
    nom: 'DJOMGUE',
    prenom: 'Miguel',
    email: 'miguel.djomgue@facsciences-uy1.cm',
    telephone: '+237 699 54 32 18',
    filiere: 'Génie Logiciel & Systèmes Natifs',
    departement: 'Informatique',
    niveau: 'M2',
    moyenne: 16.6,
    creditsValides: 120,
    creditsTotaux: 120,
    presencePct: 97.2,
    statut: 'Boursier',
    quitusPaye: 50000,
    quitusTotal: 50000,
    dateNaissance: '11/02/2001',
    lieuNaissance: 'Yaoundé, Cameroun',
    photo: '/team/miguel.jpg',
    notes: [
      { code: 'INF501', intitule: 'Architecture Desktop Rust, Tauri & WebAssembly', cc: 17.5, tp: 18.0, sn: 16.0, finale: 16.9, credits: 6, mention: 'Très Bien (A)' },
    ],
  },
];

export const INITIAL_TEACHERS: TeacherRecord[] = [
  {
    id: 'tch-01',
    matricule: 'ENS-UY1-001',
    grade: 'Pr.',
    nomComplet: 'Pr. Maurice TCHUENTE',
    email: 'm.tchuente@facsciences-uy1.cm',
    telephone: '+237 677 10 20 30',
    departement: 'Informatique',
    specialite: 'Calcul Parallèle, Automates Cellulaires & Systèmes Distribués',
    ues: ['INF301', 'ICT301', 'INF501'],
    heuresEffectuees: 138,
    heuresPrevues: 150,
    statut: 'Permanent',
    bureau: 'Bloc Pédagogique I — Bureau 204',
  },
  {
    id: 'tch-02',
    matricule: 'ENS-UY1-014',
    grade: 'Pr.',
    nomComplet: 'Pr. Thomas DJOTIO NDIE',
    email: 't.djotio@facsciences-uy1.cm',
    telephone: '+237 699 40 50 60',
    departement: 'Informatique',
    specialite: 'Réseaux Sans Fil, Cybersécurité & IoT Campus',
    ues: ['INF308', 'SEC401', 'ICT305'],
    heuresEffectuees: 124,
    heuresPrevues: 140,
    statut: 'Permanent',
    bureau: 'Département Informatique — Bureau 108',
  },
  {
    id: 'tch-03',
    matricule: 'ENS-UY1-029',
    grade: 'Dr.',
    nomComplet: 'Dr. Paulin MELATAGIA YONTA',
    email: 'p.melatagia@facsciences-uy1.cm',
    telephone: '+237 675 21 43 65',
    departement: 'Informatique',
    specialite: 'Génie Logiciel, Intelligence Artificielle & Modélisation',
    ues: ['INF204', 'INF304', 'ICT302'],
    heuresEffectuees: 112,
    heuresPrevues: 120,
    statut: 'Permanent',
    bureau: 'Extension Sciences — Bureau 312',
  },
  {
    id: 'tch-04',
    matricule: 'ENS-UY1-042',
    grade: 'Dr.',
    nomComplet: 'Dr. Valéry MONTHE',
    email: 'v.monthe@facsciences-uy1.cm',
    telephone: '+237 694 88 77 66',
    departement: 'Informatique',
    specialite: 'Systèmes d’Information, Gouvernance & ICT4D',
    ues: ['INF111', 'ICT202', 'ICT303'],
    heuresEffectuees: 96,
    heuresPrevues: 110,
    statut: 'Permanent',
    bureau: 'Département Informatique — Bureau 115',
  },
  {
    id: 'tch-05',
    matricule: 'ENS-UY1-058',
    grade: 'Pr.',
    nomComplet: 'Pr. Jean-Claude NDOUMBE',
    email: 'jc.ndoumbe@facsciences-uy1.cm',
    telephone: '+237 691 11 44 99',
    departement: 'Mathématiques',
    specialite: 'Algèbre Linéaire, Analyse Numérique & Cryptologie',
    ues: ['MAT101', 'MAT202', 'MAT301'],
    heuresEffectuees: 130,
    heuresPrevues: 135,
    statut: 'Permanent',
    bureau: 'Bâtiment Mathématiques — Porte 12',
  },
  {
    id: 'tch-06',
    matricule: 'ENS-UY1-073',
    grade: 'Dr.',
    nomComplet: 'Dr. Clarisse NGO MBOCK',
    email: 'c.ngombock@facsciences-uy1.cm',
    telephone: '+237 656 09 87 65',
    departement: 'Physique',
    specialite: 'Électronique Numérique & Systèmes Embarqués Sentinelle',
    ues: ['PHY102', 'PHY205'],
    heuresEffectuees: 84,
    heuresPrevues: 100,
    statut: 'Vacataire',
    bureau: 'Laboratoire Électronique — Salle 04',
  },
];

export const INITIAL_UES: UERecord[] = [
  {
    code: 'INF111',
    intitule: 'Algorithmique & Programmation Structurée en C',
    departement: 'Informatique',
    filiere: 'Informatique Fondamentale / ICT4D',
    niveau: 'L1',
    semestre: 'S1',
    credits: 6,
    heuresCM: 30,
    heuresTD: 15,
    heuresTP: 15,
    enseignant: 'Dr. Valéry MONTHE',
    inscrits: 640,
    tauxReussite: 78.4,
    syllabus: 'Pointeurs, allocation dynamique, structures, complexité algorithmique et fichiers binaires.',
  },
  {
    code: 'MAT101',
    intitule: 'Algèbre Linéaire & Structures Algébriques',
    departement: 'Mathématiques',
    filiere: 'Tronc Commun Info / Maths',
    niveau: 'L1',
    semestre: 'S1',
    credits: 6,
    heuresCM: 35,
    heuresTD: 25,
    heuresTP: 0,
    enseignant: 'Pr. Jean-Claude NDOUMBE',
    inscrits: 720,
    tauxReussite: 71.2,
    syllabus: 'Espaces vectoriels, réduction des endomorphismes, matrices et systèmes linéaires.',
  },
  {
    code: 'INF204',
    intitule: 'Structures de Données & Algorithmique Avancée',
    departement: 'Informatique',
    filiere: 'Informatique Fondamentale',
    niveau: 'L2',
    semestre: 'S3',
    credits: 6,
    heuresCM: 25,
    heuresTD: 20,
    heuresTP: 15,
    enseignant: 'Dr. Paulin MELATAGIA YONTA',
    inscrits: 410,
    tauxReussite: 82.0,
    syllabus: 'Arbres AVL, B-Trees, graphes, tables de hachage et programmation dynamique.',
  },
  {
    code: 'ICT301',
    intitule: 'Architecture Systèmes Distribués, Cloud & Appwrite BaaS',
    departement: 'Informatique',
    filiere: 'ICT4D',
    niveau: 'L3',
    semestre: 'S5',
    credits: 6,
    heuresCM: 25,
    heuresTD: 15,
    heuresTP: 20,
    enseignant: 'Pr. Maurice TCHUENTE',
    inscrits: 245,
    tauxReussite: 91.5,
    syllabus: 'Consensus distribué, microservices, Docker, Appwrite Self-Hosted et résilience Offline-First.',
  },
  {
    code: 'INF308',
    intitule: 'Sécurité des Réseaux, Cryptographie & Protocoles LAN',
    departement: 'Informatique',
    filiere: 'ICT4D / Réseaux',
    niveau: 'L3',
    semestre: 'S6',
    credits: 6,
    heuresCM: 25,
    heuresTD: 15,
    heuresTP: 20,
    enseignant: 'Pr. Thomas DJOTIO NDIE',
    inscrits: 230,
    tauxReussite: 88.7,
    syllabus: 'Chiffrement asymétrique, signatures SHA-256 QR, WebRTC LAN LiveKit et pare-feux campus.',
  },
  {
    code: 'INF501',
    intitule: 'Ingénierie Systèmes Natifs Rust, Tauri v2 & Edge AI',
    departement: 'Informatique',
    filiere: 'Master Génie Logiciel',
    niveau: 'M2',
    semestre: 'S3',
    credits: 6,
    heuresCM: 20,
    heuresTD: 10,
    heuresTP: 30,
    enseignant: 'Pr. Maurice TCHUENTE',
    inscrits: 95,
    tauxReussite: 94.8,
    syllabus: 'Sécurité mémoire Rust, IPC Tauri v2, packaging MSIX Microsoft Store et inférence LLM locale.',
  },
];

export const INITIAL_ROOMS: RoomRecord[] = [
  {
    id: 'rm-amphi-1000',
    code: 'AMPHI-1000',
    nom: 'Amphithéâtre 1000',
    type: 'Amphithéâtre',
    batiment: 'Campus Principal Ngoa-Ekellé',
    capacite: 1000,
    statut: 'Occupée',
    coursActuel: 'INF111 — Algorithmique & C (L1)',
    enseignantActuel: 'Dr. Valéry MONTHE',
    equipements: ['Projecteur Laser 4K', 'Sonorisation UHF', 'Nœud LAN LiveKit', 'Borne QR Sentinelle'],
    lanNodeIp: '192.168.10.101',
  },
  {
    id: 'rm-amphi-500',
    code: 'AMPHI-500',
    nom: 'Amphithéâtre 500',
    type: 'Amphithéâtre',
    batiment: 'Faculté des Sciences',
    capacite: 500,
    statut: 'Occupée',
    coursActuel: 'ICT301 — Systèmes Distribués (L3 ICT4D)',
    enseignantActuel: 'Pr. Maurice TCHUENTE',
    equipements: ['Projecteur HD', 'Audio Sans Fil', 'Nœud LAN LiveKit', 'Caméra PTZ Auto-Track'],
    lanNodeIp: '192.168.10.102',
  },
  {
    id: 'rm-amphi-350',
    code: 'AMPHI-350',
    nom: 'Amphithéâtre 350 (Nouveau Bloc)',
    type: 'Amphithéâtre',
    batiment: 'Nouveau Bloc Pédagogique',
    capacite: 350,
    statut: 'Disponible',
    equipements: ['Projecteur HD', 'Tableau Interactif', 'Nœud LAN LiveKit'],
    lanNodeIp: '192.168.10.103',
  },
  {
    id: 'rm-salle-r108',
    code: 'SALLE-R108',
    nom: 'Salle R108 (Extension Info)',
    type: 'Salle TD',
    batiment: 'Département Informatique',
    capacite: 120,
    statut: 'Disponible',
    equipements: ['Projecteur', 'Wi-Fi 6 Campus', 'Prises Étudiants'],
    lanNodeIp: '192.168.10.108',
  },
  {
    id: 'rm-lab-s01',
    code: 'LAB-INFO-S01',
    nom: 'Laboratoire Informatique & IA S01',
    type: 'Laboratoire TP',
    batiment: 'Centre de Calcul UY1',
    capacite: 80,
    statut: 'Occupée',
    coursActuel: 'INF501 — TP Rust & Tauri v2 (M2)',
    enseignantActuel: 'Pr. Thomas DJOTIO NDIE',
    equipements: ['80 Postes Linux/Windows', 'Serveur GPU Local', 'Nœud LAN LiveKit 10Gbps'],
    lanNodeIp: '192.168.10.115',
  },
  {
    id: 'rm-amphi-250',
    code: 'AMPHI-250',
    nom: 'Amphithéâtre 250',
    type: 'Amphithéâtre',
    batiment: 'Ancien Décanat',
    capacite: 250,
    statut: 'En maintenance',
    equipements: ['Sonorisation (En révision)', 'Tableau Craie & Blanc'],
    lanNodeIp: '192.168.10.120',
  },
];

export const INITIAL_SCHEDULE: ScheduleSlot[] = [
  {
    id: 'sl-1',
    jour: 'Lundi',
    heureDebut: '07h30',
    heureFin: '10h30',
    ueCode: 'INF111',
    ueTitre: 'Algorithmique & C',
    type: 'CM',
    salle: 'AMPHI-1000',
    enseignant: 'Dr. Valéry MONTHE',
    filiere: 'Informatique / ICT4D',
    niveau: 'L1',
  },
  {
    id: 'sl-2',
    jour: 'Lundi',
    heureDebut: '10h45',
    heureFin: '13h45',
    ueCode: 'ICT301',
    ueTitre: 'Systèmes Distribués & Cloud',
    type: 'CM',
    salle: 'AMPHI-500',
    enseignant: 'Pr. Maurice TCHUENTE',
    filiere: 'ICT4D',
    niveau: 'L3',
    conflit: 'Conflit détecté : Amphi 500 demandé simultanément par MAT202 (résolu automatiquement vers AMPHI-350)',
  },
  {
    id: 'sl-3',
    jour: 'Mardi',
    heureDebut: '07h30',
    heureFin: '10h30',
    ueCode: 'INF204',
    ueTitre: 'Structures de Données Avancées',
    type: 'CM',
    salle: 'AMPHI-350',
    enseignant: 'Dr. Paulin MELATAGIA YONTA',
    filiere: 'Informatique',
    niveau: 'L2',
  },
  {
    id: 'sl-4',
    jour: 'Mardi',
    heureDebut: '14h00',
    heureFin: '17h00',
    ueCode: 'INF308',
    ueTitre: 'Sécurité Réseaux & Cryptographie',
    type: 'TP',
    salle: 'LAB-INFO-S01',
    enseignant: 'Pr. Thomas DJOTIO NDIE',
    filiere: 'ICT4D',
    niveau: 'L3',
  },
  {
    id: 'sl-5',
    jour: 'Mercredi',
    heureDebut: '07h30',
    heureFin: '10h30',
    ueCode: 'MAT101',
    ueTitre: 'Algèbre Linéaire',
    type: 'CM',
    salle: 'AMPHI-1000',
    enseignant: 'Pr. Jean-Claude NDOUMBE',
    filiere: 'Tronc Commun',
    niveau: 'L1',
  },
  {
    id: 'sl-6',
    jour: 'Jeudi',
    heureDebut: '10h45',
    heureFin: '13h45',
    ueCode: 'INF501',
    ueTitre: 'Architecture Rust & Tauri v2',
    type: 'TP',
    salle: 'LAB-INFO-S01',
    enseignant: 'Pr. Maurice TCHUENTE',
    filiere: 'Génie Logiciel',
    niveau: 'M2',
  },
  {
    id: 'sl-7',
    jour: 'Vendredi',
    heureDebut: '07h30',
    heureFin: '10h30',
    ueCode: 'ICT302',
    ueTitre: 'Interfaces Mobile & Desktop UX',
    type: 'TD',
    salle: 'SALLE-R108',
    enseignant: 'Dr. Paulin MELATAGIA YONTA',
    filiere: 'ICT4D',
    niveau: 'L3',
  },
  {
    id: 'sl-8',
    jour: 'Samedi',
    heureDebut: '07h30',
    heureFin: '10h30',
    ueCode: 'ICT301',
    ueTitre: 'Contrôle Continu — Systèmes Distribués',
    type: 'Examen',
    salle: 'AMPHI-500',
    enseignant: 'Pr. Maurice TCHUENTE',
    filiere: 'ICT4D',
    niveau: 'L3',
  },
];

export const INITIAL_CONFERENCES: ConferenceRoom[] = [
  {
    id: 'conf-lan-01',
    titre: 'ICT301 — Architecture Distribuée, Appwrite & Consensus Raft',
    ueCode: 'ICT301',
    enseignant: 'Pr. Maurice TCHUENTE',
    mode: 'LAN Campus (Hors-ligne)',
    participants: 184,
    maxParticipants: 300,
    statut: 'En direct',
    horaire: 'En cours • Démarré à 10h45',
    salleRelais: 'AMPHI-500 ⟷ SALLE-R108 (Relais LAN 0ms)',
    enregistrementActif: true,
  },
  {
    id: 'conf-cloud-02',
    titre: 'INF308 — Labo Cryptographie SHA-256 & Sécurité Réseaux',
    ueCode: 'INF308',
    enseignant: 'Pr. Thomas DJOTIO NDIE',
    mode: 'Cloud Hybride (VPS)',
    participants: 96,
    maxParticipants: 150,
    statut: 'En direct',
    horaire: 'En cours • Démarré à 14h00',
    salleRelais: 'vps.kernelforge.codes (LiveKit Edge)',
    enregistrementActif: true,
  },
  {
    id: 'conf-lan-03',
    titre: 'INF501 — Soutenance Projets Desktop Rust + Tauri v2',
    ueCode: 'INF501',
    enseignant: 'Dr. Paulin MELATAGIA YONTA',
    mode: 'LAN Campus (Hors-ligne)',
    participants: 42,
    maxParticipants: 100,
    statut: 'Planifiée',
    horaire: 'Demain • 10h00 – 13h00',
    salleRelais: 'LAB-INFO-S01 (192.168.10.115)',
    enregistrementActif: false,
  },
];

export const INITIAL_ANNOUNCEMENTS: AnnouncementItem[] = [
  {
    id: 'ann-01',
    titre: 'Publication du calendrier officiel des Examens de Fin de Semestre (S1 / S3 / S5)',
    categorie: 'Décanat Sciences',
    cible: 'Tous les étudiants L1–M2 • Faculté des Sciences',
    auteur: 'Décanat — Faculté des Sciences UY1',
    date: 'Aujourd’hui, 08:30',
    epingle: true,
    publie: true,
    vues: 2845,
    contenu:
      'Les emplois du temps définitifs des évaluations de fin de semestre sont synchronisés dans Uniflow work. Chaque étudiant doit présenter son badge QR cryptographique généré par l’application ainsi que son quitus de scolarité validé.',
  },
  {
    id: 'ann-02',
    titre: 'Déploiement officiel de Uniflow work Desktop (Store ID: 9NGZKFGK98K6)',
    categorie: 'Département Info',
    cible: 'Enseignants, Délégués & Administration',
    auteur: 'Collectif KERNEL FORGE • Direction Informatique',
    date: 'Hier, 16:15',
    epingle: true,
    publie: true,
    vues: 1920,
    contenu:
      'La version native Windows (.msi / .exe / Microsoft Store KERNELFORGE.Uniflowwork) et Linux (.deb / .AppImage / .rpm) est active dans toutes les salles et amphithéâtres avec le relais vidéo LAN LiveKit sans Internet.',
  },
  {
    id: 'ann-03',
    titre: 'Date limite de paiement de la 2ème tranche des droits universitaires (25 000 FCFA)',
    categorie: 'Scolarité & Bourses',
    cible: 'Étudiants L1, L2, L3, M1, M2',
    auteur: 'Division Financière & Scolarité',
    date: '14 Oct 2026',
    epingle: false,
    publie: true,
    vues: 3410,
    contenu:
      'Les règlements par MTN Mobile Money et Orange Money génèrent instantanément votre reçu signé numériquement et débloquent l’accès aux relevés de notes officiels.',
  },
];

export const KERNEL_FORGE_TEAM: TeamMember[] = [
  {
    id: 'ravel',
    rank: '01',
    name: 'NGHOMSI FEUKOUO RAVEL',
    role: 'Fondateur & Lead Architect',
    subTeam: 'Leadership, Architecture Cloud/Appwrite, Rust Tauri & IoT Sentinelle',
    email: 'ravelnghomsi@gmail.com',
    github: 'https://github.com/KERNEL-FORGE-G',
    portfolio: 'https://ravelnghomsi.me',
    isFounder: true,
    photoUrl: '/team/ravel.jpg',
    avatarAnimeUrl: '/team/avatar_ravel_founder.jpg',
    badges: ['Architecte Suprême', 'Visionnaire', 'Kernel Master'],
    bio: 'Fondateur du collectif KERNEL FORGE et concepteur principal de l’écosystème UniFlow (Web, Mobile & Desktop Uniflow work).',
    skills: [
      { label: 'Architecture Systèmes & Cloud', score: 98 },
      { label: 'Rust, Tauri v2 & Multiplateforme', score: 96 },
      { label: 'Bases Réparties & Appwrite', score: 94 },
    ],
  },
  {
    id: 'hassane',
    rank: '02',
    name: 'HASSANE YOUSSOUF OUMAR',
    role: 'Core Systems & Backend Engineer',
    subTeam: 'Backend Microservices, Réseaux & Pipelines CI/CD',
    email: 'h.hawadja1@gmail.com',
    github: 'https://github.com/Hawadja',
    portfolio: 'https://hawadja.github.io/portfolio/',
    photoUrl: '/team/hassane.jpg',
    avatarAnimeUrl: '/team/avatar_hassane_mascot.jpg',
    badges: ['Core Engine', 'Pipeline Pro', 'Reliability Guardian'],
    bio: 'Ingénieur systèmes en charge des moteurs backend distribués, de la synchronisation offline et des pipelines haute disponibilité.',
    skills: [
      { label: 'Backend & Microservices', score: 94 },
      { label: 'Réseaux & Sécurité', score: 90 },
      { label: 'DevOps & Conteneurs', score: 89 },
    ],
  },
  {
    id: 'sandra',
    rank: '03',
    name: 'FEBNCHAK SANDRA BORELLE',
    role: 'Full-Stack & Mobile UI/UX Engineer',
    subTeam: 'Design System, Expérience Utilisateur & Interfaces',
    email: 'sandraborelle0@gmail.com',
    github: 'https://github.com/sandra-borelle',
    photoUrl: '/team/sandra.jpg',
    avatarAnimeUrl: '/team/avatar_sandra_mascot.jpg',
    badges: ['Mobile UI/UX', 'Design System', 'Frontend Flow'],
    bio: 'Architecte de l’expérience utilisateur UniFlow et des planches ergonomiques haute densité pour étudiants et enseignants.',
    skills: [
      { label: 'Design UI/UX & Ergonomie', score: 94 },
      { label: 'React & TypeScript', score: 91 },
      { label: 'Flutter & Mobile', score: 93 },
    ],
  },
  {
    id: 'william',
    rank: '04',
    name: 'MELI WILLIAM',
    role: 'Infrastructure & Cybersecurity Engineer',
    subTeam: 'Réseaux Campus LAN, LiveKit WebRTC & Sécurité',
    email: 'meliwilliam74@gmail.com',
    github: 'https://github.com/WilliamMeli27',
    photoUrl: '/team/william.jpg',
    avatarAnimeUrl: '/team/avatar_william_mascot.jpg',
    badges: ['Network Architect', 'Security Guardian', 'LAN LiveKit Master'],
    bio: 'Responsable de l’infrastructure réseau locale (LAN Campus), du routage WebRTC sans Internet et du durcissement sécurité.',
    skills: [
      { label: 'Réseaux & Protocoles LAN', score: 94 },
      { label: 'Sécurité & Pare-feux', score: 90 },
      { label: 'Linux & Systèmes', score: 88 },
    ],
  },
  {
    id: 'mokam',
    rank: '05',
    name: 'MOKAM ZUNE Ange Gabrielle',
    role: 'Ingénieure Backend, Sécurité & APIs REST',
    subTeam: 'BaaS Appwrite, Webhooks & Paiements Mobile Money',
    email: 'gabriellemokam9@gmail.com',
    github: 'https://github.com/Ange55-star',
    photoUrl: '/team/mokam.jpg',
    avatarAnimeUrl: '/team/avatar_mokam_mascot.jpg',
    badges: ['Appwrite Architect', 'Fintech MoMo/OM', 'Webhooks Master'],
    bio: 'Spécialiste des APIs sécurisées, de la modélisation des bases Appwrite et de l’intégration des paiements universitaires MTN/Orange.',
    skills: [
      { label: 'APIs REST & Appwrite BaaS', score: 93 },
      { label: 'Intégration Mobile Money', score: 92 },
      { label: 'Sécurité des Données', score: 90 },
    ],
  },
  {
    id: 'aliya',
    rank: '06',
    name: 'Aliyatou Rachid Oumou Tourab',
    role: 'Frontend Desktop & Web Developer',
    subTeam: 'Tableaux de bord Académiques & Composants Desktop',
    email: 'oumou.aliyatou@facsciences-uy1.cm',
    github: 'https://github.com/aliya-nadi',
    photoUrl: '/team/aliya.jpg',
    avatarAnimeUrl: '/team/avatar_aliya_anime.jpg',
    badges: ['Desktop UI', 'React Specialist', 'Academic Workflows'],
    bio: 'Développeuse frontend dédiée aux vues de gestion académique, fiches étudiants et tableaux de bord analytiques.',
    skills: [
      { label: 'React & Tailwind CSS', score: 92 },
      { label: 'Visualisation de Données', score: 89 },
      { label: 'Accessibilité & Thèmes', score: 90 },
    ],
  },
  {
    id: 'judith',
    rank: '07',
    name: 'Mandeng Judith Oceanne',
    role: 'Mobile & Cross-Platform Developer',
    subTeam: 'Application Compagnon, Scan QR & Gamification',
    email: 'judithoceanne12@gmail.com',
    github: 'https://github.com/oceannemj',
    photoUrl: '/team/judith.jpg',
    avatarAnimeUrl: '/team/avatar_judith_anime.jpg',
    badges: ['Mobile App', 'QR Attendance', 'Widget Master'],
    bio: 'Ingénieure mobile en charge de la synchronisation temps réel des présences QR et des quêtes de gamification étudiante.',
    skills: [
      { label: 'Applications Cross-Platform', score: 91 },
      { label: 'Synchronisation Temps Réel', score: 88 },
      { label: 'Gamification & Quêtes', score: 90 },
    ],
  },
  {
    id: 'juvenal',
    rank: '08',
    name: 'SINENG KENGNI JUVENAL',
    role: 'Frontend Developer Multiplateforme',
    subTeam: 'Constructeur EDT, Algorithmes de Conflits & UI Réactive',
    email: 'sinengjuvenal@gmail.com',
    github: 'https://github.com/skjuv',
    photoUrl: '/team/juvenal.jpg',
    avatarAnimeUrl: '/team/avatar_juvenal_anime.jpg',
    badges: ['Fullstack UI', 'Timetable Engine', 'Responsive Design'],
    bio: 'Concepteur du constructeur interactif d’emploi du temps hebdomadaire et du moteur de détection de conflits de salles.',
    skills: [
      { label: 'Interfaces Complexes & Grilles', score: 92 },
      { label: 'TypeScript & État Réactif', score: 90 },
      { label: 'Optimisation Frontend', score: 88 },
    ],
  },
  {
    id: 'marcel',
    rank: '09',
    name: 'Tessoh Pekam Marcel',
    role: 'Chef Marketing & Développeur Frontend',
    subTeam: 'Communication Institutionnelle, Adoption Campus & UI',
    email: 'tesmarcel48@gmail.com',
    github: 'https://github.com/KERNEL-FORGE-G',
    photoUrl: '/team/marcel.jpg',
    avatarAnimeUrl: '/team/avatar_marcel_anime.jpg',
    badges: ['Marketing Lead', 'Campus Growth', 'Brand Identity'],
    bio: 'Responsable de la stratégie de déploiement campus, du centre de communication et de l’identité visuelle KERNEL FORGE.',
    skills: [
      { label: 'Stratégie & Adoption Campus', score: 94 },
      { label: 'Communication & Annonces', score: 91 },
      { label: 'Intégration Frontend', score: 87 },
    ],
  },
  {
    id: 'miguel',
    rank: '10',
    name: 'DJOMGUE Miguel',
    role: 'Desktop Application Developer',
    subTeam: 'Intégration Système Windows/Linux, Packaging & Tauri',
    email: 'djomgue.miguel@facsciences-uy1.cm',
    github: 'https://github.com/KERNEL-FORGE-G',
    photoUrl: '/team/miguel.jpg',
    avatarAnimeUrl: '/team/avatar_miguel_anime.jpg',
    badges: ['Desktop Native', 'Windows Store MSIX', 'Linux Bundler'],
    bio: 'Développeur spécialisé sur le poste de travail natif Uniflow work, l’intégration système et les installateurs multi-OS.',
    skills: [
      { label: 'Applications Desktop Natives', score: 93 },
      { label: 'Packaging MSI / DEB / AppImage', score: 91 },
      { label: 'Performance & Cache Local', score: 89 },
    ],
  },
];
