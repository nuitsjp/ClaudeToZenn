param (
    [Parameter(Mandatory = $true)]
    [string] $ExtensionId
)
$extensionName = "jp.nuits.claude_to_zenn"
$modulePath = Join-Path $PSScriptRoot "ClaudeToZenn\bin\Debug\net48\ClaudeToZenn.exe"
$manifestPath = Join-Path $PSScriptRoot "ClaudeToZenn\bin\Debug\net48\manifest.json"

# マニフェストファイルの内容を動的に生成
$manifestContent = @{
    name = $extensionName
    description = "ClaudeToZenn Native Messaging Host"
    path = $modulePath
    type = "stdio"
    allowed_origins = @(
        "chrome-extension://*/"
    )
} | ConvertTo-Json

# マニフェストファイルを作成または更新
Set-Content -Path $manifestPath -Value $manifestContent

# ユーザー固有のインストールの場合
$registryPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$extensionName"

# レジストリキーが存在しない場合は作成
if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

# マニフェストファイルへのパスを設定
Set-ItemProperty -Path $registryPath -Name "(Default)" -Value $manifestPath

Write-Host "ClaudeToZenn Native Messaging Host (jp.nuits.claude_to_zenn) has been registered successfully."
Write-Host "Module Path: $modulePath"
Write-Host "Manifest Path: $manifestPath"