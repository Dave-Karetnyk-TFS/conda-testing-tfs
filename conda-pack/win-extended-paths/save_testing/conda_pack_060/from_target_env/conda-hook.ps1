$Env:CONDA_EXE = "//?/C:/Thermo_Scientific/Python/envs/example_env_3104_1_target\Scripts\conda.exe"
$Env:_CE_M = ""
$Env:_CE_CONDA = ""
$Env:_CONDA_ROOT = "//?/C:/Thermo_Scientific/Python/envs/example_env_3104_1_target"
$Env:_CONDA_EXE = "//?/C:/Thermo_Scientific/Python/envs/example_env_3104_1_target\Scripts\conda.exe"
$CondaModuleArgs = @{ChangePs1 = $True}
Import-Module "$Env:_CONDA_ROOT\shell\condabin\Conda.psm1" -ArgumentList $CondaModuleArgs

Remove-Variable CondaModuleArgs