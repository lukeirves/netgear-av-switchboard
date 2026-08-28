$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot
if (-not (Test-Path "collector\.env")) { & "$PSScriptRoot\setup-windows.ps1" }
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$ProjectRoot'; npm run collector"
Write-Host "Starting dashboard..." -ForegroundColor Cyan
npm run dev -- --host 0.0.0.0
