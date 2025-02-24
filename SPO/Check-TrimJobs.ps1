<#
.SYNOPSIS
   Checks file version trimming jobs for a chosen template or all sites, and summarizes job statuses.

.DESCRIPTION
   Retrieves all SharePoint Online sites, lets you select a specific template or run for all,
   then checks the file version trimming job status on each. Sites with no active job are skipped.
   Jobs with a status of CompleteSuccess are stored for summary (without printing as active),
   while any other status is printed as an active (in-progress) job.
   At the end, a summary of complete jobs and in-progress jobs (with total storage released) is displayed.

.NOTES
   Requires SharePoint Online Management Shell.
   Make sure you’re connected before running, e.g.:
      Connect-SPOService -Url "https://yourtenant-admin.sharepoint.com"
.EXAMPLE
   .\Check-TrimJobs.ps1
#>

# Function to invoke commands with retry for throttling (429 errors)
function Invoke-WithRetry {
    param (
        [ScriptBlock]$ScriptBlock,
        [int]$MaxRetries = 5,
        [int]$DelaySeconds = 10
    )
    $currentDelay = $DelaySeconds
    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            return & $ScriptBlock
        }
        catch {
            if ($_.Exception.Message -match "429") {
                Write-Host "Throttled (429): Waiting for $currentDelay seconds before retrying..." -ForegroundColor Yellow
                Start-Sleep -Seconds $currentDelay
                $currentDelay *= 2  # Increase delay for next retry
            }
            else {
                throw $_
            }
        }
    }
    throw "Maximum retry attempts reached."
}

# Ensure you're connected to SPO
# Connect-SPOService -Url "https://yourtenant-admin.sharepoint.com"

Write-Host "Retrieving all sites..."
$AllSites = Invoke-WithRetry { Get-SPOSite -Limit All }

# Get distinct templates
$Templates = $AllSites | Select-Object -ExpandProperty Template | Sort-Object -Unique

Write-Host "Available Templates:"
Write-Host "[0] All Templates"
for ($i = 0; $i -lt $Templates.Count; $i++) {
    Write-Host "[$($i+1)] $($Templates[$i])"
}

$userInput = Read-Host "Select a template by number (or 0 for all templates)"
if ($userInput -eq '0') {
    Write-Host "You selected: All Templates"
    $Sites = $AllSites
}
else {
    [int]$choice = $userInput
    if ($choice -lt 1 -or $choice -gt $Templates.Count) {
        Write-Host "Invalid selection. Exiting." -ForegroundColor Red
        exit
    }
    $selectedTemplate = $Templates[$choice - 1]
    Write-Host "You selected: $selectedTemplate"
    $Sites = Invoke-WithRetry { Get-SPOSite -Limit All -Template $selectedTemplate }
}

$CompleteJobs   = @()
$InProgressJobs = @()

foreach ($Site in $Sites) {
    try {
        $JobStatus = Invoke-WithRetry { Get-SPOSiteFileVersionBatchDeleteJobProgress -Identity $Site.Url }
        
        if ($JobStatus.Status -eq "NoRequestFound") {
            continue  # Skip sites with no active job
        }
        
        $jobObject = [PSCustomObject]@{
            SiteUrl            = $Site.Url
            WorkItemId         = $JobStatus.WorkItemId
            Status             = $JobStatus.Status
            LastProcessTimeUTC = $JobStatus.LastProcessTimeInUTC
            CompleteTimeUTC    = $JobStatus.CompleteTimeInUTC
            VersionsDeleted    = $JobStatus.VersionsDeleted
            VersionsFailed     = $JobStatus.VersionsFailed
            StorageReleasedGB  = [math]::Round($JobStatus.StorageReleasedInBytes / 1GB, 3)
        }
        
        if ($JobStatus.Status -eq "CompleteSuccess") {
            $CompleteJobs += $jobObject
            # Do not print message for complete jobs
        }
        else {
            $InProgressJobs += $jobObject
            Write-Host "Active job found for: $($Site.Url) - Status: $($JobStatus.Status) | Storage Released: $($jobObject.StorageReleasedGB) GB"
        }
    }
    catch {
        continue  # Silently skip any errors
    }
}

# Summarize results
$TotalCompleteStorage   = ($CompleteJobs   | Measure-Object -Property StorageReleasedGB -Sum).Sum
$TotalInProgressStorage = ($InProgressJobs | Measure-Object -Property StorageReleasedGB -Sum).Sum

Write-Host "-------------------------------------------" -ForegroundColor Green
Write-Host "Summary:"
Write-Host "Total sites with complete jobs: $($CompleteJobs.Count)"
Write-Host "Total storage released (Complete jobs): $TotalCompleteStorage GB"
Write-Host "Total sites with in-progress jobs: $($InProgressJobs.Count)"
Write-Host "Total storage released (In-progress jobs): $TotalInProgressStorage GB" -ForegroundColor Green

# Export combined results to CSV
$AllResults = $CompleteJobs + $InProgressJobs
$AllResults | Export-Csv -Path ".\TrimJob-Status.csv" -NoTypeInformation -Delimiter ";" -Encoding UTF8
Write-Host "Report saved as TrimJob-Status.csv" -ForegroundColor Green
