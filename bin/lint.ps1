#Requires -Version 5.1

# Returns the text that carries a required field's meaning, or $null when the
# field has a type the manifest schema does not allow there.
#
# 'license' may be an SPDX string or an object whose 'identifier' is required.
# The object form must be unwrapped before any emptiness test: ConvertFrom-Json
# yields a PSCustomObject, and casting one to string produces "@{identifier=}",
# which is never empty. Testing that directly passes every object unconditionally.
function Resolve-FieldText {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $Value
    )

    if ($Value -is [string]) { return $Value }
    if ($Value -is [System.Management.Automation.PSCustomObject] -and
        ($Value.PSObject.Properties.Name -contains 'identifier')) {
        $identifier = $Value.identifier
        if ($identifier -is [string]) { return $identifier }
    }

    return $null
}

$bucketDir = "$PSScriptRoot/../bucket"
$manifests = Get-ChildItem -Path $bucketDir -Filter *.json

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Running Local Scoop Manifest Linter..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$hasErrors = $false

foreach ($file in $manifests) {
    Write-Host "Checking: $($file.Name)..." -NoNewline
    $errors = [System.Collections.Generic.List[string]]::new()

    # 1. JSON parsing check
    $jsonText = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $json = $null
    try {
        $json = ConvertFrom-Json -InputObject $jsonText -ErrorAction Stop
    } catch {
        $errors.Add("Invalid JSON syntax: $_")
    }

    if ($null -ne $json) {
        # 2. Indentation check (4 spaces)
        $lines = Get-Content -Path $file.FullName -Encoding UTF8
        $lineNum = 0
        foreach ($line in $lines) {
            $lineNum++
            if ($line -match '^\t+') {
                $errors.Add("Line ${lineNum}: Contains tab characters. Use 4 spaces for indentation instead.")
                break
            }
            if ($line -match '^( +)') {
                $spaces = $Matches[1].Length
                if ($spaces % 4 -ne 0) {
                    $errors.Add("Line ${lineNum}: Indentation is $spaces spaces, which is not a multiple of 4.")
                    break
                }
            }
        }

        # 3. Check required fields, paired with what the schema accepts there
        $requiredFields = [ordered]@{
            version     = "a string"
            description = "a string"
            homepage    = "a string"
            license     = "a string, or an object with an 'identifier'"
        }
        foreach ($field in $requiredFields.Keys) {
            $raw = $json.$field
            if ($null -eq $raw) {
                $errors.Add("Missing required field: '$field'")
                continue
            }

            $text = Resolve-FieldText -Value $raw
            if ($null -eq $text) {
                $errors.Add("Required field '$field' must be $($requiredFields[$field]); got '$($raw.GetType().Name)'")
            } elseif ([string]::IsNullOrWhiteSpace($text)) {
                $errors.Add("Empty required field: '$field'")
            }
        }

        # 4. Check architecture/url field
        if ($null -eq $json.architecture -and $null -eq $json.url) {
            $errors.Add("Must specify 'architecture' or a top-level 'url'")
        }

        # 5. Check homepage URL format
        if ($null -ne $json.homepage -and $json.homepage -notmatch '^https?://') {
            $errors.Add("Homepage URL must start with http:// or https://")
        }
    }

    if ($errors.Count -gt 0) {
        $hasErrors = $true
        Write-Host " [FAILED]" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "  - $err" -ForegroundColor Red
        }
    } else {
        Write-Host " [PASSED]" -ForegroundColor Green
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
if ($hasErrors) {
    Write-Host "Linter finished with errors. Please fix them before committing." -ForegroundColor Red
    exit 1
} else {
    Write-Host "All manifests look great! Validation passed." -ForegroundColor Green
    exit 0
}
