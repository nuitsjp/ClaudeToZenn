param(
    [Parameter(Mandatory=$false)]
    [string]$Version
)

# バージョンオブジェクトを作成する関数
function New-Version {
    param([string]$VersionString)
    
    if ($VersionString -match '^v?(\d+)\.(\d+)\.(\d+)$') {
        return [PSCustomObject]@{
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = [int]$Matches[3]
            ToString = { "v$($this.Major).$($this.Minor).$($this.Patch)" }
        }
    }
    throw "Invalid version format: $VersionString"
}

# 最新のGitタグからバージョンを取得し、インクリメントする関数
function Get-NextVersion {
    $versionTags = git tag -l "v*.*.*" | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' }
    if (-not $versionTags) {
        return "1.0.0"
    }
    
    $latestVersion = $versionTags | ForEach-Object { New-Version $_ } | Sort-Object Major,Minor,Patch | Select-Object -Last 1
    $latestVersion.Patch++
    return $latestVersion.ToString()
}

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
    # バージョン番号の決定
    if (-not $Version) {
        $Version = Get-NextVersion
        Write-Host "自動生成されたバージョン: $Version"
    } elseif (-not ($Version -match '^\d+\.\d+\.\d+$')) {
        throw "無効なバージョン番号です。正しい形式は 'X.Y.Z' です。"
    }

    # バージョン番号から 'v' プレフィックスを削除
    $VersionWithoutV = $Version -replace '^v', ''

    # .NET Framework アプリケーションをビルドする
    Write-Host "アプリケーションのビルドを開始します (バージョン: $VersionWithoutV)..."
    dotnet build .\ClaudeToZenn.sln -c Release /p:ReleaseVersion=$VersionWithoutV
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
    $process = Start-Process -FilePath $innoSetupCompiler -ArgumentList "`"$scriptPath`"", "/O`"$outputDir`"", "/DMyAppVersion=$VersionWithoutV" -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        throw "インストーラーのビルドに失敗しました。終了コード: $($process.ExitCode)"
    }
    Write-Host "インストーラーのビルドが完了しました。"

    $installerPath = Get-ChildItem -Path $outputDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    $hash = Get-FileHash -Path $installerPath -Algorithm SHA256
    Write-Host "インストーラーが作成されました: $installerPath"
    Write-Host "SHA256 Hash: $($hash.Hash)"

    # 新しいGitタグを作成
    $newTag = "v$VersionWithoutV"
    git tag -a $newTag -m "Release version $VersionWithoutV"
    git push origin $newTag
    Write-Host "新しいGitタグ '$newTag' を作成し、リモートにプッシュしました。"

} catch {
    Write-Error "エラーが発生しました: $_"
    exit 1
}

Write-Host "ビルドプロセスが正常に完了しました。"