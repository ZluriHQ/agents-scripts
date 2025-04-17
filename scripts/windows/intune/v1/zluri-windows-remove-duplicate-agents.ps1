# Summary:
# Uninstallation script for removal of zluri agent from Machine
# 
# The script performs the following actions:
# 1. Finds all Zluri applications registered in both HKLM and HKCU registry locations
# 2. Terminates any running Zluri processes before uninstallation
# 3. Uninstalls applications using appropriate methods (MSI or executable uninstallers)
# 4. Handles both machine-wide and per-user installations differently
# 5. Falls back to registry removal if standard uninstallation fails
# 6. Performs thorough cleanup of installation folders and shortcuts
#    - For machine-wide installations: Cleans program files and all user profiles
#    - For per-user installations: Cleans only current user data
# 7. Provides detailed logging with color-coded status messages
#

# Get all Zluri applications from both local machine and current user registry
$apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, `
                        HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, `
                        HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, `
                        HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*zluri*" }

# If no applications found, exit
if (-not $apps) {
    Write-Host "No Zluri applications found."
    exit
}

# Convert to array if single item
if ($apps -isnot [array]) {
    $apps = @($apps)
}

Write-Host "Found $(($apps | Measure-Object).Count) Zluri installation(s) to remove."

# Stop any running Zluri processes
$zluriProcesses = Get-Process | Where-Object { $_.ProcessName -like "*zluri*" } -ErrorAction SilentlyContinue
if ($zluriProcesses) {
    Write-Host "Stopping Zluri processes before uninstallation..." -ForegroundColor Yellow
    foreach ($process in $zluriProcesses) {
        try {
            # Verify the process is still running before attempting to stop it
            if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
                Write-Host "Stopping process: $($process.ProcessName) (ID: $($process.Id))"
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                Wait-Process -Id $process.Id -Timeout 10 -ErrorAction SilentlyContinue
                Write-Host "Successfully stopped process: $($process.ProcessName)" -ForegroundColor Green
            } else {
                Write-Host "Process $($process.ProcessName) (ID: $($process.Id)) is no longer running" -ForegroundColor Yellow
            }
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Host ("Failed to stop process {0}. Error - {1}" -f $process.ProcessName, $errorMsg) -ForegroundColor Red
        }
    }
}

# Track if we found any machine-wide installations
$machineWideInstallFound = $false

# Uninstall ALL versions
foreach ($app in $apps) {
    # Check if this is a machine-wide installation
    $isMachineWide = $app.PSPath -like "*HKEY_LOCAL_MACHINE*"
    if ($isMachineWide) {
        $machineWideInstallFound = $true
        Write-Host "Found machine-wide installation: $($app.DisplayName) version $($app.DisplayVersion)" -ForegroundColor Yellow
    }
    
    if ($app.DisplayVersion -and $app.UninstallString) {
        # Prepare uninstall command
        $uninstallCmd = $app.UninstallString -replace "/I", "/X"
        
        Write-Host "Uninstalling $($app.DisplayName) version $($app.DisplayVersion)..."
        
        try {
            # If the uninstaller doesn't exist at the location, use registry removal approach
            if ($uninstallCmd -match "MsiExec") {
                # This is an MSI installation, we can use the product code directly
                $productCode = $uninstallCmd -replace '.*({[A-Z0-9-]+}).*', '$1'
                if ($productCode -match '{[A-Z0-9-]+}') {
                    # For machine-wide installations, ensure ALLUSERS=1
                    if ($isMachineWide) {
                        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productCode ALLUSERS=1 /quiet /norestart" -Wait -NoNewWindow
                    } else {
                        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productCode /quiet /norestart" -Wait -NoNewWindow
                    }
                } else {
                    # Fall back to the original uninstall string
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $uninstallCmd /quiet /norestart" -Wait -NoNewWindow
                }
            } else {
                # Try to run the uninstaller directly with silent flags
                $uninstallExe = $uninstallCmd -replace '"(.*?)".*', '$1'
                if (Test-Path $uninstallExe) {
                    # Try multiple silent installation flags to cover different installer types
                    $uninstallArgs = "/S /SILENT /VERYSILENT /QUIET /NORESTART"
                    Write-Host "Running uninstaller silently: $uninstallExe with silent flags"
                    Start-Process -FilePath $uninstallExe -ArgumentList $uninstallArgs -Wait -NoNewWindow
                } else {
                    # If the uninstaller isn't found, just remove the registry entry
                    Write-Host "Uninstaller not found. Removing registry entry for $($app.DisplayName)..."
                    Remove-Item -Path $app.PSPath -Force
                }
            }
            Write-Host "Successfully uninstalled $($app.DisplayName) version $($app.DisplayVersion)" -ForegroundColor Green
        }
        catch {
            $errorMsg = $_.Exception.Message
            Write-Error ("Failed to uninstall {0} version {1}. Error - {2}" -f $app.DisplayName, $app.DisplayVersion, $errorMsg)
            Write-Host "Attempting to remove registry entry directly..." -ForegroundColor Yellow
            try {
                Remove-Item -Path $app.PSPath -Force
                Write-Host "Registry entry removed for $($app.DisplayName)" -ForegroundColor Green
            } catch {
                $errorMsg = $_.Exception.Message
                Write-Error ("Failed to remove registry entry. Error - {0}" -f $errorMsg)
            }
        }
    } else {
        # If missing uninstall string, just remove the registry entry
        Write-Host "No valid uninstall information for $($app.DisplayName). Removing registry entry..." -ForegroundColor Yellow
        try {
            Remove-Item -Path $app.PSPath -Force
            Write-Host "Registry entry removed." -ForegroundColor Green
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Error ("Failed to remove registry entry. Error - {0}" -f $errorMsg)
        }
    }
}

# Clean up app data for all users if machine-wide installation was found
if ($machineWideInstallFound) {
    Write-Host "Machine-wide installation detected. Cleaning up Zluri data for all users..." -ForegroundColor Yellow
    
    # Clean up common program files
    $commonPaths = @(
        "$env:ProgramFiles\zluri",
        "${env:ProgramFiles(x86)}\zluri"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-Host "Removing Zluri folder: $path" -ForegroundColor Yellow
            try {
                Remove-Item -Path $path -Recurse -Force
                Write-Host "Successfully removed $path" -ForegroundColor Green
            } catch {
                $errorMsg = $_.Exception.Message
                Write-Error ("Failed to remove {0}. Error - {1}" -f $path, $errorMsg)
            }
        }
    }
    
    # Get all user profiles
    $userProfiles = Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -ne "Public" -and $_.Name -ne "Default" -and $_.Name -ne "Default User" -and $_.Name -ne "All Users" }
    
    foreach ($profile in $userProfiles) {
        $userPaths = @(
            "$($profile.FullName)\AppData\Local\Programs\zluri",
            "$($profile.FullName)\AppData\Local\zluri",
            "$($profile.FullName)\AppData\Roaming\zluri"
        )
        
        foreach ($path in $userPaths) {
            if (Test-Path $path) {
                Write-Host "Removing Zluri folder for user $($profile.Name): $path" -ForegroundColor Yellow
                try {
                    Remove-Item -Path $path -Recurse -Force
                    Write-Host "Successfully removed $path" -ForegroundColor Green
                } catch {
                    $errorMsg = $_.Exception.Message
                    Write-Error ("Failed to remove {0}. Error - {1}" -f $path, $errorMsg)
                }
            }
        }
        
        # Remove desktop shortcuts for this user
        $shortcuts = Get-ChildItem -Path "$($profile.FullName)\Desktop" -Filter "*zluri*.lnk" -ErrorAction SilentlyContinue
        foreach ($shortcut in $shortcuts) {
            Write-Host "Removing shortcut for user $($profile.Name): $($shortcut.FullName)" -ForegroundColor Yellow
            try {
                Remove-Item -Path $shortcut.FullName -Force
                Write-Host "Successfully removed shortcut: $($shortcut.FullName)" -ForegroundColor Green
            } catch {
                $errorMsg = $_.Exception.Message
                Write-Error ("Failed to remove shortcut. Error - {0}" -f $errorMsg)
            }
        }
    }
} else {
    # Clean up only current user data
    $paths_to_check = @(
        "$env:LOCALAPPDATA\Programs\zluri",
        "$env:LOCALAPPDATA\zluri",
        "$env:APPDATA\zluri"
    )

    foreach ($path in $paths_to_check) {
        if (Test-Path $path) {
            Write-Host "Removing Zluri folder: $path" -ForegroundColor Yellow
            try {
                Remove-Item -Path $path -Recurse -Force
                Write-Host "Successfully removed $path" -ForegroundColor Green
            } catch {
                $errorMsg = $_.Exception.Message
                Write-Error ("Failed to remove {0}. Error - {1}" -f $path, $errorMsg)
            }
        }
    }
    
    # Delete desktop shortcuts for current user
    $shortcuts = Get-ChildItem -Path "$env:USERPROFILE\Desktop" -Filter "*zluri*.lnk" -ErrorAction SilentlyContinue
    foreach ($shortcut in $shortcuts) {
        Write-Host "Removing shortcut: $($shortcut.FullName)" -ForegroundColor Yellow
        try {
            Remove-Item -Path $shortcut.FullName -Force
            Write-Host "Successfully removed shortcut: $($shortcut.FullName)" -ForegroundColor Green
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Error ("Failed to remove shortcut. Error - {0}" -f $errorMsg)
        }
    }
}

Write-Host "Uninstallation process completed. All Zluri versions have been removed." -ForegroundColor Cyan