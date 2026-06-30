[Setup]
AppName=Church Arena
AppVersion=1.0.0
AppPublisher=Church Arena Team
AppPublisherURL=
DefaultDirName={autopf}\ChurchArena
DefaultGroupName=Church Arena
OutputDir=D:\WORK\Church\church_arena\installer\output
OutputBaseFilename=ChurchArena_Setup_v1.0.0
SetupIconFile=
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0
UninstallDisplayName=Church Arena
UninstallDisplayIcon={app}\church_arena.exe
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Main executable
Source: "D:\WORK\Church\church_arena\build\windows\x64\runner\Release\church_arena.exe";   DestDir: "{app}"; Flags: ignoreversion

; Plugin DLLs
Source: "D:\WORK\Church\church_arena\build\windows\x64\runner\Release\*.dll";              DestDir: "{app}"; Flags: ignoreversion

; Flutter data folder (assets, ICU data, AOT snapshot)
Source: "D:\WORK\Church\church_arena\build\windows\x64\runner\Release\data\*";             DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Church Arena";        Filename: "{app}\church_arena.exe"
Name: "{group}\Uninstall Church Arena"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Church Arena"; Filename: "{app}\church_arena.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\church_arena.exe"; Description: "Launch Church Arena"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Remove the SQLite database created at runtime so the uninstall is clean
Type: filesandordirs; Name: "{localappdata}\church_arena"
