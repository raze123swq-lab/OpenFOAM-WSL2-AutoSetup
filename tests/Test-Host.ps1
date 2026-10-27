param([Parameter(Mandatory=$true)][ValidatePattern('^[a-z_][a-z0-9_-]{0,31}$')][string]$LinuxUser,
      [Parameter(Mandatory=$true)][string]$ProjectDirectory)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'scripts/windows/Common.ps1')
$values=@('space path','quote"value','trailing\','$(not-a-command)',([string][char]0x4E2D + [char]0x6587))
$r=Invoke-Native wsl.exe (@('-d','Ubuntu-22.04','-u',$LinuxUser,'--exec','python3','-c','import sys,json;print(json.dumps(sys.argv[1:]))') + $values)
$actual=$r.Stdout | ConvertFrom-Json
if ($actual.Count -ne $values.Count) { throw 'WSL argv count mismatch' }
for ($i=0; $i -lt $values.Count; $i++) { if ($actual[$i] -cne $values[$i]) { throw "WSL argv mismatch at $i" } }
Write-Host 'PASS real WSL argv: spaces, quotes, slash, literal substitution, Unicode'
& (Join-Path $root 'Install-OpenFOAM.ps1') -LinuxUser $LinuxUser -ProjectDirectory $ProjectDirectory -VerifyOnly
exit $LASTEXITCODE
