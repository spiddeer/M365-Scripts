<#
.SYNOPSIS
    Updates SharePoint Online sites to enable Auto Expiration Version Trim.

.DESCRIPTION
    This script retrieves all SharePoint Online (SPO) sites based on user selection of site templates
    and enables Auto Expiration Version Trim on sites where it is not already enabled.

.PARAMETER None
    The script prompts the user to select a template or apply the change to all sites.

.OUTPUTS
    The script logs updates to a timestamped log file in the script directory.

.NOTES
    Author: Your Name
    Version: 1.0
    GitHub: https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME
#>

# Ensure the script is running in PowerShell 7
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "This script requires PowerShell 7 or later." -ForegroundColor Red
    exit
}

# Get the directory where the script is running
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Generate a timestamped log file
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "$ScriptDirectory\SPOSite_UpdateLog_$Timestamp.log"

# Function to log messages
function Write-Log {
    param ([string]$Message)
    $Message | Tee-Object -FilePath $LogFile -Append
}

# Ensure the SharePoint Online PowerShell module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Write-Host "Installing SharePoint Online PowerShell module..."
    Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force -Scope CurrentUser
}

# Connect to SharePoint Online (requires admin credentials)
Write-Host "Connecting to SharePoint Online..."
Connect-SPOService -Url "https://yourtenant-admin.sharepoint.com"

# Get unique site templates
$Templates = Get-SPOSite -Limit All | Select-Object -ExpandProperty Template -Unique | Sort-Object

# Display menu for user selection
Write-Host "`nSelect a template to filter sites:"
$Templates += "ALL" # Add an option for all templates
for ($i = 0; $i -lt $Templates.Count; $i++) {
    Write-Host "$i. $($Templates[$i])"
}

# Get user selection
$Selection = Read-Host "`nEnter the number corresponding to your choice"

# Validate user input
if ($Selection -match "^\d+$" -and [int]$Selection -ge 0 -and [int]$Selection -lt $Templates.Count) {
    $SelectedTemplate = $Templates[$Selection]

    if ($SelectedTemplate -eq "ALL") {
        [array]$Sites = Get-SPOSite -Limit All -Filter {ArchiveStatus -eq 'NotArchived'}
    } else {
        [array]$Sites = Get-SPOSite -Limit All -Template $SelectedTemplate -Filter {ArchiveStatus -eq 'NotArchived'}
    }

    Write-Log "=== Start of SPOSite Update Log - $(Get-Date) ==="

    # Process the sites
    ForEach ($Site in $Sites) {
        If ($Site.EnableAutoExpirationVersionTrim -ne $true) {
            $LogMessage = "Updating {0}…" -f $Site.Url
            Write-Host $LogMessage -ForegroundColor Yellow
            Write-Log $LogMessage

            # Apply the setting
            Set-SPOSite -Identity $Site.Url -EnableAutoExpirationVersionTrim $true -Confirm:$false

            Write-Log "Updated: $($Site.Url)"
        }
    }

    Write-Log "=== End of SPOSite Update Log ==="
    Write-Host "`nLog saved to: $LogFile" -ForegroundColor Green
} else {
    Write-Host "Invalid selection. Exiting script." -ForegroundColor Red
}