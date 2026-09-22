# Windows setup

1. Run the latest `Netgear-Discovery-Setup-X.Y.Z.exe` as an administrator. Node.js is bundled.
2. Keep **Start Netgear Discovery when I sign in** and private-network access selected unless the network requires something different.
3. On first launch, enter the switch adapter, management subnet, and SNMPv3 credentials in Server Settings.
5. Select **Save settings & scan**.
6. Other devices can open the displayed Windows server address on port `3000`.

Use a read-only SNMPv3 user. VLAN and AV profile assignment are intentionally read-only in this release.

Installing a newer version over an older Netgear Discovery installation performs an in-place upgrade. Saved settings and credentials in `%ProgramData%\Netgear Discovery` are retained.

On a multi-NIC computer, choose the adapter connected to the switch-management network as the SNMP source address. The dashboard can listen on a separate client-facing adapter or all adapters. Diagnostic files are stored in `%ProgramData%\Netgear Discovery\logs`.
