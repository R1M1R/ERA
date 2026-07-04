param(
    [string]$ApiDomain = "",
    [string]$FrontendDomain = "",
    [string]$ServerIp = "",
    [string]$OpenAiKey = "",
    [switch]$UseIpOnly,
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519"
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

function Ensure-SshKey {
    param([string]$KeyPath)
    $pubPath = "$KeyPath.pub"
    if (Test-Path $KeyPath) {
        Write-Host "[ERA] SSH key found: $KeyPath"
        return
    }

    $sshDir = Split-Path $KeyPath -Parent
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }

    Write-Host "[ERA] Generating SSH key (ed25519)..."
    ssh-keygen -t ed25519 -f $KeyPath -N '""' -C "era-oracle-cloud"
    Write-Host "[ERA] Created: $KeyPath"
}

function Show-PublicKey {
    param([string]$KeyPath)
    $pubPath = "$KeyPath.pub"
    if (-not (Test-Path $pubPath)) {
        throw "Public key not found: $pubPath"
    }

    Write-Host ""
    Write-Host "========== COPY TO OCI (SSH keys) =========="
    Get-Content $pubPath
    Write-Host "============================================"
    Write-Host ""
}

Write-Host "[ERA/OCI] Windows prep for Oracle Cloud Always Free"
Write-Host ""

Ensure-SshKey -KeyPath $SshKeyPath
Show-PublicKey -KeyPath $SshKeyPath

if ($UseIpOnly) {
    if (-not $ServerIp) {
        $ServerIp = Read-Host "Enter Oracle instance Public IP"
    }
    $FrontendDomain = $ServerIp
    $ApiDomain = $ServerIp
    Write-Host "[ERA] IP-only mode: CORS will allow http://$ServerIp"
} else {
    if (-not $ApiDomain) {
        $ApiDomain = Read-Host "API domain (e.g. api.example.com)"
    }
    if (-not $FrontendDomain) {
        $FrontendDomain = Read-Host "Frontend domain (e.g. example.com)"
    }
}

if (-not $OpenAiKey) {
    $OpenAiKey = Read-Host "OpenAI API key (sk-...)"
}

$envScript = Join-Path $PSScriptRoot "generate-prod-env.ps1"
$envOutput = Join-Path $Root ".env.production.generated"

if ($UseIpOnly) {
    & $envScript -ApiDomain $ApiDomain -FrontendDomain $FrontendDomain -OpenAiKey $OpenAiKey -Output $envOutput
    $content = Get-Content $envOutput -Raw
    $content = $content -replace "CORS_ORIGINS=.*", "CORS_ORIGINS=http://${ServerIp}"
    Set-Content -Path $envOutput -Value $content -Encoding UTF8
    Write-Host "[ERA] Updated CORS for IP-only: http://$ServerIp"
} else {
    & $envScript -ApiDomain $ApiDomain -FrontendDomain $FrontendDomain -OpenAiKey $OpenAiKey -Output $envOutput
}

if (-not $ServerIp) {
    $ServerIp = Read-Host "Oracle Public IP (press Enter to skip upload commands)"
}

Write-Host ""
Write-Host "========== NEXT STEPS =========="
Write-Host "1. OCI Console: create VM.Standard.A1.Flex (2 OCPU / 8 GB, Ubuntu 22.04 ARM)"
Write-Host "2. Paste SSH public key above into instance creation form"
Write-Host "3. Security List: open TCP 22, 80, 443"
Write-Host ""

if ($ServerIp) {
    Write-Host "4. Upload .env and bootstrap:"
    Write-Host "   ssh -i `"$SshKeyPath`" ubuntu@$ServerIp `"mkdir -p ~/ERA`""
    Write-Host "   scp -i `"$SshKeyPath`" `"$envOutput`" ubuntu@${ServerIp}:~/ERA/.env"
    Write-Host "   ssh -i `"$SshKeyPath`" ubuntu@$ServerIp `"git clone https://github.com/R1M1R/ERA.git ~/ERA && cd ~/ERA && bash scripts/oracle-cloud-bootstrap.sh`""
    Write-Host ""
    Write-Host "Or run: .\scripts\upload-to-oci.ps1 -ServerIp $ServerIp -SshKeyPath `"$SshKeyPath`""
} else {
    Write-Host "4. When VM is ready, run:"
    Write-Host "   .\scripts\upload-to-oci.ps1 -ServerIp YOUR_IP -SshKeyPath `"$SshKeyPath`""
}

Write-Host ""
Write-Host "Full guide: deploy/oracle-cloud/README.md"
Write-Host "==============================="
