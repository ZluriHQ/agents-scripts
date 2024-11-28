# Edge extension install ID
$edgeExtensionID = "llnpohinpfhpnjbfcnmkjfccaengcffb"
$edgeRegistryEntry = "$edgeExtensionID;https://edge.microsoft.com/extensionwebstorebase/v1/crx"

$regKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"

if (!(Test-Path $regKey)) {
    Write-Information "Edge ForceList Path is not found"
    return 0
}

$extensionsList = New-Object System.Collections.ArrayList
$number = 0
$noMore = 0

do {
    $number++
    Write-Output "Pass : $number"
    try {
        $install = Get-ItemProperty $regKey -Name $number -ErrorAction Stop
        
        $extensionObj = [PSCustomObject]@{
            Name  = $number
            Value = $install.$number
        }
        $extensionsList.Add($extensionObj) | Out-Null

        Write-Output "Extension List Item : $($extensionObj.Name) / $($extensionObj.Value)"
    } catch {
        $noMore = 1
    }
} until ($noMore -eq 1)

$isExtensionPresent = $extensionsList | Where-Object { $_.Value -eq $edgeRegistryEntry }

if ($isExtensionPresent) {
    # Attempt to remove the extension if found
    Write-Output "Removing Zluri extension"
    try {
        Remove-ItemProperty $regKey -Name $isExtensionPresent.Name -Force
        return 0  # Successfully removed
    } catch {
        Write-Output "Failed to remove the Zluri extension"
        return 1  # Failed to remove
    }
} else {
    # Extension not found, no action required
    Write-Output "Zluri extension not found in the registry"
    return 0
}
