param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIp,

    [string]$OpenAiKey = "",
    [string]$ApiDomain = "",
    [string]$FrontendDomain = "",
    [string]$Email = "",
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
    [switch]$IpOnly,
    [switch]$SkipFrontend
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot

Write-Host "========================================"
Write-Host " ERA — Full Oracle Cloud Deploy"
Write-Host "========================================"
Write-Host ""

if ($IpOnly) {
    Write-Host "[1/4] Preparing IP-only config..."
    & (Join-Path $ScriptDir "oracle-cloud-prep.ps1") -UseIpOnly -ServerIp $ServerIp -OpenAiKey $OpenAiKey -SshKeyPath $SshKeyPath
} elseif ($ApiDomain -and $FrontendDomain) {
    Write-Host "[1/4] Preparing domain config..."
    & (Join-Path $ScriptDir "oracle-cloud-prep.ps1") -ApiDomain $ApiDomain -FrontendDomain $FrontendDomain -ServerIp $ServerIp -OpenAiKey $OpenAiKey -SshKeyPath $SshKeyPath
} else {
    Write-Host "[1/4] Interactive prep..."
    & (Join-Path $ScriptDir "oracle-cloud-prep.ps1") -ServerIp $ServerIp -SshKeyPath $SshKeyPath
}

Write-Host ""
Write-Host "[2/4] Uploading .env and bootstrapping backend..."
$bootstrapArgs = @{
    ServerIp     = $ServerIp
    SshKeyPath   = $SshKeyPath
    RunBootstrap = $true
}
if ($IpOnly) {
    $bootstrapArgs["IpOnlyNginx"] = $true
} elseif ($ApiDomain -and $FrontendDomain) {
    $bootstrapArgs["WithNginx"] = $true
    $bootstrapArgs["ApiDomain"] = $ApiDomain
    $bootstrapArgs["FrontendDomain"] = $FrontendDomain
    if ($Email) { $bootstrapArgs["Email"] = $Email }
}
& (Join-Path $ScriptDir "upload-to-oci.ps1") @bootstrapArgs

if (-not $SkipFrontend) {
    Write-Host ""
    Write-Host "[3/4] Building and uploading frontend..."
    $apiUrl = if ($IpOnly) { "http://$ServerIp" } elseif ($ApiDomain) { "https://$ApiDomain" } else { "http://${ServerIp}:8000" }
    & (Join-Path $ScriptDir "upload-frontend-to-oci.ps1") -ServerIp $ServerIp -SshKeyPath $SshKeyPath -ApiUrl $apiUrl
} else {
    Write-Host ""
    Write-Host "[3/4] Skipping frontend upload."
}

Write-Host ""
Write-Host "[4/4] Verifying deployment..."
$verifyArgs = @{
    ServerIp   = $ServerIp
    SshKeyPath = $SshKeyPath
}
if ($IpOnly) {
    $verifyArgs["IpOnly"] = $true
} elseif ($ApiDomain) {
    $verifyArgs["PublicApiUrl"] = "https://$ApiDomain"
}
& (Join-Path $ScriptDir "verify-deployment.ps1") @verifyArgs

Write-Host ""
Write-Host "========================================"
Write-Host " Deploy complete."
Write-Host "========================================"
