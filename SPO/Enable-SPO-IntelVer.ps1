<#
.SYNOPSIS
   Enables Intelligent Version Trim on Group#0 sites in SharePoint Online that are not archived.

.DESCRIPTION
   This script connects to SharePoint Online, retrieves all Group#0 sites that are not archived,
   filters out those where Intelligent Version Trim (EnableAutoExpirationVersionTrim) is not enabled,
   and then updates them after user confirmation. The script includes retry logic to handle throttling (HTTP 429).

.NOTES
   - Requires SharePoint Online Management Shell.
   - Update the $adminUrl variable with your tenant's admin URL.
   - Tested with PowerShell 5.1.
   
.EXAMPLE
   .\Enable-SPO-IntelVer.ps1
   Prompts for confirmation and then updates the sites accordingly.
#>

# Function to invoke a script block with retry on throttling (HTTP 429)
function Invoke-WithRetry {
    param (
        [ScriptBlock]$ScriptBlock,
        [int]$MaxRetries = 5,
        [int]$DelaySeconds = 10
    )
    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            return & $ScriptBlock
        }
        catch {
            if ($_.Exception.Message -match "429") {
                Write-Host "Throttled (429): Waiting for $DelaySeconds seconds before retrying..." -ForegroundColor Yellow
                Start-Sleep -Seconds $DelaySeconds
            }
            else {
                throw $_
            }
        }
    }
    throw "Maximum retry attempts reached."
}

# Connect to SharePoint Online Admin Site (Update with your tenant's admin URL)
$adminUrl = "https://yourtenant-admin.sharepoint.com"
Connect-SPOService -Url $adminUrl

# Retrieve all Group#0 sites that are not archived
[array]$Sites = Get-SPOSite -Limit All -Template 'GROUP#0' -Filter { ArchiveStatus -eq 'NotArchived' }

# Filter sites that need updating (where Intelligent Version Trim is not enabled)
$SitesToUpdate = $Sites | Where-Object { $_.EnableAutoExpirationVersionTrim -ne $true }

Write-Host "Total sites: $($Sites.Count)"
Write-Host "Sites to update: $($SitesToUpdate.Count)"

# Exit if there are no sites to update
if ($SitesToUpdate.Count -eq 0) {
    Write-Host "No updates needed."
    exit
}

# Confirm before starting the update
$confirmation = Read-Host "Proceed with update? (Y/N)"
if ($confirmation -notin @("Y", "y")) {
    Write-Host "Update cancelled."
    exit
}

# Loop through each site and update the setting
foreach ($Site in $SitesToUpdate) {
    Write-Host ("Updating {0}..." -f $Site.Url)
    Invoke-WithRetry { Set-SPOSite -Identity $Site.Url -EnableAutoExpirationVersionTrim $true -Confirm:$false }
}

Write-Host "Update complete."