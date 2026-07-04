param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIp,

    [string]$User = "ubuntu",
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
    [string]$PublicApiUrl = "",
    [switch]$IpOnly
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SshKeyPath)) {
    throw "SSH key not found: $SshKeyPath"
}

$sshArgs = @("-i", $SshKeyPath, "-o", "StrictHostKeyChecking=accept-new")
$target = "${User}@${ServerIp}"
if (-not $PublicApiUrl) {
    $PublicApiUrl = if ($IpOnly) { "http://$ServerIp" } else { "" }
}

Write-Host "[ERA/OCI] Verifying deployment on $target"
Write-Host ""

function Test-Remote {
    param([string]$Label, [string]$Command)
    Write-Host -NoNewline "  $Label ... "
    $result = & ssh @sshArgs $target $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK"
        if ($result) { Write-Host "    $result" }
        return $true
    }
    Write-Host "FAIL"
    if ($result) { Write-Host "    $result" }
    return $false
}

$ok = $true
$ok = (Test-Remote "SSH connection" "echo connected") -and $ok
$ok = (Test-Remote "Docker running" "docker info >/dev/null && echo docker ok") -and $ok
$ok = (Test-Remote "API health (local)" "curl -fsS http://127.0.0.1:8000/health") -and $ok
$ok = (Test-Remote "Containers up" "docker ps --format '{{.Names}}: {{.Status}}' | grep era") -and $ok

if ($IpOnly) {
    $ok = (Test-Remote "Nginx API proxy" "curl -fsS http://127.0.0.1/health") -and $ok
    $ok = (Test-Remote "Frontend files" "test -f /var/www/era-frontend/index.html && echo index.html present") -and $ok
}

Write-Host ""
if ($PublicApiUrl) {
    try {
        $publicHealth = Invoke-RestMethod -Uri "$PublicApiUrl/health" -TimeoutSec 10
        Write-Host "  Public API ($PublicApiUrl/health) ... OK"
        Write-Host "    $($publicHealth | ConvertTo-Json -Compress)"
    } catch {
        Write-Host "  Public API ($PublicApiUrl/health) ... FAIL (DNS, Security List, or Nginx?)"
        $ok = $false
    }
} else {
    Write-Host "  Public API check skipped (set -PublicApiUrl or -IpOnly)"
}

Write-Host ""
if ($ok) {
    Write-Host "[ERA/OCI] Deployment looks healthy."
    if ($IpOnly) {
        Write-Host "  Open in browser: http://$ServerIp/"
    }
} else {
    Write-Host "[ERA/OCI] Some checks failed. See deploy/oracle-cloud/README.md troubleshooting."
    exit 1
}
