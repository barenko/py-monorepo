# Define environment variable to prevent writing bytecode
$env:PYTHONDONTWRITEBYTECODE = "1"

# Get the project root directory using Git
$projectRoot = & git rev-parse --show-toplevel

if (-not $projectRoot) {
    Write-Host "This is not a git repository. Please run the script in a git repo."
    exit 1
}

# Function to delete .venv folders and poetry.lock files
function CleanUpProject {
    param (
        [string]$path
    )

    Write-Host "`n   CLEANING UP PROJECT`n"

    # Delete .venv folders
    Get-ChildItem -Path $path -Directory -Recurse -Filter ".venv" | ForEach-Object {
        Write-Host "   Removing .venv folder: $($_.FullName)"
        Remove-Item -Path $_.FullName -Recurse -Force
    }

    # Delete __pycache__ folders
    Get-ChildItem -Path $path -Directory -Recurse -Filter "__pycache__" | ForEach-Object {
        Write-Host "   Removing __pycache__ folder: $($_.FullName)"
        Remove-Item -Path $_.FullName -Recurse -Force
    }

    # Delete .ruff_cache folders
    Get-ChildItem -Path $path -Directory -Recurse -Filter ".ruff_cache" | ForEach-Object {
        Write-Host "   Removing .ruff_cache folder: $($_.FullName)"
        Remove-Item -Path $_.FullName -Recurse -Force
    }
    
    # Delete .pytest_cache folders
    Get-ChildItem -Path $path -Directory -Recurse -Filter ".pytest_cache" | ForEach-Object {
        Write-Host "   Removing .pytest_cache folder: $($_.FullName)"
        Remove-Item -Path $_.FullName -Recurse -Force
    }
    
    # Delete poetry.lock files
    Get-ChildItem -Path $path -File -Recurse -Filter "poetry.lock" | ForEach-Object {
        Write-Host "   Removing poetry.lock file: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force
    }

    Write-Host "`nAll projects have been cleared."
}

# Clean up .venv folders and poetry.lock files
CleanUpProject -path $projectRoot