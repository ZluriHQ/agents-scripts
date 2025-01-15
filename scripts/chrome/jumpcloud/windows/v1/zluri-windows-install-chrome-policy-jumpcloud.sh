$registryPathChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
$registry_path_chrome_policy = "HKLM:\Software\Policies\Google\Chrome\3rdparty\extensions\cmobkdiplndgpjodaioofofmcikimbdb\policy"


# Ensure the ExtensionInstallForceList path exists
if (-not (Test-Path $registryPathChrome)) {
    New-Item -Path $registryPathChrome -Force | Out-Null
    Write-Host "Registry path $registryPathChrome has been created."
}

$extensionID = "cmobkdiplndgpjodaioofofmcikimbdb"
$updateURL = "https://clients2.google.com/service/update2/crx"
$extensionValue = "$extensionID;$updateURL"

# Get existing entries
$existingEntries = Get-ItemProperty -Path $registryPathChrome | Select-Object -Property * | Where-Object { $_.PSChildName -ne "PSPath" }

$alreadyExists = $false
foreach ($entry in $existingEntries.PSObject.Properties) {
    if ($entry.Value -eq $extensionValue) {
        $alreadyExists = $true
        break
    }
}

if ($alreadyExists) {
    Write-Host "Extension $extensionID is already present in the registry. No changes made."
} else {
    # Find the next available key number
    $nextKey = 1
    while ($existingEntries.PSObject.Properties.Name -contains $nextKey.ToString()) {
        $nextKey++
    }

    # Add the extension entry with the next available key
    Set-ItemProperty -Path $registryPathChrome -Name $nextKey -Value $extensionValue
    Write-Host "Extension $extensionID has been added to ExtensionInstallForceList with key $nextKey in the registry."
}


# Ensure the 3rdparty extension policy path exists
if (-not (Test-Path $registry_path_chrome_policy)) {
    New-Item -Path $registry_path_chrome_policy -Force | Out-Null
    Write-Host "Registry path $registry_path_chrome_policy has been created."
} else {
    Write-Host "Registry path $registry_path_chrome_policy already exists."
}

# Set the policy properties
Set-ItemProperty -Path $registry_path_chrome_policy -Name "OrgToken" -Value "<ORGTOKEN>" -Force
Set-ItemProperty -Path $registry_path_chrome_policy -Name "AgentOpenLoginTab" -Value "true" -Force
Set-ItemProperty -Path $registry_path_chrome_policy -Name "DisableLogout" -Value "true" -Force
