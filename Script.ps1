# Step 1: Find the name of the folder of the currently logged in user
$userFolder = [System.Environment]::UserName

# Step 2: Display a popup asking the user to enter their email address
Add-Type -AssemblyName Microsoft.VisualBasic
$userEmail = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter your email address", "User Email Input")

# Step 3: Create C:\temp if it doesn't exist and generate the UserInfo CSV
$csvPath = "C:\temp"
$userInfoFile = "$csvPath\UserInfo.csv"

if (-not (Test-Path $csvPath)) {
    New-Item -ItemType Directory -Path $csvPath
}

# Create the CSV with the header and user information
$userData = @{
    "Name"  = $userFolder
    "Email" = $userEmail
}
$userData | Export-Csv -Path $userInfoFile -NoTypeInformation

# Step 5: Create a folder in C:\temp named Profwiz
$profwizPath = "$csvPath\Profwiz"
if (-not (Test-Path $profwizPath)) {
    New-Item -ItemType Directory -Path $profwizPath
}

# Step 6: Download the files from Github and copy them to the Profwiz folder
$filesToDownload = @(
    "https://github.com/statesidebrands/Tools/raw/main/Profwiz.exe",
    "https://raw.githubusercontent.com/statesidebrands/Tools/main/Profwiz.config",
    "https://raw.githubusercontent.com/statesidebrands/Tools/main/ForensiTAzureID.xml",
)

foreach ($fileUrl in $filesToDownload) {
    $fileName = Split-Path -Leaf $fileUrl
    $destinationFile = Join-Path -Path $profwizPath -ChildPath $fileName
    Invoke-WebRequest -Uri $fileUrl -OutFile $destinationFile
}

# Step 7: Run C:\temp\Profwiz\Profwiz.exe as administrator
Start-Process -FilePath "$profwizPath\Profwiz.exe" -Verb RunAs
