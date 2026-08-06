# Shared helpers for bin wrappers. Dot-source: . "$PSScriptRoot\_forward-dir.ps1"

function Get-ScoopHome {
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
            if (-not $env:SCOOP) { $env:SCOOP = $root }
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}
