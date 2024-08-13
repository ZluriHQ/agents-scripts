$registry_path_edge = "HKLM:\Software\Policies\Microsoft\Edge\3rdparty\extensions\llnpohinpfhpnjbfcnmkjfccaengcffb"
$registry_path_edge_policy="HKLM:\Software\Policies\Microsoft\Edge\3rdparty\extensions\llnpohinpfhpnjbfcnmkjfccaengcffb\policy"
if (!(Test-Path $registry_path_edge)) {
 New-Item -Path $registry_path_edge -Force -ItemType Directory |Out-Null
}
if (!(Test-Path $registry_path_edge_policy)) {
 New-Item -Path ("$registry_path_edge_policy") -Force -ItemType Directory |Out-Null
}
Set-ItemProperty -Path $registry_path_edge_policy -Name "OrgToken" -Value "<ORGTOKEN>" -Force
Set-ItemProperty -Path $registry_path_edge_policy -Name "AgentOpenLoginTab" -Value "true" -Force
Set-ItemProperty -Path $registry_path_edge_policy -Name "DisableLogout" -Value "true" -Force