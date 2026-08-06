# Wrapper: defaults -Dir to this bucket and -Upstream to this repository.
# Usage: .\bin\auto-pr.ps1 [-Push | -Request] [-Upstream <user>/<repo>:<branch>] [app]
#Requires -Version 5.1

param(
    [String] $Upstream = 'TuringRiff/TuringRiff-bucket:master',
    [String] $OriginBranch = 'master',
    [String] $App = '*',
    [String] $CommitMessageFormat = '<app>: Update to version <version>',

    [String] $Dir = (Join-Path $PSScriptRoot '..\bucket'),

    [Switch] $Push,
    [Switch] $Request,
    [Switch] $Help,
    [string[]] $SpecialSnowflakes,
    [Switch] $SkipUpdated,
    [Switch] $ThrowError
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
$params['Upstream'] = $Upstream
& "$env:SCOOP_HOME/bin/auto-pr.ps1" @params
