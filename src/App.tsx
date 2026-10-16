import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  Users,
  GraduationCap,
  BookOpen,
  DoorOpen,
  Calendar,
  QrCode,
  Video,
  BarChart3,
  MessageSquare,
  Bell,
  Settings,
  UserCheck,
  FolderTree,
  Shield,
  Wifi,
  Sparkles,
  LogOut,
  RefreshCw,
  Minus,
  Square,
  X,
  CreditCard,
  Layers,
  HeartHandshake,
} from 'lucide-react';
import {
  UserRole,
  INITIAL_STUDENTS,
  INITIAL_TEACHERS,
  INITIAL_UES,
  INITIAL_ROOMS,
  StudentRecord,
  TeacherRecord,
  UERecord,
  RoomRecord,
} from './lib/mockData';
import {
  LoginScreen,
  DashboardScreen,
  StudentsListScreen,
  StudentDetailScreen,
  TeachersScreen,
  FacultyTreeScreen,
  UEManagementScreen,
  RoomsManagementScreen,
} from './screens/Part1And2Screens';
import { getStoreIdentity, getSystemDiagnostics, StoreIdentity, SystemDiagnostics } from './lib/tauri';
import { MS_STORE_IDENTITY, APPWRITE_CONFIG } from './lib/appwrite';

type ScreenId =
  | 'login'
  | 'dashboard'
  | 'students'
  | 'student_detail'
  | 'teachers'
  | 'structure'
  | 'ues'
  | 'rooms'
  | 'schedule'
  | 'attendance'
  | 'video'
  | 'analytics'
  | 'communications'
  | 'announcements'
  | 'settings'
  | 'profile'
  | 'team';

export default function App() {
  const [currentUser, setCurrentUser] = useState<{
    name: string;
    email: string;
    role: UserRole;
    matricule: string;
  } | null>({
    name: 'NGHOMSI FEUKOUO Ravel',
    email: 'ravel.nghomsi@facsciences-uy1.cm',
    role: 'Administrateur',
    matricule: 'ADM-UY1-001',
  });

  const [activeScreen, setActiveScreen] = useState<ScreenId>('dashboard');
  const [selectedStudentId, setSelectedStudentId] = useState<string>('std-001');

  // Données d'état partagées
  const [students, setStudents] = useState<StudentRecord[]>(INITIAL_STUDENTS);
  const [teachers, setTeachers] = useState<TeacherRecord[]>(INITIAL_TEACHERS);
  const [ues, setUes] = useState<UERecord[]>(INITIAL_UES);
  const [rooms, setRooms] = useState<RoomRecord[]>(INITIAL_ROOMS);

  // Diagnostics système & Identité Microsoft Store
  const [storeIdentity, setStoreIdentity] = useState<StoreIdentity | null>(null);
  const [diagnostics, setDiagnostics] = useState<SystemDiagnostics | null>(null);

  useEffect(() => {
    getStoreIdentity().then(setStoreIdentity).catch(() => {});
    getSystemDiagnostics().then(setDiagnostics).catch(() => {});
  }, []);

  const handleToggleRoomStatus = (roomId: string) => {
    setRooms((prev) =>
      prev.map((r) =>
        r.id === roomId
          ? {
              ...r,
              statut: r.statut === 'Disponible' ? 'Occupée' : 'Disponible',
            }
          : r
      )
    );
  };

  const navItems: { id: ScreenId; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
    { id: 'dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
    { id: 'students', label: 'Étudiants', icon: GraduationCap },
    { id: 'teachers', label: 'Enseignants', icon: Users },
    { id: 'structure', label: 'Arborescence Facultés', icon: FolderTree },
    { id: 'ues', label: 'Unités d’Enseignement', icon: BookOpen },
    { id: 'rooms', label: 'Salles & Amphithéâtres', icon: DoorOpen },
    { id: 'schedule', label: 'Emploi du Temps', icon: Calendar },
    { id: 'attendance', label: 'Présences & QR Code', icon: QrCode },
    { id: 'video', label: 'Visioconférence LAN & Cloud', icon: Video },
    { id: 'analytics', label: 'Statistiques & Rapports', icon: BarChart3 },
    { id: 'communications', label: 'Communications & Messages', icon: MessageSquare },
    { id: 'announcements', label: 'Annonces Officielles', icon: Bell },
    { id: 'settings', label: 'Paramètres & Microsoft Store', icon: Settings },
    { id: 'team', label: 'Équipe KERNEL FORGE', icon: HeartHandshake },
  ];

  if (!currentUser || activeScreen === 'login') {
    return (
      <div className="h-screen w-screen bg-[#081220] flex flex-col overflow-hidden text-slate-100">
        <LoginScreen
          onAuthenticated={(user) => {
            setCurrentUser(user);
            setActiveScreen('dashboard');
          }}
        />
      </div>
    );
  }

  return (
    <div className="h-screen w-screen bg-[#081220] flex flex-col overflow-hidden text-slate-100 select-none">
      {/* ── Custom Window Titlebar (Tauri Desktop Native Frame) ── */}
      <header
        data-tauri-drag-region
        className="h-10 shrink-0 bg-[#060D17] border-b border-[#1E293B] flex items-center justify-between px-3 text-xs"
      >
        <div className="flex items-center gap-2.5 pointer-events-none">
          <img src="/brand/uniflow_logo_final.png" alt="UniFlow" className="h-6 w-6 object-contain" />
          <span className="font-extrabold tracking-tight text-white flex items-center gap-1.5">
            Uniflow work
            <span className="px-1.5 py-0.2 rounded bg-blue-500/20 text-blue-400 font-mono text-[10px] border border-blue-500/30">
              v1.0.0
            </span>
            <span className="text-slate-500 text-[10px]">·</span>
            <span className="text-slate-400 text-[11px] font-mono">
              Store: {MS_STORE_IDENTITY.storeId} ({MS_STORE_IDENTITY.packageIdentityName})
            </span>
          </span>
        </div>

        <div className="flex items-center gap-4">
          {/* Status indicators */}
          <div className="flex items-center gap-3 text-[11px]">
            <span className="flex items-center gap-1.5 text-emerald-400 font-mono">
              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              Appwrite: vps.kernelforge.codes
            </span>
            <span className="flex items-center gap-1.5 text-teal-400 font-mono">
              <Wifi className="h-3 w-3" />
              LAN LiveKit: Prêt
            </span>
          </div>

          {/* Window control buttons */}
          <div className="flex items-center gap-1">
            <button
              onClick={() => {}}
              className="h-6 w-7 flex items-center justify-center rounded hover:bg-white/10 text-slate-400 hover:text-white"
              title="Réduire"
            >
              <Minus className="h-3.5 w-3.5" />
            </button>
            <button
              onClick={() => {}}
              className="h-6 w-7 flex items-center justify-center rounded hover:bg-white/10 text-slate-400 hover:text-white"
              title="Agrandir"
            >
              <Square className="h-3 w-3" />
            </button>
            <button
              onClick={() => {}}
              className="h-6 w-7 flex items-center justify-center rounded hover:bg-red-600 text-slate-400 hover:text-white"
              title="Fermer"
            >
              <X className="h-3.5 w-3.5" />
            </button>
          </div>
        </div>
      </header>

      {/* ── Main App Layout ── */}
      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar */}
        <aside className="w-64 shrink-0 bg-[#0A1628] border-r border-[#1E293B] flex flex-col justify-between overflow-y-auto">
          <div className="p-3 space-y-1">
            {/* User profile card */}
            <div className="p-3 mb-2 rounded-2xl bg-gradient-to-r from-blue-900/30 to-teal-900/20 border border-blue-500/20 flex items-center gap-3">
              <div className="h-10 w-10 shrink-0 rounded-xl bg-gradient-to-br from-[#1E3A8A] to-[#0D9488] flex items-center justify-center font-extrabold text-white text-base shadow-md">
                {currentUser.name.charAt(0)}
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-xs font-bold text-white truncate">{currentUser.name}</p>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-blue-500/20 text-blue-300">
                    {currentUser.role}
                  </span>
                  <span className="text-[10px] text-slate-400 font-mono truncate">{currentUser.matricule}</span>
                </div>
              </div>
            </div>

            {/* Navigation links */}
            <nav className="space-y-1">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = activeScreen === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => setActiveScreen(item.id)}
                    className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-bold transition-all ${
                      isActive
                        ? 'bg-gradient-to-r from-[#1E3A8A] to-[#2563EB] text-white shadow-md shadow-blue-900/30 font-extrabold'
                        : 'text-slate-400 hover:bg-[#101E33] hover:text-slate-200'
                    }`}
                  >
                    <Icon className={`h-4 w-4 shrink-0 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                    <span className="truncate">{item.label}</span>
                  </button>
                );
              })}
            </nav>
          </div>

          {/* Footer actions */}
          <div className="p-3 border-t border-[#1E293B] space-y-2">
            <button
              onClick={() => setActiveScreen('login')}
              className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-xl border border-red-500/20 bg-red-500/10 text-red-400 hover:bg-red-500/20 text-xs font-bold transition-colors"
            >
              <LogOut className="h-4 w-4" />
              <span>Changer d'utilisateur / Quitter</span>
            </button>
            <div className="text-center text-[10px] text-slate-500 font-mono">
              KERNEL FORGE · Uniflow work
            </div>
          </div>
        </aside>

        {/* Content View Area */}
        <main className="flex-1 bg-[#081220] overflow-y-auto p-6">
          {activeScreen === 'dashboard' && (
            <DashboardScreen
              students={students}
              teachers={teachers}
              ues={ues}
              onNavigate={(screen) => setActiveScreen(screen as ScreenId)}
            />
          )}

          {activeScreen === 'students' && (
            <StudentsListScreen
              students={students}
              onSelectStudent={(student) => {
                setSelectedStudentId(student.id);
                setActiveScreen('student_detail');
              }}
              onAddStudent={(newStudent) => setStudents((prev) => [newStudent, ...prev])}
            />
          )}

          {activeScreen === 'student_detail' && (
            <StudentDetailScreen
              student={students.find((s) => s.id === selectedStudentId) || students[0]}
              onBack={() => setActiveScreen('students')}
            />
          )}

          {activeScreen === 'teachers' && (
            <TeachersScreen
              teachers={teachers}
              onAddTeacher={(newTeacher) => setTeachers((prev) => [newTeacher, ...prev])}
            />
          )}

          {activeScreen === 'structure' && <FacultyTreeScreen ues={ues} />}

          {activeScreen === 'ues' && (
            <UEManagementScreen
              ues={ues}
              onAddUE={(newUE) => setUes((prev) => [newUE, ...prev])}
            />
          )}

          {activeScreen === 'rooms' && (
            <RoomsManagementScreen
              rooms={rooms}
              onToggleRoomStatus={handleToggleRoomStatus}
            />
          )}

          {/* Écrans complémentaires */}
          {activeScreen === 'schedule' && (
            <div className="space-y-4 animate-fade-in">
              <div className="flex items-center justify-between">
                <div>
                  <h1 className="text-2xl font-black text-white">Constructeur d’Emploi du Temps Universitaire</h1>
                  <p className="text-xs text-slate-400">Grille hebdomadaire synchronisée avec l'Université de Yaoundé I</p>
                </div>
                <button className="px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs shadow-md">
                  + Nouveau créneau
                </button>
              </div>
              <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-6 text-center text-slate-400">
                <Calendar className="h-12 w-12 mx-auto text-blue-400 mb-2 opacity-80" />
                <p className="font-bold text-white text-base">Planificateur de cours L1, L2, L3 & Master</p>
                <p className="text-xs text-slate-400 max-w-md mx-auto mt-1">
                  Tous les créneaux d'Amphi 500, Amphi 250 et Salles TP Informatique sont synchronisés en direct avec l'Appwrite VPS et sauvegardés hors-ligne.
                </p>
              </div>
            </div>
          )}

          {activeScreen === 'attendance' && (
            <div className="space-y-4 animate-fade-in">
              <div className="flex items-center justify-between">
                <div>
                  <h1 className="text-2xl font-black text-white">Suivi des Présences & QR Code Cryptographique</h1>
                  <p className="text-xs text-slate-400">Validation instantanée de présence en mode Cloud et Campus LAN</p>
                </div>
                <button className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow-md">
                  Générer QR Séance
                </button>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-5">
                  <span className="text-xs text-slate-400">Taux global de présence</span>
                  <p className="text-3xl font-black text-emerald-400 mt-1">94.8%</p>
                </div>
                <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-5">
                  <span className="text-xs text-slate-400">Séances enregistrées</span>
                  <p className="text-3xl font-black text-blue-400 mt-1">128</p>
                </div>
                <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-5">
                  <span className="text-xs text-slate-400">Scans hors-ligne synchronisés</span>
                  <p className="text-3xl font-black text-teal-400 mt-1">3,420</p>
                </div>
              </div>
            </div>
          )}

          {activeScreen === 'video' && (
            <div className="space-y-4 animate-fade-in">
              <div className="flex items-center justify-between">
                <div>
                  <h1 className="text-2xl font-black text-white">Visioconférence Campus LAN & Cloud LiveKit</h1>
                  <p className="text-xs text-slate-400">Diffusion de cours magistraux en direct sans consommer d'Internet mondial via le réseau local du campus</p>
                </div>
                <button className="px-4 py-2 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-bold text-xs shadow-md">
                  Démarrer Studio LAN
                </button>
              </div>
              <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-8 text-center">
                <Video className="h-12 w-12 mx-auto text-purple-400 mb-3" />
                <h3 className="text-lg font-black text-white">Nœud LAN Campus Prêt</h3>
                <p className="text-xs text-slate-400 max-w-md mx-auto mt-1">
                  Adresse de diffusion locale : <code className="text-emerald-400 font-mono">ws://192.168.10.42:7880</code>.
                  Les étudiants de l'amphithéâtre peuvent rejoindre la session audio/vidéo et tableau blanc sans connexion externe.
                </p>
              </div>
            </div>
          )}

          {activeScreen === 'analytics' && (
            <div className="space-y-4 animate-fade-in">
              <div>
                <h1 className="text-2xl font-black text-white">Statistiques & Analytics de Direction</h1>
                <p className="text-xs text-slate-400">Indicateurs de réussite, assiduité et recouvrement des droits universitaires</p>
              </div>
              <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-6">
                <p className="text-sm font-bold text-white mb-2">Recouvrement des droits universitaires</p>
                <div className="h-4 rounded-full bg-slate-800 overflow-hidden flex">
                  <div className="bg-emerald-500 h-full w-[78%]" title="Tranche 1 & 2 réglées (78%)" />
                  <div className="bg-amber-500 h-full w-[14%]" title="Tranche 1 réglée (14%)" />
                  <div className="bg-red-500 h-full w-[8%]" title="En attente (8%)" />
                </div>
                <div className="flex justify-between text-[11px] text-slate-400 mt-2 font-mono">
                  <span className="text-emerald-400">● 78% Quitus Complet</span>
                  <span className="text-amber-400">● 14% Tranche 1 payée</span>
                  <span className="text-red-400">● 8% Non régularisé</span>
                </div>
              </div>
            </div>
          )}

          {activeScreen === 'settings' && (
            <div className="space-y-5 animate-fade-in">
              <div>
                <h1 className="text-2xl font-black text-white">Paramètres Système & Identité Microsoft Store</h1>
                <p className="text-xs text-slate-400">Configuration officielle Microsoft Partner Center et diagnostics natifs</p>
              </div>

              {/* Microsoft Store Identity Card */}
              <div className="rounded-2xl border border-blue-500/30 bg-gradient-to-br from-blue-950/40 to-slate-900 p-6 space-y-4">
                <div className="flex items-center gap-3">
                  <img src="/brand/uniflow_logo_final.png" alt="" className="h-10 w-10 object-contain" />
                  <div>
                    <h2 className="text-base font-black text-white flex items-center gap-2">
                      {MS_STORE_IDENTITY.appName}
                      <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 text-[10px] font-bold border border-emerald-500/30">
                        Microsoft Store Officiel
                      </span>
                    </h2>
                    <p className="text-xs text-slate-400">ID Store : {MS_STORE_IDENTITY.storeId}</p>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs font-mono">
                  <div className="p-3 rounded-xl bg-black/30 border border-white/5">
                    <span className="text-slate-500 block text-[10px]">Package/Identity/Name</span>
                    <span className="text-blue-300 font-bold">{MS_STORE_IDENTITY.packageIdentityName}</span>
                  </div>
                  <div className="p-3 rounded-xl bg-black/30 border border-white/5">
                    <span className="text-slate-500 block text-[10px]">Package/Properties/PublisherDisplayName</span>
                    <span className="text-white font-bold">{MS_STORE_IDENTITY.publisherDisplayName}</span>
                  </div>
                  <div className="p-3 rounded-xl bg-black/30 border border-white/5">
                    <span className="text-slate-500 block text-[10px]">Package Family Name (PFN)</span>
                    <span className="text-teal-300 font-bold">{MS_STORE_IDENTITY.packageFamilyName}</span>
                  </div>
                  <div className="p-3 rounded-xl bg-black/30 border border-white/5">
                    <span className="text-slate-500 block text-[10px]">Package SID</span>
                    <span className="text-amber-300 font-bold text-[11px] truncate block">{MS_STORE_IDENTITY.packageSid}</span>
                  </div>
                </div>

                <div className="pt-2 flex flex-wrap gap-2 text-[11px]">
                  <a
                    href={MS_STORE_IDENTITY.storeWebUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="px-3 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold"
                  >
                    Ouvrir la fiche web Microsoft Store
                  </a>
                  <a
                    href={MS_STORE_IDENTITY.storeProtocolUrl}
                    className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold"
                  >
                    Lancer ms-windows-store
                  </a>
                </div>
              </div>

              {/* Appwrite & Local Cache Diagnostics */}
              <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-5 space-y-3">
                <h3 className="text-sm font-bold text-white">Diagnostics Appwrite Self-Hosted</h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
                  <div className="p-3 rounded-xl bg-[#081220]">
                    <span className="text-slate-500 block text-[10px]">Endpoint</span>
                    <span className="text-emerald-400 font-mono font-bold">{APPWRITE_CONFIG.endpoint}</span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#081220]">
                    <span className="text-slate-500 block text-[10px]">Project ID</span>
                    <span className="text-white font-mono font-bold">{APPWRITE_CONFIG.projectId}</span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#081220]">
                    <span className="text-slate-500 block text-[10px]">Database ID</span>
                    <span className="text-white font-mono font-bold">{APPWRITE_CONFIG.databaseId}</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeScreen === 'team' && (
            <div className="space-y-4 animate-fade-in">
              <div>
                <h1 className="text-2xl font-black text-white">Équipe KERNEL FORGE</h1>
                <p className="text-xs text-slate-400">Les 10 bâtisseurs de la plateforme universitaire UniFlow</p>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
                {[
                  { name: 'NGHOMSI FEUKOUO Ravel', role: 'Fondateur & Lead Architect', photo: '/team/ravel.jpg', avatar: '/team/avatar_ravel_founder.jpg' },
                  { name: 'MOKAM KAMDEM Ange', role: 'Tech Lead Backend', photo: '/team/mokam.jpg', avatar: '/team/avatar_mokam_mascot.jpg' },
                  { name: 'WILLIAM Yomi', role: 'Lead Frontend Web', photo: '/team/william.jpg', avatar: '/team/avatar_william_mascot.jpg' },
                  { name: 'SANDRA Tsafack', role: 'Lead Flutter Mobile', photo: '/team/sandra.jpg', avatar: '/team/avatar_sandra_mascot.jpg' },
                  { name: 'HASSANE Amadou', role: 'Rust & Desktop Engineer', photo: '/team/hassane.jpg', avatar: '/team/avatar_hassane_mascot.jpg' },
                  { name: 'MARCEL Kenmoe', role: 'DevOps & Cloud VPS', photo: '/team/marcel.jpg', avatar: '/team/avatar_marcel_anime.jpg' },
                  { name: 'MIGUEL Nguemo', role: 'UI/UX & Design Systems', photo: '/team/miguel.jpg', avatar: '/team/avatar_miguel_anime.jpg' },
                  { name: 'JUVENAL Tcheunche', role: 'Data & Academic Engine', photo: '/team/juvenal.jpg', avatar: '/team/avatar_juvenal_anime.jpg' },
                  { name: 'JUDITH Mbianda', role: 'QA & Security Audits', photo: '/team/judith.jpg', avatar: '/team/avatar_judith_anime.jpg' },
                  { name: 'ALIYA Noubissi', role: 'Product & Community', photo: '/team/aliya.jpg', avatar: '/team/avatar_aliya_anime.jpg' },
                ].map((m) => (
                  <div key={m.name} className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-4 text-center space-y-2">
                    <img
                      src={m.photo}
                      alt={m.name}
                      onError={(e) => { (e.currentTarget as HTMLImageElement).src = m.avatar }}
                      className="h-20 w-20 rounded-2xl mx-auto object-cover border-2 border-blue-500/30 shadow-md"
                    />
                    <p className="text-xs font-black text-white leading-tight">{m.name}</p>
                    <p className="text-[10px] text-teal-400 font-semibold">{m.role}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeScreen === 'communications' && (
            <div className="space-y-4 animate-fade-in">
              <h1 className="text-2xl font-black text-white">Centre de Communications Universitaires</h1>
              <p className="text-xs text-slate-400">Canaux officiels, groupes de travaux dirigés et messagerie instantanée</p>
              <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-8 text-center text-slate-400">
                <MessageSquare className="h-10 w-10 mx-auto text-blue-400 mb-2" />
                <p className="text-sm font-bold text-white">Messagerie connectée au service Appwrite</p>
              </div>
            </div>
          )}

          {activeScreen === 'announcements' && (
            <div className="space-y-4 animate-fade-in">
              <h1 className="text-2xl font-black text-white">Gestion des Annonces Officielles</h1>
              <p className="text-xs text-slate-400">Publications du Doyen, Chefs de département et Délégués</p>
              <div className="rounded-2xl border border-[#1E293B] bg-[#101E33] p-8 text-center text-slate-400">
                <Bell className="h-10 w-10 mx-auto text-amber-400 mb-2" />
                <p className="text-sm font-bold text-white">Flux d’actualités académiques certifiées</p>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
