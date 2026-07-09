@{
    # Only diagnostic records of the specified severity will be generated.
    # Keep Error-level only for this bucket's helper scripts (bin/*.ps1).
    Severity = @('Error')

    # Do not analyze the following rules.
    # Note: if a rule is in both IncludeRules and ExcludeRules, the rule
    # will be excluded.
    ExcludeRules = @(
        # Bucket helper scripts (lint, test wrappers) use Write-Host for
        # colored CLI output, matching Scoop's own conventions.
        'PSAvoidUsingWriteHost'
    )
}
