<#
    .SYNOPSIS
    Remove all envs created by the Test-CondaPack.ps1 script, plus any zips of the target env.
 
    .DESCRIPTION
    Remove all envs created by the Test-CondaPack.ps1 script, plus any zips of the target env.
    * The list of envs is hardcoded in this script, see `$listOfEnvs` variable.
    * If the env does not exist, it will be skipped with an informational message to stdout.
 
    .INPUTS
    None. You cannot pipe objects to this script.
    .OUTPUTS
    None. Script does not generate any output.
    Calls 'Exit 0' if successful. Else Exit with non-zero value and message to terminal: check
    $LASTEXITCODE and $Error.
#>
$prefix = 'Remove-TestEnvs:'

Write-Host "$prefix start script..."

Write-Host "$prefix PowerShell version information"
Write-Output $PSVersionTable
Write-Host # blank line

$listOfEnvs = @(
    'conda_pack_060_1',
    'conda_pack_081_1',
    'conda_pack_081a_1',
    'example_env_3104_1',
    'example_env_3104_1_target'
)

foreach ($env in $listOfEnvs) {
    Write-Host # blank line
    Write-Host "$prefix removing conda env: $env"

    if (-not (conda info --envs | Select-String -Pattern "\b$env\b")) {
        Write-Host -ForegroundColor Yellow "$prefix no such env (nothing to do): $env"
        continue
    }

    conda env remove --name $env --yes
    if ($LASTEXITCODE -ne 0) {
        Write-Host -ForegroundColor Red "$prefix failed to remove env: $env"
        Exit 2
    }
    else {
        Write-Host -ForegroundColor Green "$prefix env removed: $env"
    }
}

# Remove the target env zip file if it exists
$targetEnvZip = "$PSScriptRoot\example_env_3104_1.zip"
if (Test-Path $targetEnvZip) {
    Remove-Item $targetEnvZip -Force
    Write-Host -ForegroundColor Green "$prefix removed target env zip file: $targetEnvZip"
}
else {
    Write-Host -ForegroundColor Yellow "$prefix no target env zip file to remove: $targetEnvZip"
}

Exit 0
