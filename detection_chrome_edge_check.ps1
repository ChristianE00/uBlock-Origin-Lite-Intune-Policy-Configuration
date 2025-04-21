<#
.SYNOPSIS
  Intune detection script – confirms all required domains are present in uBlock Origin Lite’s
  “noFiltering” policy for both Chrome and Edge.
.DESCRIPTION
  1. Defines the list of required domains.
  2. Defines registry paths for Chrome and Edge extension policies.
  3. For each browser policy:
       a. Verifies the registry key exists.
       b. Reads and deserializes the “noFiltering” JSON array.
       c. Checks each domain; collects any missing entries.
  4. Exits 0 only if no domains are missing in both policies; otherwise exits 1.
.NOTES
  Last updated: April 20 2025
#>

# List of domains that must be in every “noFiltering” list
$requiredDomains = @(
    'example3.com',
    'example4.com',
    'example5.com'
)

# Registry paths for Chrome and Edge uBlock Origin Lite policies
$policyPaths = @{
    Chrome = 'HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\Extensions\ddkjiahejlhfcafbddmgiahcphecmpfh\policy'
    Edge   = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\3rdparty\Extensions\ddkjiahejlhfcafbddmgiahcphecmpfh\policy'
}

# Name of the registry value that holds the JSON array
$noFilterValueName = 'noFiltering'

# Array to collect any missing domains
$missingEntries = @()

# Iterate each browser policy definition
foreach ($browser in $policyPaths.Keys) {
    # Get the registry path for this browser
    $regPath = $policyPaths[$browser]

    # Check that the registry key exists
    if (-not (Test-Path $regPath)) {
        Write-Output "$browser policy path not found: $regPath"
        $missingEntries += "$browser:key"
        continue
    }

    # Attempt to read the raw JSON value (skip errors if it doesn't exist)
    $rawJson = Get-ItemPropertyValue -Path $regPath `
                                     -Name $noFilterValueName `
                                     -ErrorAction SilentlyContinue

    # If there's no JSON, record that and move on
    if (-not $rawJson) {
        Write-Output "$browser registry value '$noFilterValueName' not found or empty."
        $missingEntries += "$browser:value"
        continue
    }

    # Deserialize the JSON into a PowerShell array
    $existingDomains = $rawJson | ConvertFrom-Json

    # Check each required domain for membership
    foreach ($domain in $requiredDomains) {
        if ($domain -notin $existingDomains) {
            Write-Output "$browser missing domain: $domain"
            $missingEntries += "$browser:$domain"
        }
        else {
            Write-Output "$browser domain present: $domain"
        }
    }
}

# If any missing entries were recorded, signal detection failure
if ($missingEntries.Count -gt 0) {
    exit 1   # remediation should run
}

# All checks passed
Write-Output "All required domains are present in Chrome & Edge policies."
exit 0     # detection successful
