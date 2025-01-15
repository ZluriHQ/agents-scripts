$registryPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"

$extensionID = "cmobkdiplndgpjodaioofofmcikimbdb"
$updateURL = "https://clients2.google.com/service/update2/crx"

$extensionValue = "$extensionID;$updateURL"

if (Test-Path $registryPath) {
    $existingEntries = Get-ItemProperty -Path $registryPath | Select-Object -Property * | Where-Object { $_.PSChildName -ne "PSPath" }
    $entryRemoved = $false

    foreach ($entry in $existingEntries.PSObject.Properties) {
        if ($entry.Value -eq $extensionValue) {
            Remove-ItemProperty -Path $registryPath -Name $entry.Name
            Write-Host "Extension $extensionID has been removed from ExtensionInstallForceList (Key: $entry.Name)."
            $entryRemoved = $true
            break
        }
    }

    if (-not $entryRemoved) {
        Write-Host "Extension $extensionID is not present in the registry. No changes made."
    }
} else {
    Write-Host "The registry path $registryPath does not exist. No changes made."
}


$registry_path_extension = "HKLM:\Software\Policies\Google\Chrome\3rdparty\extensions\cmobkdiplndgpjodaioofofmcikimbdb"

# Check if the registry path exists
if (Test-Path $registry_path_extension) {
    Write-Host "Registry path $registry_path_extension exists. Proceeding with removal."

    try {
        # Remove the entire registry key
        Remove-Item -Path $registry_path_extension -Recurse -Force
        Write-Host "Successfully removed the registry path: $registry_path_extension."
    } catch {
        Write-Warning "Failed to remove the registry path $registry_path_extension. Error: $_"
    }
} else {
    Write-Host "Registry path $registry_path_extension does not exist. No action needed."
}

