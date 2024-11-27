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
                if ($file.Name -like "*zluribrowseragent@zluri.com*") {
                    Write-Output "Removing extension $($file.FullName) from profile $($profile.Name)"
                    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                    if (Test-Path $file.FullName) {
                        Write-Output "Failed to remove extension $($file.FullName)"
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
