param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIp,

    [string]$User = "ubuntu",
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
    [string]$EnvFile = "",
    [switch]$RunBootstrap,
    [switch]$WithNginx,
    [switch]$IpOnlyNginx,
    [string]$ApiDomain = "",
    [string]$FrontendDomain = "",
    [string]$Email = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

if (-not $EnvFile) {
    $EnvFile = Join-Path $Root ".env.production.generated"
}

if (-not (Test-Path $EnvFile)) {
    throw "Env file not found: $EnvFile. Run .\scripts\oracle-cloud-prep.ps1 first."
}

if (-not (Test-Path $SshKeyPath)) {
    throw "SSH key not found: $SshKeyPath"
}

$sshArgs = @("-i", $SshKeyPath, "-o", "StrictHostKeyChecking=accept-new")
$target = "${User}@${ServerIp}"

Write-Host "[ERA/OCI] Target: $target"
Write-Host "[ERA/OCI] Uploading .env..."
& scp @sshArgs $EnvFile "${target}:~/era.env.upload"

if ($RunBootstrap) {
    Write-Host "[ERA/OCI] Cloning repo and running bootstrap (may take several minutes)..."
    $nginxArgs = ""
    if ($IpOnlyNginx) {
        $nginxArgs = "--ip-only-nginx"
    } elseif ($WithNginx) {
        if (-not $ApiDomain -or -not $FrontendDomain) {
            throw "WithNginx requires -ApiDomain and -FrontendDomain"
        }
        $nginxArgs = "--with-nginx --api-domain $ApiDomain --frontend-domain $FrontendDomain"
        if ($Email) { $nginxArgs += " --email $Email" }
    }

    $remoteScript = @"
set -eu
if [ ! -d ~/ERA/.git ]; then
  rm -rf ~/ERA
  git clone https://github.com/R1M1R/ERA.git ~/ERA
fi
mv ~/era.env.upload ~/ERA/.env
chmod 600 ~/ERA/.env
cd ~/ERA
bash scripts/oracle-cloud-bootstrap.sh $nginxArgs
"@

    & ssh @sshArgs $target $remoteScript
    Write-Host "[ERA/OCI] Bootstrap finished."
    & ssh @sshArgs $target "curl -fsS http://127.0.0.1:8000/health || true"
} else {
    Write-Host "[ERA/OCI] .env uploaded to ~/era.env.upload"
    Write-Host "[ERA/OCI] Run bootstrap:"
    Write-Host "  .\scripts\upload-to-oci.ps1 -ServerIp $ServerIp -RunBootstrap"
}
