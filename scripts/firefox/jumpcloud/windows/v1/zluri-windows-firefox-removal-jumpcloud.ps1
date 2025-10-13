$removalSuccess = $true

$fireFoxPathJson = Get-Content -Raw "C:\Program Files\Mozilla Firefox\distribution\policies.json" | ConvertFrom-Json

if ($fireFoxPathJson.policies.ExtensionSettings.PSObject.Properties.Name -contains "zluribrowseragent@zluri.com") {
    Write-Output "Removing Zluri Firefox extension from policies.json"
    Remove-Item "C:\Program Files\Mozilla Firefox\distribution\policies.json" -Force -ErrorAction SilentlyContinue

    if (Test-Path "C:\Program Files\Mozilla Firefox\distribution\policies.json") {
        Write-Output "Failed to remove policies.json"
        $removalSuccess = $false
    }
} else {
    Write-Output "Zluri Firefox extension doesn't exist in policies.json"
}

$profilesPath = "C:\Users\TRACK\AppData\Roaming\Mozilla\Firefox\Profiles"

if (Test-Path $profilesPath) {
    $profiles = Get-ChildItem -Path $profilesPath -Directory

    foreach ($profile in $profiles) {
        $extensionsPath = Join-Path $profile.FullName "extensions"

        if (Test-Path $extensionsPath) {
            $extensionFiles = Get-ChildItem -Path $extensionsPath -File

            foreach ($file in $extensionFiles) {
                if ($file.Name -like "*zluribrowseragent@zluri.com.xpi*") {
                    Write-Output "Removing extension $($file.FullName) from profile $($profile.Name)"

                    try {
                        # Check if Firefox is running
                        $firefoxProcess = Get-Process -Name firefox -ErrorAction SilentlyContinue
                        if ($firefoxProcess) {
                            Write-Output "Firefox is currently running. Terminating Firefox processes..."
                            try {
                                # Stop all Firefox processes
                                Stop-Process -Name firefox -Force -ErrorAction Stop
                                Write-Output "Successfully terminated all Firefox processes."
                                Start-Sleep -Seconds 1
                            } catch {
                                Write-Output "Failed to terminate Firefox processes. Error: $($_.Exception.Message)"
                                $removalSuccess = $false
                                return 1
                            }
                        } else {
                            Write-Output "No active Firefox processes found."
                        }

                        # Attempt to remove the extension file
                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop

                        # Verify if the file still exists
                        if (Test-Path $file.FullName) {
                            Write-Output "Failed to remove extension $($file.FullName) - File still exists."
                            $removalSuccess = $false
                        } else {
                            Write-Output "Successfully removed extension $($file.FullName)"
                        }
                    } catch {
                        # Log the error details if removal fails
                        Write-Output "Failed to remove extension $($file.FullName). Error: $($_.Exception.Message)"
                        $removalSuccess = $false
                    }
                }
            }
        } else {
            Write-Output "No extensions folder found in profile $($profile.Name)"
        }
    }
} else {
    Write-Output "Firefox profiles directory not found at $profilesPath"
}

# Return based on success of removal
if ($removalSuccess) {
    return 0
} else {
    return 1
}
