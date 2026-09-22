param(
    [string]$NodeVersion = '24.20.0',
    [string]$InnoCompiler = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $PSScriptRoot 'build'
$appStage = Join-Path $buildRoot 'Netgear Discovery'
$downloadRoot = Join-Path $PSScriptRoot 'downloads'
$outputRoot = Join-Path $projectRoot 'installer-output'
if (-not (Test-Path -LiteralPath (Join-Path $appStage 'node_modules\next'))) { throw 'The production application has not been staged. Run build-installer.ps1 first.' }
New-Item -ItemType Directory -Path $downloadRoot,$outputRoot -Force | Out-Null

$nodeArchive = Join-Path $downloadRoot "node-v$NodeVersion-win-x64.zip"
if (-not (Test-Path -LiteralPath $nodeArchive)) {
    Write-Host "Downloading the bundled Node.js $NodeVersion runtime..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v$NodeVersion/node-v$NodeVersion-win-x64.zip" -OutFile $nodeArchive
}
$runtimeTemp = Join-Path $buildRoot 'node-runtime'
if (Test-Path -LiteralPath $runtimeTemp) { Remove-Item -LiteralPath $runtimeTemp -Recurse -Force }
Expand-Archive -LiteralPath $nodeArchive -DestinationPath $runtimeTemp -Force
$runtimeSource = Join-Path $runtimeTemp "node-v$NodeVersion-win-x64"
$runtimeStage = Join-Path $appStage 'runtime'
New-Item -ItemType Directory -Path $runtimeStage -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $runtimeSource 'node.exe') -Destination $runtimeStage -Force
Copy-Item -LiteralPath (Join-Path $runtimeSource 'LICENSE') -Destination $runtimeStage -Force

if ([string]::IsNullOrWhiteSpace($InnoCompiler)) {
    $candidates = @((Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),(Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'))
    $InnoCompiler = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
}
if (-not $InnoCompiler -or -not (Test-Path -LiteralPath $InnoCompiler)) { throw 'Inno Setup 6 is required.' }
Write-Host 'Compiling the Windows installer...' -ForegroundColor Cyan
& $InnoCompiler (Join-Path $PSScriptRoot 'Netgear Discovery.iss')
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }
$installer = Get-ChildItem -LiteralPath $outputRoot -Filter 'Netgear-Discovery-Setup-*.exe' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $installer) { throw 'Installer output was not created.' }
Write-Host "Installer ready: $($installer.FullName)" -ForegroundColor Green
