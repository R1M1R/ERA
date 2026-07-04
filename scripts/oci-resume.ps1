param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIp,

    [string]$OpenAiKey = "",
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
    [switch]$IpOnly,
    [switch]$SetupGithubActions
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$StateFile = Join-Path $Root ".oci-deploy.local.json"

$state = [ordered]@{
    serverIp    = $ServerIp
    sshKeyPath  = $SshKeyPath
    ipOnly      = [bool]$IpOnly
    preparedAt  = (Get-Date).ToString("o")
    deployedAt  = $null
    publicUrl   = if ($IpOnly) { "http://$ServerIp/" } else { $null }
}

if ($OpenAiKey) {
    $deployArgs = @{
        ServerIp   = $ServerIp
        SshKeyPath = $SshKeyPath
        OpenAiKey  = $OpenAiKey
    }
    if ($IpOnly) { $deployArgs["IpOnly"] = $true }

    & (Join-Path $PSScriptRoot "deploy-all-oci.ps1") @deployArgs

    $state.deployedAt = (Get-Date).ToString("o")
    $state | ConvertTo-Json | Set-Content $StateFile -Encoding UTF8
    Write-Host "[ERA] State saved: $StateFile"
} else {
    Write-Host "[ERA] No -OpenAiKey provided. Running verification only..."
    $verifyArgs = @{ ServerIp = $ServerIp; SshKeyPath = $SshKeyPath }
    if ($IpOnly) { $verifyArgs["IpOnly"] = $true }
    & (Join-Path $PSScriptRoot "verify-deployment.ps1") @verifyArgs
}

if ($SetupGithubActions) {
    & (Join-Path $PSScriptRoot "setup-github-actions.ps1") -ServerIp $ServerIp -SshKeyPath $SshKeyPath
}

Write-Host ""
Write-Host "[ERA] Resume later:"
Write-Host "  .\scripts\oci-resume.ps1 -ServerIp $ServerIp -IpOnly"
