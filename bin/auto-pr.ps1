param(
    # overwrite upstream param
    [String]$upstream = "TuringRiff/TuringRiff-bucket:master"
)

. "$PSScriptRoot\_forward-dir.ps1"
$env:SCOOP_HOME = Get-ScoopHome
if (-not $env:SCOOP_HOME) { throw 'Scoop is not available. Install Scoop or set SCOOP_HOME.' }
$fwd = Get-BucketDirAndArgs -InputArgs $Args
$autopr = "$env:SCOOP_HOME/bin/auto-pr.ps1"
& $autopr -Dir $fwd.Dir -Upstream $Upstream @($fwd.Passthrough)
