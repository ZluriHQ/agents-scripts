# chrome extension install id
$chromeExtensionID = "cmobkdiplndgpjodaioofofmcikimbdb"
$chromeExtensionID = "$chromeExtensionID;https://clients2.google.com/service/update2/crx"


# function to remove chrome and edge extension
function zluriRemoveExtensions{
   Param([String]$extensionId,[String]$regKey)
   Write-Output $extensionID
   Write-Output $regKey


   # Add Extension to Chrome
$extensionsList = New-Object System.Collections.ArrayList
$number = 0
$noMore = 0
   do{
       $number++
       Write-Output "Pass : $number"
       try {
           $install = Get-ItemProperty $regKey -name $number -ErrorAction Stop
           $extensionObj = [PSCustomObject]@{
               Name = $number
               Value = $install.$number
           }
           $extensionsList.add($extensionObj) | Out-Null
           Write-Output "Extension List Item : $($extensionObj.name) / $($extensionObj.value)"
       }
       catch{
           $noMore = 1
       }
   }
   until($noMore -eq 1)
$extensionCheck = $extensionsList | Where-Object {$_.Value -eq $extensionId}
   if($extensionCheck){
       Write-Output "Removing zluri extension"
       Remove-ItemProperty $regKey -Name $extensionCheck.name -Force
   }
}


zluriRemoveExtensions -extensionId $chromeExtensionID -regKey "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist";


return "DONE"