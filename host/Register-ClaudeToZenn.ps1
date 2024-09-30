$hostName = "jp.nuits.claude_to_zenn"
$modulePath = Join-Path $PSScriptRoot "ClaudeToZenn\bin\Debug\net481\ClaudeToZenn.exe"
$manifestPath = Join-Path $PSScriptRoot "ClaudeToZenn\bin\Debug\net481\manifest.json"

# マニフェストファイルの内容を動的に生成
$manifestContent = @{
    name = $hostName
    description = "ClaudeToZenn Native Messaging Host"
    path = $modulePath
    type = "stdio"
    allowed_origins = @(
        "chrome-extension://biegnbaehdjbljpmlhmbmafggijcbhhm/"
    )
} | ConvertTo-Json

# マニフェストファイルを作成または更新
Set-Content -Path $manifestPath -Value $manifestContent

# ユーザー固有のインストールの場合
$registryPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$hostName"

# マシン全体のインストールの場合は以下を使用
# $registryPath = "HKLM:\Software\Google\Chrome\NativeMessagingHosts\$hostName"

# レジストリキーが存在しない場合は作成
if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

# マニフェストファイルへのパスを設定
Set-ItemProperty -Path $registryPath -Name "(Default)" -Value $manifestPath

Write-Host "ClaudeToZenn Native Messaging Host (jp.nuits.claude_to_zenn) has been registered successfully."
Write-Host "Module Path: $modulePath"
Write-Host "Manifest Path: $manifestPath"