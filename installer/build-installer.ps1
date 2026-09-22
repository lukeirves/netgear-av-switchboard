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

$resolvedProject = [IO.Path]::GetFullPath($projectRoot)
$resolvedBuild = [IO.Path]::GetFullPath($buildRoot)
if (-not $resolvedBuild.StartsWith($resolvedProject, [StringComparison]::OrdinalIgnoreCase)) { throw 'Installer build directory escaped the project root.' }
if (Test-Path -LiteralPath $buildRoot) {
    for ($attempt=1; $attempt -le 8 -and (Test-Path -LiteralPath $buildRoot); $attempt++) {
        try { Remove-Item -LiteralPath $buildRoot -Recurse -Force -ErrorAction Stop }
        catch {
            try { [IO.Directory]::Delete('\\?\' + $resolvedBuild, $true) } catch {}
            if (Test-Path -LiteralPath $buildRoot) { Start-Sleep -Milliseconds 750 }
        }
    }
    if (Test-Path -LiteralPath $buildRoot) { throw 'Could not clear the installer staging folder because a file is still in use.' }
}
New-Item -ItemType Directory -Path $appStage,$downloadRoot,$outputRoot -Force | Out-Null

Write-Host 'Building Netgear Discovery...' -ForegroundColor Cyan
Push-Location $projectRoot
try { & npm.cmd run build; if ($LASTEXITCODE -ne 0) { throw 'Dashboard build failed.' } }
finally { Pop-Location }

Copy-Item -LiteralPath (Join-Path $projectRoot '.next') -Destination (Join-Path $appStage '.next') -Recurse
if (Test-Path -LiteralPath (Join-Path $appStage '.next\cache')) { Remove-Item -LiteralPath (Join-Path $appStage '.next\cache') -Recurse -Force }
Copy-Item -LiteralPath (Join-Path $projectRoot 'public') -Destination (Join-Path $appStage 'public') -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot 'package.json') -Destination $appStage
Copy-Item -LiteralPath (Join-Path $projectRoot 'package-lock.json') -Destination $appStage
Copy-Item -LiteralPath (Join-Path $projectRoot 'AGENTS.md') -Destination $appStage
Copy-Item -LiteralPath (Join-Path $projectRoot 'AI-HANDOFF.md') -Destination $appStage
Copy-Item -LiteralPath (Join-Path $projectRoot 'WINDOWS-SETUP.md') -Destination $appStage
New-Item -ItemType Directory -Path (Join-Path $appStage 'collector'),(Join-Path $appStage 'scripts') -Force | Out-Null
foreach ($name in @('server.mjs','setup.html','setup.css','setup.js','.env.example','discovery-cache.json.example')) {
    $source = Join-Path (Join-Path $projectRoot 'collector') $name
    if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination (Join-Path $appStage 'collector') }
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'scripts\installed-tray.ps1') -Destination (Join-Path $appStage 'scripts')
Copy-Item -LiteralPath (Join-Path $projectRoot 'scripts\stop-installed.ps1') -Destination (Join-Path $appStage 'scripts')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Netgear Discovery.vbs') -Destination $appStage

Write-Host 'Installing production-only application packages...' -ForegroundColor Cyan
$dependencyStep = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$(Join-Path $PSScriptRoot 'install-production.ps1')`"",'-AppStage',"`"$appStage`"") -NoNewWindow -Wait -PassThru
if ($dependencyStep.ExitCode -ne 0) { throw 'Production dependency installation failed.' }
Write-Host 'Production staging is ready.' -ForegroundColor Green
