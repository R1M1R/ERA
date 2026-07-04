param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIp,

    [string]$User = "ubuntu",
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
    [string]$ApiUrl = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$FrontendDir = Join-Path $Root "frontend"

if (-not $ApiUrl) {
    $ApiUrl = "http://$ServerIp"
}

if (-not (Test-Path $SshKeyPath)) {
    throw "SSH key not found: $SshKeyPath"
}

$sshArgs = @("-i", $SshKeyPath, "-o", "StrictHostKeyChecking=accept-new")
$target = "${User}@${ServerIp}"
$archive = Join-Path $env:TEMP "era-frontend-dist.tgz"

Write-Host "[ERA/OCI] Building frontend with VITE_API_URL=$ApiUrl"
Push-Location $FrontendDir
$env:VITE_API_URL = $ApiUrl
npm run build
Pop-Location

Write-Host "[ERA/OCI] Packaging dist..."
if (Test-Path $archive) { Remove-Item $archive -Force }
tar -czf $archive -C (Join-Path $FrontendDir "dist") .

Write-Host "[ERA/OCI] Uploading to server..."
& scp @sshArgs $archive "${target}:~/era-frontend-dist.tgz"

$remoteScript = @'
set -eu
sudo mkdir -p /var/www/era-frontend
sudo rm -rf /tmp/era-frontend-dist
mkdir -p /tmp/era-frontend-dist
tar -xzf ~/era-frontend-dist.tgz -C /tmp/era-frontend-dist
sudo rsync -av --delete /tmp/era-frontend-dist/ /var/www/era-frontend/
rm -f ~/era-frontend-dist.tgz
echo "[ERA] Frontend installed to /var/www/era-frontend"
'@

& ssh @sshArgs $target $remoteScript
Remove-Item $archive -Force

Write-Host "[ERA/OCI] Frontend deployed: $ApiUrl"
