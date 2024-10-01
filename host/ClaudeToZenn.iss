#define MyAppName "ClaudeToZenn"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "nuits.jp"
#define MyAppURL "https://github.com/nuitsjp/ClaudeToZenn"
#define MyAppExeName "ClaudeToZenn.exe"

[Setup]
AppId={{24254DEA-9933-461C-94A7-136CD235EA38}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\{#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename={#MyAppName}_Setup_{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
DisableWelcomePage=yes
DisableDirPage=yes

[Languages]
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Files]
Source: "{#SourcePath}bin\Release\net481\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}bin\Release\net481\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#SourcePath}manifest.json"; DestDir: "{app}"; Flags: ignoreversion; AfterInstall: ModifyManifest

[Registry]
Root: HKCU; Subkey: "Software\Google\Chrome\NativeMessagingHosts\jp.nuits.claude_to_zenn"; ValueType: string; ValueName: ""; ValueData: "{app}\manifest.json"; Flags: uninsdeletevalue

[Code]
procedure ModifyManifest;
var
  Lines: TStringList;
  Content, NewPath: String;
  I: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(ExpandConstant('{app}\manifest.json'));
    for I := 0 to Lines.Count - 1 do
    begin
      if Pos('"path":', Lines[I]) > 0 then
      begin
        NewPath := ExpandConstant('{app}\{#MyAppExeName}');
        NewPath := StringReplace(NewPath, '\', '\\', [rfReplaceAll]);
        Lines[I] := '  "path": "' + NewPath + '",';
        Break;
      end;
    end;
    Lines.SaveToFile(ExpandConstant('{app}\manifest.json'));
  finally
    Lines.Free;
  end;
end;

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent