$registry_path_chrome = "HKLM:\Software\Policies\Google\Chrome\3rdparty\extensions\cmobkdiplndgpjodaioofofmcikimbdb"
$registry_path_chrome_policy="HKLM:\Software\Policies\Google\Chrome\3rdparty\extensions\cmobkdiplndgpjodaioofofmcikimbdb\policy"
if (!(Test-Path $registry_path_chrome)) {
 New-Item -Path $registry_path_chrome -Force -ItemType Directory |Out-Null
}
if (!(Test-Path $registry_path_chrome_policy)) {
 New-Item -Path ("$registry_path_chrome_policy") -Force -ItemType Directory |Out-Null
}
Set-ItemProperty -Path $registry_path_chrome_policy -Name "OrgToken" -Value "<ORGTOKEN>" -Force
Set-ItemProperty -Path $registry_path_chrome_policy -Name "AgentOpenLoginTab" -Value "true" -Force
Set-ItemProperty -Path $registry_path_chrome_policy -Name "DisableLogout" -Value "true" -Force