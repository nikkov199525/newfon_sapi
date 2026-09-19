; Newfon SAPI installer. Built by the "installer" target of the x64 CMake tree
; (see build_release.cmd); every path below can be overridden with /D.
; Layout, registration and the move-aside trick are ours; the wording, the
; date-based version and the uninstall question come from the 2019 installer.
#define PRODUCT_NAME "Newfon SAPI"
#define FOLDER_NAME "NewfonSAPI"
#define CURRENT_YEAR GetDateTimeString('yyyy', '', '')
; SetupVersion comes from the build; ISCC mangles /D names with underscores.
#ifdef SetupVersion
  #define PRODUCT_VERSION SetupVersion
#else
  #define PRODUCT_VERSION GetDateTimeString('yyyy.mm.dd', '', '')
#endif
; VersionInfoVersion takes plain numbers, so no leading zeros here.
#define FILE_VERSION GetDateTimeString('yyyy.m.d', '', '')
#ifndef SourceRoot
  #define SourceRoot AddBackslash(SourcePath) + ".."
#endif
#ifndef X64Bin
  #define X64Bin SourceRoot + "\build\x64\bin"
#endif
#ifndef X86Bin
  #define X86Bin SourceRoot + "\build\x86\bin"
#endif
#ifndef OutputDir
  #define OutputDir SourceRoot + "\build\installer"
#endif

#define Configurer "NewfonConfigurer.exe"

[Setup]
AppId={{73D8A3E0-FBDE-4C31-AA20-F3B4EEBD676E}
AppName={#PRODUCT_NAME}
AppVersion={#PRODUCT_VERSION}
AppPublisher=БелСИнт, Сергей Шишминцев, O-Team Development, 2018 - {#CURRENT_YEAR}
DefaultDirName={autopf}\{#FOLDER_NAME}
DefaultGroupName={#PRODUCT_NAME}
DisableProgramGroupPage=yes
DirExistsWarning=no
; Both engines are installed so 32-bit and 64-bit SAPI clients see the voices;
; the configurer is a 64-bit build.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
; Screen readers keep newfon_sapi.dll loaded. Instead of closing the program the
; user hears the setup through, engines in use are renamed (MoveAside below) and
; replaced at once; restartreplace stays as the fallback if renaming fails.
CloseApplications=no
OutputDir={#OutputDir}
OutputBaseFilename=Setup-{#PRODUCT_NAME}-v{#PRODUCT_VERSION}-X86-x64
Compression=lzma2/ultra
InternalCompressLevel=ultra
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#Configurer}
UninstallDisplayName={#PRODUCT_NAME}
VersionInfoVersion={#FILE_VERSION}
VersionInfoProductName={#PRODUCT_NAME}
VersionInfoProductVersion={#FILE_VERSION}

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[InstallDelete]
; Per-architecture copies of rulex.db from earlier builds.
Type: files; Name: "{app}\x86\rulex.db"
Type: files; Name: "{app}\x64\rulex.db"
; Engines that MoveAside renamed while a SAPI host still had them loaded.
Type: files; Name: "{app}\x86\*.old"
Type: files; Name: "{app}\x64\*.old"

[Files]
Source: "{#X86Bin}\newfon_core.dll"; DestDir: "{app}\x86"; BeforeInstall: MoveAside; Flags: ignoreversion restartreplace uninsrestartdelete 32bit
Source: "{#X86Bin}\newfon_rulex.dll"; DestDir: "{app}\x86"; BeforeInstall: MoveAside; Flags: ignoreversion restartreplace uninsrestartdelete 32bit
Source: "{#X86Bin}\rulex.dll"; DestDir: "{app}\x86"; BeforeInstall: MoveAside; Flags: ignoreversion restartreplace uninsrestartdelete 32bit
Source: "{#X86Bin}\newfon_sapi.dll"; DestDir: "{app}\x86"; BeforeInstall: MoveAside; Flags: ignoreversion restartreplace uninsrestartdelete regserver 32bit
Source: "{#X64Bin}\newfon_core.dll"; DestDir: "{app}\x64"; BeforeInstall: MoveAside; Flags: ignoreversion restartreplace uninsrestartdelete 64bit
Source: "{#X64Bin}\newfon_rulex.dll"; DestDir: "{app}\x64"; BeforeInstall: MoveAside; Flags: ignoreversion restartreplace uninsrestartdelete 64bit
Source: "{#X64Bin}\rulex.dll"; DestDir: "{app}\x64"; BeforeInstall: MoveAside; Flags: ignoreversion restartreplace uninsrestartdelete 64bit
Source: "{#X64Bin}\newfon_sapi.dll"; DestDir: "{app}\x64"; BeforeInstall: MoveAside; Flags: ignoreversion restartreplace uninsrestartdelete regserver 64bit
; One database for both engines: the x64 and x86 build trees produce identical
; files, and newfon_rulex.dll looks for it one level above its own folder.
Source: "{#X64Bin}\rulex.db"; DestDir: "{app}"; Flags: ignoreversion restartreplace uninsrestartdelete
Source: "{#X64Bin}\{#Configurer}"; DestDir: "{app}"; Flags: ignoreversion
; Template the configurer copies to %APPDATA%\NewfonSAPI when the user has no
; prefs.ini yet; the engine writes the same defaults itself.
Source: "{#X64Bin}\prefs.ini"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceRoot}\LICENSES\*"; DestDir: "{app}\LICENSES"; Flags: ignoreversion recursesubdirs
; The configurer opens it with the "Документация" button and F1.
Source: "{#SourceRoot}\docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Icons]
Name: "{group}\Настройки {#PRODUCT_NAME}"; Filename: "{app}\{#Configurer}"; WorkingDir: "{app}"
Name: "{autodesktop}\Настройки {#PRODUCT_NAME}"; Filename: "{app}\{#Configurer}"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{group}\Документация по {#PRODUCT_NAME}"; Filename: "{app}\docs\Russian.html"
Name: "{group}\{cm:UninstallProgram,{#PRODUCT_NAME}}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#Configurer}"; Description: "Открыть настройки {#PRODUCT_NAME}"; Flags: nowait postinstall skipifsilent

[Code]
// A loaded DLL cannot be overwritten, but it can be renamed. Moving the old
// engine aside lets the new one be installed at once: a screen reader that
// keeps the old copy loaded picks up the new one on its next start, with no
// reboot. The renamed copy is deleted now if nothing uses it, else on reboot.
procedure MoveAside();
var
  FileName, OldName: String;
begin
  FileName := ExpandConstant(CurrentFileName);
  if not FileExists(FileName) then Exit;
  OldName := FileName + '.' + GetDateTimeString('yyyymmddhhnnss', #0, #0) + '.old';
  if RenameFile(FileName, OldName) then
  begin
    if not DeleteFile(OldName) then
      RestartReplace(OldName, '');
  end;
end;

// Settings and the user dictionary live in %APPDATA%\NewfonSAPI and are kept
// unless the user says otherwise, as in the 2019 installer.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    if MsgBox('Удалить из папки пользователя настройки программы и словарь ударений?', mbConfirmation, MB_YESNO) = idYes then
      DelTree(ExpandConstant('{userappdata}\{#FOLDER_NAME}'), True, True, True);
  end;
end;
