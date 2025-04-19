# Domains that must be in the “noFiltering” list
$requiredDomains = @(
    'example3.com',
    'example4.com',
    'example5.com'
)

# Registry key path for Chrome uBlock Origin Lite policy
$regPath            = 'HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\Extensions\ddkjiahejlhfcafbddmgiahcphecmpfh\policy'
$noFilterValueName  = 'noFiltering'

# Ensure the policy key exists
if (-not (Test-Path $regPath)) {
    try { New-Item -Path $regPath -Force | Out-Null }
    catch { 
        Write-Output "Unable to create policy key: $regPath" 
        exit 1 
    }
}

# Read existing JSON (if any)
$existingJsonValue   = Get-ItemPropertyValue -Path $regPath -Name $noFilterValueName -ErrorAction SilentlyContinue
$existingDomainsList = @()

if ($existingJsonValue) {
    $existingDomainsList = $existingJsonValue | ConvertFrom-Json
}

# Track whether we need to write back changes
$hasModifications = $false

foreach ($domain in $requiredDomains) {
    if ($domain -notin $existingDomainsList) {
        Write-Output "Adding domain: $domain"
        $existingDomainsList += $domain
        $hasModifications  = $true
    }
    else {
        Write-Output "Domain already present: $domain"
    }
}

if ($hasModifications) {
    $updatedJsonValue = $existingDomainsList | ConvertTo-Json -Compress
    try {
        Set-ItemProperty -Path  $regPath `
                         -Name  $noFilterValueName `
                         -Value $updatedJsonValue `
                         -Type  String
        Write-Output "Registry updated successfully."
    }
    catch {
        Write-Output "Failed to write updated list: $($_.Exception.Message)"
        exit 1
    }
}
else {
    Write-Output "No changes required – list already up to date."
}

exit 0   # remediation succeeded

