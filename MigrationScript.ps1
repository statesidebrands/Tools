# Create the C:\temp directory if it doesn't exist
$tempFolder = "C:\temp"
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder
}

# Create a folder in C:\temp named Profwiz
$profwizFolder = "$tempFolder\Profwiz"
if (-not (Test-Path -Path $profwizFolder)) {
    New-Item -ItemType Directory -Path $profwizFolder
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
}

# PowerShell script to stop the "Windows Biometric Service", disable biometric devices and cameras, 
# delete files in WinBioDatabase folder, and then re-enable the devices and restart the service

# Define the service name
$serviceName = "WbioSrvc"

# Stop the Windows Biometric Service
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service.Status -eq 'Running') {
    Stop-Service -Name $serviceName -Force
    Write-Host "The Windows Biometric Service has been stopped."
} else {
    Write-Host "The Windows Biometric Service is not running."
}

# Disable biometric devices using PnPUtil
Write-Host "Disabling biometric devices in Device Manager..."

# Get list of biometric devices using Device Manager class for Biometric devices (class GUID: {53D29EF7-377C-4D14-864B-EB3A85769359})
$biometricDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPClass -eq "Biometric" }

if ($biometricDevices) {
    foreach ($device in $biometricDevices) {
        # Use the PnPUtil tool to disable each biometric device
        $deviceInstanceId = $device.DeviceID
        $disableCommand = "pnputil /disable-device `"$deviceInstanceId`""
        
        # Execute the command to disable the device
        Invoke-Expression $disableCommand
        
        Write-Host "Biometric device with Device ID $deviceInstanceId has been disabled."
    }
} else {
    Write-Host "No biometric devices found in Device Manager."
}

# Disable camera devices using PnPUtil
Write-Host "Disabling camera devices in Device Manager..."

# Get list of camera devices using Device Manager class for Image devices (class GUID: {6BDD1FC6-810F-11D0-BEC7-08002BE2092F})
$cameraDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPClass -eq "Image" -or $_.PNPClass -eq "Camera" }

if ($cameraDevices) {
    foreach ($device in $cameraDevices) {
        # Use the PnPUtil tool to disable each camera device
        $deviceInstanceId = $device.DeviceID
        $disableCommand = "pnputil /disable-device `"$deviceInstanceId`""
        
        # Execute the command to disable the device
        Invoke-Expression $disableCommand
        
        Write-Host "Camera device with Device ID $deviceInstanceId has been disabled."
    }
} else {
    Write-Host "No camera devices found in Device Manager."
}

# Delete all files in the folder C:\Windows\System32\WinBioDatabase\
$folderPath = "C:\Windows\System32\WinBioDatabase\"
Write-Host "Deleting all files in $folderPath..."

# Check if the folder exists
if (Test-Path $folderPath) {
    # Delete all files in the folder
    Get-ChildItem -Path $folderPath | Remove-Item -Force
    
    Write-Host "All files in $folderPath have been deleted."
} else {
    Write-Host "The folder $folderPath does not exist."
}

# Re-enable biometric devices using PnPUtil
Write-Host "Re-enabling biometric devices in Device Manager..."

if ($biometricDevices) {
    foreach ($device in $biometricDevices) {
        # Use the PnPUtil tool to re-enable each biometric device
        $deviceInstanceId = $device.DeviceID
        $enableCommand = "pnputil /enable-device `"$deviceInstanceId`""
        
        # Execute the command to enable the device
        Invoke-Expression $enableCommand
        
        Write-Host "Biometric device with Device ID $deviceInstanceId has been re-enabled."
    }
}

# Re-enable camera devices using PnPUtil
Write-Host "Re-enabling camera devices in Device Manager..."

if ($cameraDevices) {
    foreach ($device in $cameraDevices) {
        # Use the PnPUtil tool to re-enable each camera device
        $deviceInstanceId = $device.DeviceID
        $enableCommand = "pnputil /enable-device `"$deviceInstanceId`""
        
        # Execute the command to enable the device
        Invoke-Expression $enableCommand
        
        Write-Host "Camera device with Device ID $deviceInstanceId has been re-enabled."
    }
}

# Start the Windows Biometric Service again
Write-Host "Starting the Windows Biometric Service..."
Start-Service -Name $serviceName
Write-Host "The Windows Biometric Service has been started."

Write-Host "Process completed."

# Stops Onedrive and unlinks current user
Stop-Process -name "Onedrive" -Force
Remove-Item -Path HKCU:\Software\Microsoft\OneDrive\Accounts\* -Recurse

# Run C:\temp\Profwiz\Profwiz.exe as administrator
$profwizExe = "$profwizFolder\Profwiz.exe"
Start-Process $profwizExe -Verb RunAs
