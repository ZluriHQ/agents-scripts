$isZluriApp=Get-WmiObject -Class Win32_Product | where name -eq zluri
foreach($zluriApp in $isZluriApp){
   $zluriProcess=Get-Process -Name "zluri"
   $nid = (Get-Process zluri).id
   Stop-Process -Id $nid -Force
   Wait-Process -Id $nid -ErrorAction SilentlyContinue
   # Uninstalling zluri app
   $zluriApp.uninstall() | Out-Null
   # deleting zluri folder from %localappdata%\programs
   Remove-Item C:\Users\$env:username\AppData\Local\Programs\zluri -Recurse -Force -ErrorAction silentlycontinue
   Remove-Item C:\Users\$env:username\AppData\Roaming\zluri -Recurse -Force -ErrorAction silentlycontinue
   # deleting the shortcut on desktop
   $ShortcutsToDelete = Get-ChildItem -Path "C:\Users\$env:username\Desktop" -Filter "zluri.lnk"
   $ShortcutsToDelete | ForEach-Object {
   Remove-Item -Path $_.FullName
   }
}
# Remove client config files
Remove-Item C:\ProgramData\zluri -Recurse -Force -ErrorAction silentlycontinue
Remove-Item C:\Users\Administrator\AppData\Local\zluri -Recurse -Force -ErrorAction silentlycontinue
return "DONE"