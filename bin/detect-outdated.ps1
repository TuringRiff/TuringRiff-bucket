<#
.SYNOPSIS
    Detect manifests that still lag upstream (read-only; does not update files).

.DESCRIPTION
    Runs Scoop checkver -SkipUpdated and reports residual outdated apps / checkver errors.
    Used after Excavator soft-fails so silent autoupdate failures become visible.

.PARAMETER Dir
    Bucket directory (default: ../bucket).

.PARAMETER SummaryPath
    Markdown report path (default: ../outdated-summary.md).

.PARAMETER FailOnOutdated
    Exit 1 when drift or errors are found.
#>
param(
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [String] $Dir = (Join-Path $PSScriptRoot '..\bucket'),

    [String] $SummaryPath = (Join-Path $PSScriptRoot '..\outdated-summary.md'),

    [Switch] $FailOnOutdated
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Dir = (Resolve-Path $Dir).Path

function Resolve-ScoopHome {
    if ($env:SCOOP_HOME -and (Test-Path (Join-Path $env:SCOOP_HOME 'bin\checkver.ps1'))) {
        return (Resolve-Path $env:SCOOP_HOME).Path
    }

    # Prefer "scoop prefix scoop" when shims are on PATH (local dev)
    try {
        $cmd = Get-Command scoop -ErrorAction Stop
        if ($cmd) {
            $prefix = & scoop prefix scoop 2>$null
            if ($prefix -and (Test-Path (Join-Path $prefix 'bin\checkver.ps1'))) {
                return (Resolve-Path $prefix).Path
            }
        }
    } catch {
        # ignore — fall through to well-known paths (CI often has Scoop installed but PATH not refreshed)
    }

    $roots = @()
    if ($env:SCOOP) { $roots += $env:SCOOP }
    $roots += (Join-Path $env:USERPROFILE 'scoop')
    $roots += (Join-Path $env:USERPROFILE 'SCOOP')
    if ($env:ProgramData) { $roots += (Join-Path $env:ProgramData 'scoop') }

    foreach ($root in ($roots | Select-Object -Unique)) {
        $candidate = Join-Path $root 'apps\scoop\current'
        if (Test-Path (Join-Path $candidate 'bin\checkver.ps1')) {
            if (-not $env:SCOOP) { $env:SCOOP = $root }
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

$env:SCOOP_HOME = Resolve-ScoopHome
if (-not $env:SCOOP_HOME) {
    throw "Scoop is not available. Install Scoop or set SCOOP_HOME / SCOOP (and ensure apps\scoop\current\exists)."
}

# Ensure Scoop shims + home are visible to nested scripts
if ($env:SCOOP) {
    $shim = Join-Path $env:SCOOP 'shims'
    if ((Test-Path $shim) -and ($env:Path -notlike "*$shim*")) {
        $env:Path = "$shim;$env:Path"
    }
}

$checkver = Join-Path $env:SCOOP_HOME 'bin\checkver.ps1'
if (-not (Test-Path $checkver)) {
    throw "checkver.ps1 not found at $checkver"
}

if (-not $env:SCOOP_GH_TOKEN -and $env:GITHUB_TOKEN) {
    $env:SCOOP_GH_TOKEN = $env:GITHUB_TOKEN
}

$logPath = Join-Path ([System.IO.Path]::GetTempPath()) ("scoop-checkver-outdated-{0}.log" -f [guid]::NewGuid().ToString('n'))

Write-Host "Running checkver -SkipUpdated on $Dir" -ForegroundColor Cyan
Start-Transcript -Path $logPath -Force | Out-Null
try {
    & $checkver -Dir $Dir -SkipUpdated
} finally {
    Stop-Transcript | Out-Null
}

$logText = Get-Content -LiteralPath $logPath -Raw -ErrorAction SilentlyContinue
if (-not $logText) { $logText = '' }

Write-Host '----- checkver transcript -----' -ForegroundColor DarkGray
Write-Host $logText
Write-Host '----- end transcript -----' -ForegroundColor DarkGray

$outdated = [System.Collections.Generic.List[object]]::new()
$errors = [System.Collections.Generic.List[string]]::new()

foreach ($line in ($logText -split "`r?`n")) {
    $trim = $line.Trim()
    if (-not $trim) { continue }

    # app: 3.7.17 (scoop version is 3.7.13) autoupdate available
    if ($trim -match '^(?<app>[\w][\w.-]*):\s+(?<remote>\S+)\s+\(scoop version is\s+(?<local>.+?)\)') {
        $outdated.Add([pscustomobject]@{
                App             = $Matches.app
                ManifestVersion = $Matches.local.Trim()
                DetectedVersion = $Matches.remote.Trim()
            }) | Out-Null
        continue
    }

    if ($trim -match 'Could not update\s+(?<app>[\w][\w.-]*)') {
        $errors.Add($trim) | Out-Null
        continue
    }

    if (
        $trim -match '^(?<app>[\w*][\w.-]*):\s+(?<msg>.+)$' -and
        $trim -notmatch '\(scoop version is' -and
        $Matches.msg -match "couldn't|not valid|error|failed|unable|timeout|404|exception"
    ) {
        $errors.Add($trim) | Out-Null
    }
}

$outdated = @($outdated | Sort-Object App -Unique)
$errors = @($errors | Select-Object -Unique)

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('## Manifest drift report')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
[void]$sb.AppendLine('')

if ($outdated.Count -eq 0 -and $errors.Count -eq 0) {
    [void]$sb.AppendLine('No outdated manifests detected. Bucket versions match checkver results.')
} else {
    if ($outdated.Count -gt 0) {
        [void]$sb.AppendLine('### Outdated (upstream newer than manifest)')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| App | Manifest | Detected |')
        [void]$sb.AppendLine('|:----|:---------|:---------|')
        foreach ($item in $outdated) {
            [void]$sb.AppendLine("| $($item.App) | $($item.ManifestVersion) | **$($item.DetectedVersion)** |")
        }
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('Typical causes: wrong `autoupdate.url` (e.g. `v$version` vs `$version`), asset rename, hash extraction failure, or network blip during hash download.')
        [void]$sb.AppendLine('')
    }
    if ($errors.Count -gt 0) {
        [void]$sb.AppendLine('### checkver errors')
        [void]$sb.AppendLine('')
        foreach ($err in $errors) {
            [void]$sb.AppendLine("- $err")
        }
        [void]$sb.AppendLine('')
    }
    [void]$sb.AppendLine('### Suggested fix')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('```powershell')
    [void]$sb.AppendLine('.\bin\checkver.ps1 <app> -u')
    [void]$sb.AppendLine('```')
}

$summary = $sb.ToString()
$summaryDir = Split-Path -Parent $SummaryPath
if ($summaryDir -and -not (Test-Path $summaryDir)) {
    New-Item -ItemType Directory -Path $summaryDir -Force | Out-Null
}
Set-Content -Path $SummaryPath -Value $summary -Encoding utf8
Write-Host "Wrote summary: $SummaryPath" -ForegroundColor Green
Write-Host $summary

$hasDrift = ($outdated.Count -gt 0) -or ($errors.Count -gt 0)

if ($env:GITHUB_OUTPUT) {
    "has_drift=$($hasDrift.ToString().ToLowerInvariant())" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "outdated_count=$($outdated.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "error_count=$($errors.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

if ($env:GITHUB_STEP_SUMMARY) {
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $summary -Encoding utf8
}

Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue

if ($FailOnOutdated -and $hasDrift) {
    exit 1
}

exit 0
