#define AppName "Signature Bridge"
#define AppVersion "1.0.0"
#define AppExeName "SignatureBridge.exe"

[Setup]
AppId={{A8E488DB-0AA2-4B0D-9AD8-A95D9B73D356}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=.
OutputBaseFilename=SignatureBridgeInstaller
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "..\SignatureBridge\bin\Release\net8.0-windows\publish\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\SignatureBridge\bin\Release\net8.0-windows\publish\config.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\SignatureBridge\bin\Release\net8.0-windows\publish\Microsoft.Web.WebView2.Core.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\SignatureBridge\bin\Release\net8.0-windows\publish\WebView2Loader.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#AppName}"; ValueData: """{app}\{#AppExeName}"""; Flags: uninsdeletevalue

[Code]
function IsDotNet8Installed: Boolean;
var
  Version: string;
begin
  Result := False;
  if RegQueryStringValue(HKLM64, 'SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedhost', 'Version', Version) then
  begin
    Result := CompareVersion(Version, '8.0.0') >= 0;
  end;
end;

function InitializeSetup(): Boolean;
begin
  if not IsDotNet8Installed() then
  begin
    MsgBox('.NET 8 Desktop Runtime is required. Install it first, then rerun setup.', mbCriticalError, MB_OK);
    Result := False;
  end
  else
  begin
    Result := True;
  end;
end;
