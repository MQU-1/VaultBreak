# VaultBreak

A Network-Security attack & defense walkthrough, presented as a creative, interactive
HTML project.

A segmented enterprise network — built from scratch — is breached three different ways,
then hardened step by step until each attack fails. Every scenario runs on the same
topology: an edge router, a trunked core, two access switches, and three VLANs, kept off
VLAN 1 on purpose.

![tldr](https://img.shields.io/badge/linux-information%20security-blue)
![vlan](https://img.shields.io/badge/3%20VLANS-vlan10--dmz-%23D9A544)

## What's in the repo

| Path | What it is |
| --- | --- |
| `index.html` / `VaultBreak.html` | The interactive walkthrough — three case files with animated topology, before/after hardening mode, terminal simulations |
| `sim/` | Standalone browser-based labs you can actually run: ARP / DAI, Layer-2 (MAC flood + DHCP starvation), and Web exploitation (SQLi / XSS) |
| `Dockerfile` | Serves the whole site + labs from a lightweight `nginx` container |
| `docker-compose.yml` | One command to run the site **and** a real DVWA lab target for hands-on practice |
| `lab/compose/` | **Real machines** — Docker Compose lab: Kali attacker, DVWA, DHCP router, victim PC, segmented EXT/DMZ/INTERNAL/MGMT networks |
| `lab/gns3/` | **Real network** — GNS3 project + Cisco IOSv/IOSvL2 configs (R1/SW1/SW2/SW3) with DAI, DHCP snooping, port security |

## The three case files

1. **THE FLOOD** — Layer 2 chaos. MAC flood, VLAN hopping, DHCP starvation.
2. **THE GHOST IN THE WIRE** — ARP spoofing / man-in-the-middle, stopped by DAI.
3. **THE HIDDEN LEDGER** — SQL injection, XSS, hash cracking, and a file hidden inside a JPEG.

Each case has a *Before Hardening* and *After Hardening* mode so you can watch an attack
succeed, then watch the same attack get blocked by the exact security control that stops it.

## Quick start (no Docker)

Serve the folder with any static server:

```bash
# Python
python -m http.server 8000

# or npx
npx serve .
```

Open <http://localhost:8000> → pick a case file, or open the labs under `sim/`.

## Quick start (Docker)

Requires Docker with Compose v2.

```bash
docker compose up --build -d
```

| Service | Address | Purpose |
| --- | --- | --- |
| `vaultbreak-site` | <http://localhost:80> | Static site + all simulation labs |
| `vaultbreak-lab` | <http://localhost:8080> | DVWA — the vulnerable web target referenced in Case 03 |

Bring everything down with `docker compose down`.

> The lab runs **DVWA** (Damn Vulnerable Web Application). It is intentionally
> vulnerable — run it only in an isolated environment. Default login is `admin`
> / `password`.

## The lab simulations (`sim/`)

Each lab is a sandboxed, in-browser approximation of a case-file chapter. Nothing real is
attacked; packets, CAM tables, ARP caches and query plans are simulated in JavaScript so
you can flip the same hardening switches the walkthrough describes.

- `sim/arp-mitm.html` — forge ARP replies, build a man-in-the-middle, then enable **DAI**
  and watch the forged replies get dropped at the switch.
- `sim/layer2.html` — flood the CAM table and starve the DHCP pool, then turn on
  **Port Security** and **DHCP Snooping** to contain both.
- `sim/web-impl.html` — guess the SQLi payload, dump a user table, try an XSS payload in a
  guestbook, then flip on **parameterized queries** and **output encoding**.

## The real lab (`lab/`)

The sims are approximations — `lab/` is the **actually-run** version.

- **`lab/compose/`** — real machines in containers. `docker compose up --build -d`
  brings up a Kali attacker (arpspoof, macof, dhcpig, sqlmap, hashcat, stegseek…),
  the DVWA target, an edge "router" (dnsmasq DHCP pool + extended ACL) and an
  Employee-PC1, wired across EXT / VLAN10 DMZ / VLAN20 INTERNAL / VLAN99 MGMT.
- **`lab/gns3/`** — the same topology in GNS3 with Cisco IOSv / IOSvL2, so the
  switch-only defenses (Port Security, **DHCP Snooping**, **DAI**, BPDU Guard)
  can be run against real `macof` / `arpspoof` / `dhcpstarv` traffic.

Start with the **sims**, then move to the real machines. Full instructions:
`lab/README.md`.

## Project layout

```text
VaultBreak/
├─ index.html / VaultBreak.html   interactive case-file walkthrough
├─ sim/
│  ├─ index.html                  lab hub
│  ├─ arp-mitm.html               ARP spoofing + DAI lab
│  ├─ layer2.html                 MAC flood + DHCP starvation lab
│  └─ web-impl.html               SQLi / XSS web lab
├─ lab/
│  ├─ compose/                    real Docker lab (Kali, DVWA, r1, victim)
│  └─ gns3/                       real Cisco IOSv/IOSvL2 topology + configs
├─ Dockerfile                     nginx static server
├─ docker-compose.yml             site + DVWA lab
├─ LICENSE
└─ README.md
```

## Notes & ethics

This project is **educational**. All "attacks" run against simulated or intentionally
vulnerable sandbox targets. The whole point of the walkthrough is defense: every scenario
ends with the security control that stops the attack. Do not run any of this against
systems you don't own or don't have written permission to test.

## Credit

Built as a combined project for Linux, Information Security, and Network Security
coursework. Topology concepts: Cisco (IOSv / IOSvL2), GNS3; targets: DVWA; tools
referenced: Kali Linux, Wireshark, arpspoof, macof, yersinia, sqlmap, hashcat, stegseek.