# -------------------------------------------------------------------------
# Title:        ESXi Hosts Ping Script Ver. 1.3
# Author:       Jakub Zyzanski
# Date:         August 12, 2024
# -------------------------------------------------------------------------

# Description:
# This PowerShell script is designed to ping multiple remote ESXi hosts
# whose names are specified in a CSV file exported from ServiceNow. The script
# reads hostnames from a specific column ("short_description") in the CSV file,
# checks for any hostnames that start with "ESXi host", and then pings each
# identified host four times. The results are logged in a file.

# Prerequisites:
# - PowerShell 5.0 or higher.
# - A single CSV file located in the same directory as the script.

# Usage:
# 1. Place this script in the same directory as your CSV file.
# 2. Ensure the exported file from ServiceNow has .csv format.
# 3. Run the script using PowerShell.
# 4. The results will be logged in a file named "ping_results.txt"
#    in the same directory as the script.

# Notes:
# - If there are multiple CSV files in the directory, the script will terminate
#   and prompt you to ensure only one file is present.
# - The script assumes that only one CSV file is present in the directory
#   alongside the script.
# -------------------------------------------------------------------------

# Get the directory of the currently running script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Find all CSV files that match the pattern
$csvFiles = Get-ChildItem -Path $scriptDir -Filter "*.csv"

# Check for CSV file presence
if ($csvFiles.Count -eq 0) {
    Write-Host "No CSV files found in the directory."
    Write-Host ""
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit
}

# Handle case with multiple CSV files
if ($csvFiles.Count -gt 1) {
    Write-Host "Multiple CSV files found. Please ensure only one CSV file is present."
    Write-Host "Found files:"
    $csvFiles | ForEach-Object { Write-Host $_.FullName }
    Write-Host ""
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()  
    exit
}

# If there is exactly one CSV file, use it
$hosts_file = $csvFiles[0].FullName
$log_file = Join-Path -Path $scriptDir -ChildPath "ping_results.txt"
$details_log_file = Join-Path -Path $scriptDir -ChildPath "details_log.txt"

# Get local time zone offset
$timeZone = [System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).ToString("hh\:mm")
$timeZonePrefix = if ($timeZone -like "-*") { "UTC$timeZone" } else { "UTC+$timeZone" }

# Initialize the log files (overwrite any existing files)
$logStartMessage = "Log Start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$timeZonePrefix]"
$logStartMessage | Set-Content -Path $log_file
"" | Add-Content -Path $log_file

# Initialize the details log file (overwrite any existing file)
"" | Set-Content -Path $details_log_file

# Initialize counters for summary
$totalHosts = 0
$hostsResponded = 0

# Read the CSV file
$hosts = Import-Csv -Path $hosts_file

# Filter and process hostnames starting with "ESXi host"
$maxHostLength = 0
$filteredHosts = $hosts | ForEach-Object {
    $line = $_.short_description
    if ($line -match "^ESXi host") {
        $targetHost = $line -replace "^ESXi host\s+", "" -replace "\s.*", ""
        if ($targetHost.Length -gt $maxHostLength) {
            $maxHostLength = $targetHost.Length
        }
        $targetHost
    }
}

# Check if no ESXi hosts were found
if ($filteredHosts.Count -eq 0) {
    Write-Host "No ESXi hosts found in the CSV file."
    Write-Host "No further action will be taken."
    "No ESXi hosts found in the CSV file." | Add-Content -Path $log_file
    "No further action will be taken." | Add-Content -Path $log_file
    Write-Host ""
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit
}

# Re-read the file for actual processing
$hosts | ForEach-Object {
    $line = $_.short_description

    # Check if the line starts with "ESXi host"
    if ($line -match "^ESXi host") {
        # Extract the hostname after "ESXi host"
        $targetHost = $line -replace "^ESXi host\s+", "" -replace "\s.*", ""
        $totalHosts++

        if ($targetHost) {
            # Execute ping command
            $pingOutput = ping $targetHost -n 4

            # Convert ping output to an array of lines
            $pingOutputLines = $pingOutput -split "`n"

            # Count successful and failed pings
            $successfulPings = ($pingOutputLines | Where-Object { $_ -match "Reply from" }).Count
            $failedPings = ($pingOutputLines | Where-Object { $_ -match "Request timed out" }).Count
            $totalPings = $successfulPings + $failedPings

            # Determine the percentage of successful pings
            if ($totalPings -eq 4) {
                $percentage = [math]::Round(($successfulPings / $totalPings) * 100)
                $successMessage = "{0}% ({1}/{2}) pings received." -f $percentage, $successfulPings, $totalPings
            } else {
                $successMessage = "host not found."
            }

            # Prepare output message
            $outputMessage = "{0,-$($maxHostLength + 3)}{1}" -f $targetHost, $successMessage

            # Print the output with the appropriate color
            Write-Host -NoNewline $outputMessage.Substring(0, $outputMessage.IndexOf($successMessage))
            $color = if ($successfulPings -eq 4) { "Green" } elseif ($successfulPings -ge 1) { "Yellow" } else { "Red" }
            Write-Host $successMessage -ForegroundColor $color
            $outputMessage | Add-Content -Path $log_file

            # Log detailed ping results
            "---$targetHost---" | Add-Content -Path $details_log_file
            $pingOutputLines | ForEach-Object {
                $_ | Add-Content -Path $details_log_file
            }
            "" | Add-Content -Path $details_log_file
            "" | Add-Content -Path $details_log_file
            "" | Add-Content -Path $details_log_file

            if ($successfulPings -ge 1) {
                $hostsResponded++
            }
        } else {
            $message = "No valid host found in line: $line"
            Write-Host $message
            $message | Add-Content -Path $log_file
        }
    }
}

# Print summary
Write-Host ""
$summaryMessage = "{0}/{1} hosts responded successfully." -f $hostsResponded, $totalHosts
if ($hostsResponded -eq $totalHosts) {
    Write-Host $summaryMessage -ForegroundColor Green
} else {
    Write-Host $summaryMessage -ForegroundColor Red
}

"" | Add-Content -Path $log_file
$summaryMessage | Add-Content -Path $log_file
"" | Add-Content -Path $log_file
"" | Add-Content -Path $log_file
"" | Add-Content -Path $log_file

# Add saved log information
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "Logs saved in ping_results.txt"

# Combine logs
$separator = "`n------------------------ Detail logs ------------------------`n"
$separator | Add-Content -Path $log_file
Get-Content -Path $details_log_file | Add-Content -Path $log_file

# Remove the details log file
Remove-Item -Path $details_log_file

# Pause the script execution to view results
Write-Host ""
Write-Host "Press Enter to exit..."
[void][System.Console]::ReadLine()
