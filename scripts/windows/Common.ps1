Set-StrictMode -Version Latest

function ConvertTo-NativeArgument([string]$Value) {
    if ($Value.Contains([char]0) -or $Value.Contains("`n") -or $Value.Contains("`r")) { throw 'Invalid argument.' }
    # WSL parses option tokens before normal argv decoding; leave simple tokens bare.
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') { return $Value }
    # Windows CommandLineToArgvW quoting; no shell interpolation.
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-Native {
    param([string]$File, [string[]]$ArgumentList, [string]$LogBase,
          [switch]$UnicodeOutput, [switch]$AllowFailure)
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $File
    $info.Arguments = ($ArgumentList | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' '
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = [Text.Encoding]::UTF8
    if ($UnicodeOutput) { $info.StandardOutputEncoding = [Text.Encoding]::Unicode }
    $info.StandardErrorEncoding = [Text.Encoding]::UTF8
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $info
    try {
        if (-not $proc.Start()) { throw 'Process did not start.' }
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $proc.WaitForExit()
        $result = [pscustomobject]@{ ExitCode=$proc.ExitCode; Stdout=$stdoutTask.Result; Stderr=$stderrTask.Result }
    } finally { $proc.Dispose() }
    if ($LogBase) {
        [IO.File]::WriteAllText($LogBase + '.stdout.log', $result.Stdout, [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText($LogBase + '.stderr.log', $result.Stderr, [Text.UTF8Encoding]::new($false))
    }
    if ($result.ExitCode -ne 0 -and -not $AllowFailure) { throw "Command failed (exit $($result.ExitCode)). Logs: $LogBase" }
    return $result
}

function Get-DistroVersion([string]$Listing, [string]$Distro) {
    foreach ($line in ($Listing -replace "`0", '' -split "`n")) {
        if ($line -match ('^\s*\*?\s*' + [regex]::Escape($Distro) + '\s+.+?\s+([12])\s*$')) { return [int]$Matches[1] }
    }
    return 0
}

function Test-PendingRestart {
    return ((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
        (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or
        ($null -ne (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue)))
}

function ConvertTo-LinuxPath([string]$Path, [string]$Distro, [string]$LinuxUser) {
    $r = Invoke-Native wsl.exe @('-d',$Distro,'-u',$LinuxUser,'--exec','wslpath','-a',$Path.Replace('\','/'))
    $value = $r.Stdout.Trim()
    if (-not $value.StartsWith('/')) { throw 'wslpath returned an invalid path.' }
    return $value
}
