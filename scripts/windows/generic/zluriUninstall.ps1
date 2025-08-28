# Stop all Zluri processes
Get-Process -Name "*zluri*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Find and uninstall Zluri from registry
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($path in $uninstallPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path | ForEach-Object {
            $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
            if ($props.DisplayName -match 'zluri') {
                # Try MSI uninstall
                if ($props.UninstallString -match "({[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}})") {
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($matches[1]) /qn" -Wait -NoNewWindow
                }
                # Try EXE uninstall
                elseif ($props.UninstallString) {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($props.UninstallString) /S`"" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                }
                # Remove registry entry
                Remove-Item -Path $_.PSPath -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }
}

# Remove files and folders
$cleanupPaths = @(
    "$env:ProgramData\zluri",
    "$env:ProgramFiles\zluri", 
    "${env:ProgramFiles(x86)}\zluri"
)

# Add user profile paths
Get-ChildItem "C:\Users\" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $cleanupPaths += "$($_.FullName)\AppData\Roaming\zluri"
    $cleanupPaths += "$($_.FullName)\AppData\Local\zluri"
    $cleanupPaths += "$($_.FullName)\AppData\Local\Programs\zluri"
}

foreach ($path in $cleanupPaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# Remove shortcuts
$shortcutPaths = @("$env:PUBLIC\Desktop", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs")
Get-ChildItem "C:\Users\" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $shortcutPaths += "$($_.FullName)\Desktop"
    $shortcutPaths += "$($_.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
}

foreach ($path in $shortcutPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Filter "*zluri*.lnk" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Get-ChildItem -Path $path -Filter "*zluri*.url" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
}

Write-Host "Zluri removal completed"