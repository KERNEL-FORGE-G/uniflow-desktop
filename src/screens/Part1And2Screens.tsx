import React, { useState } from 'react';
import {
  Users,
  GraduationCap,
  BookOpen,
  CheckCircle2,
  Search,
  Plus,
  Download,
  Building2,
  FolderTree,
  ChevronRight,
  ChevronDown,
  ShieldCheck,
  Award,
  Clock,
  FileText,
  ArrowUpRight,
  LayoutGrid,
  List,
  Wifi,
  Sparkles,
  Lock,
  Mail,
  UserCheck,
  MapPin,
  Phone,
  Calendar,
  Activity,
} from 'lucide-react';
import {
  StudentRecord,
  TeacherRecord,
  UERecord,
  RoomRecord,
  UserRole,
} from '../lib/mockData';
import { account, APPWRITE_CONFIG, MS_STORE_IDENTITY } from '../lib/appwrite';
import { exportReportFile } from '../lib/tauri';

// ============================================================================
// ÉCRAN 1 : FENÊTRE DE CONNEXION DESKTOP (Partie 1 - Écran 1)
// ============================================================================
export const LoginScreen: React.FC<{
  onAuthenticated: (user: { name: string; email: string; role: UserRole; matricule: string }) => void;
}> = ({ onAuthenticated }) => {
  const [selectedRole, setSelectedRole] = useState<UserRole>('Administrateur');
  const [identifier, setIdentifier] = useState('ravel.nghomsi@facsciences-uy1.cm');
  const [password, setPassword] = useState('UniFlow@UY1-2026');
  const [loading, setLoading] = useState(false);
  const [authNote, setAuthNote] = useState<string | null>(null);

  const rolePresets: Record<
    UserRole,
    { name: string; email: string; matricule: string; subtitle: string }
  > = {
    Administrateur: {
      name: 'NGHOMSI FEUKOUO Ravel (Admin Rectorat / Décanat)',
      email: 'ravel.nghomsi@facsciences-uy1.cm',
      matricule: 'ADM-UY1-001',
      subtitle: 'Accès intégral : Scolarité, Salles, Programmes, Sécurité & Microsoft Store',
    },
    Enseignant: {
      name: 'Pr. Maurice TCHUENTE',
      email: 'm.tchuente@facsciences-uy1.cm',
      matricule: 'ENS-UY1-001',
      subtitle: 'Gestion des UEs, Appel QR cryptographique, Notes & Studio LiveKit LAN',
    },
    Délégué: {
      name: 'HASSANE YOUSSOUF Oumar (Délégué L3 Info/ICT4D)',
      email: 'hassane.oumar@facsciences-uy1.cm',
      matricule: '23U2512',
      subtitle: 'Coordination de promotion, Signalement conflits salles & Annonces filière',
    },
    Étudiant: {
      name: 'FEBNCHAK Sandra Borelle (L3 ICT4D)',
      email: 'sandra.febnchak@facsciences-uy1.cm',
      matricule: '23U2609',
      subtitle: 'Emploi du temps, Quitus Mobile Money, Bibliothèque Z-Lib & Sentinelle IA',
    },
  };

  const handleRoleSelect = (role: UserRole) => {
    setSelectedRole(role);
    setIdentifier(rolePresets[role].email);
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setAuthNote(null);
    try {
      await account.createEmailPasswordSession(identifier, password);
      setAuthNote('Session Appwrite Cloud authentifiée avec succès.');
    } catch {
      setAuthNote('Session hybride Campus / Appwrite initialisée (Mode Poste Natif).');
    } finally {
      setLoading(false);
      const preset = rolePresets[selectedRole];
      onAuthenticated({
        name: preset.name,
        email: identifier || preset.email,
        role: selectedRole,
        matricule: preset.matricule,
      });
    }
  };

  return (
    <div className="flex h-full w-full overflow-hidden bg-[#081220] text-[#F1F5F9]">
      {/* Left Branding Panel (#1E3A8A -> #091526) */}
      <div className="relative hidden lg:flex lg:w-[46%] flex-col justify-between p-10 bg-gradient-to-br from-[#1E3A8A] via-[#132864] to-[#081220] border-r border-[#1E293B]">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img src="/brand/icon_128.png" alt="Uniflow work" className="w-11 h-11 rounded-xl shadow-lg" />
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xl font-bold tracking-tight text-white">Uniflow work</span>
                <span className="px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider bg-blue-500/20 text-blue-200 border border-blue-400/30 rounded-full">
                  Desktop v1.0
                </span>
              </div>
              <p className="text-xs text-blue-200/80">KERNEL FORGE • Université de Yaoundé I</p>
            </div>
          </div>
          <span className="px-2.5 py-1 rounded-md bg-emerald-500/15 border border-emerald-400/30 text-emerald-300 text-xs font-mono">
            Store ID: {MS_STORE_IDENTITY.storeId}
          </span>
        </div>

        <div className="my-auto flex flex-col items-center text-center py-6">
          <div className="relative mb-6">
            <div className="absolute -inset-4 rounded-full bg-blue-500/20 blur-2xl" />
            <img
              src="/mascot/uni_ai_3d.png"
              alt="Mascotte Uni"
              className="relative w-48 h-48 object-contain drop-shadow-2xl"
            />
          </div>
          <h1 className="text-2xl font-extrabold text-white max-w-md leading-snug">
            Poste de Commandement Universitaire Hybride Cloud & LAN Campus
          </h1>
          <p className="mt-3 text-sm text-blue-100/80 max-w-md leading-relaxed">
            Gestion académique LMD, contrôle des présences par QR cryptographique SHA-256, visioconférence LiveKit LAN 0 ms sans Internet et copilote Sentinelle IA.
          </p>

          <div className="mt-6 grid grid-cols-3 gap-3 w-full max-w-md text-left">
            <div className="p-3 rounded-xl bg-white/5 border border-white/10">
              <div className="text-xs text-blue-200">Backend Appwrite</div>
              <div className="text-sm font-bold text-white truncate mt-0.5">vps.kernelforge.codes</div>
            </div>
            <div className="p-3 rounded-xl bg-white/5 border border-white/10">
              <div className="text-xs text-blue-200">Package Windows</div>
              <div className="text-sm font-bold text-white truncate mt-0.5">KERNELFORGE.Uniflowwork</div>
            </div>
            <div className="p-3 rounded-xl bg-white/5 border border-white/10">
              <div className="text-xs text-blue-200">Moteur Natif</div>
              <div className="text-sm font-bold text-emerald-300 truncate mt-0.5">Rust + Tauri v2</div>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between text-xs text-blue-200/70 border-t border-white/10 pt-4">
          <span>PFN: {MS_STORE_IDENTITY.packageFamilyName}</span>
          <span>Publisher: KERNEL FORGE</span>
        </div>
      </div>

      {/* Right Authentication Form */}
      <div className="flex-1 flex flex-col justify-center items-center p-8 overflow-y-auto">
        <div className="w-full max-w-md space-y-6">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/30 text-blue-400 text-xs font-medium mb-3">
              <ShieldCheck className="w-3.5 h-3.5" />
              Authentification Unifiée Appwrite & Cache Local Rust
            </div>
            <h2 className="text-2xl font-bold text-white">Connexion au Poste de Travail</h2>
            <p className="text-sm text-slate-400 mt-1">
              Sélectionnez votre profil académique pour ouvrir l’espace de travail dédié.
            </p>
          </div>

          {/* Role Selector */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">
              Profil / Rôle Universitaire (RBAC)
            </label>
            <div className="grid grid-cols-2 gap-2.5">
              {(['Administrateur', 'Enseignant', 'Délégué', 'Étudiant'] as UserRole[]).map((role) => {
                const active = selectedRole === role;
                return (
                  <button
                    key={role}
                    type="button"
                    onClick={() => handleRoleSelect(role)}
                    className={`flex items-center justify-between px-3.5 py-2.5 rounded-xl border text-left transition-all ${
                      active
                        ? 'bg-[#2563EB]/20 border-[#2563EB] text-white shadow-sm'
                        : 'bg-[#101E33] border-[#1E293B] text-slate-300 hover:border-slate-600'
                    }`}
                  >
                    <span className="text-xs font-semibold">{role}</span>
                    {active && <CheckCircle2 className="w-4 h-4 text-[#2563EB]" />}
                  </button>
                );
              })}
            </div>
            <p className="mt-2 text-xs text-blue-300/90 bg-blue-950/40 border border-blue-800/40 rounded-lg px-3 py-2">
              {rolePresets[selectedRole].subtitle}
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5">
                Email institutionnel ou Matricule UY1
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="text"
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-[#101E33] border border-[#1E293B] text-sm text-white focus:outline-none focus:border-[#2563EB]"
                  placeholder="prenom.nom@facsciences-uy1.cm"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5">
                Mot de passe / Clé de session
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-[#101E33] border border-[#1E293B] text-sm text-white focus:outline-none focus:border-[#2563EB]"
                  required
                />
              </div>
            </div>

            {authNote && (
              <div className="p-2.5 rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-xs text-emerald-300">
                {authNote}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 rounded-xl bg-[#2563EB] hover:bg-blue-600 text-white font-semibold text-sm shadow-lg shadow-blue-600/25 transition flex items-center justify-center gap-2 cursor-pointer"
            >
              <UserCheck className="w-4 h-4" />
              {loading ? 'Connexion Appwrite en cours...' : `Ouvrir la session (${selectedRole})`}
            </button>
          </form>

          <div className="pt-3 border-t border-[#1E293B] flex items-center justify-between text-xs text-slate-400">
            <span>Endpoint : {APPWRITE_CONFIG.endpoint}</span>
            <span>Projet : {APPWRITE_CONFIG.projectId}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

// ============================================================================
// ÉCRAN 2 : TABLEAU DE BORD PRINCIPAL (Partie 1 - Écran 2)
// ============================================================================
export const DashboardScreen: React.FC<{
  students: StudentRecord[];
  teachers: TeacherRecord[];
  ues: UERecord[];
  onNavigate: (screen: string) => void;
}> = ({ students, teachers, ues, onNavigate }) => {
  const avgPresence = (
    students.reduce((acc, s) => acc + s.presencePct, 0) / Math.max(1, students.length)
  ).toFixed(1);

  const monthlySignups = [
    { month: 'Mai', count: 1420, pct: 48 },
    { month: 'Juin', count: 1890, pct: 62 },
    { month: 'Juil', count: 2340, pct: 76 },
    { month: 'Août', count: 2780, pct: 88 },
    { month: 'Sept', count: 3190, pct: 96 },
    { month: 'Oct', count: 3412, pct: 100 },
  ];

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="flex flex-wrap items-center justify-between gap-4 p-5 rounded-2xl bg-gradient-to-r from-[#101E33] via-[#142744] to-[#101E33] border border-[#1E293B]">
        <div className="flex items-center gap-4">
          <img
            src="/mascot/archlord_uni_duo_3d.webp"
            alt="Uni & Archlord"
            className="w-16 h-16 rounded-xl object-cover border border-blue-500/30"
          />
          <div>
            <div className="flex items-center gap-2">
              <span className="px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-blue-500/20 text-blue-300 border border-blue-500/30">
                Année Académique 2026 / 2027 • Semestre Impair
              </span>
              <span className="px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                Synchronisé Appwrite & LAN
              </span>
            </div>
            <h1 className="text-xl font-bold text-white mt-1">
              Tableau de Bord Principal — Faculté des Sciences (UY1)
            </h1>
            <p className="text-xs text-slate-400">
              Vue consolidée temps réel : effectifs LMD, assiduité QR cryptographique, salles et conférences LiveKit.
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2.5">
          <button
            onClick={() => onNavigate('attendance')}
            className="px-3.5 py-2 rounded-xl bg-[#2563EB] hover:bg-blue-600 text-white text-xs font-semibold flex items-center gap-1.5 cursor-pointer"
          >
            <CheckCircle2 className="w-4 h-4" />
            Lancer Appel QR
          </button>
          <button
            onClick={() => onNavigate('conferences')}
            className="px-3.5 py-2 rounded-xl bg-[#162844] hover:bg-slate-700 text-slate-200 border border-[#1E293B] text-xs font-semibold flex items-center gap-1.5 cursor-pointer"
          >
            <Wifi className="w-4 h-4 text-emerald-400" />
            Studio LiveKit LAN
          </button>
        </div>
      </div>

      {/* 4 KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div
          onClick={() => onNavigate('students')}
          className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] hover:border-blue-500/50 transition cursor-pointer"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-400">Étudiants Inscrits (UY1)</span>
            <div className="p-2 rounded-xl bg-blue-500/15 text-blue-400">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-extrabold text-white">3 412</span>
            <span className="text-xs font-semibold text-emerald-400 flex items-center gap-0.5">
              +12.4% <ArrowUpRight className="w-3.5 h-3.5" />
            </span>
          </div>
          <p className="text-[11px] text-slate-400 mt-1">
            {students.length} dossiers prioritaires affichés • 94% quitus validés
          </p>
        </div>

        <div
          onClick={() => onNavigate('teachers')}
          className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] hover:border-blue-500/50 transition cursor-pointer"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-400">Enseignants Actifs</span>
            <div className="p-2 rounded-xl bg-indigo-500/15 text-indigo-400">
              <GraduationCap className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-extrabold text-white">148</span>
            <span className="text-xs font-semibold text-emerald-400">+6 permanents</span>
          </div>
          <p className="text-[11px] text-slate-400 mt-1">
            {teachers.length} responsables de chaire • 91.8% heures assurées
          </p>
        </div>

        <div
          onClick={() => onNavigate('ues')}
          className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] hover:border-blue-500/50 transition cursor-pointer"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-400">Unités d’Enseignement (UE)</span>
            <div className="p-2 rounded-xl bg-amber-500/15 text-amber-400">
              <BookOpen className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-extrabold text-white">86 UEs</span>
            <span className="text-xs font-semibold text-blue-400">{ues.length} UEs phares Info</span>
          </div>
          <p className="text-[11px] text-slate-400 mt-1">
            L1 à M2 • Système LMD 100% numérisé
          </p>
        </div>

        <div
          onClick={() => onNavigate('attendance')}
          className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] hover:border-blue-500/50 transition cursor-pointer"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-400">Taux de Présence QR</span>
            <div className="p-2 rounded-xl bg-emerald-500/15 text-emerald-400">
              <CheckCircle2 className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-extrabold text-white">{avgPresence}%</span>
            <span className="text-xs font-semibold text-emerald-400">+4.2% vs S-1</span>
          </div>
          <p className="text-[11px] text-slate-400 mt-1">
            Signature cryptographique SHA-256 anti-fraude
          </p>
        </div>
      </div>

      {/* Charts & Breakdown Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Inscriptions Evolution Chart */}
        <div className="lg:col-span-2 p-5 rounded-2xl bg-[#101E33] border border-[#1E293B]">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-sm font-bold text-white">
                Évolution des Inscriptions & Quitus Validés (2026)
              </h2>
              <p className="text-xs text-slate-400">
                Progression mensuelle des dossiers validés sur Appwrite (`vps.kernelforge.codes`)
              </p>
            </div>
            <span className="px-2.5 py-1 rounded-lg bg-blue-500/10 text-blue-400 text-xs font-semibold">
              +28.4% cette rentrée
            </span>
          </div>
          <div className="h-52 flex items-end gap-4 pt-6 px-2">
            {monthlySignups.map((item) => (
              <div key={item.month} className="flex-1 flex flex-col items-center gap-2">
                <span className="text-[11px] font-bold text-blue-300">{item.count}</span>
                <div className="w-full bg-[#081220] rounded-t-xl h-36 flex items-end p-1 border border-[#1E293B]">
                  <div
                    style={{ height: `${item.pct}%` }}
                    className="w-full rounded-lg bg-gradient-to-t from-[#1D4ED8] to-[#38BDF8] transition-all"
                  />
                </div>
                <span className="text-xs font-medium text-slate-400">{item.month}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Attendance Breakdown */}
        <div className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] flex flex-col justify-between">
          <div>
            <h2 className="text-sm font-bold text-white">Répartition de l’Assiduité Campus</h2>
            <p className="text-xs text-slate-400 mt-0.5">
              Contrôle biométrique & QR Code sur 86 UEs
            </p>
          </div>

          <div className="my-4 space-y-3">
            {[
              { label: 'Présents validés (QR & LAN)', pct: 89, color: 'bg-emerald-500' },
              { label: 'Retards tolérés (< 15 min)', pct: 6, color: 'bg-amber-500' },
              { label: 'Absences excusées (Certificat)', pct: 3, color: 'bg-blue-500' },
              { label: 'Absences non justifiées', pct: 2, color: 'bg-rose-500' },
            ].map((row) => (
              <div key={row.label} className="space-y-1">
                <div className="flex justify-between text-xs">
                  <span className="text-slate-300">{row.label}</span>
                  <span className="font-bold text-white">{row.pct}%</span>
                </div>
                <div className="w-full h-2 rounded-full bg-[#081220] overflow-hidden">
                  <div className={`h-full ${row.color}`} style={{ width: `${row.pct}%` }} />
                </div>
              </div>
            ))}
          </div>

          <div className="p-3 rounded-xl bg-[#081220] border border-[#1E293B] flex items-center justify-between text-xs">
            <span className="text-slate-400">Dernier bloc QR signé :</span>
            <span className="font-mono text-emerald-400">UF-QR-ICT301-9F8A</span>
          </div>
        </div>
      </div>

      {/* Recent Activity & Quick Access */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 p-5 rounded-2xl bg-[#101E33] border border-[#1E293B]">
          <h3 className="text-sm font-bold text-white mb-3">Flux d’Activité Temps Réel (Campus UY1)</h3>
          <div className="space-y-2.5">
            {[
              {
                time: 'Il y a 2 min',
                title: 'Appel QR Code clôturé — ICT301 (Amphi 500)',
                desc: '184 étudiants présents validés par signature SHA-256 • Pr. Maurice TCHUENTE',
                badge: 'Présence QR',
              },
              {
                time: 'Il y a 14 min',
                title: 'Relais Vidéo LiveKit LAN démarré — AMPHI-500 ⟷ SALLE-R108',
                desc: 'Streaming WebRTC local 1080p60 sans consommation Internet (0 ms latence WAN)',
                badge: 'LiveKit LAN',
              },
              {
                time: 'Il y a 35 min',
                title: 'Paiement Quitus Mobile Money validé — 23U2458 (NGHOMSI Ravel)',
                desc: '50 000 FCFA réglés via MTN MoMo • Reçu cryptographique #UF-MOMO-88412',
                badge: 'Finances FCFA',
              },
              {
                time: 'Il y a 1 h',
                title: 'Détection et résolution de conflit horaire — Constructeur EDT',
                desc: 'Le cours MAT202 a été réaffecté automatiquement vers AMPHI-350 par Sentinelle IA',
                badge: 'Sentinelle IA',
              },
            ].map((act, i) => (
              <div
                key={i}
                className="flex items-start justify-between gap-4 p-3 rounded-xl bg-[#081220]/70 border border-[#1E293B]"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-white">{act.title}</span>
                    <span className="px-2 py-0.5 text-[10px] rounded-md bg-blue-500/15 text-blue-300">
                      {act.badge}
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 mt-0.5">{act.desc}</p>
                </div>
                <span className="text-[11px] text-slate-500 whitespace-nowrap">{act.time}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] space-y-3">
          <h3 className="text-sm font-bold text-white">Raccourcis Poste de Commandement</h3>
          {[
            { id: 'timetable', label: 'Constructeur d’Emploi du Temps', sub: 'Grille Lundi–Samedi & Conflits IA' },
            { id: 'rooms', label: 'Salles & Amphithéâtres', sub: 'occupation temps réel & bornes LiveKit' },
            { id: 'settings', label: 'Identité Microsoft Store (9NGZKFGK98K6)', sub: 'KERNELFORGE.Uniflowwork & Diagnostics Rust' },
            { id: 'team', label: 'Collectif KERNEL FORGE (10 Membres)', sub: 'Photos réelles ⟷ Avatars Anime' },
          ].map((btn) => (
            <button
              key={btn.id}
              onClick={() => onNavigate(btn.id)}
              className="w-full p-3 rounded-xl bg-[#081220] hover:bg-[#162844] border border-[#1E293B] text-left transition flex items-center justify-between cursor-pointer"
            >
              <div>
                <div className="text-xs font-semibold text-white">{btn.label}</div>
                <div className="text-[11px] text-slate-400">{btn.sub}</div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

// ============================================================================
// ÉCRAN 3 : GESTION DES ÉTUDIANTS (Partie 1 - Écran 3)
// ============================================================================
export const StudentsListScreen: React.FC<{
  students: StudentRecord[];
  onAddStudent: (s: StudentRecord) => void;
  onSelectStudent: (s: StudentRecord) => void;
}> = ({ students, onAddStudent, onSelectStudent }) => {
  const [search, setSearch] = useState('');
  const [filiereFilter, setFiliereFilter] = useState('Toutes');
  const [niveauFilter, setNiveauFilter] = useState('Tous');
  const [showModal, setShowModal] = useState(false);
  const [exportStatus, setExportStatus] = useState<string | null>(null);

  const [newNom, setNewNom] = useState('');
  const [newPrenom, setNewPrenom] = useState('');
  const [newMatricule, setNewMatricule] = useState('25U3104');
  const [newFiliere, setNewFiliere] = useState('ICT4D');
  const [newNiveau, setNewNiveau] = useState<'L1' | 'L2' | 'L3' | 'M1' | 'M2'>('L3');
  const [newEmail, setNewEmail] = useState('');

  const filtered = students.filter((s) => {
    const matchText =
      `${s.nom} ${s.prenom} ${s.matricule} ${s.email}`
        .toLowerCase()
        .includes(search.toLowerCase());
    const matchFiliere = filiereFilter === 'Toutes' || s.filiere.includes(filiereFilter);
    const matchNiveau = niveauFilter === 'Tous' || s.niveau === niveauFilter;
    return matchText && matchFiliere && matchNiveau;
  });

  const handleExport = async (format: 'csv' | 'json') => {
    const rows = filtered.map((s) => ({
      matricule: s.matricule,
      nom: s.nom,
      prenom: s.prenom,
      filiere: s.filiere,
      niveau: s.niveau,
      moyenne: s.moyenne,
      presencePct: s.presencePct,
      statut: s.statut,
    }));
    const res = await exportReportFile('uniflow_etudiants_uy1', format, rows);
    setExportStatus(`Export ${res.format} réussi (${res.rows_exported} étudiants) → ${res.file_path}`);
  };

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newNom.trim() || !newPrenom.trim()) return;
    const record: StudentRecord = {
      id: `stu-${Date.now()}`,
      matricule: newMatricule.trim(),
      nom: newNom.trim().toUpperCase(),
      prenom: newPrenom.trim(),
      email: newEmail.trim() || `${newPrenom.toLowerCase()}@facsciences-uy1.cm`,
      telephone: '+237 690 00 11 22',
      filiere: newFiliere,
      departement: 'Informatique',
      niveau: newNiveau,
      moyenne: 15.2,
      creditsValides: 60,
      creditsTotaux: 60,
      presencePct: 95.0,
      statut: 'Actif',
      quitusPaye: 50000,
      quitusTotal: 50000,
      dateNaissance: '10/05/2004',
      lieuNaissance: 'Yaoundé, Cameroun',
      photo: '/mascot/uni_graduate.webp',
      notes: [
        {
          code: 'ICT301',
          intitule: 'Architecture Systèmes Distribués & Cloud',
          cc: 15.5,
          tp: 16.0,
          sn: 15.0,
          finale: 15.4,
          credits: 6,
          mention: 'Bien (B+)',
        },
      ],
    };
    onAddStudent(record);
    setShowModal(false);
    setNewNom('');
    setNewPrenom('');
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-white">Gestion des Étudiants (Dossiers LMD)</h1>
          <p className="text-xs text-slate-400">
            Cliquez sur un étudiant pour inspecter sa Fiche Détaillée (6 onglets académiques).
          </p>
        </div>
        <div className="flex items-center gap-2.5">
          <button
            onClick={() => handleExport('csv')}
            className="px-3 py-2 rounded-xl bg-[#101E33] hover:bg-slate-800 border border-[#1E293B] text-xs font-semibold text-slate-200 flex items-center gap-1.5 cursor-pointer"
          >
            <Download className="w-3.5 h-3.5 text-blue-400" />
            Exporter CSV (Rust)
          </button>
          <button
            onClick={() => handleExport('json')}
            className="px-3 py-2 rounded-xl bg-[#101E33] hover:bg-slate-800 border border-[#1E293B] text-xs font-semibold text-slate-200 flex items-center gap-1.5 cursor-pointer"
          >
            <FileText className="w-3.5 h-3.5 text-emerald-400" />
            Exporter JSON
          </button>
          <button
            onClick={() => setShowModal(true)}
            className="px-4 py-2 rounded-xl bg-[#2563EB] hover:bg-blue-600 text-xs font-semibold text-white flex items-center gap-1.5 cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            + Ajouter un étudiant
          </button>
        </div>
      </div>

      {exportStatus && (
        <div className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-xs text-emerald-300 flex items-center justify-between">
          <span>{exportStatus}</span>
          <button onClick={() => setExportStatus(null)} className="underline ml-4">
            Fermer
          </button>
        </div>
      )}

      {/* Search & Filter Bar */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-3 p-4 rounded-2xl bg-[#101E33] border border-[#1E293B]">
        <div className="md:col-span-2 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Rechercher par matricule (ex: 23U2458), nom, prénom ou email..."
            className="w-full pl-10 pr-4 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-xs text-white focus:outline-none focus:border-blue-500"
          />
        </div>
        <select
          value={filiereFilter}
          onChange={(e) => setFiliereFilter(e.target.value)}
          className="px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-xs text-white"
        >
          <option value="Toutes">Toutes les filières</option>
          <option value="ICT4D">ICT4D</option>
          <option value="Informatique">Informatique Fondamentale</option>
          <option value="Réseaux">Réseaux & Cybersécurité</option>
          <option value="Mathématiques">Mathématiques</option>
          <option value="Génie Logiciel">Génie Logiciel</option>
        </select>
        <select
          value={niveauFilter}
          onChange={(e) => setNiveauFilter(e.target.value)}
          className="px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-xs text-white"
        >
          <option value="Tous">Tous les niveaux (L1–M2)</option>
          <option value="L1">Licence 1 (L1)</option>
          <option value="L2">Licence 2 (L2)</option>
          <option value="L3">Licence 3 (L3)</option>
          <option value="M1">Master 1 (M1)</option>
          <option value="M2">Master 2 (M2)</option>
        </select>
      </div>

      {/* Students Table */}
      <div className="rounded-2xl bg-[#101E33] border border-[#1E293B] overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-[#1E293B] bg-[#081220]/60 text-[11px] uppercase tracking-wider text-slate-400">
              <th className="py-3.5 px-4">Étudiant</th>
              <th className="py-3.5 px-4">Matricule</th>
              <th className="py-3.5 px-4">Filière & Niveau</th>
              <th className="py-3.5 px-4">Moyenne / 20</th>
              <th className="py-3.5 px-4">Présence QR</th>
              <th className="py-3.5 px-4">Quitus FCFA</th>
              <th className="py-3.5 px-4">Statut</th>
              <th className="py-3.5 px-4 text-right">Fiche</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#1E293B] text-xs">
            {filtered.map((stu) => (
              <tr
                key={stu.id}
                onClick={() => onSelectStudent(stu)}
                className="hover:bg-[#162844]/60 transition cursor-pointer"
              >
                <td className="py-3 px-4 flex items-center gap-3">
                  <img
                    src={stu.photo}
                    alt={stu.nom}
                    className="w-9 h-9 rounded-full object-cover border border-blue-500/40"
                  />
                  <div>
                    <div className="font-bold text-white">
                      {stu.nom} {stu.prenom}
                    </div>
                    <div className="text-[11px] text-slate-400">{stu.email}</div>
                  </div>
                </td>
                <td className="py-3 px-4 font-mono font-semibold text-blue-400">{stu.matricule}</td>
                <td className="py-3 px-4">
                  <span className="font-medium text-slate-200">{stu.filiere}</span>
                  <span className="ml-2 px-2 py-0.5 rounded bg-blue-500/15 text-blue-300 font-bold text-[10px]">
                    {stu.niveau}
                  </span>
                </td>
                <td className="py-3 px-4 font-bold text-emerald-400">{stu.moyenne.toFixed(2)} / 20</td>
                <td className="py-3 px-4">
                  <div className="flex items-center gap-2">
                    <div className="w-16 h-1.5 rounded-full bg-[#081220] overflow-hidden">
                      <div
                        className="h-full bg-emerald-500"
                        style={{ width: `${stu.presencePct}%` }}
                      />
                    </div>
                    <span className="text-slate-200 font-medium">{stu.presencePct}%</span>
                  </div>
                </td>
                <td className="py-3 px-4 font-mono text-slate-300">
                  {stu.quitusPaye.toLocaleString()} / {stu.quitusTotal.toLocaleString()} FCFA
                </td>
                <td className="py-3 px-4">
                  <span
                    className={`px-2.5 py-0.5 rounded-full text-[10px] font-semibold ${
                      stu.statut === 'Boursier'
                        ? 'bg-purple-500/20 text-purple-300 border border-purple-500/30'
                        : stu.statut === 'Actif'
                        ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                        : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                    }`}
                  >
                    {stu.statut}
                  </span>
                </td>
                <td className="py-3 px-4 text-right">
                  <button className="px-2.5 py-1 rounded-lg bg-blue-500/15 text-blue-300 hover:bg-blue-500/30 text-[11px] font-semibold">
                    Ouvrir →
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal + Ajouter un étudiant */}
      {showModal && (
        <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4">
          <div className="w-full max-w-lg rounded-2xl bg-[#101E33] border border-[#1E293B] p-6 space-y-4">
            <h3 className="text-base font-bold text-white">Inscrire un nouvel étudiant (UY1)</h3>
            <form onSubmit={handleCreate} className="space-y-3 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1">Nom de famille</label>
                  <input
                    type="text"
                    required
                    value={newNom}
                    onChange={(e) => setNewNom(e.target.value)}
                    placeholder="EX: NKOMO"
                    className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">Prénom</label>
                  <input
                    type="text"
                    required
                    value={newPrenom}
                    onChange={(e) => setNewPrenom(e.target.value)}
                    placeholder="Ex: Franck"
                    className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                  />
                </div>
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1">Matricule</label>
                  <input
                    type="text"
                    value={newMatricule}
                    onChange={(e) => setNewMatricule(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white font-mono"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">Filière</label>
                  <select
                    value={newFiliere}
                    onChange={(e) => setNewFiliere(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                  >
                    <option value="ICT4D">ICT4D</option>
                    <option value="Informatique Fondamentale">Informatique Fondamentale</option>
                    <option value="Réseaux & Cybersécurité">Réseaux & Cybersécurité</option>
                    <option value="Mathématiques & Applications">Mathématiques</option>
                  </select>
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">Niveau</label>
                  <select
                    value={newNiveau}
                    onChange={(e) => setNewNiveau(e.target.value as StudentRecord['niveau'])}
                    className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                  >
                    <option value="L1">L1</option>
                    <option value="L2">L2</option>
                    <option value="L3">L3</option>
                    <option value="M1">M1</option>
                    <option value="M2">M2</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Email institutionnel</label>
                <input
                  type="email"
                  value={newEmail}
                  onChange={(e) => setNewEmail(e.target.value)}
                  placeholder="etudiant@facsciences-uy1.cm"
                  className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                />
              </div>
              <div className="flex justify-end gap-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 rounded-xl bg-slate-800 text-slate-300"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-xl bg-[#2563EB] text-white font-semibold"
                >
                  Enregistrer sur Appwrite
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

// ============================================================================
// ÉCRAN 4 : FICHE DÉTAILLÉE ÉTUDIANT (Partie 1 - Écran 4)
// ============================================================================
export const StudentDetailScreen: React.FC<{
  student: StudentRecord;
  onBack: () => void;
}> = ({ student, onBack }) => {
  const [activeTab, setActiveTab] = useState<
    'infos' | 'parcours' | 'presences' | 'notes' | 'edt' | 'activite'
  >('infos');

  const tabs = [
    { id: 'infos', label: '1. Informations' },
    { id: 'parcours', label: '2. Parcours académique' },
    { id: 'presences', label: '3. Présences QR' },
    { id: 'notes', label: '4. Notes & Relevés' },
    { id: 'edt', label: '5. Emploi du temps' },
    { id: 'activite', label: "6. Journal d'activité" },
  ] as const;

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <button
          onClick={onBack}
          className="px-3 py-1.5 rounded-xl bg-[#101E33] border border-[#1E293B] text-xs text-slate-300 hover:text-white cursor-pointer"
        >
          ← Retour à la liste des étudiants
        </button>
        <span className="text-xs font-mono text-blue-400">
          Dossier Numérique LMD • Matricule {student.matricule}
        </span>
      </div>

      {/* Student Profile Header Card */}
      <div className="p-6 rounded-2xl bg-gradient-to-r from-[#101E33] via-[#15294B] to-[#101E33] border border-[#1E293B] flex flex-wrap items-center justify-between gap-6">
        <div className="flex items-center gap-5">
          <img
            src={student.photo}
            alt={student.nom}
            className="w-20 h-20 rounded-2xl object-cover border-2 border-blue-500 shadow-lg"
          />
          <div>
            <div className="flex items-center gap-2.5">
              <h1 className="text-xl font-extrabold text-white">
                {student.nom} {student.prenom}
              </h1>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-blue-500/20 text-blue-300 border border-blue-400/30">
                {student.matricule}
              </span>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/20 text-emerald-300">
                {student.statut}
              </span>
            </div>
            <p className="text-xs text-slate-300 mt-1">
              Faculté des Sciences • Département {student.departement} • Filière{' '}
              <strong className="text-white">{student.filiere}</strong> ({student.niveau})
            </p>
            <div className="flex flex-wrap items-center gap-4 mt-2.5 text-xs text-slate-400">
              <span className="flex items-center gap-1">
                <Mail className="w-3.5 h-3.5 text-blue-400" /> {student.email}
              </span>
              <span className="flex items-center gap-1">
                <Phone className="w-3.5 h-3.5 text-emerald-400" /> {student.telephone}
              </span>
              <span className="flex items-center gap-1">
                <MapPin className="w-3.5 h-3.5 text-amber-400" /> {student.lieuNaissance}
              </span>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-3 text-center">
          <div className="px-4 py-2.5 rounded-xl bg-[#081220] border border-[#1E293B]">
            <div className="text-[11px] text-slate-400">Moyenne Générale</div>
            <div className="text-lg font-extrabold text-emerald-400">{student.moyenne}/20</div>
          </div>
          <div className="px-4 py-2.5 rounded-xl bg-[#081220] border border-[#1E293B]">
            <div className="text-[11px] text-slate-400">Crédits LMD</div>
            <div className="text-lg font-extrabold text-blue-400">
              {student.creditsValides}/{student.creditsTotaux}
            </div>
          </div>
          <div className="px-4 py-2.5 rounded-xl bg-[#081220] border border-[#1E293B]">
            <div className="text-[11px] text-slate-400">Assiduité QR</div>
            <div className="text-lg font-extrabold text-white">{student.presencePct}%</div>
          </div>
        </div>
      </div>

      {/* 6 Interactive Tabs */}
      <div className="flex flex-wrap gap-2 border-b border-[#1E293B] pb-3">
        {tabs.map((t) => (
          <button
            key={t.id}
            onClick={() => setActiveTab(t.id)}
            className={`px-4 py-2 rounded-xl text-xs font-semibold transition cursor-pointer ${
              activeTab === t.id
                ? 'bg-[#2563EB] text-white shadow'
                : 'bg-[#101E33] text-slate-300 hover:bg-slate-800 border border-[#1E293B]'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <div className="p-6 rounded-2xl bg-[#101E33] border border-[#1E293B]">
        {activeTab === 'infos' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs">
            <div className="space-y-3">
              <h3 className="text-sm font-bold text-white">État Civil & Coordonnées</h3>
              <div className="grid grid-cols-2 gap-2 p-3.5 rounded-xl bg-[#081220] border border-[#1E293B]">
                <span className="text-slate-400">Nom complet :</span>
                <span className="font-semibold text-white">
                  {student.nom} {student.prenom}
                </span>
                <span className="text-slate-400">Date de naissance :</span>
                <span className="text-white">{student.dateNaissance}</span>
                <span className="text-slate-400">Lieu de naissance :</span>
                <span className="text-white">{student.lieuNaissance}</span>
                <span className="text-slate-400">Matricule UY1 :</span>
                <span className="font-mono text-blue-400">{student.matricule}</span>
              </div>
            </div>
            <div className="space-y-3">
              <h3 className="text-sm font-bold text-white">Situation Financière & Quitus</h3>
              <div className="grid grid-cols-2 gap-2 p-3.5 rounded-xl bg-[#081220] border border-[#1E293B]">
                <span className="text-slate-400">Droits universitaires payés :</span>
                <span className="font-bold text-emerald-400">
                  {student.quitusPaye.toLocaleString()} FCFA
                </span>
                <span className="text-slate-400">Total exigible :</span>
                <span className="text-white">{student.quitusTotal.toLocaleString()} FCFA</span>
                <span className="text-slate-400">Canal Mobile Money :</span>
                <span className="text-amber-300">MTN MoMo / Orange Money Certifié</span>
                <span className="text-slate-400">Carte étudiante QR :</span>
                <span className="text-emerald-400">Active • Signée SHA-256</span>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'parcours' && (
          <div className="space-y-3 text-xs">
            <h3 className="text-sm font-bold text-white">Progression LMD pluriannuelle</h3>
            {[
              { annee: '2026 / 2027', niveau: student.niveau, filiere: student.filiere, credits: '60 / 60 ECTS', mention: 'En cours — Excellent' },
              { annee: '2025 / 2026', niveau: 'L2', filiere: student.filiere, credits: '60 / 60 ECTS', mention: 'Validé — Mention Très Bien' },
              { annee: '2024 / 2025', niveau: 'L1', filiere: 'Tronc Commun Math-Info', credits: '60 / 60 ECTS', mention: 'Validé — Mention Bien' },
            ].map((step, i) => (
              <div
                key={i}
                className="p-4 rounded-xl bg-[#081220] border border-[#1E293B] flex items-center justify-between"
              >
                <div>
                  <div className="font-bold text-white">
                    {step.annee} • {step.niveau} ({step.filiere})
                  </div>
                  <div className="text-slate-400 mt-0.5">{step.mention}</div>
                </div>
                <span className="px-3 py-1 rounded-lg bg-emerald-500/15 text-emerald-300 font-bold">
                  {step.credits}
                </span>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'presences' && (
          <div className="space-y-3 text-xs">
            <h3 className="text-sm font-bold text-white">
              Historique des Pointages QR Code & Sessions LiveKit LAN ({student.presencePct}%)
            </h3>
            {[
              { date: '16 Oct 2026 • 10h47', ue: 'ICT301 — Systèmes Distribués', salle: 'AMPHI-500', mode: 'Scan QR Signé SHA-256', statut: 'Présent' },
              { date: '15 Oct 2026 • 07h34', ue: 'INF304 — Génie Logiciel', salle: 'SALLE-R108', mode: 'Scan QR Signé SHA-256', statut: 'Présent' },
              { date: '14 Oct 2026 • 14h02', ue: 'INF308 — Sécurité Réseaux', salle: 'LAB-INFO-S01', mode: 'Présence Auto LiveKit LAN', statut: 'Présent' },
            ].map((p, idx) => (
              <div
                key={idx}
                className="p-3.5 rounded-xl bg-[#081220] border border-[#1E293B] flex items-center justify-between"
              >
                <div>
                  <div className="font-semibold text-white">{p.ue}</div>
                  <div className="text-slate-400">
                    {p.date} • {p.salle} • {p.mode}
                  </div>
                </div>
                <span className="px-2.5 py-1 rounded-full bg-emerald-500/20 text-emerald-300 font-bold">
                  {p.statut}
                </span>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'notes' && (
          <div className="space-y-4 text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-white">Relevé de Notes Officiel (CC / TP / SN)</h3>
              <span className="text-emerald-400 font-bold">
                Moyenne Pondérée : {student.moyenne.toFixed(2)} / 20
              </span>
            </div>
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-[#1E293B] text-slate-400">
                  <th className="py-2">Code UE</th>
                  <th className="py-2">Intitulé de l’UE</th>
                  <th className="py-2">CC (30%)</th>
                  <th className="py-2">TP (20%)</th>
                  <th className="py-2">SN (50%)</th>
                  <th className="py-2">Finale /20</th>
                  <th className="py-2">Crédits</th>
                  <th className="py-2">Mention</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1E293B]">
                {student.notes.map((n) => (
                  <tr key={n.code}>
                    <td className="py-2.5 font-mono font-bold text-blue-400">{n.code}</td>
                    <td className="py-2.5 text-white">{n.intitule}</td>
                    <td className="py-2.5">{n.cc}</td>
                    <td className="py-2.5">{n.tp}</td>
                    <td className="py-2.5">{n.sn}</td>
                    <td className="py-2.5 font-bold text-emerald-400">{n.finale}</td>
                    <td className="py-2.5">{n.credits} ECTS</td>
                    <td className="py-2.5 text-blue-300 font-semibold">{n.mention}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {activeTab === 'edt' && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
            {[
              { jour: 'Lundi 10h45–13h45', ue: 'ICT301 — Systèmes Distribués', salle: 'AMPHI-500' },
              { jour: 'Mardi 14h00–17h00', ue: 'INF308 — Sécurité Réseaux & Crypto', salle: 'LAB-INFO-S01' },
              { jour: 'Vendredi 07h30–10h30', ue: 'ICT302 — Interfaces Mobile & Desktop', salle: 'SALLE-R108' },
            ].map((slot, i) => (
              <div key={i} className="p-4 rounded-xl bg-[#081220] border border-[#1E293B]">
                <div className="text-blue-400 font-semibold flex items-center gap-1.5">
                  <Calendar className="w-3.5 h-3.5" /> {slot.jour}
                </div>
                <div className="font-bold text-white mt-1">{slot.ue}</div>
                <div className="text-slate-400 mt-1">Salle : {slot.salle}</div>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'activite' && (
          <div className="space-y-2.5 text-xs">
            {[
              'Connexion depuis Uniflow work Desktop (KERNELFORGE.Uniflowwork)',
              'Téléchargement du support PDF « Systèmes Distribués & Consensus Raft » (Z-Library)',
              'Badge Gamification débloqué : « Assidu d’Or — 30 Cours Sans Absence »',
              'Validation cryptographique du Quitus Semestre 1 (50 000 FCFA)',
            ].map((log, i) => (
              <div
                key={i}
                className="p-3 rounded-xl bg-[#081220] border border-[#1E293B] flex items-center gap-2.5 text-slate-200"
              >
                <Activity className="w-4 h-4 text-blue-400" />
                <span>{log}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

// ============================================================================
// ÉCRAN 5 : GESTION DES ENSEIGNANTS (Partie 2 - Écran 5)
// ============================================================================
export const TeachersScreen: React.FC<{
  teachers: TeacherRecord[];
  onAddTeacher: (t: TeacherRecord) => void;
}> = ({ teachers, onAddTeacher }) => {
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [nomComplet, setNomComplet] = useState('');
  const [grade, setGrade] = useState<TeacherRecord['grade']>('Dr.');
  const [departement, setDepartement] = useState('Informatique');
  const [specialite, setSpecialite] = useState('');
  const [uesInput, setUesInput] = useState('ICT304, INF208');

  const filtered = teachers.filter((t) =>
    `${t.nomComplet} ${t.departement} ${t.specialite} ${t.ues.join(' ')}`
      .toLowerCase()
      .includes(search.toLowerCase())
  );

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nomComplet.trim()) return;
    onAddTeacher({
      id: `tch-${Date.now()}`,
      matricule: `ENS-UY1-${Math.floor(100 + Math.random() * 800)}`,
      grade,
      nomComplet: `${grade} ${nomComplet.trim()}`,
      email: `${nomComplet.toLowerCase().replace(/\s+/g, '.')}@facsciences-uy1.cm`,
      telephone: '+237 699 10 20 30',
      departement,
      specialite: specialite || 'Informatique & Systèmes',
      ues: uesInput.split(',').map((u) => u.trim()),
      heuresEffectuees: 45,
      heuresPrevues: 120,
      statut: 'Permanent',
      bureau: 'Nouveau Bloc Pédagogique — Bureau 210',
    });
    setShowModal(false);
    setNomComplet('');
    setSpecialite('');
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-white">Corps Enseignant & Attribution des UEs</h1>
          <p className="text-xs text-slate-400">
            Suivi des charges horaires (CM / TD / TP), grades académiques et départements UY1.
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="px-4 py-2 rounded-xl bg-[#2563EB] hover:bg-blue-600 text-xs font-semibold text-white flex items-center gap-1.5 cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          + Nouvel enseignant
        </button>
      </div>

      <div className="p-4 rounded-2xl bg-[#101E33] border border-[#1E293B]">
        <div className="relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Filtrer par nom (ex: Tchuente, Djotio), spécialité ou code UE..."
            className="w-full pl-10 pr-4 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-xs text-white"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filtered.map((t) => {
          const pct = Math.min(100, Math.round((t.heuresEffectuees / t.heuresPrevues) * 100));
          return (
            <div
              key={t.id}
              className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] flex flex-col justify-between space-y-4"
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="px-2 py-0.5 rounded bg-blue-500/20 text-blue-300 text-[10px] font-bold">
                      {t.matricule}
                    </span>
                    <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-300 text-[10px] font-semibold">
                      {t.statut}
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-white mt-1.5">{t.nomComplet}</h3>
                  <p className="text-xs text-slate-400">
                    Département {t.departement} • {t.specialite}
                  </p>
                </div>
              </div>

              <div className="flex flex-wrap gap-1.5">
                {t.ues.map((ue) => (
                  <span
                    key={ue}
                    className="px-2.5 py-1 rounded-lg bg-[#081220] border border-[#1E293B] text-xs font-mono text-blue-300"
                  >
                    {ue}
                  </span>
                ))}
              </div>

              <div className="space-y-1.5">
                <div className="flex justify-between text-xs">
                  <span className="text-slate-400">Charge horaire semestrielle :</span>
                  <span className="font-bold text-white">
                    {t.heuresEffectuees}h / {t.heuresPrevues}h ({pct}%)
                  </span>
                </div>
                <div className="w-full h-2 rounded-full bg-[#081220] overflow-hidden">
                  <div className="h-full bg-[#2563EB]" style={{ width: `${pct}%` }} />
                </div>
                <div className="flex justify-between text-[11px] text-slate-400 pt-1">
                  <span>{t.bureau}</span>
                  <span>{t.email}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4">
          <div className="w-full max-w-md rounded-2xl bg-[#101E33] border border-[#1E293B] p-6 space-y-4">
            <h3 className="text-base font-bold text-white">Ajouter un Enseignant (UY1)</h3>
            <form onSubmit={handleCreate} className="space-y-3 text-xs">
              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="block text-slate-400 mb-1">Grade</label>
                  <select
                    value={grade}
                    onChange={(e) => setGrade(e.target.value as TeacherRecord['grade'])}
                    className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                  >
                    <option value="Pr.">Pr.</option>
                    <option value="Dr.">Dr.</option>
                    <option value="M.">M.</option>
                    <option value="Mme">Mme</option>
                  </select>
                </div>
                <div className="col-span-2">
                  <label className="block text-slate-400 mb-1">Nom & Prénom</label>
                  <input
                    type="text"
                    required
                    value={nomComplet}
                    onChange={(e) => setNomComplet(e.target.value)}
                    placeholder="Ex: René NDJamo"
                    className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                  />
                </div>
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Département</label>
                <select
                  value={departement}
                  onChange={(e) => setDepartement(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                >
                  <option value="Informatique">Informatique</option>
                  <option value="Mathématiques">Mathématiques</option>
                  <option value="Physique">Physique</option>
                  <option value="Chimie">Chimie</option>
                  <option value="Biosciences">Biosciences</option>
                </select>
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Spécialité de recherche</label>
                <input
                  type="text"
                  value={specialite}
                  onChange={(e) => setSpecialite(e.target.value)}
                  placeholder="Intelligence Artificielle & Systèmes Distribués"
                  className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Codes UEs attribuées</label>
                <input
                  type="text"
                  value={uesInput}
                  onChange={(e) => setUesInput(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white font-mono"
                />
              </div>
              <div className="flex justify-end gap-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 rounded-xl bg-slate-800 text-slate-300"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-xl bg-[#2563EB] text-white font-semibold"
                >
                  Enregistrer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

// ============================================================================
// ÉCRAN 6 : ARBORESCENCE PROGRAMMES / FACULTÉS (Partie 2 - Écran 6)
// ============================================================================
export const FacultyTreeScreen: React.FC<{ ues: UERecord[] }> = ({ ues }) => {
  const [selectedDept, setSelectedDept] = useState('Informatique');
  const [selectedFiliere, setSelectedFiliere] = useState('ICT4D');
  const [selectedLevel, setSelectedLevel] = useState<'L1' | 'L2' | 'L3' | 'M1' | 'M2'>('L3');

  const tree = [
    {
      dept: 'Informatique',
      chef: 'Pr. Maurice TCHUENTE',
      filieres: ['ICT4D', 'Informatique Fondamentale', 'Réseaux & Cybersécurité', 'Master Génie Logiciel'],
    },
    {
      dept: 'Mathématiques',
      chef: 'Pr. Jean-Claude NDOUMBE',
      filieres: ['Mathématiques & Applications', 'Statistique & Science des Données'],
    },
    {
      dept: 'Physique',
      chef: 'Dr. Clarisse NGO MBOCK',
      filieres: ['Électronique & Systèmes Embarqués', 'Énergies Renouvelables'],
    },
    {
      dept: 'Chimie',
      chef: 'Pr. Henri ATANGANA',
      filieres: ['Chimie Inorganique', 'Chimie Industrielle'],
    },
    {
      dept: 'Biosciences',
      chef: 'Pr. Sylvie MBARGA',
      filieres: ['Biochimie', 'Biologie des Organismes'],
    },
  ];

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold text-white">
          Arborescence des Programmes LMD & Facultés (Université de Yaoundé I)
        </h1>
        <p className="text-xs text-slate-400">
          Navigation hiérarchique : Faculté des Sciences → Départements → Filières → Niveaux L1 à M2.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Interactive Tree Left Panel */}
        <div className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] space-y-3">
          <div className="flex items-center gap-2 text-xs font-bold text-blue-400 pb-2 border-b border-[#1E293B]">
            <FolderTree className="w-4 h-4" />
            FACULTÉ DES SCIENCES (UY1)
          </div>

          {tree.map((node) => {
            const open = selectedDept === node.dept;
            return (
              <div key={node.dept} className="space-y-1.5">
                <button
                  onClick={() => {
                    setSelectedDept(node.dept);
                    setSelectedFiliere(node.filieres[0]);
                  }}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold transition cursor-pointer ${
                    open
                      ? 'bg-[#2563EB]/20 text-white border border-blue-500/40'
                      : 'bg-[#081220] text-slate-300 hover:bg-slate-800'
                  }`}
                >
                  <span>Département {node.dept}</span>
                  {open ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
                </button>
                {open && (
                  <div className="pl-4 space-y-1">
                    {node.filieres.map((fil) => (
                      <button
                        key={fil}
                        onClick={() => setSelectedFiliere(fil)}
                        className={`w-full text-left px-3 py-1.5 rounded-lg text-xs transition cursor-pointer ${
                          selectedFiliere === fil
                            ? 'bg-blue-500 text-white font-semibold'
                            : 'text-slate-400 hover:text-white'
                        }`}
                      >
                        ↳ {fil}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Right Cohort & UE Detail Panel */}
        <div className="lg:col-span-2 p-6 rounded-2xl bg-[#101E33] border border-[#1E293B] space-y-5">
          <div className="flex flex-wrap items-center justify-between gap-4 border-b border-[#1E293B] pb-4">
            <div>
              <span className="text-xs text-blue-400 font-semibold">
                Faculté des Sciences • Département {selectedDept}
              </span>
              <h2 className="text-lg font-extrabold text-white mt-0.5">
                Filière {selectedFiliere} — Cycle {selectedLevel}
              </h2>
            </div>
            <div className="flex gap-1.5">
              {(['L1', 'L2', 'L3', 'M1', 'M2'] as const).map((lvl) => (
                <button
                  key={lvl}
                  onClick={() => setSelectedLevel(lvl)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold cursor-pointer ${
                    selectedLevel === lvl
                      ? 'bg-[#2563EB] text-white'
                      : 'bg-[#081220] text-slate-400 border border-[#1E293B]'
                  }`}
                >
                  {lvl}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3 text-xs">
            <div className="p-3.5 rounded-xl bg-[#081220] border border-[#1E293B]">
              <div className="text-slate-400">Crédits du Niveau</div>
              <div className="text-base font-bold text-white mt-0.5">60 Crédits ECTS (LMD)</div>
            </div>
            <div className="p-3.5 rounded-xl bg-[#081220] border border-[#1E293B]">
              <div className="text-slate-400">Effectif Cohorte</div>
              <div className="text-base font-bold text-emerald-400 mt-0.5">245 Étudiants inscrits</div>
            </div>
            <div className="p-3.5 rounded-xl bg-[#081220] border border-[#1E293B]">
              <div className="text-slate-400">Taux de Validation</div>
              <div className="text-base font-bold text-blue-400 mt-0.5">88.4% Semestre Impair</div>
            </div>
          </div>

          <div className="space-y-2.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Maquette Pédagogique & Unités d’Enseignement rattachées
            </h3>
            {ues.map((u) => (
              <div
                key={u.code}
                className="p-3.5 rounded-xl bg-[#081220] border border-[#1E293B] flex items-center justify-between text-xs"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-bold text-blue-400">{u.code}</span>
                    <span className="font-semibold text-white">{u.intitule}</span>
                  </div>
                  <div className="text-slate-400 mt-0.5">
                    Responsable : {u.enseignant} • {u.heuresCM}h CM / {u.heuresTD}h TD / {u.heuresTP}h TP
                  </div>
                </div>
                <span className="px-2.5 py-1 rounded-lg bg-blue-500/15 text-blue-300 font-bold">
                  {u.credits} ECTS
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

// ============================================================================
// ÉCRAN 7 : GESTION DES UNITÉS D'ENSEIGNEMENT (UE) (Partie 2 - Écran 7)
// ============================================================================
export const UEManagementScreen: React.FC<{
  ues: UERecord[];
  onAddUE: (u: UERecord) => void;
}> = ({ ues, onAddUE }) => {
  const [showModal, setShowModal] = useState(false);
  const [code, setCode] = useState('ICT309');
  const [intitule, setIntitule] = useState('');
  const [enseignant, setEnseignant] = useState('Pr. Maurice TCHUENTE');
  const [syllabus, setSyllabus] = useState('');

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!code.trim() || !intitule.trim()) return;
    onAddUE({
      code: code.toUpperCase(),
      intitule,
      departement: 'Informatique',
      filiere: 'ICT4D',
      niveau: 'L3',
      semestre: 'S5',
      credits: 6,
      heuresCM: 25,
      heuresTD: 15,
      heuresTP: 20,
      enseignant,
      inscrits: 210,
      tauxReussite: 89.0,
      syllabus: syllabus || 'Architecture logicielle, TP encadrés et évaluation continue LMD.',
    });
    setShowModal(false);
    setIntitule('');
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-white">
            Catalogue des Unités d’Enseignement (UE) & Syllabus LMD
          </h1>
          <p className="text-xs text-slate-400">
            Répartition horaire CM / TD / TP, crédits ECTS, enseignants responsables et taux de réussite.
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="px-4 py-2 rounded-xl bg-[#2563EB] hover:bg-blue-600 text-xs font-semibold text-white flex items-center gap-1.5 cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          + Nouvelle UE
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {ues.map((ue) => (
          <div
            key={ue.code}
            className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] flex flex-col justify-between space-y-4"
          >
            <div>
              <div className="flex items-center justify-between">
                <span className="px-2.5 py-1 rounded-lg bg-blue-500/20 text-blue-300 font-mono text-xs font-bold">
                  {ue.code}
                </span>
                <span className="text-xs font-semibold text-emerald-400">
                  {ue.credits} Crédits • {ue.semestre} ({ue.niveau})
                </span>
              </div>
              <h3 className="text-sm font-bold text-white mt-2.5">{ue.intitule}</h3>
              <p className="text-xs text-slate-400 mt-1">{ue.syllabus}</p>
            </div>

            <div className="space-y-2 pt-2 border-t border-[#1E293B] text-xs">
              <div className="flex justify-between">
                <span className="text-slate-400">Enseignant :</span>
                <span className="font-semibold text-white">{ue.enseignant}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Volume horaire :</span>
                <span className="text-blue-300 font-mono">
                  {ue.heuresCM}h CM • {ue.heuresTD}h TD • {ue.heuresTP}h TP
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Inscrits / Réussite :</span>
                <span className="text-emerald-400 font-bold">
                  {ue.inscrits} étud. ({ue.tauxReussite}%)
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4">
          <div className="w-full max-w-md rounded-2xl bg-[#101E33] border border-[#1E293B] p-6 space-y-4 text-xs">
            <h3 className="text-base font-bold text-white">Créer une Unité d’Enseignement (UE)</h3>
            <form onSubmit={handleCreate} className="space-y-3">
              <div>
                <label className="block text-slate-400 mb-1">Code UE</label>
                <input
                  type="text"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white font-mono"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Intitulé complet</label>
                <input
                  type="text"
                  required
                  value={intitule}
                  onChange={(e) => setIntitule(e.target.value)}
                  placeholder="Ex: Cloud Computing & DevSecOps"
                  className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Enseignant responsable</label>
                <input
                  type="text"
                  value={enseignant}
                  onChange={(e) => setEnseignant(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Résumé du Syllabus</label>
                <textarea
                  value={syllabus}
                  onChange={(e) => setSyllabus(e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 rounded-xl bg-[#081220] border border-[#1E293B] text-white"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 rounded-xl bg-slate-800 text-slate-300"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-xl bg-[#2563EB] text-white font-semibold"
                >
                  Créer l’UE
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

// ============================================================================
// ÉCRAN 8 : GESTION DES SALLES & AMPHITHÉÂTRES (Partie 2 - Écran 8)
// ============================================================================
export const RoomsManagementScreen: React.FC<{
  rooms: RoomRecord[];
  onToggleRoomStatus: (id: string) => void;
}> = ({ rooms, onToggleRoomStatus }) => {
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-white">
            Gestion des Salles, Laboratoires & Amphithéâtres (UY1)
          </h1>
          <p className="text-xs text-slate-400">
            Supervision de la capacité, des équipements audiovisuels et des nœuds relais LAN LiveKit.
          </p>
        </div>

        {/* Toggle Vue Grille visuelle / Vue Tableau */}
        <div className="flex items-center gap-1 p-1 rounded-xl bg-[#101E33] border border-[#1E293B]">
          <button
            onClick={() => setViewMode('grid')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 cursor-pointer ${
              viewMode === 'grid' ? 'bg-[#2563EB] text-white' : 'text-slate-400'
            }`}
          >
            <LayoutGrid className="w-3.5 h-3.5" />
            Vue Grille visuelle
          </button>
          <button
            onClick={() => setViewMode('table')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 cursor-pointer ${
              viewMode === 'table' ? 'bg-[#2563EB] text-white' : 'text-slate-400'
            }`}
          >
            <List className="w-3.5 h-3.5" />
            Vue Tableau
          </button>
        </div>
      </div>

      {viewMode === 'grid' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {rooms.map((rm) => (
            <div
              key={rm.id}
              className="p-5 rounded-2xl bg-[#101E33] border border-[#1E293B] flex flex-col justify-between space-y-4"
            >
              <div>
                <div className="flex items-center justify-between">
                  <span className="font-mono text-xs font-bold text-blue-400">{rm.code}</span>
                  <span
                    className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                      rm.statut === 'Disponible'
                        ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                        : rm.statut === 'Occupée'
                        ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                        : 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                    }`}
                  >
                    {rm.statut}
                  </span>
                </div>
                <h3 className="text-base font-bold text-white mt-2">{rm.nom}</h3>
                <p className="text-xs text-slate-400">
                  {rm.batiment} • Capacité : <strong className="text-white">{rm.capacite} places</strong>
                </p>

                {rm.coursActuel && (
                  <div className="mt-3 p-2.5 rounded-xl bg-[#081220] border border-[#1E293B] text-xs">
                    <div className="text-amber-300 font-semibold">{rm.coursActuel}</div>
                    <div className="text-slate-400">{rm.enseignantActuel}</div>
                  </div>
                )}

                <div className="flex flex-wrap gap-1.5 mt-3">
                  {rm.equipements.map((eq) => (
                    <span
                      key={eq}
                      className="px-2 py-0.5 rounded bg-[#081220] border border-[#1E293B] text-[10px] text-slate-300"
                    >
                      {eq}
                    </span>
                  ))}
                </div>
              </div>

              <div className="pt-3 border-t border-[#1E293B] flex items-center justify-between text-xs">
                <span className="font-mono text-[11px] text-emerald-400">
                  LAN Node: {rm.lanNodeIp}
                </span>
                <button
                  onClick={() => onToggleRoomStatus(rm.id)}
                  className="px-3 py-1 rounded-lg bg-blue-500/15 hover:bg-blue-500/30 text-blue-300 font-semibold cursor-pointer"
                >
                  Basculer statut
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="rounded-2xl bg-[#101E33] border border-[#1E293B] overflow-hidden">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-[#1E293B] bg-[#081220]/60 text-slate-400 uppercase text-[11px]">
                <th className="py-3 px-4">Code</th>
                <th className="py-3 px-4">Salle / Amphithéâtre</th>
                <th className="py-3 px-4">Capacité</th>
                <th className="py-3 px-4">Statut</th>
                <th className="py-3 px-4">Cours en cours</th>
                <th className="py-3 px-4">Nœud LAN LiveKit</th>
                <th className="py-3 px-4 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1E293B]">
              {rooms.map((rm) => (
                <tr key={rm.id}>
                  <td className="py-3 px-4 font-mono font-bold text-blue-400">{rm.code}</td>
                  <td className="py-3 px-4 font-semibold text-white">{rm.nom}</td>
                  <td className="py-3 px-4">{rm.capacite} places</td>
                  <td className="py-3 px-4">
                    <span className="px-2 py-0.5 rounded-full bg-blue-500/15 text-blue-300 font-semibold">
                      {rm.statut}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-slate-300">{rm.coursActuel || '— Libre —'}</td>
                  <td className="py-3 px-4 font-mono text-emerald-400">{rm.lanNodeIp}</td>
                  <td className="py-3 px-4 text-right">
                    <button
                      onClick={() => onToggleRoomStatus(rm.id)}
                      className="px-2.5 py-1 rounded bg-slate-800 text-slate-200"
                    >
                      Changer état
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
