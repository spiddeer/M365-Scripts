<#
.SYNOPSIS
    Checks SharePoint Online storage cleared by version history cleanup jobs.
.DESCRIPTION
    This script monitors the progress of SharePoint Online version history cleanup jobs
    and reports on storage space released across all sites.
.PARAMETER AdminSiteUrl
    The SharePoint Online admin center URL (e.g., "https://contoso-admin.sharepoint.com")
.PARAMETER MaxRetries
    Maximum number of retry attempts for throttled requests
.PARAMETER DelaySeconds
    Number of seconds to wait between retry attempts
.EXAMPLE
    .\CheckCleardStorage.ps1 -AdminSiteUrl "https://contoso-admin.sharepoint.com"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminSiteUrl,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 5,
    
    [Parameter(Mandatory = $false)]
    [int]$DelaySeconds = 10
)

# Function to invoke a script block with retry on throttling (429)
function Invoke-WithRetry {
    param (
        [Parameter(Mandatory = $true)]
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
                Write-Warning "Throttled (429): Waiting for $DelaySeconds seconds before retrying..."
                Start-Sleep -Seconds $DelaySeconds
            }
            else {
                throw $_
            }
        }
    }
    throw "Maximum retry attempts reached."
}

# Ensure required module is available
if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    throw "Required module 'Microsoft.Online.SharePoint.PowerShell' is not installed. Please install it using: Install-Module -Name Microsoft.Online.SharePoint.PowerShell"
}

# Connect to SharePoint Online if not already connected
if (-not (Get-SPOSite -Limit 1 -ErrorAction SilentlyContinue)) {
    try {
        Connect-SPOService -Url $AdminSiteUrl
    }
    catch {
        throw "Failed to connect to SharePoint Online admin center. Error: $($_.Exception.Message)"
    }
}

# Array to hold job progress data
$jobs = @()

# Retrieve all sites
try {
    $allSites = Get-SPOSite -Limit All
}
catch {
    throw "Failed to retrieve SharePoint sites. Error: $($_.Exception.Message)"
}

foreach ($site in $allSites) {
    $siteUrl = $site.Url
    try {
        # Attempt to get the trim job progress for this site
        $job = Invoke-WithRetry -ScriptBlock { 
            Get-SPOSiteFileVersionBatchDeleteJobProgress -Identity $siteUrl -ErrorAction SilentlyContinue 
        } -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds
        
        if ($job) {
            $job | Add-Member -MemberType NoteProperty -Name SiteUrl -Value $siteUrl -Force
            $jobs += $job
        }
    }
    catch {
        if ($_.Exception.Message -match "site is locked") {
            Write-Warning "Skipping locked site: $siteUrl"
        }
        else {
            Write-Warning "Error retrieving job for ${siteUrl}: $($_.Exception.Message)"
        }
    }
}

# Report on jobs in progress
$jobsInProgress = $jobs | Where-Object { $_.Status -eq "InProgress" }
Write-Host "`nJobs in progress:" -ForegroundColor Cyan
$jobsInProgress | Format-Table SiteUrl, Status, StorageReleasedInBytes

# Report on completed jobs
$jobsComplete = $jobs | Where-Object { $_.Status -eq "CompleteSuccess" }
$totalReleasedBytes = ($jobsComplete | Measure-Object -Property StorageReleasedInBytes -Sum).Sum
$totalReleasedGB = [math]::Round($totalReleasedBytes / 1GB, 3)

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "--------------------------------------------"
Write-Host "Total storage released in complete jobs: $totalReleasedGB GB"

# Summary of all jobs
$totalReleasedAllBytes = ($jobs | Measure-Object -Property StorageReleasedInBytes -Sum).Sum
$totalReleasedAllGB = [math]::Round($totalReleasedAllBytes / 1GB, 3)
Write-Host "Total storage released in all jobs: $totalReleasedAllGB GB"