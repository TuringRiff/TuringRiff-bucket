# Shared helpers for bin wrappers. Dot-source: . "$PSScriptRoot\_forward-dir.ps1"

# Scoop's core.ps1 resolves apps/, cache/ and buckets/ from $env:SCOOP, not from
# SCOOP_HOME. Every Get-ScoopHome branch must export it, otherwise a non-default
# install (e.g. D:\Scoop) silently falls back to ~\scoop and reads the wrong
# directories. Only derive it from a "<root>\apps\scoop\current" layout: CI
# points SCOOP_HOME at a bare Scoop checkout that has no install root above it.
function Export-ScoopRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ScoopHome
    )

    if ($env:SCOOP) { return }

    $appsScoop = Split-Path $ScoopHome -Parent
    $apps = Split-Path $appsScoop -Parent
    if ((Split-Path $ScoopHome -Leaf) -ne 'current') { return }
    if ((Split-Path $appsScoop -Leaf) -ne 'scoop') { return }
    if ((Split-Path $apps -Leaf) -ne 'apps') { return }

    $root = Split-Path $apps -Parent
    if ($root -and (Test-Path -LiteralPath $root)) {
        $env:SCOOP = $root
    }
}

function Get-ScoopHome {
    if ($env:SCOOP_HOME -and (Test-Path (Join-Path $env:SCOOP_HOME 'bin\checkver.ps1'))) {
        $resolved = (Resolve-Path $env:SCOOP_HOME).Path
        Export-ScoopRoot -ScoopHome $resolved
        return $resolved
    }

    # Prefer "scoop prefix scoop" when shims are on PATH (local dev)
    try {
        $cmd = Get-Command scoop -ErrorAction Stop
        if ($cmd) {
            $prefix = & scoop prefix scoop 2>$null
            if ($prefix -and (Test-Path (Join-Path $prefix 'bin\checkver.ps1'))) {
                $resolved = (Resolve-Path $prefix).Path
                Export-ScoopRoot -ScoopHome $resolved
                return $resolved
            }
        }
    } catch {
        # Ignore - fall through to well-known paths (CI often has Scoop installed but PATH not refreshed)
    }

    $roots = @()
    if ($env:SCOOP) { $roots += $env:SCOOP }
    if ($env:USERPROFILE) {
        $roots += (Join-Path $env:USERPROFILE 'scoop')
        $roots += (Join-Path $env:USERPROFILE 'SCOOP')
    }
    if ($env:ProgramData) { $roots += (Join-Path $env:ProgramData 'scoop') }

    foreach ($root in ($roots | Select-Object -Unique)) {
        $candidate = Join-Path $root 'apps\scoop\current'
        if (Test-Path (Join-Path $candidate 'bin\checkver.ps1')) {
            $resolved = (Resolve-Path $candidate).Path
            Export-ScoopRoot -ScoopHome $resolved
            return $resolved
        }
    }

    return $null
}

# checkver prints each part of a line with separate Write-Host calls (e.g.
# "$name: " and the version). Capturing the information stream yields those
# fragments without the newlines that the host renders. Reconstruct console
# lines: a fragment that does not start a new "app: " line is a
# continuation of the current line.
#
# The whitespace after the colon is required, not cosmetic. Without it a
# fragment beginning with "https://..." or "C:\..." looks like a new app line,
# which splits an error message away from the app name that prefixes it. The
# orphaned half then matches no parser rule and is dropped, so the failing URL
# never reaches the report.
function ConvertTo-CheckverLines {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]] $Fragments
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fragment in $Fragments) {
        if ([string]::IsNullOrEmpty($fragment)) { continue }
        if (($lines.Count -gt 0) -and ($fragment -notmatch '^\s*[\w*][\w.-]*:\s')) {
            $lines[$lines.Count - 1] += $fragment
        } else {
            $lines.Add($fragment)
        }
    }

    return $lines.ToArray()
}
