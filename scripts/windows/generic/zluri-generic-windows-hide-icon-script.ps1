# Windows MDM Configuration Script

# Configuration variables
$ORG_TOKEN = "<orgToken>" # needs to be added by the customer
$INTERVAL = 600000  # check enrollment API in ms
$SCREEN_RECORD = "off"  # screen recording permission
$LOCAL_SERVER = "on"  # node auth server, cross auth of DA & BA, as per the customer pref
$HIDE_ZLURI_TRAY_ICON = $true  # Setting this flag will not show the zluri icon on the status bar

# Validate required inputs
if ($ORG_TOKEN -eq "<orgToken>" -or [string]::IsNullOrEmpty($ORG_TOKEN)) {
    Write-Host "Error: ORG_TOKEN must be set in the script"
    exit 1
}

# Function to find Zluri installation
function Find-ZluriEntries {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    $entries = @()
    foreach ($path in $uninstallPaths) {
        if (Test-Path $path) {
            Get-ChildItem $path | ForEach-Object {
                $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
                if ($props.DisplayName -match 'zluri') {
                    $entries += [PSCustomObject]@{
                        DisplayName     = $props.DisplayName
                        Version         = $props.DisplayVersion
                        UninstallString = $props.UninstallString
                        KeyPath         = $_.PSPath
                    }
                }
            }
        }
    }
    return $entries
}

# Check if Zluri is installed
$ZluriEntries = Find-ZluriEntries
if ($ZluriEntries.Count -eq 0) {
    Write-Host "Error: Zluri is not installed"
    exit 1
}

Write-Host "Current user: $env:USERNAME"
Write-Host "Zluri found: $($ZluriEntries[0].DisplayName) - Version: $($ZluriEntries[0].Version)"
Write-Host "Local server: $LOCAL_SERVER"

# Create config JSON
$ConfigJson = @{
    "org_token" = $ORG_TOKEN
    "interval" = $INTERVAL
    "screen_recording" = $SCREEN_RECORD
    "silent_auth" = "on"
    "local_server" = $LOCAL_SERVER
    "hide_zluri_tray_icon" = $HIDE_ZLURI_TRAY_ICON
} | ConvertTo-Json -Depth 10

# Create temp directory if it doesn't exist
$TempDir = "C:\temp\zluritemp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Write config file to temp directory
$ConfigJson | Out-File -FilePath "$TempDir\client-config.json" -Encoding UTF8
Write-Host "Written config to temp directory"

# Create ProgramData directory and write config
$ProgramDataDir = "C:\ProgramData\zluri"
if (-not (Test-Path $ProgramDataDir)) {
    New-Item -ItemType Directory -Path $ProgramDataDir -Force | Out-Null
}

$ConfigJson | Out-File -FilePath "$ProgramDataDir\client-config.json" -Encoding UTF8
Write-Host "Written config to ProgramData directory"

# Kill existing zluri process
$ZluriProcess = Get-Process -Name "zluri" -ErrorAction SilentlyContinue
if ($ZluriProcess) {
    Write-Host "Stopping zluri process"
    Stop-Process -Name "zluri" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

# Start zluri application
Write-Host "Starting zluri application"
try {
    Start-Process -FilePath "zluri" -ErrorAction Stop
    Write-Host "Zluri started successfully"
} catch {
    Write-Host "Error starting zluri: $_"
    exit 1
}

Write-Host "Configuration completed"
exit 0