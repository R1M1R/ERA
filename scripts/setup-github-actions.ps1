param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIp,

    [string]$User = "ubuntu",
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SshKeyPath)) {
    throw "SSH key not found: $SshKeyPath. Run .\scripts\oracle-cloud-prep.ps1 first."
}

$privateKey = Get-Content $SshKeyPath -Raw

Write-Host ""
Write-Host "========================================"
Write-Host " GitHub Actions Secrets"
Write-Host " https://github.com/R1M1R/ERA/settings/secrets/actions"
Write-Host "========================================"
Write-Host ""
Write-Host "Add these 3 repository secrets:"
Write-Host ""
Write-Host "1. SSH_HOST"
Write-Host "   $ServerIp"
Write-Host ""
Write-Host "2. SSH_USER"
Write-Host "   $User"
Write-Host ""
Write-Host "3. SSH_PRIVATE_KEY"
Write-Host "   (paste entire private key below, including BEGIN/END lines)"
Write-Host "----------------------------------------"
Write-Host $privateKey
Write-Host "----------------------------------------"
Write-Host ""
Write-Host "Then run workflows:"
Write-Host "  Actions -> Deploy Backend  (oci_profile: true)"
Write-Host "  Actions -> Deploy Frontend -> VITE_API_URL=http://$ServerIp"
Write-Host ""
Write-Host "SECURITY: never commit the private key to git."
Write-Host "========================================"
