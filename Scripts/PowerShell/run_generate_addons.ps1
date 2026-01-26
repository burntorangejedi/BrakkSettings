# Run generate_addons_md.py script with all required parameters

# Set the script directory and paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$PythonScriptDir = Join-Path -Path (Split-Path -Parent $ScriptDir) -ChildPath "python"
$PythonScript = Join-Path -Path $PythonScriptDir -ChildPath "generate_addons_md.py"
$ConfigFile = Join-Path -Path $PythonScriptDir -ChildPath "config.json"
$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Verify Python script exists
if (-not (Test-Path $PythonScript)) {
    Write-Error "Python script not found: $PythonScript"
    exit 1
}

# Verify config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Warning "Config file not found: $ConfigFile"
    Write-Host "Script will attempt to run without config file..."
}

# Run the Python script with config
Write-Host "Running generate_addons_md.py..." -ForegroundColor Cyan
Write-Host "Workspace Root: $WorkspaceRoot" -ForegroundColor Gray
Write-Host "Config File: $ConfigFile" -ForegroundColor Gray
Write-Host ""

# Execute with config file and copy AddOns.txt option
python $PythonScript `
    --workspace-root $WorkspaceRoot `
    --config $ConfigFile `
    --copy-addons-txt

# Check if the command succeeded
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nAddons.md generated successfully!" -ForegroundColor Green
} else {
    Write-Error "Failed to generate Addons.md (Exit code: $LASTEXITCODE)"
    exit $LASTEXITCODE
}
