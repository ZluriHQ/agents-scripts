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

#expected version. zluri apps lesser than this version will get uninstalled.
$expectedVersion="3.3.0.0" # Update the minimum version that is expected to be installed

#Values to insert into client-config.json file
$configValues='{"org_token": "<orgToken>","interval": "3600000","local_server":"on"}' #Replace <orgToken> with valid valid orgToken

#########################################################################################

    # Path for zluri script logs
$logPathRoot=$env:programdata
If (-not (Test-Path "$logPathRoot\zluri")) {
        Log-Message "Creating zluri folder in $folderPath"
        New-Item -Path "$logPathRoot\zluri" -ItemType "directory"
    }

    # Logger function
Function Log-Message([String]$Message){
    Add-Content -Path "$logPathRoot\zluri\zluriscriptlog.txt" $Message
}

    # Specify the expected version in the same format
$logDate=Get-date
Log-Message "$logDate"

    # Get the installed zluri apps
$isZluriApp=Get-WmiObject -Class Win32_Product | where name -eq zluri
Log-Message "$isZluriApp"

    # For each zluri agent present in the system
    foreach($zluriApp in $isZluriApp){
        Log-Message "$zluriApp"
        $currentVersion=$zluriApp.version

            # Check if expected version is greater than the installed zluri version
        if($expectedVersion -gt $currentVersion){
            Log-Message "checking if $expectedVersion greater than $currentVersion"
            $zluriProcess=Get-Process -Name "zluri"

                # stopping all zluri process
            Log-Message "$zluriProcess"
            $nid = (Get-Process zluri).id
                Stop-Process -Id $nid -Force
                Wait-Process -Id $nid -ErrorAction SilentlyContinue

                # Uninstalling zluri app
            $zluriApp.uninstall() | Out-Null

                # deleting zluri folders
            Remove-Item C:\Users\$env:username\AppData\Local\Programs\zluri -Recurse -Force -ErrorAction silentlycontinue
            Remove-Item C:\Users\$env:username\AppData\Roaming\zluri -Recurse -Force -ErrorAction silentlycontinue
            
                # deleting the shortcut on desktop
            $ShortcutsToDelete = Get-ChildItem -Path "C:\Users\$env:username\Desktop" -Filter "zluri.lnk"
            $ShortcutsToDelete | ForEach-Object {
                Remove-Item -Path $_.FullName
            }

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