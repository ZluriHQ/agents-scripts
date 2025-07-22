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
$expectedVersion = "4.0.0.0" # Update the minimum version that is expected to be present in the system
$orgToken = "<orgToken>" # replace your org token here

#Values to insert into client-config.json file
$configValues = @"
    {
        "org_token": $orgToken, 
        "interval": "3600000",
        "local_server":"on",
        "silent_auth": "on",
         "hide_zluri_tray_icon": false
    }
"@ 

#########################################################################################

# Logger function
Function Log-Message([String]$Message)
{
    Add-Content -Path "$logPathRoot\zluri\zluriscriptlog.txt" $Message
}

# Path for zluri script logs
$logPathRoot=$env:programdata
If (-not (Test-Path "$logPathRoot\zluri")) {
        New-Item -Path "$logPathRoot\zluri" -ItemType "directory"
    }



    # Specify the expected version in the same format
$logDate=Get-date
Log-Message "$logDate"

# Function to find all Zluri versions and their uninstall info
function Find-ZluriEntries {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    $entries = @()

    foreach ($path in $uninstallPaths) {
        if (Test-Path $path) {
            Get-ChildItem $path | ForEach-Object {
                $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
                if ($props.DisplayName -match 'zluri') {
                    $entries += [PSCustomObject]@{
                        DisplayName     = $props.DisplayName
                        Version         = $props.DisplayVersion
                        UninstallString = $props.UninstallString
                        KeyPath         = $_.PSPath
                    }
                }
            }
        }
    }

    return $entries
}

# Get all installed Zluri entries
$zluriEntries = Find-ZluriEntries
Log-Message "Found $($zluriEntries.Count) Zluri entry(ies)"

foreach ($entry in $zluriEntries) {
    $currentVersion = $entry.Version
    Log-Message "Zluri Entry: $($entry.DisplayName), Version: $currentVersion"

    if ([version]$expectedVersion -gt [version]$currentVersion) {
        # Log-Message "Version $currentVersion is older than expected $expectedVersion — proceeding to uninstall"

        try {
            $zluriProcess = Get-Process -Name "zluri" -ErrorAction SilentlyContinue
            if ($zluriProcess) {
                $nid = $zluriProcess.Id
                Stop-Process -Id $nid -Force
                Wait-Process -Id $nid -ErrorAction SilentlyContinue
                Log-Message "Stopped running Zluri process"
            }

            if ($entry.UninstallString) {
                $uninstallStr = $entry.UninstallString

                if ($uninstallStr -match "msiexec\.exe" -or $uninstallStr -match "msiexec") {
                    # Extract the ProductCode from the uninstall string if it's in the format /X{GUID}
            
                    if ($uninstallStr -match "({[0-9A-Fa-f\-]+})") {
                        $productCode = $matches[1]
                        Log-Message "Extracted ProductCode: $productCode"

                        $msiArgs = "/x $productCode /qn /norestart"
                        Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait
                        Log-Message "Performed silent MSI uninstall"
                    }
                    else {
                        Log-Message "Unable to extract ProductCode from: $uninstallStr"
                    }
                } else {
                    Log-Message "Non-MSI uninstall string detected. Deleting registry entry: $($entry.KeyPath)"
                    Remove-Item -Path $entry.KeyPath -Force -Recurse -ErrorAction SilentlyContinue
                    Log-Message "Deleted registry key: $($entry.KeyPath)"
               }
            } 

            # Delete local folders and desktop shortcuts
            Remove-Item "C:\Users\$env:USERNAME\AppData\Local\Programs\zluri" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "C:\Users\$env:USERNAME\AppData\Roaming\zluri" -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem "C:\Users\$env:USERNAME\Desktop" -Filter "zluri.lnk" | ForEach-Object {
                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            }
            Log-Message "Cleaned up folders and shortcuts"

        }
        catch {
            Log-Message "Error during uninstall: $_"
        }
    }
    else {
        Log-Message "Version $currentVersion is up-to-date"
    }
}



# function to create client-config.json file
function zluriClientConfigFiles{

    # reading param
    Param([String]$configFolderPath)

    # Setting variable for folder path & file path
    $folderPath = $("$configFolderPath\zluri")
    $filePath=$("$folderPath\client-config.json")

    # If there is no folderPath then create a zluri folder in that specific location
    If (-not (Test-Path $folderPath)) {
        Log-Message "Creating zluri folder in $folderPath"
        New-Item -Path $folderPath -ItemType "directory"
    }

    # If there is a client-config.json file in the filepath remove the file
    If (Test-Path $filePath) {
        Log-Message "deleting existing $filePath"
        Remove-Item $filePath
    }

    # Create client-config.json file in the filepath & insert the values
    New-Item -Path $filePath -ItemType "file" -value $configValues
    Log-Message "Created client config file in $filePath"
    
}

# Calling the function to create client-config.json file in programdata
zluriClientConfigFiles -configFolderPath $env:programdata

# Calling the function to create client-config.json file in localappdata
zluriClientConfigFiles -configFolderPath $env:localappdata

}

invoke-ascurrentuser -scriptblock $Command