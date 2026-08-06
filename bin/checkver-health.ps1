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

    In addition, current manifest download URLs and autoupdate URL templates
    are validated with HTTP HEAD/GET requests:
      - current URLs catch assets that were renamed/deleted without a version
        bump (checkver alone cannot see those);
      - autoupdate templates are expanded with the detected version for drift
        apps, so a 404 caused by an upstream asset rename is reported with the
        exact failing URL.

.PARAMETER Dir
    Bucket directory (default: ../bucket).

.PARAMETER SummaryPath
    Markdown report path (default: ../checkver-health-summary.md).

.PARAMETER IgnoreDrift
    Exit 0 when only drift is found; checkver errors still fail.

.PARAMETER SkipUrlChecks
    Skip HTTP validation of current URLs and autoupdate templates.

.EXAMPLE
    PS> .\bin\checkver-health.ps1

.EXAMPLE
    PS> .\bin\checkver-health.ps1 -IgnoreDrift

.EXAMPLE
    PS> .\bin\checkver-health.ps1 -SkipUrlChecks
#>
param(
    [ValidateScript( { Test-Path $_ -PathType Container })]
    [String] $Dir = (Join-Path $PSScriptRoot '..\bucket'),

    [String] $SummaryPath = (Join-Path $PSScriptRoot '..\checkver-health-summary.md'),

    [Switch] $IgnoreDrift,
    [Switch] $SkipUrlChecks
)

function Get-ManifestUrls {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Manifest
    )

    $urls = [System.Collections.Generic.List[string]]::new()
    if ($null -ne $Manifest.url) {
        $Manifest.url | ForEach-Object { $urls.Add([string]$_) }
    } elseif ($null -ne $Manifest.architecture) {
        foreach ($arch in @('64bit', '32bit', 'arm64')) {
            $entry = $Manifest.architecture.$arch
            if ($null -ne $entry -and $null -ne $entry.url) {
                $entry.url | ForEach-Object { $urls.Add([string]$_) }
            }
        }
    }

    return $urls.ToArray()
}

function Get-AutoupdateTemplates {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Autoupdate
    )

    $templates = [System.Collections.Generic.List[string]]::new()
    if ($null -ne $Autoupdate.url) {
        $Autoupdate.url | ForEach-Object { $templates.Add([string]$_) }
    } elseif ($null -ne $Autoupdate.architecture) {
        foreach ($arch in @('64bit', '32bit', 'arm64')) {
            $entry = $Autoupdate.architecture.$arch
            if ($null -ne $entry -and $null -ne $entry.url) {
                $entry.url | ForEach-Object { $templates.Add([string]$_) }
            }
        }
    }

    return $templates.ToArray()
}

function Test-Url {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Url,
        [int] $TimeoutSeconds = 10
    )

    $clean = ($Url -split '#/')[0]
    if ($clean -notmatch '^https?://') {
        return [pscustomobject]@{ Url = $Url; Ok = $false; Status = 'unsupported'; Detail = 'Not an http(s) URL' }
    }

    $userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    foreach ($method in @([System.Net.Http.HttpMethod]::Head, [System.Net.Http.HttpMethod]::Get)) {
        for ($attempt = 0; $attempt -lt 2; $attempt++) {
            $handler = [System.Net.Http.HttpClientHandler]::new()
            $client = [System.Net.Http.HttpClient]::new($handler)
            $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
            $client.DefaultRequestHeaders.UserAgent.ParseAdd($userAgent)
            try {
                $request = [System.Net.Http.HttpRequestMessage]::new($method, $clean)
                $response = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
                $status = [int]$response.StatusCode
                $response.Dispose()
                if ($status -ge 200 -and $status -lt 400) {
                    return [pscustomobject]@{ Url = $Url; Ok = $true; Status = $status; Detail = '' }
                }
                if ($status -eq 405 -or $status -eq 501) { break }
                return [pscustomobject]@{ Url = $Url; Ok = $false; Status = $status; Detail = '' }
            } catch {
                if ($attempt -eq 1) {
                    return [pscustomobject]@{ Url = $Url; Ok = $false; Status = 'Error'; Detail = $_.Exception.Message }
                }
            } finally {
                $client.Dispose()
            }
        }
    }

    return [pscustomobject]@{ Url = $Url; Ok = $false; Status = 'Error'; Detail = 'HEAD and GET requests failed' }
}

# Do NOT enable Set-StrictMode here: Scoop's checkver probes optional
# config properties; under StrictMode that becomes a terminating error.
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    Add-Type -AssemblyName System.Net.Http
}

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

# Optional URL-level validation: current download URLs and autoupdate templates.
$urlFailures = [System.Collections.Generic.List[object]]::new()
$autoupdateFailures = [System.Collections.Generic.List[object]]::new()
$urlChecked = 0
$autoupdateChecked = 0
$autoupdateSkipped = 0

if (-not $SkipUrlChecks) {
    $testedUrls = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($file in $manifests) {
        $m = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $m) { continue }

        foreach ($u in (Get-ManifestUrls -Manifest $m)) {
            $clean = ($u -split '#/')[0]
            if (-not $testedUrls.Add($clean)) { continue }
            $urlChecked++
            $r = Test-Url -Url $u
            if (-not $r.Ok) {
                $urlFailures.Add([pscustomobject]@{
                        App    = $file.BaseName
                        Url    = $r.Url
                        Status = $r.Status
                        Detail = $r.Detail
                    }) | Out-Null
            }
        }

        if ($null -ne $m.autoupdate) {
            $versionForTemplate = $m.version
            $driftItem = $outdated | Where-Object { $_.App -eq $file.BaseName } | Select-Object -First 1
            if ($null -ne $driftItem) { $versionForTemplate = $driftItem.DetectedVersion }

            foreach ($t in (Get-AutoupdateTemplates -Autoupdate $m.autoupdate)) {
                # Templates with variables other than $version (e.g. $matchX,
                # $baseurl, $cleanVersion) cannot be resolved here; skip them.
                if ($t -match '\$(?!version)') {
                    $autoupdateSkipped++
                    continue
                }
                $expanded = $t.Replace('$version', $versionForTemplate)
                $clean = ($expanded -split '#/')[0]
                if (-not $testedUrls.Add($clean)) { continue }
                $autoupdateChecked++
                $r = Test-Url -Url $expanded
                if (-not $r.Ok) {
                    $autoupdateFailures.Add([pscustomobject]@{
                            App     = $file.BaseName
                            Version = $versionForTemplate
                            Url     = $r.Url
                            Status  = $r.Status
                            Detail  = $r.Detail
                        }) | Out-Null
                }
            }
        }
    }
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
[void]$sb.AppendLine("- Current URLs checked: $urlChecked (failures: $($urlFailures.Count))")
[void]$sb.AppendLine("- Autoupdate templates checked: $autoupdateChecked (failures: $($autoupdateFailures.Count), skipped: $autoupdateSkipped)")
[void]$sb.AppendLine('')

if ($errors.Count -eq 0 -and $outdated.Count -eq 0 -and $urlFailures.Count -eq 0 -and $autoupdateFailures.Count -eq 0) {
    [void]$sb.AppendLine('All manifests check successfully; no drift, checkver errors, or URL failures.')
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
    if ($urlFailures.Count -gt 0) {
        [void]$sb.AppendLine('### Current URL failures')
        [void]$sb.AppendLine('')
        foreach ($f in $urlFailures) {
            $detail = if ($f.Detail) { " ($($f.Detail))" } else { '' }
            [void]$sb.AppendLine("- $($f.App): HTTP $($f.Status) $($f.Url)$detail")
        }
        [void]$sb.AppendLine('')
    }
    if ($autoupdateFailures.Count -gt 0) {
        [void]$sb.AppendLine('### Autoupdate URL failures')
        [void]$sb.AppendLine('')
        foreach ($f in $autoupdateFailures) {
            $detail = if ($f.Detail) { " ($($f.Detail))" } else { '' }
            [void]$sb.AppendLine("- $($f.App) (version $($f.Version)): HTTP $($f.Status) $($f.Url)$detail")
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
    "url_failed_count=$($urlFailures.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "autoupdate_failed_count=$($autoupdateFailures.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "manifest_count=$($expected.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "output_count=$($reported.Count)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

if ($env:GITHUB_STEP_SUMMARY) {
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $summary -Encoding utf8
}

if ($errors.Count -gt 0 -or $urlFailures.Count -gt 0 -or $autoupdateFailures.Count -gt 0) {
    exit 1
}
if ($outdated.Count -gt 0 -and -not $IgnoreDrift) {
    exit 1
}

exit 0
