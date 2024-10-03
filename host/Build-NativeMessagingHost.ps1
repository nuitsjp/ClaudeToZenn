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
        }
    }
    throw "Invalid version format: $VersionString"
}

# バージョンオブジェクトを文字列に変換する関数
function ConvertTo-VersionString {
    param([PSCustomObject]$Version)
    return "v$($Version.Major).$($Version.Minor).$($Version.Patch)"
}

# 最新のGitタグからバージョンを取得し、インクリメントする関数
function Get-NextVersion {
    $versionTags = git tag -l "v*.*.*" | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' }
    if (-not $versionTags) {
        return "1.0.0"
    }
    
    $latestVersion = $versionTags | ForEach-Object { New-Version $_ } | Sort-Object Major,Minor,Patch | Select-Object -Last 1
    $latestVersion.Patch++
    return ConvertTo-VersionString $latestVersion
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

# PowerShellForGitHub モジュールをインストールおよびインポート
if (-not (Get-Module -ListAvailable -Name PowerShellForGitHub)) {
    Install-Module -Name PowerShellForGitHub -Force -Scope CurrentUser
}
Import-Module PowerShellForGitHub

# エラーが発生した場合にスクリプトを停止する
$ErrorActionPreference = "Stop"

try {
    # リポジトリーの最新化
    git pull

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

    # アプリケーション名を定義
    $MyAppName = "ClaudeToZenn"

    # 出力ファイル名を設定
    $outputBaseFilename = "{0}-{1}-setup" -f $MyAppName, $VersionWithoutV

    # Inno Setup Compiler を実行
    Write-Host "インストーラーのビルドを開始します..."
    $process = Start-Process -FilePath $innoSetupCompiler -ArgumentList @(
        "`"$scriptPath`"",
        "/DMyAppName=`"$MyAppName`"",
        "/DMyAppVersion=$VersionWithoutV",
        "/DMyOutputDir=`"$outputDir`"",
        "/DMyOutputBaseFilename=`"$outputBaseFilename`"",
        "/O`"$outputDir`""
    ) -NoNewWindow -PassThru -Wait
    
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

    # GitHub リリースの作成とインストーラーのアップロード
    $repoOwner = "nuitsjp"  # あなたの GitHub ユーザー名またはองかl名
    $repoName = "ClaudeToZenn"  # リポジトリ名

    # GitHub 認証情報を設定（環境変数から取得）
    $secureString = ($env:CLAUDE_TO_ZENN_GH_TOKEN | ConvertTo-SecureString -AsPlainText -Force)
    $cred = New-Object System.Management.Automation.PSCredential "username is ignored", $secureString
    Set-GitHubAuthentication -Credential $cred

    Write-Host "GitHub リリースの作成を開始します..."
    $releaseParams = @{
        OwnerName = $repoOwner
        RepositoryName = $repoName
        Tag = $newTag
        Name = "Release $VersionWithoutV"
        Body = "Release notes for version $VersionWithoutV"
        Draft = $false
        Prerelease = $false
    }
    $release = New-GitHubRelease @releaseParams

    Write-Host "インストーラーのアップロードを開始します..."
    $assetParams = @{
        OwnerName = $repoOwner
        RepositoryName = $repoName
        ReleaseId = $release.ID
        Path = $installerPath
        ContentType = "application/octet-stream"
    }
    $asset = New-GitHubReleaseAsset @assetParams

    Write-Host "GitHub リリースが作成され、インストーラーがアップロードされました。"
    Write-Host "リリース URL: $($release.HtmlUrl)"
    Write-Host "インストーラー URL: $($asset.BrowserDownloadUrl)"
} catch {
    Write-Error "エラーが発生しました: $_"
    exit 1
}

Write-Host "ビルドプロセスが正常に完了しました。"