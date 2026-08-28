# Windows setup

1. Install the current Node.js LTS release on the Windows computer.
2. Copy this project folder to that computer.
3. Double-click `NETGEAR AV Switchboard.vbs`.
4. On first launch, the graphical setup page opens automatically. Enter the adapter, subnet, and SNMPv3 settings and select **Save settings & scan network**.
5. Allow Node.js on the appropriate private networks if Windows Firewall asks.
6. Other devices can open the Windows computer's client-facing IP on port `3000`.

No PowerShell commands are required. Use the dashboard's gear button on the Windows computer to change settings later. The collector begins with `10.1.0.0/24`, polls every 30 seconds, and exposes read-only data. On a multi-NIC computer, choose the adapter connected to the switch-management network as the SNMP source address. The dashboard can listen on a separate client-facing adapter or on `0.0.0.0` (all adapters).

The launcher prepares a production build, starts both services, and waits until they respond before opening the browser. If startup fails, plain-text diagnostic files are written to the `logs` folder.
