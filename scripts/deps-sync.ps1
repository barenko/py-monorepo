$env:PYTHONDONTWRITEBYTECODE = "1"

$projectRoot = git rev-parse --show-toplevel

if (-not $projectRoot) {
    Write-Host "This is not a git repository. Please run the script in a git repo."
    exit 1
}

# Path to the global requirements.txt within the git project root
$requirementsPath = Join-Path $projectRoot "pip-requirements.txt"
$requirementsDevPath = Join-Path $projectRoot "pip-dev-requirements.txt"

if (-not (Test-Path $requirementsPath)) {
    Write-Host "pip-requirements.txt not found in the project root: $projectRoot"
    exit 1
}

if (-not (Test-Path $requirementsDevPath)) {
    Write-Host "pip-dev-requirements.txt not found in the project root: $projectRoot"
    exit 1
}

# Root directories to scan for pyproject.toml
$rootDirs = @(
    (Join-Path $projectRoot "packages"),
    (Join-Path $projectRoot "services")
)

# Read the global requirements.txt file
$requirements = Get-Content $requirementsPath
$requirementsDev = Get-Content $requirementsDevPath

# Function to remove and reinstall dependencies for each project using Poetry
function EnforceDependenciesWithPoetry {
    param (
        [string]$projectPath
    )

    Write-Host "`n   DEPENDENCIES`n"

    # Change directory to the project
    Push-Location $projectPath

    # For each requirement, check installed version, and if needed, reinstall using Poetry
    foreach ($requirement in $requirements) {
        if ($requirement -match "(\S+)==(\S+)") {
            $packageName = $matches[1]
            $requiredVersion = $matches[2]

            # Check installed version of the package using Poetry
            
            $installedVersion = py -m poetry show $packageName | Select-String "version" | ForEach-Object {
                if ($_ -match "version\s*:\s*(\S+?)(?:\s|$)") {
                    $matches[1]
                }
            }

            $formattedPackageName = $packageName.PadRight(25)
            if ($installedVersion -ne $requiredVersion) {
                Write-Host "   [$formattedPackageName] version mismatch: Installed ($installedVersion), Required ($requiredVersion)`n"

                # Remove the package
                Write-Host "   [$formattedPackageName] Removing ..."
                py -m poetry remove $packageName

                # Reinstall the package with the correct version and cache off
                Write-Host "   [$formattedPackageName] Reinstalling $packageName==$requiredVersion ..."
                py -m poetry add "$packageName==$requiredVersion"
            }
            else {
                Write-Host "   [$formattedPackageName] is already at the required version ($requiredVersion)"
            }
        } 
    }

    # Return to the original directory
    Pop-Location
}

# Function to remove and reinstall dependencies for each project using Poetry
function EnforceDevDependenciesWithPoetry {
    param (
        [string]$projectPath
    )

    Write-Host "`n   DEV DEPENDENCIES`n"

    # Change directory to the project
    Push-Location $projectPath

    # For each requirement, check installed version, and if needed, reinstall using Poetry
    foreach ($requirement in $requirementsDev) {
        if ($requirement -match "(\S+)==(\S+)") {
            $packageName = $matches[1]
            $requiredVersion = $matches[2]

            # Check installed version of the package using Poetry
            $installedVersion = py -m poetry show $packageName | Select-String "version" | ForEach-Object {
                if ($_ -match "version\s*:\s*(\S+?)(?:\s|$)") {
                    $matches[1]
                }
            }

            $formattedPackageName = $packageName.PadRight(25)
            if ($installedVersion -ne $requiredVersion) {
                Write-Host "   [$formattedPackageName] version mismatch: Installed ($installedVersion), Required ($requiredVersion)"

                # Remove the package
                Write-Host "   [$formattedPackageName] Removing ..."
                py -m poetry remove $packageName

                # Reinstall the package with the correct version and cache off
                Write-Host "   [$formattedPackageName] Reinstalling $packageName==$requiredVersion ..."
                py -m poetry add "$packageName==$requiredVersion" --group dev
            }
            else {
                Write-Host "   [$formattedPackageName] is already at the required version ($requiredVersion)"
            }
        } 
    }

    # Return to the original directory
    Pop-Location
}


Write-Host "`n+-------------------------------------------------------------------+"
Write-Host "    Project: $projectRoot"
Write-Host "+-------------------------------------------------------------------+"
#EnforceDependenciesWithPoetry -projectPath $projectRoot
EnforceDevDependenciesWithPoetry -projectPath $projectRoot

# Loop through each root directory (packages and services)
foreach ($rootDir in $rootDirs) {
    if (Test-Path $rootDir) {
        # Find all pyproject.toml files
        $pyprojectFiles = Get-ChildItem -Path $rootDir -Recurse -Filter "pyproject.toml" -File | Where-Object { $_.DirectoryName -notmatch ".*/?.venv/?.*$" }

        foreach ($pyprojectFile in $pyprojectFiles) {
            # Get the directory of the pyproject.toml
            $projectDir = $pyprojectFile.Directory.FullName

            Write-Host "`n+-------------------------------------------------------------------+"
            Write-Host "    Project: $projectDir"
            Write-Host "+-------------------------------------------------------------------+"

            # Enforce dependencies for each found project using Poetry
            EnforceDependenciesWithPoetry -projectPath $projectDir
            EnforceDevDependenciesWithPoetry -projectPath $projectDir
        }
    }
}

Write-Host "`nAll projects have been processed."
