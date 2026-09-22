#define AppName "Netgear Discovery"
#define AppVersion "0.2.1"
#define Publisher "Netgear Discovery"
#define SourceRoot "build\Netgear Discovery"

[Setup]
AppId={{34C74E21-7364-4A44-A471-AC168756C13B}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#Publisher}
DefaultDirName={autopf}\Netgear Discovery
DefaultGroupName=Netgear Discovery
DisableProgramGroupPage=yes
OutputDir=..\installer-output
OutputBaseFilename=Netgear-Discovery-Setup-{#AppVersion}
SetupIconFile={#SourceRoot}\public\switchboard-icon.ico
UninstallDisplayIcon={app}\public\switchboard-icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline
WizardStyle=modern
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "startup"; Description: "Start Netgear Discovery when I sign in"; Flags: checkedonce
Name: "networkaccess"; Description: "Allow dashboard access from other computers on private networks"; Flags: checkedonce
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Dirs]
Name: "{commonappdata}\Netgear Discovery"; Permissions: users-modify
Name: "{commonappdata}\Netgear Discovery\logs"; Permissions: users-modify

[Files]
Source: "{#SourceRoot}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Netgear Discovery"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Netgear Discovery.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\public\switchboard-icon.ico"
Name: "{group}\Dashboard"; Filename: "http://localhost:3000/"
Name: "{group}\Server settings"; Filename: "http://localhost:8787/setup"
Name: "{group}\Uninstall Netgear Discovery"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Netgear Discovery"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Netgear Discovery.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\public\switchboard-icon.ico"; Tasks: desktopicon
Name: "{commonstartup}\Netgear Discovery"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Netgear Discovery.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\public\switchboard-icon.ico"; Tasks: startup

[Run]
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""Netgear Discovery Dashboard"""; Flags: runhidden; Tasks: networkaccess
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""Netgear Discovery Dashboard"" dir=in action=allow protocol=TCP localport=3000,8787 profile=private"; Flags: runhidden; Tasks: networkaccess
Filename: "{sys}\wscript.exe"; Parameters: """{app}\Netgear Discovery.vbs"""; Description: "Launch Netgear Discovery"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\scripts\stop-installed.ps1"""; Flags: runhidden waituntilterminated; RunOnceId: "StopNetgearDiscovery"
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""Netgear Discovery Dashboard"""; Flags: runhidden; RunOnceId: "RemoveFirewallRule"

[Code]
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  StopScript: String;
  ResultCode: Integer;
begin
  Result := '';
  StopScript := AddBackslash(WizardDirValue) + 'scripts\stop-installed.ps1';
  if FileExists(StopScript) then
  begin
    Exec(
      ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
      '-NoProfile -ExecutionPolicy Bypass -File "' + StopScript + '"',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode
    );
    Sleep(1200);
  end;
end;
