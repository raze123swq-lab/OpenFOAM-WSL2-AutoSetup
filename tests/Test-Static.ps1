$ErrorActionPreference='Stop'
$root = Split-Path -Parent $PSScriptRoot
foreach ($file in (Get-ChildItem $root -Recurse -Filter *.ps1)) {
    $tokens=$null; $errors=$null
    [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors) | Out-Null
    if ($errors.Count) { throw "$($file.Name): $errors" }
    if (@([IO.File]::ReadAllBytes($file.FullName) | Where-Object { $_ -gt 127 }).Count) { throw "Non-ASCII PowerShell: $file" }
    Write-Host "PASS syntax/ASCII: $($file.Name)"
}
. (Join-Path $root 'scripts/windows/Common.ps1')
if ((Get-DistroVersion "  NAME STATE VERSION`n* Ubuntu-22.04 Running 2" 'Ubuntu-22.04') -ne 2) { throw 'WSL2 parser' }
if ((Get-DistroVersion 'Ubuntu-22.04 Stopped 1' 'Ubuntu-22.04') -ne 1) { throw 'WSL1 parser' }
if ((Get-DistroVersion 'Ubuntu-22.04-other Running 2' 'Ubuntu-22.04') -ne 0) { throw 'Distro exact-match parser' }
if ((Get-DistroVersion 'wsl: localhost proxy warning' 'Ubuntu-22.04') -ne 0) { throw 'Warning parsed as success' }
Write-Host 'PASS WSL listing fixtures'
# Exercise real native stderr handling and nonzero exit, without WSL dependency.
$script = '[Console]::Out.Write("DATA"); [Console]::Error.Write("warning"); exit 7'
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
$r = Invoke-Native powershell.exe @('-NoProfile','-EncodedCommand',$encoded) -AllowFailure
if ($r -is [array] -or $r.ExitCode -ne 7 -or $r.Stdout -ne 'DATA' -or $r.Stderr -ne 'warning') { throw 'Native output/exit isolation failed' }
$caught=$false
try { $null=Invoke-Native powershell.exe @('-NoProfile','-EncodedCommand',$encoded) } catch { $caught=$true }
if (-not $caught) { throw 'Native failures must stop' }
Write-Host 'PASS stderr separation, scalar return and nonzero failure'
if ((ConvertTo-NativeArgument 'a b') -ne '"a b"') { throw 'Space quoting' }
if ((ConvertTo-NativeArgument 'x"y') -ne '"x\"y"') { throw 'Quote escaping' }
if ((ConvertTo-NativeArgument 'C:\space path\') -ne '"C:\space path\\"') { throw 'Trailing slash escaping' }
Write-Host 'PASS argument quoting'
