# Stop all Zluri processes
Get-Process -Name "*zluri*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Find and collect Zluri uninstaller information from registry
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)

$uninstallersToRemove = @()

foreach ($path in $uninstallPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path | ForEach-Object {
            $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
            if ($props.DisplayName -imatch 'zluri') {
                $uninstallersToRemove += @{
                    RegistryPath = $_.PSPath
                    UninstallString = $props.UninstallString
                    Properties = $props
                }
            }
        }
    }
}

# Execute uninstallers first (before removing registry entries)
foreach ($uninstaller in $uninstallersToRemove) {
    $props = $uninstaller.Properties
    
    # Try MSI uninstall
    if ($props.UninstallString -match "({[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}})") {
        Write-Host "Attempting MSI uninstall for $($props.DisplayName)..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($matches[1]) /qn" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
    # Try EXE uninstall with multiple silent flags
    elseif ($props.UninstallString) {
        Write-Host "Attempting EXE uninstall for $($props.DisplayName)..."
        
        function Invoke-ZluriUninstallExe {
            param (
                [string]$uninstallString
            )
            
            $flags = @("/S", "/silent", "/quiet", "")
            foreach ($flag in $flags) {
                $cmd = $uninstallString
                if ($flag -ne "") {
                    $cmd += " $flag"
                }
                
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`"" -Wait -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                if ($process.ExitCode -eq 0) {
                    break
                }
            }
        }
        
        Invoke-ZluriUninstallExe -uninstallString $props.UninstallString
    }
}

# Now remove registry entries after uninstall attempts are completed
foreach ($uninstaller in $uninstallersToRemove) {
    Write-Host "Removing registry entry: $($uninstaller.RegistryPath)"
    Remove-Item -Path $uninstaller.RegistryPath -Force -Recurse -ErrorAction SilentlyContinue
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

Write-Host "Cleaning up files and folders..."
foreach ($path in $cleanupPaths) {
    if (Test-Path $path) {
        Write-Host "Removing: $path"
        Remove-Item $path -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# Remove shortcuts
$shortcutPaths = @("$env:PUBLIC\Desktop", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs")
Get-ChildItem "C:\Users\" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $shortcutPaths += "$($_.FullName)\Desktop"
    $shortcutPaths += "$($_.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
}

Write-Host "Removing shortcuts..."
foreach ($path in $shortcutPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Filter "*zluri*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Removing shortcut: $($_.FullName)"
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
        Get-ChildItem -Path $path -Filter "*zluri*.url" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Removing URL shortcut: $($_.FullName)"
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Zluri removal completed successfully!"