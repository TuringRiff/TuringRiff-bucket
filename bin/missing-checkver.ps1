if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
. "$PSScriptRoot\_forward-dir.ps1"
$fwd = Get-BucketDirAndArgs -InputArgs $Args
& "$env:SCOOP_HOME/bin/missing-checkver.ps1" -Dir $fwd.Dir @($fwd.Passthrough)
