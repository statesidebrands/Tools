# Initialize an array to hold the log messages
$logMessages = @()

# Create the C:\temp directory if it doesn't exist
$tempFolder = "C:\temp"
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder
    $logMessages += "Created directory: $tempFolder"
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

# Check Windows Edition and change product key if it is Windows Home
$windowsEdition = (Get-WmiObject -Class Win32_OperatingSystem).OperatingSystemSKU
$isHomeEdition = $false

switch ($windowsEdition) {
    1 { $editionName = "Windows 10 Home"; $isHomeEdition = $true }
    101 { $editionName = "Windows 11 Home"; $isHomeEdition = $true }
    48 { $editionName = "Windows 10 Home Single Language"; $isHomeEdition = $true }
    98 { $editionName = "Windows 11 Home Single Language"; $isHomeEdition = $true }
    default { $editionName = "Other Edition"; $isHomeEdition = $false }
}

$logMessages += "Detected Windows Edition: $editionName"

# If Windows is Home edition, change the product key
if ($isHomeEdition) {
    $newProductKey = "NPPR9-FWDCX-D2C8J-H872K-2YT43"
    Write-Host "Detected Home Edition, changing product key..."
    Start-Process "changepk.exe" -ArgumentList "/ProductKey", $newProductKey -Wait -NoNewWindow
    $logMessages += "Product key changed for Home Edition to: $newProductKey"
} else {
    $logMessages += "No product key change needed for detected edition: $editionName"
}


# Display all log messages at the end
$logMessages | ForEach-Object { Write-Host $_ }
