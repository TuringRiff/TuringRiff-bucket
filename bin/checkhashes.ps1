. "$PSScriptRoot\_forward-dir.ps1"
$env:SCOOP_HOME = Get-ScoopHome
if (-not $env:SCOOP_HOME) { throw 'Scoop is not available. Install Scoop or set SCOOP_HOME.' }
$fwd = Get-BucketDirAndArgs -InputArgs $Args
& "$env:SCOOP_HOME/bin/checkhashes.ps1" -Dir $fwd.Dir @($fwd.Passthrough)
