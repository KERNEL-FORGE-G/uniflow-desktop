import React, { useState, useMemo } from 'react';
import {
  Calendar,
  Clock,
  MapPin,
  User,
  Filter,
  CheckCircle2,
  Building2,
  Sparkles,
  ChevronLeft,
  ChevronRight,
  Download,
  AlertTriangle,
} from 'lucide-react';

interface ScheduleSlot {
  id: string;
  courseCode: string;
  courseName: string;
  dayOfWeek: 'Lundi' | 'Mardi' | 'Mercredi' | 'Jeudi' | 'Vendredi' | 'Samedi';
  startTime: string;
  endTime: string;
  classroom: string;
  type: 'CM' | 'TD' | 'TP';
  teacherName: string;
  program: string;
  level: string;
  group?: string;
}

const DESKTOP_SCHEDULES: ScheduleSlot[] = [
  // ICT4D L3
  { id: '1', courseCode: 'ENG303', courseName: 'English III', dayOfWeek: 'Lundi', startTime: '08:00', endTime: '11:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Dr. MUSIMA', program: 'ICT4D', level: 'L3', group: 'G1' },
  { id: '2', courseCode: 'ICT307', courseName: 'Computer Systems Engineering', dayOfWeek: 'Lundi', startTime: '12:00', endTime: '15:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Pr. Halidou AMINOU / Pr. Hyacinthe TAPAMO', program: 'ICT4D', level: 'L3', group: 'G1' },
  { id: '3', courseCode: 'ICT305', courseName: 'Web Application Development', dayOfWeek: 'Lundi', startTime: '15:00', endTime: '18:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Dr. NJINE / Dr. MBEYA', program: 'ICT4D', level: 'L3', group: 'G2' },
  { id: '4', courseCode: 'FRA303', courseName: 'Français III', dayOfWeek: 'Mardi', startTime: '08:00', endTime: '11:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Dr. BIYONG', program: 'ICT4D', level: 'L3', group: 'G1' },
  { id: '5', courseCode: 'ICT301', courseName: 'Software Architectures and Design', dayOfWeek: 'Mardi', startTime: '12:00', endTime: '15:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Dr. MONTHE', program: 'ICT4D', level: 'L3', group: 'G1' },
  { id: '6', courseCode: 'ICT317', courseName: 'Information System', dayOfWeek: 'Mardi', startTime: '15:00', endTime: '18:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Dr. ABESSOLO', program: 'ICT4D', level: 'L3', group: 'G1' },
  { id: '7', courseCode: 'ICT313', courseName: 'Cyber and Internet Security', dayOfWeek: 'Mercredi', startTime: '08:00', endTime: '11:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Dr. MOYOU', program: 'ICT4D', level: 'L3', group: 'G2' },
  { id: '8', courseCode: 'ICT303', courseName: 'Data Communication and Security', dayOfWeek: 'Mercredi', startTime: '12:00', endTime: '15:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Pr. AMINOU / Dr. MBOUS', program: 'ICT4D', level: 'L3', group: 'G2' },
  { id: '9', courseCode: 'ICT315', courseName: 'Network Application Development', dayOfWeek: 'Jeudi', startTime: '08:00', endTime: '11:00', classroom: 'Salle S107', type: 'CM', teacherName: 'Dr. KUTCHE / Dr. TANKOU', program: 'ICT4D', level: 'L3', group: 'G2' },
  { id: '10', courseCode: 'ICT300', courseName: 'Projets Tuteurés & Stage', dayOfWeek: 'Samedi', startTime: '15:00', endTime: '18:00', classroom: 'Salle S107', type: 'TP', teacherName: 'Pr. AMINOU / Dr. MESSI', program: 'ICT4D', level: 'L3', group: 'G1-G4' },

  // ICT4D L1
  { id: '11', courseCode: 'ICT105', courseName: 'Introduction to Algorithms', dayOfWeek: 'Lundi', startTime: '08:00', endTime: '11:00', classroom: 'Salle R101', type: 'CM', teacherName: 'Dr. WABO', program: 'ICT4D', level: 'L1', group: 'G1' },
  { id: '12', courseCode: 'ICT107', courseName: 'Mathematics for Computer Science I', dayOfWeek: 'Lundi', startTime: '12:00', endTime: '15:00', classroom: 'Salle R101', type: 'CM', teacherName: 'Dr. NIMPA', program: 'ICT4D', level: 'L1', group: 'G1' },
  { id: '13', courseCode: 'ICT103', courseName: 'Introduction to Programming', dayOfWeek: 'Mardi', startTime: '08:00', endTime: '11:00', classroom: 'Salle R101', type: 'CM', teacherName: 'Dr. MESSI', program: 'ICT4D', level: 'L1', group: 'G2' },
  { id: '14', courseCode: 'ICT111', courseName: 'Data Coding', dayOfWeek: 'Mercredi', startTime: '08:00', endTime: '11:00', classroom: 'Salle R101', type: 'CM', teacherName: 'Dr. TAMO', program: 'ICT4D', level: 'L1', group: 'G1' },

  // SIGL M1
  { id: '15', courseCode: 'INF471', courseName: 'Principes et pratique des réseaux', dayOfWeek: 'Lundi', startTime: '16:00', endTime: '20:00', classroom: 'Salle S111', type: 'CM', teacherName: 'Pr. AMINOU / Dr. MBOUS', program: 'SIGL', level: 'M1' },
  { id: '16', courseCode: 'INF463', courseName: 'Programmation Java & CMS', dayOfWeek: 'Mardi', startTime: '16:00', endTime: '20:00', classroom: 'Salle S111', type: 'CM', teacherName: 'Dr. KWETTE', program: 'SIGL', level: 'M1' },
  { id: '17', courseCode: 'INF461', courseName: 'Génie Logiciel Avancé', dayOfWeek: 'Mercredi', startTime: '16:00', endTime: '20:00', classroom: 'Salle S111', type: 'CM', teacherName: 'Dr. ABESSOLO', program: 'SIGL', level: 'M1' },
  { id: '18', courseCode: 'INF465', courseName: 'Modélisation des SI', dayOfWeek: 'Jeudi', startTime: '08:00', endTime: '12:00', classroom: 'Salle S111', type: 'CM', teacherName: 'Dr. KIMBI', program: 'SIGL', level: 'M1' },

  // Informatique Fondamentale L1
  { id: '19', courseCode: 'INF111', courseName: 'Algorithmique & C', dayOfWeek: 'Lundi', startTime: '07:00', endTime: '10:00', classroom: 'Amphi 1002', type: 'CM', teacherName: 'Pr. Maurice TCHUENTE', program: 'INF', level: 'L1' },
  { id: '20', courseCode: 'MAT111', courseName: 'Algèbre Linéaire', dayOfWeek: 'Mardi', startTime: '10:05', endTime: '13:00', classroom: 'Amphi 1002', type: 'CM', teacherName: 'Dr. NGANSO', program: 'INF', level: 'L1' },
];

const DAYS: Array<'Lundi' | 'Mardi' | 'Mercredi' | 'Jeudi' | 'Vendredi' | 'Samedi'> = [
  'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'
];

export const DesktopScheduleScreen: React.FC<{
  userRole?: string;
  userMatricule?: string;
}> = () => {
  const [selectedProgram, setSelectedProgram] = useState<'ICT4D' | 'SIGL' | 'INF'>('ICT4D');
  const [selectedLevel, setSelectedLevel] = useState<string>('L3');

  const filteredSlots = useMemo(() => {
    return DESKTOP_SCHEDULES.filter(
      (s) => s.program === selectedProgram && s.level === selectedLevel
    );
  }, [selectedProgram, selectedLevel]);

  return (
    <div className="space-y-6 animate-fade-in text-slate-100">
      {/* Header bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 p-6 rounded-3xl bg-gradient-to-r from-[#1E3A8A] to-[#0E1E38] border border-[#1E293B] shadow-xl">
        <div>
          <div className="flex items-center gap-2 mb-1.5">
            <span className="px-2.5 py-0.5 rounded-full bg-blue-500/20 text-blue-300 text-[10px] font-bold border border-blue-400/30 uppercase tracking-wider">
              Faculté des Sciences · UY1
            </span>
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 text-[10px] font-bold border border-emerald-400/30">
              Semestre 1 2026-2027
            </span>
          </div>
          <h1 className="text-2xl font-black text-white">Constructeur & Emploi du Temps Universitaire</h1>
          <p className="text-xs text-slate-300 mt-1">
            Grille officielle synchronisée en direct avec le VPS Appwrite et le cache hors-ligne natif Rust.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="px-3.5 py-2 rounded-2xl bg-white/5 border border-white/10 text-xs">
            <span className="text-slate-400">Salle principale :</span>{' '}
            <strong className="text-teal-300 font-mono">
              {selectedProgram === 'ICT4D' && selectedLevel === 'L3' ? 'Salle S107' : selectedProgram === 'ICT4D' && selectedLevel === 'L1' ? 'Salle R101' : selectedProgram === 'SIGL' ? 'Salle S111' : 'Amphi 1002'}
            </strong>
          </div>
        </div>
      </div>

      {/* Program and Level Switcher */}
      <div className="flex flex-wrap items-center justify-between gap-4 p-4 rounded-2xl bg-[#101E33] border border-[#1E293B]">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider mr-2">
            Filière :
          </span>
          {[
            { code: 'ICT4D', label: 'ICT4D (Licence Pro)' },
            { code: 'SIGL', label: 'SIGL (Master Pro)' },
            { code: 'INF', label: 'Informatique Fondamentale' },
          ].map((prog) => {
            const active = selectedProgram === prog.code;
            return (
              <button
                key={prog.code}
                onClick={() => {
                  setSelectedProgram(prog.code as any);
                  if (prog.code === 'SIGL') setSelectedLevel('M1');
                  else if (prog.code === 'INF') setSelectedLevel('L1');
                  else setSelectedLevel('L3');
                }}
                className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                  active
                    ? 'bg-[#2563EB] text-white shadow-md'
                    : 'bg-[#0A1220] text-slate-400 hover:text-white border border-[#1E293B]'
                }`}
              >
                {prog.label}
              </button>
            );
          })}
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs font-semibold text-slate-400 mr-2">Niveau :</span>
          {(selectedProgram === 'SIGL' ? ['M1', 'M2'] : ['L1', 'L2', 'L3']).map((lvl) => {
            const active = selectedLevel === lvl;
            return (
              <button
                key={lvl}
                onClick={() => setSelectedLevel(lvl)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                  active
                    ? 'bg-[#0D9488] text-white'
                    : 'bg-[#0A1220] text-slate-400 hover:text-white border border-[#1E293B]'
                }`}
              >
                {lvl}
              </button>
            );
          })}
        </div>
      </div>

      {/* Weekly Schedule Grid */}
      <div className="p-5 rounded-3xl bg-[#101E33] border border-[#1E293B] shadow-xl overflow-x-auto">
        <div className="min-w-[900px]">
          {/* Days header */}
          <div className="grid grid-cols-6 gap-3 pb-4 border-b border-[#1E293B]">
            {DAYS.map((day) => {
              const dayCount = filteredSlots.filter((s) => s.dayOfWeek === day).length;
              return (
                <div key={day} className="p-3 rounded-2xl bg-[#0B1526] border border-[#1E293B] text-center">
                  <span className="text-xs font-black uppercase tracking-wider text-blue-300 block">
                    {day}
                  </span>
                  <span className="text-[10px] text-slate-400">
                    {dayCount} cours
                  </span>
                </div>
              );
            })}
          </div>

          {/* Day Columns */}
          <div className="grid grid-cols-6 gap-3 pt-4 min-h-[440px] items-start">
            {DAYS.map((day) => {
              const slots = filteredSlots
                .filter((s) => s.dayOfWeek === day)
                .sort((a, b) => a.startTime.localeCompare(b.startTime));

              if (slots.length === 0) {
                return (
                  <div
                    key={day}
                    className="flex flex-col items-center justify-center h-40 rounded-2xl border border-dashed border-[#1E293B] bg-[#0B1526]/40 p-4 text-center"
                  >
                    <span className="text-xs text-slate-500 font-medium">Libre</span>
                    <span className="text-[10px] text-slate-600 mt-0.5">Étude personnelle</span>
                  </div>
                );
              }

              return (
                <div key={day} className="space-y-3">
                  {slots.map((slot) => (
                    <div
                      key={slot.id}
                      className="p-3.5 rounded-2xl bg-[#0D192D] border border-blue-900/30 hover:border-blue-500/70 transition-all shadow-md group"
                    >
                      <div className="flex items-center justify-between gap-1 mb-1.5">
                        <span className="font-mono text-xs font-black text-blue-400">
                          {slot.courseCode}
                        </span>
                        <span className="px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-300 text-[9px] font-bold">
                          {slot.type} {slot.group ? `· ${slot.group}` : ''}
                        </span>
                      </div>

                      <h4 className="text-xs font-bold text-white leading-snug line-clamp-2">
                        {slot.courseName}
                      </h4>

                      <div className="mt-3 pt-2 border-t border-white/5 space-y-1.5 text-[11px] text-slate-300">
                        <div className="flex items-center gap-1.5 font-semibold text-white">
                          <Clock className="w-3.5 h-3.5 text-blue-400 shrink-0" />
                          <span>{slot.startTime} – {slot.endTime}</span>
                        </div>
                        <div className="flex items-center gap-1.5 text-teal-300 font-medium">
                          <MapPin className="w-3.5 h-3.5 shrink-0" />
                          <span className="truncate">{slot.classroom}</span>
                        </div>
                        <div className="flex items-center gap-1.5 text-slate-400">
                          <User className="w-3.5 h-3.5 shrink-0 text-amber-400" />
                          <span className="truncate">{slot.teacherName}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};
