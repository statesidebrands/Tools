# Initialize an array to hold the log messages
$logMessages = @()

# Create the C:\temp directory if it doesn't exist
$tempFolder = "C:\temp"
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder
    $logMessages += "Created directory: $tempFolder"
}

# Create a folder in C:\temp named Profwiz
$profwizFolder = "$tempFolder\Profwiz"
if (-not (Test-Path -Path $profwizFolder)) {
    New-Item -ItemType Directory -Path $profwizFolder
    $logMessages += "Created directory: $profwizFolder"
}

# Download the files from GitHub and copy them to the Profwiz folder
$files = @(
    "https://github.com/statesidebrands/Tools/raw/main/Profwiz.exe",
    "https://raw.githubusercontent.com/statesidebrands/Tools/main/Profwiz.config",
    "https://raw.githubusercontent.com/statesidebrands/Tools/main/StatesideAzureID.xml"
)

foreach ($file in $files) {
    $fileName = [System.IO.Path]::GetFileName($file)
    $destination = "$profwizFolder\$fileName"
    Invoke-WebRequest -Uri $file -OutFile $destination
    $logMessages += "Downloaded $file to $destination"
}

# Stop the "Windows Biometric Service", disable devices, delete files, and restart the service
$serviceName = "WbioSrvc"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service.Status -eq 'Running') {
    Stop-Service -Name $serviceName -Force
    $logMessages += "The Windows Biometric Service has been stopped."
} else {
    $logMessages += "The Windows Biometric Service was not running."
}

# Disable biometric devices
$biometricDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPClass -eq "Biometric" }
if ($biometricDevices) {
    foreach ($device in $biometricDevices) {
        $deviceInstanceId = $device.DeviceID
        $disableCommand = "pnputil /disable-device `"$deviceInstanceId`""
        Invoke-Expression $disableCommand
        $logMessages += "Biometric device with Device ID $deviceInstanceId has been disabled."
    }
} else {
    $logMessages += "No biometric devices found."
}

# Disable camera devices
$cameraDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPClass -eq "Image" -or $_.PNPClass -eq "Camera" }
if ($cameraDevices) {
    foreach ($device in $cameraDevices) {
        $deviceInstanceId = $device.DeviceID
        $disableCommand = "pnputil /disable-device `"$deviceInstanceId`""
        Invoke-Expression $disableCommand
        $logMessages += "Camera device with Device ID $deviceInstanceId has been disabled."
    }
} else {
    $logMessages += "No camera devices found."
}

# Delete files in the WinBioDatabase folder
$folderPath = "C:\Windows\System32\WinBioDatabase\"
if (Test-Path $folderPath) {
    Get-ChildItem -Path $folderPath | Remove-Item -Force
    $logMessages += "All files in $folderPath have been deleted."
} else {
    $logMessages += "Folder $folderPath does not exist."
}

# Re-enable biometric devices
if ($biometricDevices) {
    foreach ($device in $biometricDevices) {
        $deviceInstanceId = $device.DeviceID
        $enableCommand = "pnputil /enable-device `"$deviceInstanceId`""
        Invoke-Expression $enableCommand
        $logMessages += "Biometric device with Device ID $deviceInstanceId has been re-enabled."
    }
}

# Re-enable camera devices
if ($cameraDevices) {
    foreach ($device in $cameraDevices) {
        $deviceInstanceId = $device.DeviceID
        $enableCommand = "pnputil /enable-device `"$deviceInstanceId`""
        Invoke-Expression $enableCommand
        $logMessages += "Camera device with Device ID $deviceInstanceId has been re-enabled."
    }
}

# Start the Windows Biometric Service again
Start-Service -Name $serviceName
$logMessages += "The Windows Biometric Service has been started."

# Stops OneDrive and unlinks the current user
Stop-Process -name "Onedrive" -Force
Remove-Item -Path HKCU:\Software\Microsoft\OneDrive\Accounts\* -Recurse
$logMessages += "OneDrive has been stopped and the user unlinked."

# Create destination folder for exported bookmarks if it doesn't exist
$destinationPath = "C:\temp\Bookmarks"
if (!(Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath -Force
    $logMessages += "Created directory: $destinationPath for bookmarks export."
}

# Export Edge bookmarks
$edgeOutputFile = "$destinationPath\EdgeBookmarks.json"
$edgeFavoritesPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"
if (Test-Path $edgeFavoritesPath) {
    Copy-Item -Path $edgeFavoritesPath -Destination $edgeOutputFile -Force
    $logMessages += "Edge bookmarks have been exported to $edgeOutputFile"
} else {
    $logMessages += "Edge bookmarks file not found at $edgeFavoritesPath"
}

# Export Chrome bookmarks
$chromeOutputFile = "$destinationPath\ChromeBookmarks.json"
$chromeBookmarksPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
if (Test-Path $chromeBookmarksPath) {
    Copy-Item -Path $chromeBookmarksPath -Destination $chromeOutputFile -Force
    $logMessages += "Chrome bookmarks have been exported to $chromeOutputFile"
} else {
    $logMessages += "Chrome bookmarks file not found at $chromeBookmarksPath"
}

# Run Profwiz.exe as administrator
$profwizExe = "$profwizFolder\Profwiz.exe"
Start-Process $profwizExe -Verb RunAs
$logMessages += "Started Profwiz.exe as administrator."

# Display all log messages at the end
$logMessages | ForEach-Object { Write-Host $_ }
