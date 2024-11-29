$registryPathChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForceList"
$registry_path_chrome_policy="HKLM:\Software\Policies\Google\Chrome\3rdparty\extensions\cmobkdiplndgpjodaioofofmcikimbdb\policy"


if (-not (Test-Path $registryPathChrome)) {
    New-Item -Path $registryPathChrome -Force | Out-Null
    Write-Host "Registry path $registryPathChrome has been created."
}


$extensionID = "cmobkdiplndgpjodaioofofmcikimbdb"
$updateURL = "https://clients2.google.com/service/update2/crx"

$extensionValue = "$extensionID;$updateURL"

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
    
    $nextKey = 1
    while ($existingEntries.PSObject.Properties.Name -contains $nextKey.ToString()) {
        $nextKey++
    }

    Set-ItemProperty -Path $registryPath -Name $nextKey -Value $extensionValue
    Write-Host "Extension $extensionID has been added to ExtensionInstallForceList with key $nextKey in the registry."
}


if (-not (Test-Path $registry_path_chrome_policy)) {
    New-Item -Path $registry_path_chrome_policy -Force | Out-Null
    Write-Host "Registry path $registry_path_chrome_policy has been created."
} else {
    Write-Host "Registry path $registry_path_chrome_policy already exists."
}


Set-ItemProperty -Path $registry_path_chrome_policy -Name "OrgToken" -Value "<ORGTOKEN>" -Force
Set-ItemProperty -Path $registry_path_chrome_policy -Name "AgentOpenLoginTab" -Value "true" -Force
Set-ItemProperty -Path $registry_path_chrome_policy -Name "DisableLogout" -Value "true" -Force