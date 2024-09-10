# 1. Find the folder name of the currently logged in user
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[-1]

# 2. Displays a popup asking the user to enter their email address
$email = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter your email address", "Email Input", "")

# 3. Create a CSV named UserInfo in C:\temp
$csvPath = "C:\temp\UserInfo.csv"
if (-not (Test-Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory
}

$csvContent = "$currentUser,$email"
$csvContent | Out-File -FilePath $csvPath -Force

# 4. Creates a folder in C:\temp named Profwiz
$profwizFolder = "C:\temp\Profwiz"
if (-not (Test-Path $profwizFolder)) {
    New-Item -Path $profwizFolder -ItemType Directory
}

# 5. Download files from Github and copy them to that folder
$files = @(
    "https://github.com/statesidebrands/Tools/raw/main/Profwiz.exe",
    "https://raw.githubusercontent.com/statesidebrands/Tools/main/Profwiz.config",
    "https://raw.githubusercontent.com/statesidebrands/Tools/main/ForensiTAzureID.xml"
)

foreach ($file in $files) {
    $fileName = [System.IO.Path]::GetFileName($file)
    $destinationPath = Join-Path -Path $profwizFolder -ChildPath $fileName
    Invoke-WebRequest -Uri $file -OutFile $destinationPath
}

# 6. Runs C:\temp\Profwiz\Profwiz.exe as administrator
$profwizExePath = "C:\temp\Profwiz\Profwiz.exe"
Start-Process -FilePath $profwizExePath -Verb RunAs
