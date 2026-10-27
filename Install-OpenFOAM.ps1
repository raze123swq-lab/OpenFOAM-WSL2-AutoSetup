# Requires Windows PowerShell 5.1 or newer. ASCII source.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-z_][a-z0-9_-]{0,31}$')][string]$LinuxUser,
    [Parameter(Mandatory=$true)][string]$ProjectDirectory,
    [ValidateSet('Ubuntu-22.04')][string]$Distro='Ubuntu-22.04',
    [switch]$AllowInstall, [switch]$VerifyOnly, [switch]$SkipGui
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/windows/Common.ps1')
try {
    if ($LinuxUser -eq 'root') { throw 'Use a normal Linux user, not root.' }
    if ([Environment]::OSVersion.Platform -ne 'Win32NT') { throw 'Windows is required.' }
    if ([Environment]::OSVersion.Version.Build -lt 22000) { throw 'This project targets Windows 11.' }
    $ProjectDirectory = [IO.Path]::GetFullPath($ProjectDirectory)
    if ($ProjectDirectory -match '["\r\n]' -or $ProjectDirectory.StartsWith('\\')) { throw 'Use a local drive path without quotes or newlines.' }
    $logs = Join-Path $ProjectDirectory ('logs/' + (Get-Date -Format 'yyyyMMdd_HHmmss_fff'))
    New-Item -ItemType Directory -Path $logs -Force | Out-Null
    if (Test-PendingRestart) {
        if (-not $VerifyOnly) { throw 'RESTART_REQUIRED: save your work, restart Windows manually, then rerun this command.' }
        Write-Host 'RESTART_PENDING: read-only verification may continue; installation is blocked until restart.'
    }
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { throw 'WSL unavailable. In an administrator terminal run: wsl --install -d Ubuntu-22.04. Then restart and rerun.' }
    $r = Invoke-Native wsl.exe @('--list','--verbose') (Join-Path $logs 'wsl-list') -UnicodeOutput -AllowFailure
    $version = Get-DistroVersion $r.Stdout $Distro
    if ($version -eq 0) {
        if (-not $AllowInstall -or $VerifyOnly) { throw 'Distro missing. Rerun with -AllowInstall after reviewing docs/install.md.' }
        $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $admin) { throw 'ADMIN_REQUIRED: reopen PowerShell as administrator and rerun the same command.' }
        if ((Read-Host 'Install WSL and Ubuntu-22.04? Type INSTALL') -cne 'INSTALL') { throw 'Installation not approved.' }
        & wsl.exe --install -d $Distro --no-launch
        if ($LASTEXITCODE -notin @(0,3010)) { throw "WSL installation failed: $LASTEXITCODE" }
        throw 'USER_ACTION_REQUIRED: restart if requested, open Ubuntu, create your chosen Linux user/password, then rerun. No automatic restart.'
    }
    if ($version -ne 2) { throw 'WSL2_REQUIRED: review your distro backup, then manually run wsl --set-version Ubuntu-22.04 2.' }
    $null = Invoke-Native wsl.exe @('-d',$Distro,'-u',$LinuxUser,'--exec','id','-u') (Join-Path $logs 'user')
    $repoLinux = ConvertTo-LinuxPath $PSScriptRoot $Distro $LinuxUser
    $projectLinux = ConvertTo-LinuxPath $ProjectDirectory $Distro $LinuxUser
    $prefix = @('-d',$Distro,'-u',$LinuxUser,'--exec')
    $null = Invoke-Native wsl.exe ($prefix + @('bash',"$repoLinux/scripts/linux/check-ubuntu.sh")) (Join-Path $logs 'ubuntu')
    $r = Invoke-Native wsl.exe ($prefix + @('bash',"$repoLinux/scripts/linux/verify.sh")) (Join-Path $logs 'verify-before') -AllowFailure
    if ($r.ExitCode -ne 0) {
        if (-not $AllowInstall -or $VerifyOnly) { throw 'Verification failed. Inspect logs; use -AllowInstall only for missing packages.' }
        if ((Read-Host 'Install missing packages using sudo? Type INSTALL; enter any sudo password yourself') -cne 'INSTALL') { throw 'Installation not approved.' }
        # Interactive sudo: no redirected stdin and no password capture.
        & wsl.exe @prefix bash "$repoLinux/scripts/linux/install-packages.sh" "$projectLinux/logs"
        if ($LASTEXITCODE -ne 0) { throw "Package installation failed: $LASTEXITCODE" }
    }
    $null = Invoke-Native wsl.exe ($prefix + @('bash',"$repoLinux/scripts/linux/verify.sh")) (Join-Path $logs 'verify-after')
    if ($VerifyOnly) { Write-Host "PASS: installed environment verified. Logs: $logs"; exit 0 }
    $r = Invoke-Native wsl.exe ($prefix + @('python3',"$repoLinux/scripts/linux/benchmark.py")) (Join-Path $logs 'benchmark')
    $benchmark = $r.Stdout | ConvertFrom-Json
    $config = [ordered]@{ distro=$Distro; user=$LinuxUser; case=$benchmark.case; reports="$projectLinux/reports"; viewer="$repoLinux/scripts/linux/view.py" }
    New-Item -ItemType Directory -Path (Join-Path $ProjectDirectory 'reports') -Force | Out-Null
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $caseId = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($benchmark.case)))).Replace('-','').Substring(0,12).ToLowerInvariant() } finally { $sha.Dispose() }
    $configPath = Join-Path $ProjectDirectory ('paraview-' + $caseId + '.json')
    $json = $config | ConvertTo-Json
    if (Test-Path $configPath) {
        $existing = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($key in $config.Keys) { if ($existing.$key -ne $config[$key]) { throw "Existing config differs ($key). Use a new project directory; existing config preserved." } }
    } else { [IO.File]::WriteAllText($configPath,$json,[Text.UTF8Encoding]::new($false)) }
    $launcher = Join-Path $PSScriptRoot 'scripts/windows/Open-ParaView.ps1'
    $shortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'OpenFOAM CFD Results.lnk'
    if (Test-Path $shortcut) {
        Write-Host 'Existing desktop shortcut preserved. Creating a project-local shortcut instead.'
        $shortcut = Join-Path $ProjectDirectory ('OpenFOAM CFD Results-' + $caseId + '.lnk')
    }
    if (-not (Test-Path $shortcut)) {
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($shortcut)
        $link.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        $link.Arguments = '-NoProfile -File ' + (ConvertTo-NativeArgument $launcher) + ' -Config ' + (ConvertTo-NativeArgument $configPath)
        $link.WorkingDirectory = $PSScriptRoot
        $link.Description = 'OpenFOAM results (keep the repository and project directory in place)'
        $link.Save()
    }
    if (-not $SkipGui) { & $launcher -Config $configPath; if ($LASTEXITCODE -ne 0) { throw 'ParaView launch failed.' } }
    Write-Host "PASS: automated benchmark checks. Physical validation and GUI visual review are separate. Logs: $logs"
} catch {
    if (Get-Variable logs -ErrorAction SilentlyContinue) { $_ | Out-File (Join-Path $logs 'failure.log') -Encoding utf8 }
    Write-Error $_
    exit 1
}
