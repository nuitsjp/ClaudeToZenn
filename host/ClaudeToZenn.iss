; 以下の値は外部から定義されることを想定
;#define MyAppName "ClaudeToZenn"
;#define MyAppVersion "0.0.1"
;#define MyOutputDir "ClaudeToZenn\bin\Release\Installer"
;#define MyOutputBaseFilename "ClaudeToZenn-0.0.1-setup"

#define MyAppPublisher "nuits.jp"
#define MyAppURL "https://github.com/nuitsjp/ClaudeToZenn"
#define MyAppExeName MyAppName + ".exe"

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
OutputDir={#MyOutputDir}
OutputBaseFilename={#MyOutputBaseFilename}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
DisableWelcomePage=yes
DisableDirPage=yes
; サイレントインストールのための追加設定
DisableFinishedPage=yes
SetupMutex={{24254DEA-9933-461C-94A7-136CD235EA38}setup

[Languages]
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Files]
Source: "{#SourcePath}{#MyAppName}\bin\Release\publish\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}{#MyAppName}\bin\Release\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#SourcePath}manifest.json"; DestDir: "{app}"; Flags: ignoreversion; AfterInstall: ModifyManifest

[Registry]
Root: HKCU; Subkey: "Software\Google\Chrome\NativeMessagingHosts\jp.nuits.claude_to_zenn"; ValueType: string; ValueName: ""; ValueData: "{app}\manifest.json"; Flags: uninsdeletevalue

[Code]
procedure ModifyManifest;
var
  Lines: TStringList;
  NewPath: String;
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
        StringChangeEx(NewPath, '\', '\\', True);
        Lines[I] := '  "path": "' + NewPath + '",';
        Break;
      end;
    end;
    Lines.SaveToFile(ExpandConstant('{app}\manifest.json'));
  finally
    Lines.Free;
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if not WizardSilent then
  begin
    // 通常のインストール時の追加処理（必要な場合）
  end;
end;