# Windows setup

1. Install the current Node.js LTS release on the Windows computer.
2. Copy this project folder to that computer and open PowerShell in it.
3. Run `npm install` once.
4. Run `powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1` and enter the SNMPv3 keys locally.
5. Run `powershell -ExecutionPolicy Bypass -File scripts\start-windows.ps1`.
6. Open the address shown in PowerShell. Other devices on the same network can use the Windows computer's IP with that port.

The collector begins with `10.1.0.0/24`, polls every 30 seconds, and exposes read-only data. On a multi-NIC computer, enter the IP of the adapter connected to the switch-management network as the SNMP source address. The dashboard/API can listen on a separate client-facing adapter or on `0.0.0.0` (all adapters). Run the setup script again whenever the subnet, adapter addresses, or credentials change. Allow Node.js on the appropriate private networks if Windows Firewall prompts.
