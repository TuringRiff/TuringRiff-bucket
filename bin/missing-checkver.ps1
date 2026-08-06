# Wrapper: defaults -Dir to this bucket. Usage: .\bin\missing-checkver.ps1 [-SkipSupported] [app]
#Requires -Version 5.1

param(
    [String] $App = '*',

    [String] $Dir = (Join-Path $PSScriptRoot '..\bucket'),

    [Switch] $SkipSupported
)

if ($args.Count -gt 0) {
    throw "Unexpected argument(s): $($args -join ' ')."
}

. "$PSScriptRoot\_forward-dir.ps1"
$env:SCOOP_HOME = Get-ScoopHome
if (-not $env:SCOOP_HOME) { throw 'Scoop is not available. Install Scoop or set SCOOP_HOME.' }

$params = @{}
$PSBoundParameters.GetEnumerator() | ForEach-Object { $params[$_.Key] = $_.Value }
$params['Dir'] = $Dir
& "$env:SCOOP_HOME/bin/missing-checkver.ps1" @params
