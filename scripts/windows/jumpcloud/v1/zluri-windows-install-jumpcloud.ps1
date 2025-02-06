# This script is installing Zluri for the current signed in user and usually takes around 4-5 minutes.

# URL of the file to download
$url = "https://zluri-prod-agent-builds.s3.us-west-2.amazonaws.com/zluri+3.3.0.msi"

# Local path to save the downloaded file
$localPath = "C:\Users\Public\Downloads\zluriWindowsAgent.msi"

# Function to download the file
function Download-File {
    param (
        [string]$url,
        [string]$output
    )
    Write-Host "Downloading file from $url..."
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Host "File downloaded to $output."
}

# Download the file
Download-File -url $url -output $localPath

# Wait for the download process to complete
Start-Sleep -Seconds 1

# If Nuget is not installed, go ahead and install it
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PkgProvider = Get-PackageProvider
If ("Nuget" -notin $PkgProvider.Name){
    Install-PackageProvider -Name NuGet -Force
}

# If PSModule RunAsUser is not installed, install it
if ( -not (get-installedModule "RunAsUser" -ErrorAction SilentlyContinue)) {
    install-module RunAsUser -force
}

$Command = {
    #Powershell Command Goes Here.
    $msiPath="C:\Users\Public\Downloads\zluriWindowsAgent.msi"
    echo $msiPath;

    #install command
    Start-Process "msiexec.exe" -ArgumentList "/I `"$msiPath`" /qn" -Wait
}

echo $Command;

invoke-ascurrentuser -scriptblock $Command