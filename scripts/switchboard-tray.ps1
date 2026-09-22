$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$startupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'Netgear Discovery.lnk'
$launcherPath = Join-Path $projectRoot 'Netgear Discovery.vbs'
$createdNew = $false
$instanceMutex = [Threading.Mutex]::new($true, 'NetgearDiscoveryTray', [ref]$createdNew)
if (-not $createdNew) { exit 0 }

$collectorProcess = $null
$dashboardProcess = $null
$servicesDesired = $true
$context = [Windows.Forms.ApplicationContext]::new()
$notifyIcon = [Windows.Forms.NotifyIcon]::new()
$iconPath = Join-Path $projectRoot 'public\switchboard-icon.ico'
if (Test-Path -LiteralPath $iconPath) {
    $notifyIcon.Icon = [Drawing.Icon]::new($iconPath)
} else {
    $notifyIcon.Icon = [Drawing.SystemIcons]::Application
}
$notifyIcon.Text = 'Netgear Discovery'
$notifyIcon.Visible = $true

function Start-ManagedProcess {
    param([string]$Command, [string]$LogName)
    $logPath = Join-Path $projectRoot "logs\$LogName"
    $arguments = "/d /s /c `"npm.cmd $Command >> `"`"$logPath`"`" 2>&1`""
    $info = [Diagnostics.ProcessStartInfo]::new('cmd.exe', $arguments)
    $info.WorkingDirectory = $projectRoot
    $info.CreateNoWindow = $true
    $info.UseShellExecute = $false
    return [Diagnostics.Process]::Start($info)
}

function Start-Services {
    $script:servicesDesired = $true
    $script:collectorProcess = Start-ManagedProcess -Command 'run collector' -LogName 'collector.log'
    $script:dashboardProcess = Start-ManagedProcess -Command 'run start -- --port 3000' -LogName 'dashboard.log'
}

function Stop-ManagedProcess {
    param($Process)
    if ($null -ne $Process -and -not $Process.HasExited) {
        & taskkill.exe /PID $Process.Id /T /F 2>$null | Out-Null
    }
}

function Stop-Services {
    $script:servicesDesired = $false
    Stop-ManagedProcess $script:dashboardProcess
    Stop-ManagedProcess $script:collectorProcess
    $script:dashboardProcess = $null
    $script:collectorProcess = $null
}

function Open-Page {
    param([string]$Url)
    Start-Process $Url
}

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
$startupItem.CheckOnClick = $false
$startupItem.Checked = Test-Path -LiteralPath $startupShortcut
[void]$menu.Items.Add([Windows.Forms.ToolStripSeparator]::new())
$quitItem = $menu.Items.Add('Quit Netgear Discovery')

$dashboardItem.Add_Click({ Open-Page 'http://localhost:3000' })
$setupItem.Add_Click({ Open-Page 'http://localhost:8787/setup' })
$restartItem.Add_Click({
    $restartItem.Enabled = $false
    $notifyIcon.Text = 'Netgear Discovery - restarting'
    Stop-Services
    Start-Sleep -Milliseconds 700
    Start-Services
    $notifyIcon.Text = 'Netgear Discovery'
    $restartItem.Enabled = $true
    $notifyIcon.ShowBalloonTip(2500, 'Netgear Discovery', 'Dashboard and collector restarted.', [Windows.Forms.ToolTipIcon]::Info)
})
$startupItem.Add_Click({
    if (Test-Path -LiteralPath $startupShortcut) {
        Remove-Item -LiteralPath $startupShortcut -Force
    } else {
        Enable-Startup
    }
    $startupItem.Checked = Test-Path -LiteralPath $startupShortcut
})
$quitItem.Add_Click({
    Stop-Services
    $notifyIcon.Visible = $false
    $context.ExitThread()
})
$notifyIcon.Add_DoubleClick({ Open-Page 'http://localhost:3000' })
$notifyIcon.ContextMenuStrip = $menu
$watchdog = [Windows.Forms.Timer]::new()
$watchdog.Interval = 5000
$watchdog.Add_Tick({
    if (-not $script:servicesDesired) { return }
    if ($null -eq $script:collectorProcess -or $script:collectorProcess.HasExited) {
        $script:collectorProcess = Start-ManagedProcess -Command 'run collector' -LogName 'collector.log'
        $notifyIcon.ShowBalloonTip(1800, 'Netgear Discovery', 'Collector recovered after an unexpected stop.', [Windows.Forms.ToolTipIcon]::Warning)
    }
    if ($null -eq $script:dashboardProcess -or $script:dashboardProcess.HasExited) {
        $script:dashboardProcess = Start-ManagedProcess -Command 'run start -- --port 3000' -LogName 'dashboard.log'
    }
})

try {
    Start-Services
    $watchdog.Start()
    $notifyIcon.ShowBalloonTip(3000, 'Netgear Discovery', 'Netgear Discovery is running. Double-click this icon to open the dashboard.', [Windows.Forms.ToolTipIcon]::Info)
    [Windows.Forms.Application]::Run($context)
} finally {
    $watchdog.Stop()
    Stop-Services
    $notifyIcon.Dispose()
    $menu.Dispose()
    $context.Dispose()
    $watchdog.Dispose()
    if ($createdNew) { $instanceMutex.ReleaseMutex() }
    $instanceMutex.Dispose()
}
