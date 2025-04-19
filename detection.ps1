<#
.SYNOPSIS
  Intune detection script – confirms all required domains are present in uBlock Origin Lite’s
  “noFiltering” policy value.
.DESCRIPTION
  Checks each domain in $sitesRequired against the JSON array stored in the registry.
  - Exits 0 only if every domain is found.
  - Exits 1 on any missing domain or if the policy isn’t in place.
.NOTES
  Last updated: April 18, 2025
#>

# Domains to verify
$sitesRequired = @(
    "example3.com",
    "example4.com",
    "example5.com"
)

# Chrome policy registry path for uBlock Origin Lite
$regPath   = "HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\Extensions\ddkjiahejlhfcafbddmgiahcphecmpfh\policy"
$valueName = "noFiltering"

# Fail if policy key isn’t there
if (-not (Test-Path $regPath)) {
    Write-Output "Policy path not found: $regPath"
    exit 1
}

# Try to get the JSON value (silently continue if missing)
$currentJson = Get-ItemPropertyValue -Path $regPath -Name $valueName -ErrorAction SilentlyContinue

if (-not $currentJson) {
    Write-Output "Registry value '$valueName' not found or empty."
    exit 1
}

# Deserialize into an array
$currentList = $currentJson | ConvertFrom-Json

# Loop through each required site
$missing = @()
foreach ($site in $sitesRequired) {
    if ($site -notin $currentList) {
        $missing += $site
        Write-Output "Missing domain: $site"
    }
    else {
        Write-Output "Domain present: $site"
    }
}

# Exit based on whether there were any misses
if ($missing.Count -gt 0) {
    exit 1   # remediation should run
}

Write-Output "All required domains already present."
exit 0       # detection successful

