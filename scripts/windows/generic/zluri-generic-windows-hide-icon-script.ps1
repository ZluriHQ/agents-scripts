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

# Get the executable path from the first entry
$ZluriEntry = $ZluriEntries[0]
$ZluriExe = $null

# Try to extract executable path from uninstall string or common locations
if ($ZluriEntry.UninstallString) {
    # Clean up the uninstall string and extract directory
    $uninstallString = $ZluriEntry.UninstallString -replace '"', ''
    # Remove any parameters after .exe
    if ($uninstallString -match '(.+\.exe)') {
        $uninstallExe = $matches[1]
        $installDir = Split-Path -Path $uninstallExe -Parent
        $ZluriExe = Join-Path -Path $installDir -ChildPath "zluri.exe"
        Write-Host "Trying path from uninstall string: $ZluriExe"
    }
}

# Fallback to common installation paths if not found
if (-not $ZluriExe -or -not (Test-Path $ZluriExe)) {
    Write-Host "Executable not found at registry path, trying common locations..."
    $commonPaths = @(
        "${env:ProgramFiles}\zluri\zluri.exe",
        "${env:ProgramFiles(x86)}\zluri\zluri.exe",
        "${env:LOCALAPPDATA}\Programs\zluri\zluri.exe",
        "${env:APPDATA}\zluri\zluri.exe"
    )
    foreach ($path in $commonPaths) {
        Write-Host "Checking: $path"
        if (Test-Path $path) {
            $ZluriExe = $path
            Write-Host "Found at: $path"
            break
        }
    }
}

if (-not $ZluriExe -or -not (Test-Path $ZluriExe)) {
    Write-Host "Error: Zluri executable not found"
    Write-Host "Registry uninstall string: $($ZluriEntry.UninstallString)"
    exit 1
}

Write-Host "Current user: $env:USERNAME"
Write-Host "Zluri found: $($ZluriEntries[0].DisplayName) - Version: $($ZluriEntries[0].Version)"
Write-Host "Zluri executable: $ZluriExe"
Write-Host "Local server: $LOCAL_SERVER"

# Creating config JSON
$ConfigJson = @{
    "org_token" = $ORG_TOKEN
    "interval" = $INTERVAL
    "screen_recording" = $SCREEN_RECORD
    "silent_auth" = "on"
    "local_server" = $LOCAL_SERVER
    "hide_zluri_tray_icon" = $HIDE_ZLURI_TRAY_ICON
} | ConvertTo-Json -Depth 10

# Creating temp directory if it doesn't exist
$TempDir = "C:\temp\zluritemp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Writing config file to temp directory
$ConfigJson | Out-File -FilePath "$TempDir\client-config.json" -Encoding UTF8 -NoNewline
Write-Host "Written config to temp directory"

# Creating ProgramData directory and write config
$ProgramDataDir = "C:\ProgramData\zluri"
if (-not (Test-Path $ProgramDataDir)) {
    New-Item -ItemType Directory -Path $ProgramDataDir -Force | Out-Null
}

$ConfigJson | Out-File -FilePath "$ProgramDataDir\client-config.json" -Encoding UTF8 -NoNewline
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
    if (-not $ZluriExe -or -not (Test-Path $ZluriExe)) {
        throw "Zluri executable not found at: $ZluriExe"
    }
    
    # Using cmd.exe with start command to fully detach the process
    $cmdArgs = "/c start `"`" `"$ZluriExe`""
    Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WindowStyle Hidden -ErrorAction Stop
    
    # Waiting for a moment to start
    Start-Sleep -Seconds 2
    
    # Verifing it started
    if (Get-Process -Name "zluri" -ErrorAction SilentlyContinue) {
        Write-Host "Zluri started successfully"
    } else {
        Write-Host "Zluri may not have started properly"
    }
} catch {
    Write-Host "Error starting zluri: $_"
    exit 1
}

Write-Host "Configuration completed"
exit 0