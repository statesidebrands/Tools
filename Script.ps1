# 1. Create the C:\temp directory if it doesn't exist
$tempFolder = "C:\temp"
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder
}

# 2. Create a folder in C:\temp named Profwiz
$profwizFolder = "$tempFolder\Profwiz"
if (-not (Test-Path -Path $profwizFolder)) {
    New-Item -ItemType Directory -Path $profwizFolder
}

# 3. Download the files from GitHub and copy them to the Profwiz folder
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

# 4. Define the path to the local OneDrive folder
$onedrivePath = "$env:USERPROFILE\OneDrive" # Change this if your OneDrive path is different

# Check if OneDrive folder exists
if (-not (Test-Path -Path $onedrivePath)) {
    Write-Host "OneDrive folder not found at $onedrivePath. Please verify the path."
    exit
}

# Recursively go through the files in the OneDrive directory
Get-ChildItem -Path $onedrivePath -Recurse | ForEach-Object {
    # Check if the file is an online-only file using the Offline attribute (Attribute 'O')
    if ($_ -is [System.IO.FileInfo] -and ($_ | Get-ItemProperty -Name Attributes).Attributes -band [System.IO.FileAttributes]::Offline) {
        # Force download the file by opening and reading it
        try {
            Write-Host "Downloading file: $($_.FullName)"
            # Read the file content to force download (small read just to bring it local)
            [System.IO.File]::ReadAllBytes($_.FullName) | Out-Null
        }
        catch {
            Write-Host "Failed to download file: $($_.FullName). Error: $_"
        }
    }
}

# 5. Stops Onedrive and unlinks current user
Stop-Process -name "Onedrive" -Force
Remove-Item -Path HKCU:\Software\Microsoft\OneDrive\Accounts\* -Recurse

# 6. Run C:\temp\Profwiz\Profwiz.exe as administrator
$profwizExe = "$profwizFolder\Profwiz.exe"
Start-Process $profwizExe -Verb RunAs
