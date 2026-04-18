#define AppName "Signature Bridge"
#define AppVersion "1.2.0"
#define AppExeName "SignatureBridge.exe"
#define AppPublisher "MyPerformance"
#define AppURL "https://github.com/dawideq5/myperformance-driver"

[Setup]
AppId={{A8E488DB-0AA2-4B0D-9AD8-A95D9B73D356}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=.
OutputBaseFilename=SignatureBridge-Setup
Compression=lzma2/ultra
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
WizardStyle=Modern
WizardImageFile=installer\wizard-image.bmp
WizardSmallImageFile=installer\wizard-small.bmp
UninstallDisplayIcon={app}\{#AppExeName}
DisableDirPage=no
DisableProgramGroupPage=yes

[Files]
Source: "..\SignatureBridge\bin\Release\net10.0-windows\win-x64\publish\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\SignatureBridge\bin\Release\net10.0-windows\win-x64\publish\config.json"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#AppName}"; ValueData: """{app}\{#AppExeName}"""; Flags: uninsdeletevalue
