$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $ProjectRoot "collector\.env"
Write-Host "Netgear Discovery setup" -ForegroundColor Cyan
$Subnet = Read-Host "Management subnet [10.1.0.0/24]"
if ([string]::IsNullOrWhiteSpace($Subnet)) { $Subnet = "10.1.0.0/24" }
$SourceAddress = Read-Host "IP of the Windows adapter connected to the switch network (leave blank for automatic routing)"
$BindAddress = Read-Host "IP that clients use to reach this Windows computer [0.0.0.0 = all adapters]"
if ([string]::IsNullOrWhiteSpace($BindAddress)) { $BindAddress = "0.0.0.0" }
$Username = Read-Host "SNMPv3 username [dashboard]"
if ([string]::IsNullOrWhiteSpace($Username)) { $Username = "dashboard" }
$AuthSecure = Read-Host "SNMPv3 authentication key" -AsSecureString
$PrivSecure = Read-Host "SNMPv3 encryption key" -AsSecureString
$Auth = [System.Net.NetworkCredential]::new("", $AuthSecure).Password
$Priv = [System.Net.NetworkCredential]::new("", $PrivSecure).Password
if ($Auth.Length -lt 8 -or $Priv.Length -lt 8) { throw "Both SNMPv3 keys must be at least 8 characters." }
$Lines = @("SNMP_SUBNET=$Subnet","SNMP_SOURCE_ADDRESS=$SourceAddress","SNMP_USERNAME=$Username","SNMP_AUTH_PROTOCOL=sha512","SNMP_AUTH_KEY=$Auth","SNMP_PRIV_PROTOCOL=aes","SNMP_PRIV_KEY=$Priv","COLLECTOR_PORT=8787","SERVER_BIND_ADDRESS=$BindAddress","POLL_SECONDS=30")
[System.IO.File]::WriteAllLines($ConfigPath, $Lines)
Write-Host "Configuration saved locally. It is excluded from source control." -ForegroundColor Green
Write-Host "Run scripts\start-windows.ps1 to start the dashboard." -ForegroundColor Green
