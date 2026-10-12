#define MyAppName "TAFRA Studio"
#define MyAppVersion "0.1.0"
#define MyAppExeName "tafrastudio.exe"

[Setup]
AppId={{9B043BEC-8EB4-4E0B-B68B-9B31C3983E51}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\TAFRA Studio
DefaultGroupName={#MyAppName}
OutputDir=..\release
OutputBaseFilename=TAFRA-Studio-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern

[Files]
Source: "..\tafrastudio.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\runtime\php\*"; DestDir: "{app}\runtime\php"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\tools\php\*"; DestDir: "{app}\tools\php"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\resources\*"; DestDir: "{app}\resources"; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

[Dirs]
Name: "{app}\config"; Permissions: users-modify

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
