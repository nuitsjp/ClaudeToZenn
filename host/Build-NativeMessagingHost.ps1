# Inno Setup Compiler のパスを見つける関数
function Find-InnoSetupCompiler {
    $possiblePaths = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
        "${env:LocalAppData}\Programs\Inno Setup 6\ISCC.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    Write-Error "Inno Setup Compiler (ISCC.exe) が見つかりません。手動でパスを指定してください。"
    exit 1
}

# エラーが発生した場合にスクリプトを停止する
$ErrorActionPreference = "Stop"

# .NET Framework アプリケーションをビルドする
dotnet build .\ClaudeToZenn.sln -c Release 

# Inno Setup Compiler のパスを取得
$innoSetupCompiler = Find-InnoSetupCompiler

# Inno Setup スクリプトのパス
$scriptPath = ".\ClaudeToZenn.iss"

# 出力ディレクトリ
$outputDir = ".\ClaudeToZenn\bin\Release\Installer"

# 出力ディレクトリが存在しない場合は作成
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir
}

# Inno Setup Compiler を実行
try {
    $process = Start-Process -FilePath $innoSetupCompiler -ArgumentList "`"$scriptPath`"", "/O`"$outputDir`"" -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        Write-Error "インストーラーのビルドに失敗しました。終了コード: $($process.ExitCode)"
    }
} catch {
    Write-Error "エラーが発生しました: $_"
}