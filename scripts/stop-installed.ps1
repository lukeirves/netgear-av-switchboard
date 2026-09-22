$ErrorActionPreference = 'SilentlyContinue'
$projectRoot = Split-Path -Parent $PSScriptRoot
$nodePath = [IO.Path]::GetFullPath((Join-Path $projectRoot 'runtime\node.exe'))
Get-CimInstance Win32_Process |
    Where-Object { $_.ExecutablePath -and [IO.Path]::GetFullPath($_.ExecutablePath).Equals($nodePath,[StringComparison]::OrdinalIgnoreCase) } |
    ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName Terminate | Out-Null }
Get-CimInstance Win32_Process |
    Where-Object { $_.CommandLine -and $_.CommandLine.Contains((Join-Path $projectRoot 'scripts\installed-tray.ps1')) } |
    ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName Terminate | Out-Null }
