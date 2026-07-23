# Shared helper: default -Dir to this bucket; user -Dir overrides (no double-bind).
# Dot-source from wrappers: . "$PSScriptRoot\_forward-dir.ps1"
function Get-BucketDirAndArgs {
    param(
        [object[]] $InputArgs,
        [string] $DefaultDir = (Join-Path $PSScriptRoot '..\bucket')
    )
    $dir = $DefaultDir
    $passthrough = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $InputArgs.Count; $i++) {
        $a = $InputArgs[$i]
        if ($a -is [string] -and ($a -eq '-Dir' -or $a -eq '-dir' -or $a -eq '/Dir')) {
            if ($i + 1 -lt $InputArgs.Count) { $dir = $InputArgs[++$i] }
            continue
        }
        if ($a -is [string] -and $a -match '^-(?i)Dir:(.+)$') {
            $dir = $Matches[1]
            continue
        }
        $passthrough.Add($a) | Out-Null
    }
    if (Test-Path -LiteralPath $dir) {
        $dir = (Resolve-Path -LiteralPath $dir).Path
    }
    return @{
        Dir         = $dir
        Passthrough = $passthrough.ToArray()
    }
}
