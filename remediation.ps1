<#
.SYNOPSIS
  Intune remediation script – adds missing domains to uBlock Origin Lite’s “noFiltering” policy.
.NOTES
  Last updated: April 18 2025
#>

# List of domains that must be in the “noFiltering” policy
$requiredDomains    = @('example3.com','example4.com','example5.com')

# Registry key path for uBlock Origin Lite policy (Chrome)
$regPath            = 'HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\Extensions\ddkjiahejlhfcafbddmgiahcphecmpfh\policy'

# Name of the registry value containing the JSON array
$noFilterValueName  = 'noFiltering'

# Check if the policy registry key exists; create it if missing
if (-not (Test-Path $regPath)) {
    try {
        New-Item -Path $regPath -Force | Out-Null
    }
    catch {
        Write-Output "Error: cannot create registry key $regPath"
        #exit 1
    }
}

# Retrieve the existing JSON string for noFiltering; ignore errors if it doesn't exist
##$existingJsonValue   = Get-ItemPropertyValue -Path $regPath -Name $noFilterValueName -ErrorAction SilentlyContinue

$existingJsonValue = $null
$entry = Get-ItemProperty -Path $regPath
if ($entry.PSObject.Properties.Name -contains $noFilterValueName) {
	$existingJsonValue = $entry.$noFilterValueName
	Write-Output "Existing domain filters found"
}
else {
	Write-Output "No existing domain filter were found"
}

# Initialize an empty array to hold the current domains
$existingDomainsList = @()

# If a JSON value was retrieved, convert it to an array of domains
if ($existingJsonValue) {
    $existingDomainsList = $existingJsonValue | ConvertFrom-Json
}

# Flag to track whether any domains were added
$hasModifications = $false

# Loop through each required domain and add any that are missing
foreach ($domain in $requiredDomains) {
    # If the domain isn't already in the list, add it and mark that we modified the list
    if ($domain -notin $existingDomainsList) {
        Write-Output "Adding domain: $domain"
        $existingDomainsList += $domain
        $hasModifications = $true
    }
    else {
        Write-Output "Domain already present: $domain"
    }
}

# If we added any domains, serialize back to JSON and update the registry
if ($hasModifications) {
    $updatedJsonValue = $existingDomainsList | ConvertTo-Json -Compress
    try {
        Set-ItemProperty -Path $regPath `
                         -Name $noFilterValueName `
                         -Value $updatedJsonValue `
                         -Type String
        Write-Output "Registry updated successfully."
    }
    catch {
        Write-Output "Error: failed to update registry - $($_.Exception.Message)"
        #exit 1
    }
}
else {
    Write-Output "No changes required; all domains already present."
}

# Exit with code 0 to signal success to Intune
#exit 0

