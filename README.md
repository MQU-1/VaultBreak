# VaultBreak

A Network-Security **attack & defense walkthrough** that also runs for real.

A segmented enterprise network — built from scratch — is breached three different ways,
then hardened step by step until each attack fails. Every scenario runs on the same
topology: an edge router, a trunked core, two access switches, and three VLANs, kept off
VLAN 1 on purpose.

![tldr](https://img.shields.io/badge/linux-information%20security-blue)
![vlan](https://img.shields.io/badge/3%20VLANS-vlan10--dmz-%23D9A544)
![docker](https://img.shields.io/badge/run-docker%20only-2496ED)
![pages](https://img.shields.io/badge/zero%20install-github%20pages-2EA44F)

> **Try it right now — no install.** The full walkthrough and all three attack labs run
> in your browser: **https://mqu-1.github.io/VaultBreak/**
>
> Want to repeat the same attacks against *real* machines? That needs **Docker only** —
> no GNS3, no OS installs, no Kali VM. Everything (Kali, router, victim, target) boots
> as containers.

---

## Table of contents

- [The short version](#the-short-version)
- [The three case files](#the-three-case-files)
- [The sim labs (`sim/`)](#the-sim-labs-sim)
- [The real lab (`lab/`)](#the-real-lab-lab)
  - [Docker compose — the only install you need](#docker-compose--the-only-install-you-need)
  - [GNS3 + Cisco (optional, advanced)](#gns3--cisco-optional-advanced)
- [What you need to install](#what-you-need-to-install)
- [How to run everything](#how-to-run-everything)
  - [1. Online — zero install (GitHub Pages)](#1-online--zero-install-github-pages)
  - [2. Docker — the real lab (recommended)](#2-docker--the-real-lab-recommended)
  - [3. Docker — just the site + DVWA target](#3-docker--just-the-site--dvwa-target)
  - [4. GNS3 + Cisco IOSv (optional)](#4-gns3--cisco-iosv-optional)
- [Troubleshooting](#troubleshooting)
- [Notes & ethics](#notes--ethics)
- [Credit](#credit)

---

## The short version

| You want to | Do this | You must install |
| --- | --- | --- |
| Watch / replay every attack in the browser | Open the GitHub Pages link in the header | **Nothing** |
| Run the same attacks against real machines | `docker compose up` in `lab/compose/` | **Docker only** |
| Learn how to build the topology | Walk the interactive case files | Bundled in the site |
| Replay it on real Cisco switches | Import the GNS3 project | Optional (see below) |

---

## The three case files

`index.html` (mirrored as `VaultBreak.html`) is the full interactive walkthrough — an
animated topology with the three case files below. Every case has a ***Before
Hardening*** and an ***After Hardening*** mode: the exact same attack either succeeds
or gets blocked by the security control designed to stop it.

1. **THE FLOOD** — Layer 2 chaos: MAC flooding, VLAN hopping, DHCP starvation.
   Stopped by **Port Security**, **DTP hardening**, and **DHCP Snooping**.
   → browser lab [sim/layer2.html](sim/layer2.html) · real lab `macof-flood.sh` / `dhcp-starv.sh`
2. **THE GHOST IN THE WIRE** — ARP spoofing / man-in-the-middle.
   Stopped by **DAI**.
   → browser lab [sim/arp-mitm.html](sim/arp-mitm.html) · real lab `arp-mitm.sh`
3. **THE HIDDEN LEDGER** — SQL injection, XSS, hash cracking, and a file hidden
   inside a JPEG. Stopped by **parameterized queries**, **output encoding**, and longer
   password hashes.
   → browser lab [sim/web-impl.html](sim/web-impl.html) · real lab `sqli.sh` + `hashcat-run.sh` + `stegseek-run.sh`

Each case maps to a chapter of the walkthrough's built-in terminal simulation, one of
the standalone `sim/` labs, and a matching command in the Docker lab — so you can watch
an attack in the browser, then run it for real with the same command.

---

## The sim labs (`sim/`)

Three sandboxed, **in-browser** labs that reproduce the attacks in JavaScript. Nothing
real is touched; CAM tables, ARP caches, DHCP pools and query plans are simulated so you
can flip the exact hardening switches the walkthrough describes:

- `sim/layer2.html` — MAC flood + DHCP starvation, stopped by **Port Security** and **DHCP Snooping**.
- `sim/arp-mitm.html` — ARP spoofing MITM, stopped by **DAI**.
- `sim/web-impl.html` — SQLi / XSS, stopped by **parameterized queries** and **output encoding**.

Open them from the site's **Run the Labs** section, or go straight to `sim/index.html`
(browser) with just the site URL.

---

## The real lab (`lab/`)

The sims are approximations — `lab/` runs the attacks against **real machines**.

### Docker compose — the only install you need

Real containers wired across EXT / VLAN10 DMZ / VLAN20 INTERNAL / VLAN99 MGMT:

| Container | What it is | Role in the attacks |
| --- | --- | --- |
| `vb-attacker` | Kali Linux attacker | Runs the real tooling: `arpspoof`, `macof`, `dhcpig`, `sqlmap`, `hashcat`, `stegseek` — all preinstalled |
| `vb-dvwa` | DVWA web target | The intentionally vulnerable web app from Case 03 |
| `vb-dvwa-db` | MariaDB backend | DVWA's database, DMZ-only |
| `vb-r1` | Edge router | DHCP pool + inter-VLAN routing + the extended ACL |
| `vb-victim` | Employee-PC1 | The DHCP client that gets MITM'd / starved |
| `vb-forward` | Host-networking helper | Flips `ip_forward` + enforces the Case-03 ACL |

### GNS3 + Cisco (optional, advanced)

The same topology as real Cisco IOSv / IOSvL2, so the **switch-only** defenses
(Port Security, DHCP snooping, DAI, BPDU Guard) fight real wire traffic. This is the
only part that pulls in machine images — see [section 4](#4-gns3--cisco-iosv-optional).

---

## What you need to install

| Path | You need | Notes |
| --- | --- | --- |
| Browser version (sims + case files) | A modern browser (Chrome / Firefox / Edge) | Nothing to install. The GitHub-hosted site is the fastest way in |
| Real Docker lab | **Docker** (Desktop on Win/macOS, Engine + Compose v2 on Linux) · [Git](https://git-scm.com/) | The Kali image is a few GB — the first `pull` takes a while |
| GNS3 half *(optional only)* | GNS3 + your own Cisco and Kali/DVWA images | You supply the `.qcow2` images — not required for anything else |

> **Windows first-time Docker setup.** Docker Desktop on Windows needs the WSL2 backend.
> From an **elevated** PowerShell, once:
> ```powershell
> wsl --install   # then reboot
> ```
> Install [Docker Desktop](https://www.docker.com/products/docker-desktop/), start it, and
> confirm with `docker version`.

---

## How to run everything

### 1. Online — zero install (GitHub Pages)

The site is deployed automatically by the bundled GitHub Actions workflow every time you
push to `main`. Just visit:

```
https://mqu-1.github.io/VaultBreak/
```

Walk the case files, then hit **Run the Labs → Simulation labs** to attack the simulated
network and watch the defenses block each attack — all in the browser, nothing installed.
This workflow keeps a mirror of `lab/gns3/README.md` and the compose docs as the
"run it for real" pointers.

Prefer a local copy? Just open `index.html` by double-clicking it, or serve the folder:

```bash
python -m http.server 8000    # from the project folder
# or: npx serve .
```

### 2. Docker — the real lab (recommended)

Everything runs as containers — the attacker is Kali *inside* Docker, so there is no OS
or VM to install:

```bash
git clone https://github.com/MQU-1/VaultBreak
cd VaultBreak/lab/compose
docker compose up --build -d

docker exec -it vb-attacker bash     # attacker console (all tools are in $PATH)
docker exec -it vb-victim sh         # victim console (Employee-PC1)
```

**One-time DVWA setup (a single manual step):** open
<http://localhost:8080/setup.php> → click **Create / Reset Database** → log in at
<http://localhost:8080/login.php> with `admin` / `password`.

Then run the real attacks from the attacker console (the banner prints this cheat sheet
on login):

```bash
netif.sh 192.168.20.              # which NIC is the INTERNAL (VLAN 20) leg
macof-flood.sh <nic>              # CAM-table flood            (Case 01)
dhcp-starv.sh <nic>               # drain the DHCP pool        (Case 01)
arp-mitm.sh <victim-ip> 192.168.20.1 20   # MITM + sniff login (Case 02)
sqli.sh                           # log in, then sqlmap dumps users via the SQLi module (Case 03)
hashcat-run.sh                    # crack the dumped MD5s      (Case 03)
stegseek-run.sh                   # hide + recover a file      (Case 03)
```

With the victim in another window:

```bash
sh /home/victim/scripts/login.sh   # "employee logs in" — the MITM steals this
sh /home/victim/scripts/renew.sh   # asks for a new DHCP lease (fails when the pool is starved)
```

Bring it all down with `docker compose down`. Full instructions: `lab/README.md`.

### 3. Docker — just the site + DVWA target

A lighter stack if you only want the website and a live DVWA to poke at:

```bash
cd VaultBreak
docker compose up --build -d
```

| Service | Address | Purpose |
| --- | --- | --- |
| `vaultbreak-site` | <http://localhost> | The interactive site + all sim labs |
| `vaultbreak-lab` | <http://localhost:8080> | DVWA — the vulnerable web target |

### 4. GNS3 + Cisco IOSv (optional)

This is the only path that needs images you supply yourself. It's **not** required for
anything above — the same defenses are demonstrated in the browser sims and the switch
configs are readable in `lab/gns3/devices/`.

1. Download `IOSv-15.6.qcow2`, `IOSvL2-15.2.qcow2` (Cisco), `kali-linux-2026.qcow2`
   (kali.org) and a DVWA Ubuntu image.
2. Put them in `~/.config/GNS3/images/QEMU/` (Linux) or
   `%USERPROFILE%\.config\GNS3\images\QEMU\` (Windows).
3. GNS3 → **File → New Project → Import** → `VaultBreak/lab/gns3/VaultBreak.gns3project`.
4. Pick the image for each node when prompted, wire the 9 links per `lab/gns3/README.md`.

Each device ships in its **hardened** form; the GNS3 README explains how to strip the
defenses to replay each attack's "before" state.

---

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `docker: command not found` | Docker isn't installed / the daemon isn't running. See the Windows setup note; open Docker Desktop and wait for *Engine running*. |
| DVWA shows a DB connection error | The compose stack runs a MariaDB backend (`vaultbreak-db` / `dvwa-db`). One manual step still needed: visit `/setup.php` → **Create / Reset Database** once. |
| `docker exec vb-attacker` not found | Run `docker compose ps` in `lab/compose/`. If missing, the stack didn't finish — re-run `docker compose up --build -d`. |
| The victim never gets a DHCP lease | The pool (192.168.20.100-200) was starved by a `dhcp-starv.sh` run — renew after the attack stops, or restart the stack. |
| Kali image download is slow | `kalilinux/kali-rolling` is large; this is normal on first run. |
| GitHub Pages shows a 404 | Pages takes up to a minute after a push; also confirm the Pages source is **GitHub Actions** so the workflow handles it. |

---

## Notes & ethics

This project is **educational**. All "attacks" run against simulated or intentionally
vulnerable sandbox targets. The whole point of the walkthrough is defense: every scenario
ends with the security control that stops the attack. Do not run any of this against
systems you don't own or don't have written permission to test.

## Credit

Built as a combined project for Linux, Information Security, and Network Security
coursework. Topology concepts: Cisco (IOSv / IOSvL2), GNS3; targets: DVWA; tools
referenced: Kali Linux, Wireshark, arpspoof, macof, yersinia, sqlmap, hashcat, stegseek.