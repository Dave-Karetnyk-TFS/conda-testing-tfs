<#
    .SYNOPSIS
    Build an env using conda-pack, install it, then test for the extended path format issue in
    the installed `conda-hook.ps1' script.
 
    .DESCRIPTION
    Build an env using conda-pack, install it, then test for the extended path format issue in
    the installed `conda-hook.ps1' script.
    * Should be run from a PowerShell session with Conda activated.
    * Conda-pack being used from the selected Conda env, e.g. conda_pack_060_1.
    * Conda being used from the base env, so whatever version is installed there.
    * Conda must be activated in the current PowerShell session before running this script.
 
    .PARAMETER packEnv
    The conda-pack environment to use. Must be one of: conda_pack_060_1, conda_pack_081_1,
    conda_pack_081a_1

    .INPUTS
    None. You cannot pipe objects to this script.
    .OUTPUTS
    None. Script does not generate any output.
    Calls 'Exit 0' if successful. Else Exit with non-zero value and message to terminal: check
    $LASTEXITCODE and $Error.

    .EXAMPLE
    .\Test-CondaPack.ps1 -packEnv conda_pack_081a_1
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("conda_pack_060_1", "conda_pack_081_1", "conda_pack_081a_1")]
    [string]$packEnv
)
$prefix = 'Set-PythonEnv:'

Write-Host "$prefix start script..."
Write-Host "$prefix using conda-pack environment: $packEnv"

Write-Host "$prefix PowerShell version information"
Write-Output $PSVersionTable
Write-Host # blank line
Write-Host "$prefix Conda base env"
conda list --name base
Write-Host # blank line


$packEnvConfig = "$PSScriptRoot\envs\$packEnv.yml"

$sourceEnv = 'example_env_3104_1'
$sourceEnvConfig = "$PSScriptRoot\envs\$sourceEnv.yml"

$targetEnvDir = "C:\Thermo_Scientific\Python\envs\example_env_3104_1_target"


# Check if env that will do the packing exists, if not, create it.
if (-not (conda env list | Select-String -Pattern $packEnv)) {
   Write-Host "$prefix creating conda env for packing: $packEnv"
    conda env create --name $packEnv --file $packEnvConfig
    if ($LASTEXITCODE -ne 0) {
        Write-Host -ForegroundColor Red "$prefix failed to create env for packing: $packEnv"
        Exit 1
    }
    else {
        Write-Host -ForegroundColor Green "$prefix env for packing created: $packEnv"
    }
}
else {
    Write-Host -ForegroundColor Green "$prefix env for packing already exists: $packEnv"
}
Write-Host # blank line

# Check if the source env exists, if not, create it.
if (-not (conda env list | Select-String -Pattern $sourceEnv)) {
    Write-Host "$prefix creating source conda env: $sourceEnv"
    conda env create --name $sourceEnv --file $sourceEnvConfig
    if ($LASTEXITCODE -ne 0) {
        Write-Host -ForegroundColor Red "$prefix failed to create source env: $sourceEnv"
        Exit 3
    }
    else {
        Write-Host -ForegroundColor Green "$prefix source env created: $sourceEnv"
    }
}
else {
    Write-Host -ForegroundColor Green "$prefix source env already exists: $sourceEnv"
}
Write-Host # blank line

# TODO??? Needed? Copied from the existing AutoStar production installer code.
# Or taken care of by newer conda version?
# Get prompt to display env name by setting "env_prompt" in env config (will create ".condarc"
# in the env directory)
Write-Host "$prefix activate source env and configure prompt to display env name"
conda activate $sourceEnv
conda config --env --set env_prompt '({name}) '
conda deactivate

# TODO??? Needed? Copied from the existing AutoStar production installer code.
# --exclude Scripts/activate.bat -> exclude the envs own activation script.
# Conda-pack adds its own activation script to the archive, which would result in two activate.bat
# scripts being present in the archive. This may cause issues when extracting, so exclude the env
# one. E.g. a warning message on stderr during zip packaging -> tripping up FDT tools on Jenkins.
conda activate $packEnv
conda-pack --name $sourceEnv --format zip --exclude Scripts/activate.bat
if ($LASTEXITCODE -ne 0) {
    Write-Host -ForegroundColor Red "$prefix failed to pack conda env: $sourceEnv"
    Exit 5
}
else {
    Write-Host -ForegroundColor Green "$prefix packed conda env: $sourceEnv"
}
conda deactivate

# Now create a new env using the zip archive.
$zipFile = "$PSScriptRoot\$sourceEnv.zip"
Write-Host "$prefix creating new conda env from packed zip archive: $zipFile"

# Unpack the zip archive to target location.

# Expand-Archive is very slow!
# Expand-Archive -Path $zipFile -DestinationPath $targetEnvDir -Force
# Use 7z.exe instead, which is much faster, e.g. install via Scoop.
Write-host "$prefix unpacking zip archive using to: $targetEnvDir"
7z.exe x "$zipFile" -o"$targetEnvDir" -aoa
if ($LASTEXITCODE -ne 0) {
    Write-Host -ForegroundColor Red "$prefix failed to unpack zip archive: $zipFile"
    Exit 7
}
else {
    Write-Host -ForegroundColor Green "$prefix unpacked zip archive: $zipFile"
}

Write-host "$prefix activate the new env & clean up the prefixes"
conda activate $targetEnvDir
conda-unpack
if ($LASTEXITCODE -ne 0) {
    Write-Host -ForegroundColor Red "$prefix failed to clean up prefixes for env: $targetEnvDir"
    conda deactivate
    Exit 11
}
else {
    Write-Host -ForegroundColor Green "$prefix cleaned up prefixes for env: $targetEnvDir"
}
conda deactivate


Write-Host "$prefix testing conda-hook.ps1 for extended path format issue..."
conda activate $sourceEnv
python ./check_env_files.py $targetEnvDir
if ($LASTEXITCODE -ne 0) { 
    conda deactivate
    Write-Host -ForegroundColor Red "$prefix ERROR: found extended path format issue/s"
    Exit 13
}
else {
    Write-Host -ForegroundColor Green "$prefix no extended path format issues found"
}
conda deactivate

Exit 0
