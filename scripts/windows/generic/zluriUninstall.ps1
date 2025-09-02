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

# Function to validate uninstall string format
function Test-UninstallStringFormat {
    param([string]$uninstallString)
    
    if ([string]::IsNullOrWhiteSpace($uninstallString)) {
        return $false
    }
    
    # Check if it matches expected patterns
    $validPatterns = @(
        '^"[^"]+\.exe"(\s+/.+)?$',           # "path\to\file.exe" optional_args
        '.*msiexec\.exe.*/[IiXx]\s*\{[\w-]+\}.*' # MSI uninstall pattern
    )
    
    foreach ($pattern in $validPatterns) {
        if ($uninstallString -match $pattern) {
            return $true
        }
    }
    
    return $false
}

# Execute uninstallers first (before removing registry entries)
foreach ($uninstaller in $uninstallersToRemove) {
    $props = $uninstaller.Properties
    
    # Try MSI uninstall
    if ($props.UninstallString -match "({[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}})") {
        Write-Host "Attempting MSI uninstall for $($props.DisplayName)..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($matches[1]) /qn" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
    # Try EXE uninstall with validation
    elseif ($props.UninstallString -and (Test-UninstallStringFormat $props.UninstallString)) {
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
                
                # Execute the uninstall command with validation already performed
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`"" -Wait -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                if ($process.ExitCode -eq 0) {
                    break
                }
            }
        }
        
        Invoke-ZluriUninstallExe -uninstallString $props.UninstallString
    }
    elseif ($props.UninstallString) {
        Write-Warning "Invalid uninstall string format, skipping: $($props.UninstallString)"
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

# Add current user profile paths (always accessible)
$cleanupPaths += "$env:USERPROFILE\AppData\Roaming\zluri"
$cleanupPaths += "$env:USERPROFILE\AppData\Local\zluri"
$cleanupPaths += "$env:USERPROFILE\AppData\Local\Programs\zluri"

Write-Host "Cleaning up files and folders..."
foreach ($path in $cleanupPaths) {
    if (Test-Path $path) {
        Write-Host "Removing: $path"
        Remove-Item $path -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# Remove shortcuts
$shortcutPaths = @()

# Add current user paths (always accessible)
$shortcutPaths += "$env:USERPROFILE\Desktop"
$shortcutPaths += "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

# Add system-wide paths (may require admin rights, but handle gracefully)
$shortcutPaths += "$env:PUBLIC\Desktop"  
$shortcutPaths += "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"

Write-Host "Removing shortcuts..."
foreach ($path in $shortcutPaths) {
    if (Test-Path $path) {
        try {
            Get-ChildItem -Path $path -Filter "*zluri*.lnk" -Recurse -ErrorAction Stop | ForEach-Object {
                Write-Host "Removing shortcut: $($_.FullName)"
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            }
            Get-ChildItem -Path $path -Filter "*zluri*.url" -Recurse -ErrorAction Stop | ForEach-Object {
                Write-Host "Removing URL shortcut: $($_.FullName)"
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Host "Skipping $path - insufficient permissions (run as administrator for complete cleanup)"
        }
        catch {
            Write-Host "Skipping $path - access error: $($_.Exception.Message)"
        }
    }
}

Write-Host "Zluri removal completed successfully!"