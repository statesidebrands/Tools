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
    "https://raw.githubusercontent.com/statesidebrands/Tools/main/Profwiz.config?token=GHSAT0AAAAAACXCNGOILAN2S24FQLK4XB6SZXASHHQ",
    "https://raw.githubusercontent.com/statesidebrands/Tools/main/StatesideAzureID.xml"
)

foreach ($file in $files) {
    $fileName = [System.IO.Path]::GetFileName($file)
    $destination = "$profwizFolder\$fileName"
    Invoke-WebRequest -Uri $file -OutFile $destination
}

# 4. Stops Onedrive and unlinks current user
Stop-Process -name "Onedrive" -Force
Remove-Item -Path HKCU:\Software\Microsoft\OneDrive\Accounts\* -Recurse

# 5. Run C:\temp\Profwiz\Profwiz.exe as administrator
$profwizExe = "$profwizFolder\Profwiz.exe"
Start-Process $profwizExe -Verb RunAs
