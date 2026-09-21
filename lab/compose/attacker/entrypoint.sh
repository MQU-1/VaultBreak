#!/bin/bash
# Print the lab cheat sheet, then hand over to an interactive shell.
cat <<'SHEET'
======================================================================
 VaultBreak ATTACKER — Kali inside the Docker lab
======================================================================
 Interfaces:
   eth? (EXT)      192.168.250.66   "outside the edge"
   eth? (DMZ)      192.168.10.66    "VLAN 10"
   eth? (INTERNAL) 192.168.20.66    "VLAN 20"  <- L2 attacks live here
 (run `ip addr` to see the exact names)

 Targets:
   r1 DHCP/gateway  192.168.20.1    (pool 192.168.20.100-200)
   Employee-PC1     `docker exec vb-victim ip -4 addr show eth0`
   DVWA             http://192.168.10.20  (cytopia/dvwa)
   DVWA (host)      http://localhost:8080 (only out of the VM)

 One-command tools (all in $PATH, all real):
   netif.sh 192.168.20.             -> print NIC on that subnet
   arp-mitm.sh <victim> <gateway>   -> MITM + tcpdump creds (Case 02)
   macof-flood.sh <nic> [n]         -> CAM flood (Case 01)
   dhcp-starv.sh <nic>             -> drain the pool (Case 01)
   sqli.sh                         -> log in, sqlmap-dump users via the SQLi module (Case 03)
   hashcat-run.sh                  -> crack the dumped MD5s (Case 03)
   stegseek-run.sh                 -> embed + crack ledger.jpg (Case 03)

 First-run DVWA note: visit http://localhost:8080 once, run the
 "Create / Reset Database" button at /setup.php, then log in admin/password.
======================================================================
SHEET
exec "$@"