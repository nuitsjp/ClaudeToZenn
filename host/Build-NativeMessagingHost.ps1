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

    throw "Inno Setup Compiler (ISCC.exe) が見つかりません。手動でパスを指定してください。"
}

# エラーが発生した場合にスクリプトを停止する
$ErrorActionPreference = "Stop"

try {
    # .NET Framework アプリケーションをビルドする
    Write-Host "アプリケーションのビルドを開始します..."
    dotnet build .\ClaudeToZenn.sln -c Release 
    Write-Host "アプリケーションのビルドが完了しました。"

    # Inno Setup Compiler のパスを取得
    $innoSetupCompiler = Find-InnoSetupCompiler
    Write-Host "Inno Setup Compiler が見つかりました: $innoSetupCompiler"

    # Inno Setup スクリプトのパス
    $scriptPath = ".\ClaudeToZenn.iss"

    # 出力ディレクトリ
    $outputDir = ".\ClaudeToZenn\bin\Release\Installer"

    # 出力ディレクトリが存在しない場合は作成
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
        Write-Host "出力ディレクトリを作成しました: $outputDir"
    }

    # Inno Setup Compiler を実行
    Write-Host "インストーラーのビルドを開始します..."
    $process = Start-Process -FilePath $innoSetupCompiler -ArgumentList "`"$scriptPath`"", "/O`"$outputDir`"" -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        throw "インストーラーのビルドに失敗しました。終了コード: $($process.ExitCode)"
    }
    Write-Host "インストーラーのビルドが完了しました。"

    $installerPath = Get-ChildItem -Path $outputDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    $hash = Get-FileHash -Path $installerPath -Algorithm SHA256
    Write-Host "インストーラーが作成されました: $installerPath"
    Write-Host "SHA256 Hash: $($hash.Hash)"
} catch {
    Write-Error "エラーが発生しました: $_"
    exit 1
}

Write-Host "ビルドプロセスが正常に完了しました。"