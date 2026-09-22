$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$nodePath = Join-Path $projectRoot 'runtime\node.exe'
$dataRoot = Join-Path $env:ProgramData 'Netgear Discovery'
$logRoot = Join-Path $dataRoot 'logs'
$startupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'Netgear Discovery.lnk'
$launcherPath = Join-Path $projectRoot 'Netgear Discovery.vbs'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

$createdNew = $false
$instanceMutex = [Threading.Mutex]::new($true, 'NetgearDiscoveryTray', [ref]$createdNew)
if (-not $createdNew) { exit 0 }

$collectorProcess = $null
$dashboardProcess = $null
$servicesDesired = $true
$context = [Windows.Forms.ApplicationContext]::new()
$notifyIcon = [Windows.Forms.NotifyIcon]::new()
$iconPath = Join-Path $projectRoot 'public\switchboard-icon.ico'
$notifyIcon.Icon = if (Test-Path -LiteralPath $iconPath) { [Drawing.Icon]::new($iconPath) } else { [Drawing.SystemIcons]::Application }
$notifyIcon.Text = 'Netgear Discovery'
$notifyIcon.Visible = $true

function Start-NodeProcess {
    param([string]$Arguments, [string]$LogName)
    $outLog = Join-Path $logRoot $LogName
    $errorLog = Join-Path $logRoot ($LogName -replace '\.log$', '.error.log')
    $oldDataRoot = $env:NETGEAR_DISCOVERY_DATA_DIR
    $oldTelemetry = $env:NEXT_TELEMETRY_DISABLED
    try {
        $env:NETGEAR_DISCOVERY_DATA_DIR = $dataRoot
        $env:NEXT_TELEMETRY_DISABLED = '1'
        Start-Process -FilePath $nodePath -ArgumentList $Arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errorLog -PassThru
    } finally {
        $env:NETGEAR_DISCOVERY_DATA_DIR = $oldDataRoot
        $env:NEXT_TELEMETRY_DISABLED = $oldTelemetry
    }
}

function Start-Services {
    $script:servicesDesired = $true
    $envFile = Join-Path $dataRoot '.env'
    $collector = Join-Path $projectRoot 'collector\server.mjs'
    $next = Join-Path $projectRoot 'node_modules\next\dist\bin\next'
    $script:collectorProcess = Start-NodeProcess -Arguments "--env-file-if-exists=`"$envFile`" `"$collector`"" -LogName 'collector.log'
    $script:dashboardProcess = Start-NodeProcess -Arguments "`"$next`" start --port 3000 --hostname 0.0.0.0" -LogName 'dashboard.log'
}

function Stop-ManagedProcess {
    param($Process)
    if ($null -ne $Process -and -not $Process.HasExited) { & taskkill.exe /PID $Process.Id /T /F 2>$null | Out-Null }
}
function Stop-Services { $script:servicesDesired=$false; Stop-ManagedProcess $script:dashboardProcess; Stop-ManagedProcess $script:collectorProcess; $script:dashboardProcess=$null; $script:collectorProcess=$null }
function Open-Page { param([string]$Url) Start-Process $Url }
function Enable-Startup {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($startupShortcut)
    $shortcut.TargetPath = Join-Path $env:WINDIR 'System32\wscript.exe'
    $shortcut.Arguments = "`"$launcherPath`""
    $shortcut.WorkingDirectory = $projectRoot
    $shortcut.IconLocation = "$iconPath,0"
    $shortcut.Description = 'Start Netgear Discovery'
    $shortcut.Save()
}

$menu = [Windows.Forms.ContextMenuStrip]::new()
$dashboardItem = $menu.Items.Add('Open dashboard')
$setupItem = $menu.Items.Add('Open setup')
[void]$menu.Items.Add([Windows.Forms.ToolStripSeparator]::new())
$restartItem = $menu.Items.Add('Restart services')
$startupItem = $menu.Items.Add('Start with Windows')
$startupItem.Checked = Test-Path -LiteralPath $startupShortcut
$quitItem = $menu.Items.Add('Quit Netgear Discovery')
$dashboardItem.Add_Click({ Open-Page 'http://localhost:3000' })
$setupItem.Add_Click({ Open-Page 'http://localhost:8787/setup' })
$restartItem.Add_Click({ $restartItem.Enabled=$false; Stop-Services; Start-Sleep -Milliseconds 700; Start-Services; $restartItem.Enabled=$true; $notifyIcon.ShowBalloonTip(2200,'Netgear Discovery','Dashboard and collector restarted.',[Windows.Forms.ToolTipIcon]::Info) })
$startupItem.Add_Click({ if(Test-Path -LiteralPath $startupShortcut){Remove-Item -LiteralPath $startupShortcut -Force}else{Enable-Startup};$startupItem.Checked=Test-Path -LiteralPath $startupShortcut })
$quitItem.Add_Click({ Stop-Services; $notifyIcon.Visible=$false; $context.ExitThread() })
$notifyIcon.Add_DoubleClick({ Open-Page 'http://localhost:3000' })
$notifyIcon.ContextMenuStrip = $menu
$watchdog = [Windows.Forms.Timer]::new()
$watchdog.Interval = 5000
$watchdog.Add_Tick({
    if (-not $script:servicesDesired) { return }
    if ($null -eq $script:collectorProcess -or $script:collectorProcess.HasExited) {
        $envFile = Join-Path $dataRoot '.env'; $collector = Join-Path $projectRoot 'collector\server.mjs'
        $script:collectorProcess = Start-NodeProcess -Arguments "--env-file-if-exists=`"$envFile`" `"$collector`"" -LogName 'collector.log'
        $notifyIcon.ShowBalloonTip(1800,'Netgear Discovery','Collector recovered after an unexpected stop.',[Windows.Forms.ToolTipIcon]::Warning)
    }
    if ($null -eq $script:dashboardProcess -or $script:dashboardProcess.HasExited) {
        $next = Join-Path $projectRoot 'node_modules\next\dist\bin\next'
        $script:dashboardProcess = Start-NodeProcess -Arguments "`"$next`" start --port 3000 --hostname 0.0.0.0" -LogName 'dashboard.log'
    }
})

try { Start-Services; $watchdog.Start(); $notifyIcon.ShowBalloonTip(2500,'Netgear Discovery','Netgear Discovery is running.',[Windows.Forms.ToolTipIcon]::Info); [Windows.Forms.Application]::Run($context) }
finally { $watchdog.Stop(); Stop-Services; $notifyIcon.Dispose(); $menu.Dispose(); $context.Dispose(); $watchdog.Dispose(); if($createdNew){$instanceMutex.ReleaseMutex()}; $instanceMutex.Dispose() }
