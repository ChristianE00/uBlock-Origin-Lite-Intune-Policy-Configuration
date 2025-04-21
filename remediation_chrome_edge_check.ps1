<#
.SYNOPSIS
  Intune remediation script – adds missing domains to uBlock Origin Lite’s “noFiltering” policy for Chrome and Edge.
.NOTES
  Last updated: April 20 2025
#>

# List of domains that must be in the “noFiltering” list
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

# Name of the registry value holding the JSON array
$noFilterValueName = 'noFiltering'

# Track if any errors occur during remediation
$errorOccurred = $false

# Loop through each browser policy to remediate
foreach ($browser in $policyPaths.Keys) {

    # Get the registry key path for this browser
    $regPath = $policyPaths[$browser]

    # Ensure the registry key exists; create it if missing
    if (-not (Test-Path $regPath)) {
        try {
            New-Item -Path $regPath -Force | Out-Null
            Write-Output "$browser : Created missing registry key $regPath"
        }
        catch {
            Write-Output "Error: $browser cannot create registry key $regPath"
            $errorOccurred = $true
            continue
        }
    }

    # Retrieve the existing JSON string for noFiltering; ignore if not present
    #$existingjsonvalue = Get-ItemPropertyValue -Path $regPath -Name $noFilterValueName -ErrorAction SilentlyContinue

		$existingJsonValue = $null
		$entry = Get-ItemProperty -Path $regPath
		if ($entry.PSObject.Properties.Name -contains $noFilterValueName) {
			$existingJsonValue = $entry.$noFilterValueName
			Write-Output "Existing domain filters found"
	  }	
		else {
			Write-Output "No existing domain filters found"
		}

    # Initialize an empty array for current domains
    $existingDomainsList = @()

    # If a JSON value was retrieved, convert it to a PowerShell array
    if ($existingJsonValue) {
        $existingDomainsList = $existingJsonValue | ConvertFrom-Json
        Write-Output "$browser : Loaded existing domains: $($existingDomainsList -join ', ')"
    }
    else {
        Write-Output "$browser : No existing 'noFiltering' value; starting with empty list."
    }

    # Track whether we added any domains for this browser
    $hasModifications = $false

    # Loop through each required domain and append if missing
    foreach ($domain in $requiredDomains) {
        if ($domain -notin $existingDomainsList) {
            Write-Output "$browser : Adding domain $domain"
            $existingDomainsList += $domain
            $hasModifications = $true
        }
        else {
            Write-Output "$browser : Domain already present: $domain"
        }
    }

    # If modifications were made, serialize to JSON and write back to registry
    if ($hasModifications) {
        $updatedJsonValue = $existingDomainsList | ConvertTo-Json -Compress

        try {
            Set-ItemProperty `
                -Path  $regPath `
                -Name  $noFilterValueName `
                -Value $updatedJsonValue `
                -Type  String
            Write-Output "$browser : Registry updated successfully."
        }
        catch {
            Write-Output "Error: $browser failed to update registry - $($_.Exception.Message)"
            $errorOccurred = $true
        }
    }
    else {
        Write-Output "$browser : No changes required; list already up to date."
    }
}

# Exit code 0 if all browsers succeeded, or 1 if any errors occurred
if ($errorOccurred) {
    exit 1
}
else {
    exit 0
}`
