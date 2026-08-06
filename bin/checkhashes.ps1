# Wrapper: defaults -Dir to this bucket. Usage: .\bin\checkhashes.ps1 [-Update] [-ForceUpdate] [-SkipCorrect] [-UseCache] [app]
#Requires -Version 5.1

param(
    [String] $App = '*',

    [String] $Dir = (Join-Path $PSScriptRoot '..\bucket'),

    [Switch] $Update,
    [Switch] $ForceUpdate,
    [Switch] $SkipCorrect,
    [Alias('k')]
    [Switch] $UseCache
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
& "$env:SCOOP_HOME/bin/checkhashes.ps1" @params
