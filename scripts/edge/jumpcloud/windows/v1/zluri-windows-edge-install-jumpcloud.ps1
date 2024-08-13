$extensionID="llnpohinpfhpnjbfcnmkjfccaengcffb"
Write-Information "ExtensionID = $extensionID"
$extensionId = "$extensionId;https://edge.microsoft.com/extensionwebstorebase/v1/crx"
$regKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"
    if(!(Test-Path $regKey)){
        New-Item $regKey -Force
        Write-Information "Created Reg Key $regKey"
    }
    # Add Extension to Chrome
$extensionsList = New-Object System.Collections.ArrayList
$number = 0
$noMore = 0
    do{
        $number++
        Write-Information "Pass : $number"
        try{
            $install = Get-ItemProperty $regKey -name $number -ErrorAction Stop
            $extensionObj = [PSCustomObject]@{
                Name = $number
                Value = $install.$number
            }
            $extensionsList.add($extensionObj) | Out-Null
            Write-Information "Extension List Item : $($extensionObj.name) / $($extensionObj.value)"
        }
        catch{
            $noMore = 1
        }
    }
    until($noMore -eq 1)
$extensionCheck = $extensionsList | Where-Object {$_.Value -eq $extensionId}
    if($extensionCheck){
        $result = "Extension Already Exists"
        Write-Information "Extension Already Exists"
    }else{
        $newExtensionId = $extensionsList[-1].name + 1
        New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist -PropertyType String -Name $newExtensionId -Value $extensionId
        $result = "Installed"
    }
$result
