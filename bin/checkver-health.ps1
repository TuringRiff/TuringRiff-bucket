<#
.SYNOPSIS
    Full-bucket checkver health check.

.DESCRIPTION
    Runs Scoop checkver WITHOUT -SkipUpdated so every manifest with a checkver
    block must produce exactly one per-app output line. Output is captured via
    the information stream (checkver prints with Write-Host in fragments) and
    reconstructed into console lines before structural classification:

      app: version                          -> OK
      app: remote (scoop version is local)  -> drift (update pending)
      any other "app: ..." line             -> checkver error

    A manifest with checkver that produces no output line is reported as an
    error. This guards against silent no-ops (broken wrappers, checkver
    regressions) and against upstream tag/regex/asset format changes.

.PARAMETER Dir
    Bucket directory (default: ../bucket).

.PARAMETER SummaryPath
    Markdown report path (default: ../checkver-health-summary.md).

.PARAMETER IgnoreDrift
    Exit 0 when only drift is found; checkver errors still fail.

.EXAMPLE
    PS> .\bin\checkver-health.ps1

.EXAMPLE
    PS> .\bin\checkver-health.ps1 -IgnoreDrift
#>
param(
    [ValidateScript( { Test-Path $_ -PathType Container })]
    [String] $Dir = (Join-Path $PSScriptRoot '..\bucket'),

    [String] $SummaryPath = (Join-Path $PSScriptRoot '..\checkver-health-summary.md'),

    [Switch] $IgnoreDrift
)

# Do NOT enable Set-StrictMode here: Scoop's checkver probes optional
# config properties; under StrictMode that becomes a terminating error.
$ErrorActionPreference = 'Stop'

$Dir = (Resolve-Path $Dir).Path
. (Join-Path $PSScriptRoot '_forward-dir.ps1')
$env:SCOOP_HOME = Get-ScoopHome
if (-not $env:SCOOP_HOME) {
    throw "Scoop is not available. Install Scoop or set SCOOP_HOME / SCOOP (and ensure apps\scoop\current exists)."
}

# Ensure Scoop shims + home are visible to nested scripts
if (-not $env:SCOOP) {
    $env:SCOOP = Split-Path (Split-Path $env:SCOOP_HOME -Parent) -Parent
}
$shim = Join-Path $env:SCOOP 'shims'
if ((Test-Path $shim) -and ($env:Path -notlike "*$shim*")) {
    $env:Path = "$shim;$env:Path"
}

$checkver = Join-Path $env:SCOOP_HOME 'bin\checkver.ps1'
if (-not (Test-Path $checkver)) {
    throw "checkver.ps1 not found at $checkver"
}

if (-not $env:SCOOP_GH_TOKEN -and $env:GITHUB_TOKEN) {
    $env:SCOOP_GH_TOKEN = $env:GITHUB_TOKEN
}

$manifests = @(Get-ChildItem -LiteralPath $Dir -Filter *.json | Sort-Object Name)
$expected = @(
    foreach ($file in $manifests) {
        $m = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -ne $m -and $null -ne $m.checkver) {
            $file.BaseName
        }
    }
)

Write-Host "Running checkver on $Dir ($($expected.Count) manifests with checkver)" -ForegroundColor Cyan
Write-Host "SCOOP=$env:SCOOP SCOOP_HOME=$env:SCOOP_HOME" -ForegroundColor DarkGray

# checkver prints via Write-Host in fragments; capture the information stream and
# reconstruct real console lines from the fragments (Start-Transcript would
# split them and break line-based parsing).
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
Set-StrictMode -Off
$captured = @(& $checkver -Dir $Dir 6>&1 | ForEach-Object { "$_" })
$ErrorActionPreference = $prevEap

$logLines = ConvertTo-CheckverLines -Fragments $captured
$logText = $logLines -join "`r`n"

Write-Host '----- checkver output -----' -ForegroundColor DarkGray
Write-Host $logText
Write-Host '----- end checkver output -----' -ForegroundColor DarkGray

$reported = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$outdated = [System.Collections.Generic.List[object]]::new()
$errors = [System.Collections.Generic.List[string]]::new()

foreach ($line in $logLines) {
    $trim = $line.Trim()
    if (-not $trim) { continue }

    # app: 3.7.17 (scoop version is 3.7.13) autoupdate available
    if ($trim -match '^(?<app>[\w][\w.-]*):\s+(?<remote>\S+)\s+\(scoop version is\s+(?<local>.+?)\)') {
        [void]$reported.Add($Matches.app)
        $outdated.Add([pscustomobject]@{
                App             = $Matches.app
                ManifestVersion = $Matches.local.Trim()
                DetectedVersion = $Matches.remote.Trim()
            }) | Out-Null
        continue
    }

    # app: version (OK) or app: <error text> (failure)
    if ($trim -match '^(?<app>[\w*][\w.-]*):\s+(?<msg>.+)$') {
        [void]$reported.Add($Matches.app)
        if ($trim -match '^[\w*][\w.-]*:\s+\S+$') { continue }
        $errors.Add($trim) | Out-Null
    }
}

# Every manifest with checkver must have produced an app line (silent no-op guard).
$missing = @($expected | Where-Object { -not $reported.Contains($_) })
foreach ($app in $missing) {
    $errors.Add("No checkver output for '$app'.") | Out-Null
}

$outdated = @($outdated | Sort-Object App -Unique)
$errors = @($errors | Select-Object -Unique)

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('## Checkver health report')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
[void]$sb.AppendLine('')
[void]$sb.AppendLine("- Manifests with checkver: $($expected.Count)")
[void]$sb.AppendLine("- Apps with output: $($reported.Count)")
[void]$sb.AppendLine("- Errors: $($errors.Count)")
[void]$sb.AppendLine("- Drift: $($outdated.Count)")
[void]$sb.AppendLine('')

if ($errors.Count -eq 0 -and $outdated.Count -eq 0) {
    [void]$sb.AppendLine('All manifests check successfully; no drift or checkver errors.')
} else {
    if ($errors.Count -gt 0) {
        [void]$sb.AppendLine('### checkver errors')
        [void]$sb.AppendLine('')
        foreach ($err in $errors) {
            [void]$sb.AppendLine("- $err")
        }
        [void]$sb.AppendLine('')
    }
    if ($outdated.Count -gt 0) {
        [void]$sb.AppendLine('### Outdated (upstream newer than manifest)')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| App | Manifest | Detected |')
        [void]$sb.AppendLine('|:----|:---------|:---------|')
        foreach ($item in $outdated) {
            [void]$sb.AppendLine("| $($item.App) | $($item.ManifestVersion) | **$($item.DetectedVersion)** |")
        }
        [void]$sb.AppendLine('')
    }
    [void]$sb.AppendLine('Typical causes: upstream changed its release tag/asset format, checkver regex no longer matches, autoupdate URL template is stale, or hash extraction failed.')
}

$summary = $sb.ToString()
$summaryDir = Split-Path -Parent $SummaryPath
if ($summaryDir -and -not (Test-Path $summaryDir)) {
    New-Item -ItemType Directory -Path $summaryDir -Force | Out-Null
}
Set-Content -Path $SummaryPath -Value $summary -Encoding utf8
Write-Host $summary -ForegroundColor Cyan

if ($env:GITHUB_OUTPUT) {
    "has_errors=$($errors.Count -gt 0)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "has_drift=$($outdated.Count -gt 0)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "error_count=$($errors.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "drift_count=$($outdated.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "manifest_count=$($expected.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "output_count=$($reported.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

if ($env:GITHUB_STEP_SUMMARY) {
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $summary -Encoding utf8
}

if ($errors.Count -gt 0) {
    exit 1
}
if ($outdated.Count -gt 0 -and -not $IgnoreDrift) {
    exit 1
}

exit 0
