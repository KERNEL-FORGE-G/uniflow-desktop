; ==============================================================================
; Script d'installation Inno Setup pour UniFlow Desktop (.EXE)
; Génère : UniFlow-1.0.0-Setup.exe
; Éditeur : KERNEL FORGE
; ==============================================================================

#define MyAppName "UniFlow"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "KERNEL FORGE"
#define MyAppURL "https://uniflow.kernelforge.codes"
#define MyAppExeName "uniflow_desktop.exe"
#define MyAppAssocName "Paquet Éducatif UniFlow"
#define MyAppAssocExt ".uniflow"
#define MyAppAssocKey StringChange(MyAppAssocName, " ", "") + MyAppAssocExt

[Setup]
AppId={{9E6A6D14-5B8F-4D2A-937C-0C315E4C8821}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/download
DefaultDirName={autopf}\UniFlow
UninstallDisplayIcon={app}\{#MyAppExeName}
ChangesAssociations=yes
DisableProgramGroupPage=yes
LicenseFile=..\..\..\LICENSE.md
OutputDir=..\..\build\windows\installer
OutputBaseFilename=UniFlow-{#MyAppVersion}-Setup
SetupIconFile=..\runner\resources\app_icon.ico
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "quicklaunchicon"; Description: "Créer un raccourci dans la barre des tâches"; Flags: unchecked

[Files]
; Fichiers de l'application compilée Flutter
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExeName}"

[Registry]
; Enregistrement du protocole URL uniflow://
Root: HKA; Subkey: "Software\Classes\uniflow"; ValueType: string; ValueName: ""; ValueData: "URL:UniFlow Protocol"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\uniflow"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\uniflow\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKA; Subkey: "Software\Classes\uniflow\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

; Association d'extension de fichier .uniflow
Root: HKA; Subkey: "Software\Classes\{#MyAppAssocExt}\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppAssocKey}"; ValueData: ""; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\{#MyAppAssocKey}"; ValueType: string; ValueName: ""; ValueData: "{#MyAppAssocName}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#MyAppAssocKey}\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKA; Subkey: "Software\Classes\{#MyAppAssocKey}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
