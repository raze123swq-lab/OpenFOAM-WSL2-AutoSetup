[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Config)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
try {
    $Config = (Resolve-Path -LiteralPath $Config).Path
    $settings = Get-Content -LiteralPath $Config -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($settings.user -notmatch '^[a-z_][a-z0-9_-]{0,31}$' -or $settings.user -eq 'root') { throw 'Invalid Linux user.' }
    if ($settings.distro -ne 'Ubuntu-22.04') { throw 'Unsupported distro.' }
    $repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $linuxRepo = ConvertTo-LinuxPath $repo $settings.distro $settings.user
    $linuxConfig = ConvertTo-LinuxPath $Config $settings.distro $settings.user
    $logdir = Join-Path (Split-Path -Parent $Config) 'logs'
    New-Item -ItemType Directory -Path $logdir -Force | Out-Null
    $log = Join-Path $logdir ('viewer-' + (Get-Date -Format 'yyyyMMdd_HHmmss_fff'))
    $r = Invoke-Native wsl.exe @('-d',$settings.distro,'-u',$settings.user,'--exec','python3',"$linuxRepo/scripts/linux/launch-viewer.py",$linuxConfig) $log
    Write-Host $r.Stdout
    exit 0
} catch { Write-Host "ERROR: $_"; exit 1 }
