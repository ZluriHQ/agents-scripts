$registry_path_chrome_policy="HKLM:\Software\Policies\Google\Chrome\3rdparty\extensions\cmobkdiplndgpjodaioofofmcikimbdb\policy"




if (-not (Test-Path $registry_path_chrome_policy)) {
    New-Item -Path $registry_path_chrome_policy -Force | Out-Null
    Write-Host "Registry path $registry_path_chrome_policy has been created."
} else {
    Write-Host "Registry path $registry_path_chrome_policy already exists."
}


Set-ItemProperty -Path $registry_path_chrome_policy -Name "OrgToken" -Value "<ORGTOKEN>" -Force
Set-ItemProperty -Path $registry_path_chrome_policy -Name "AgentOpenLoginTab" -Value "true" -Force
Set-ItemProperty -Path $registry_path_chrome_policy -Name "DisableLogout" -Value "true" -Force