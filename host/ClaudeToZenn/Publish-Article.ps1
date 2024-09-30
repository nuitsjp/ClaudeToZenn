#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoPath,

    [Parameter(Mandatory=$true)]
    [string]$ArticleTitle,

    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

# エラーが発生した場合にスクリプトを停止
$ErrorActionPreference = "Stop"

# 関数: エラーメッセージを表示して終了
function Show-ErrorAndExit($message) {
    Write-Host "エラー: $message" -ForegroundColor Red
    exit 1
}

# リポジトリパスの存在チェック
if (-not (Test-Path $RepoPath)) {
    Show-ErrorAndExit "指定されたリポジトリのパスが存在しません。"
}

# ファイルの存在チェック
if (-not (Test-Path $FilePath)) {
    Show-ErrorAndExit "指定されたファイルが存在しません。"
}

# リポジトリに移動
try {
    Set-Location $RepoPath
}
catch {
    Show-ErrorAndExit "リポジトリへの移動に失敗しました: $_"
}

# ファイルの内容を表示
Write-Host "記事の内容:"
Write-Host "-------------------"
Get-Content $FilePath -Encoding UTF8
Write-Host "-------------------"

# 記事発行の確認
$confirmPublish = Read-Host "上記の内容で記事を発行しますか？ (Y/N)"
if ($confirmPublish -ne "Y" -and $confirmPublish -ne "y") {
    Write-Host "記事の発行をキャンセルしました。ファイルを削除します。"
    try {
        Remove-Item $FilePath -Force
        Write-Host "ファイルが正常に削除されました。" -ForegroundColor Green
    }
    catch {
        Show-ErrorAndExit "ファイルの削除に失敗しました: $_"
    }
    exit 0
}

# Git操作の実行
try {
    Write-Host "最新の変更を取得中..."
    git pull

    Write-Host "記事を追加中..."
    git add $FilePath

    Write-Host "記事を発行中..."
    git commit -m "記事を発行: $ArticleTitle"

    Write-Host "変更をプッシュ中..."
    git push

    Write-Host "記事が正常に発行されました。" -ForegroundColor Green

    Pause
}
catch {
    Show-ErrorAndExit "Git操作中にエラーが発生しました: $_"
}