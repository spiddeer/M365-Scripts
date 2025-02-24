<#
.SYNOPSIS
    Updates SharePoint Online sites to enable Auto Expiration Version Trim.

.DESCRIPTION
    This script retrieves SharePoint Online (SPO) sites based on user selection of site templates
    and enables Auto Expiration Version Trim on sites where it is not already enabled.

.PARAMETER None
    The script prompts the user to select a template or apply the change to all eligible sites.

.OUTPUTS
    The script logs updates to a timestamped log file in the script directory.

.NOTES
    Author: Your Name
    Version: 1.0
    GitHub: https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME
#>

# Get script directory and generate log file
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "$ScriptDirectory\SPOSite_UpdateLog_$Timestamp.log"

# Function to log messages
function Write-Log {
    param ([string]$Message)
    $Message | Out-File -FilePath $LogFile -Append
}

# Ensure the SharePoint Online PowerShell module is available
if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Write-Host "The SharePoint Online PowerShell module is not installed. Please install it first." -ForegroundColor Red
    exit
}

# Connect to SharePoint Online
Write-Host "Connecting to SharePoint Online..."
Connect-SPOService -Url "https://yourtenant-admin.sharepoint.com"

# Templates that should be excluded from updates
$ExcludedTemplates = @(
    "APPCATALOG#0", "RedirectSite#0", "RedirectSite#1",
    "SPSMSITEHOST#0", "SRCHCEN#0", "POINTPUBLISHINGHUB#0",
    "POINTPUBLISHINGPERSONAL#0", "POINTPUBLISHINGTOPIC#0",
    "EDISC#0", "EHS#1"
)

# Get available site templates (excluding system-critical ones)
$Templates = Get-SPOSite -Limit All | Select-Object -ExpandProperty Template -Unique | Sort-Object
$Templates = $Templates | Where-Object { $_ -notin $ExcludedTemplates }

# Display menu
Write-Host "`nSelect a template to filter sites:"
$Templates += "ALL" # Add 'ALL' as an option
for ($i = 0; $i -lt $Templates.Count; $i++) {
    Write-Host "$i. $($Templates[$i])"
}

# Get user selection
$Selection = Read-Host "`nEnter the number corresponding to your choice"

# Validate input
if ($Selection -match "^\d+$" -and [int]$Selection -ge 0 -and [int]$Selection -lt $Templates.Count) {
    $SelectedTemplate = $Templates[$Selection]

    if ($SelectedTemplate -eq "ALL") {
        [array]$Sites = Get-SPOSite -Limit All -Filter {ArchiveStatus -eq 'NotArchived'} |
                        Where-Object { $_.Template -notin $ExcludedTemplates }
    } else {
        [array]$Sites = Get-SPOSite -Limit All -Template $SelectedTemplate -Filter {ArchiveStatus -eq 'NotArchived'}
    }

    Write-Log "=== Start of SPOSite Update Log - $(Get-Date) ==="

    # Process sites
    ForEach ($Site in $Sites) {
        If ($Site.EnableAutoExpirationVersionTrim -ne $true) {
            $LogMessage = "Updating {0}…" -f $Site.Url
            Write-Host $LogMessage -ForegroundColor Yellow
            Write-Log $LogMessage

            # Apply setting
            Set-SPOSite -Identity $Site.Url -EnableAutoExpirationVersionTrim $true -Confirm:$false

            Write-Log "Updated: $($Site.Url)"
        }
    }

    Write-Log "=== End of SPOSite Update Log ==="
    Write-Host "`nLog saved to: $LogFile" -ForegroundColor Green
} else {
    Write-Host "Invalid selection. Exiting script." -ForegroundColor Red
}