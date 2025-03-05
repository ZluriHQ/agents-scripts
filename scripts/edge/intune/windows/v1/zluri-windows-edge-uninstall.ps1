$edgeExtensionID = "cmobkdiplndgpjodaioofofmcikimbdb"
$edgeExtensionIDValue = "$edgeExtensionID;https://clients2.google.com/service/update2/crx"


# function to remove edge and edge extension
function zluriRemoveExtensions {
    Param([String]$extensionId, [String]$regKey)
    Write-Output $extensionID
    Write-Output $regKey


    # Add Extension to edge
    $extensionsList = New-Object System.Collections.ArrayList
    $number = 0
    $noMore = 0
    do {
        $number++
        Write-Output "Pass : $number"
        try {
            $install = Get-ItemProperty $regKey -name $number -ErrorAction Stop
            $extensionObj = [PSCustomObject]@{
                Name  = $number
                Value = $install.$number
            }
            $extensionsList.add($extensionObj) | Out-Null
            Write-Output "Extension List Item : $($extensionObj.name) / $($extensionObj.value)"
        }
        catch {
            $noMore = 1
        }
    }
    until($noMore -eq 1)
    $extensionCheck = $extensionsList | Where-Object { $_.Value -eq $extensionId }
    if ($extensionCheck) {
        Write-Output "Removing zluri extension"
        Remove-ItemProperty $regKey -Name $extensionCheck.name -Force
    }
}

function Remove-Policy {
    Param([String]$regKey)

    if (Test-Path -Path $regKey) {
        Write-Output "Removing registry key: $regKey"
        try {
            Remove-Item -Path $regKey -Recurse -Force -ErrorAction Stop
            Write-Output "Registry key removed successfully."
        }
        catch {
            Write-Error "Error removing registry key: $_"
        }
    }
    else {
        Write-Output "Registry key '$regKey' does not exist."
    }
}


zluriRemoveExtensions -extensionId $edgeExtensionIDValue -regKey "HKLM:\SOFTWARE\Policies\Google\edge\ExtensionInstallForcelist";

Remove-Policy -regKey "HKLM:\SOFTWARE\Policies\\Microsoft\Edge\3rdparty\extensions\$edgeExtensionID"

return "DONE"