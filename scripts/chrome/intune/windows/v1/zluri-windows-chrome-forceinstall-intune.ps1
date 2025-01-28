$extensionID = 'cmobkdiplndgpjodaioofofmcikimbdb;https://clients2.google.com/service/update2/crx'
$path = 'HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist'

# Ensure the registry key exists
if (!(Test-Path $path)) {
    New-Item -Path $path -Force
}

# Function to add extensions incrementally
function Add-Extension {
    param (
        [string]$extensionId,
        [string]$path
    )

    # Check if the extension ID already exists in the registry
    $existingKeys = Get-ItemProperty -Path $path
    $existingExtension = $existingKeys.PSObject.Properties | Where-Object { $_.Value -eq $extensionId }

    # If the extension already exists, skip adding it
    if ($existingExtension) {
        Write-Host "Extension with ID $extensionId already exists. Skipping addition."
        return
    }
    
    # Find the highest current index in the registry
    $maxIndex = 0
    $existingKeys = Get-ItemProperty -Path $path
    foreach ($key in $existingKeys.PSObject.Properties) {
        if ($key.Name -match '^\d+$' -and [int]$key.Name -gt $maxIndex) {
            $maxIndex = [int]$key.Name
        }
    }

    # Increment index for the new extension
    $newIndex = $maxIndex + 1
    Set-ItemProperty -Path $path -Name $newIndex -Value $extensionId -Type String -Force
    Write-Host "Added extension at index $newIndex"
}

# Add the first extension
Add-Extension -extensionId $extensionID -path $path