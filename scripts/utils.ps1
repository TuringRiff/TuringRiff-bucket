
function New-PersistDirectory {
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]
        $dataPath,

        [parameter(Mandatory = $true, Position = 1)]
        [string]
        $persistPath,

        [switch]
        $Migrate
    )
    # Normalize paths for reliable comparison
    $persistPath = [System.IO.Path]::GetFullPath($persistPath)

    # Create persist dir
    New-Item $persistPath -Type Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if (Test-Path $dataPath) {
        $dataPathItem = Get-Item -Path $dataPath
        if ($dataPathItem.LinkType -eq 'Junction') {
            # Idempotent: skip if already pointing to correct target
            $currentTarget = ($dataPathItem.Target | Select-Object -First 1)
            if ($currentTarget) {
                $normalizedTarget = [System.IO.Path]::GetFullPath($currentTarget)
                if ($normalizedTarget -eq $persistPath) {
                    return
                }
            }
            # Delete old Junction
            # Remove-Item regard junction as actual directory, do not use it.
            try { $dataPathItem.Delete() } catch {}
        } else {
            if ($Migrate) {
                # Migrate data
                Get-ChildItem $dataPath | ForEach-Object { Move-Item $_.FullName $persistPath -Force } | Out-Null
            }
            Remove-Item $dataPath -Force -Recurse | Out-Null
        }
    }
    # Ensure parent directory exists before creating Junction
    $parentPath = Split-Path $dataPath -Parent
    if ($parentPath -and -not (Test-Path $parentPath)) {
        New-Item $parentPath -Type Directory -Force | Out-Null
    }
    # Create new Junction
    New-Item -ItemType Junction -Path $dataPath -Target $persistPath | Out-Null
}

function Remove-Junction {
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]
        $dataPath
    )
    # Delete Junction only
    if (Test-Path $dataPath) {
        $dataPathItem = Get-Item -Path $dataPath
        if ($dataPathItem.LinkType -eq 'Junction') {
            try { $dataPathItem.Delete() } catch {}
        }
    }
}

function Remove-EmptyDirectory {
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]
        $Path
    )

    if ((Test-Path -LiteralPath $Path -PathType Container) -and -not (Get-ChildItem -LiteralPath $Path -Force | Select-Object -First 1)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

