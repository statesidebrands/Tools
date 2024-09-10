# 1. Get the folder name of the currently logged in user
$userFolder = $env:USERNAME

# 2. Display a popup asking the user to enter their email address
Add-Type -AssemblyName Microsoft.VisualBasic
$emailAddress = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter your email address:", "Email Entry", "")

# 3. Create the C:\temp directory if it doesn't exist
$tempFolder = "C:\temp"
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder
}

# 4. Create a CSV named UserInfo in C:\temp with username and email
$userInfoCsv = "$tempFolder\UserInfo.csv"
$userInfo = @"
Username,Email
$userFolder,$emailAddress
"@
$userInfo | Out-File -FilePath $userInfoCsv -Encoding UTF8

# 5. Create a folder in C:\temp named Profwiz
$profwizFolder = "$tempFolder\Profwiz"
if (-not (Test-Path -Path $profwizFolder)) {
    New-Item -ItemType Directory -Path $profwizFolder
}

# 6. Download the files from GitHub and copy them to the Profwiz folder
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

# 7. Run C:\temp\Profwiz\Profwiz.exe as administrator
$profwizExe = "$profwizFolder\Profwiz.exe"
Start-Process $profwizExe -Verb RunAs
