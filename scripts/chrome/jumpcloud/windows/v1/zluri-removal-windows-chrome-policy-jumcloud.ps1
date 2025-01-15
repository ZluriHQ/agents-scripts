$registry_path_extension = "HKLM:\Software\Policies\Google\Chrome\3rdparty\extensions\cmobkdiplndgpjodaioofofmcikimbdb"

# Check if the registry path exists
if (Test-Path $registry_path_extension) {
    Write-Host "Registry path $registry_path_extension exists. Proceeding with removal."

    try {
        # Remove the entire registry key
        Remove-Item -Path $registry_path_extension -Recurse -Force
        Write-Host "Successfully removed the registry path: $registry_path_extension."
    } catch {
        Write-Warning "Failed to remove the registry path $registry_path_extension. Error: $_"
    }
} else {
    Write-Host "Registry path $registry_path_extension does not exist. No action needed."
}
