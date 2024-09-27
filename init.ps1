# クローンしたリポジトリのルートディレクトリに移動していることを前提とします
# 必要なフォルダとファイルを作成するPowerShellスクリプト

# フォルダ作成
New-Item -ItemType Directory -Path "src" -Force
New-Item -ItemType Directory -Path "src\images" -Force

# ファイル作成
$filesToCreate = @(
    "src\manifest.json",
    "src\background.js",
    "src\content.js",
    "src\popup.html",
    "src\popup.js",
    "src\styles.css"
)

foreach ($file in $filesToCreate) {
    if (!(Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force
        Write-Host "Created file: $file"
    } else {
        Write-Host "File already exists: $file"
    }
}

# アイコンファイルのプレースホルダー作成
$iconSizes = @(16, 48, 128)
foreach ($size in $iconSizes) {
    $iconPath = "src\images\icon$size.png"
    if (!(Test-Path $iconPath)) {
        New-Item -ItemType File -Path $iconPath -Force
        Write-Host "Created placeholder icon: $iconPath"
    } else {
        Write-Host "Icon already exists: $iconPath"
    }
}

Write-Host "ClaudeToZenn extension structure has been created successfully."