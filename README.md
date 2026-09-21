# VaultBreak

A Network-Security attack & defense walkthrough, presented as a creative, interactive
HTML project.

A segmented enterprise network — built from scratch — is breached three different ways,
then hardened step by step until each attack fails. Every scenario runs on the same
topology: an edge router, a trunked core, two access switches, and three VLANs, kept off
VLAN 1 on purpose.

![tldr](https://img.shields.io/badge/linux-information%20security-blue)
![vlan](https://img.shields.io/badge/3%20VLANS-vlan10--dmz-%23D9A544)

---

## Table of contents

- [What this is](#what-this-is)
- [What you need to run it](#what-you-need-to-run-it)
- [How to run it — choose a path](#how-to-run-it--choose-a-path)
  - [1. View it in your browser right now (no install)](#1-view-it-in-your-browser-right-now-no-install)
  - [2. Host it on GitHub Pages](#2-host-it-on-github-pages)
  - [3. Docker — the site + a real DVWA target](#3-docker--the-site--a-real-dvwa-target)
  - [4. The real lab — Kali attacker + DVWA + router + victim (Docker)](#4-the-real-lab--kali-attacker--dvwa--router--victim-docker)
  - [5. The real network — GNS3 + Cisco IOSv/IOSvL2 (advanced)](#5-the-real-network--gns3--cisco-iosviosvl2-advanced)
- [The three case files](#the-three-case-files)
- [The lab simulations (`sim/`)](#the-lab-simulations-sim)
- [The real lab (`lab/`)](#the-real-lab-lab)
- [Troubleshooting](#troubleshooting)
- [Notes & ethics](#notes--ethics)
- [Credit](#credit)

---

## What this is

| Piece | What you get |
| --- | --- |
| **Interactive walkthrough** | `index.html` — three case files with an animated topology, a before/after hardening toggle, and terminal simulations |
| **Browser sim labs** | `sim/` — three sandboxed labs that actually run in the browser (no install) |
| **Docker stack** | One command brings up the site **and** a real DVWA lab target |
| **Real Docker lab** | `lab/compose/` — real machines: Kali attacker, DVWA, a DHCP edge router, and a victim PC on segmented networks |
| **Real network** | `lab/gns3/` — the same topology in GNS3 with Cisco IOSv/IOSvL2 and switch-level defenses |

The three cases are described in detail in [The three case files](#the-three-case-files).

---

## What you need to run it

| Path you want | What you must have | Notes |
| --- | --- | --- |
| Static site (browser) | Any modern browser (Chrome/Firefox/Edge) | No install. Just open the file, or serve it with **Python 3** |
| GitHub Pages | A GitHub account + the repo pushed | Free, ~1 minute to enable |
| Docker stack (site + DVWA) | **Docker Desktop** (Windows/macOS) or Docker + Compose v2 (Linux) | Windows needs **WSL2** enabled |
| Real Docker lab (`lab/compose/`) | Same as above | The Kali image is ~a few GB; first `pull` takes a while |
| GNS3 + Cisco (`lab/gns3/`) | **GNS3** + your own **Cisco IOSv / IOSvL2 images** + Kali/DVWA VM images | You must supply the images yourself — see [section 5](#5-the-real-network--gns3--cisco-iosviosvl2-advanced) |
| Running the real attacks | None beyond Docker | Everything else (arpspoof, macof, dhcpig, sqlmap, hashcat, stegseek) is installed *inside* the attacker container for you |

> **Windows first-time Docker setup.** Docker Desktop on Windows needs the WSL2 backend.
> From an **elevated** PowerShell run once:
> ```powershell
> wsl --install
> ```
> then reboot, install [Docker Desktop](https://www.docker.com/products/docker-desktop/),
> start it, and confirm with `docker version`.

---

## How to run it — choose a path

### 1. View it in your browser right now (no install)

Open `index.html` directly by double-clicking it, **or** serve the folder (recommended —
the sim labs and relative links work better served):

```bash
# from the project folder:
python -m http.server 8000
# or: npx serve .
```

Then open <http://localhost:8000>.

### 2. Host it on GitHub Pages

1. Push the repo (already done: <https://github.com/MQU-1/VaultBreak>).
2. GitHub → repo → **Settings → Pages**.
3. **Source:** *Deploy from a branch* → branch `main`, folder `/(root)` → **Save**.
4. Wait ~1 minute, then open `https://<your-username>.github.io/VaultBreak/`.

### 3. Docker — the site + a real DVWA target

This is the "one command" experience from the walkthrough — it serves the whole site
**and** starts DVWA, the intentionally vulnerable web target from Case 03.

```bash
cd VaultBreak
docker compose up --build -d
```

| Service | Address | Purpose |
| --- | --- | --- |
| `vaultbreak-site` | <http://localhost> | The interactive site + all sim labs |
| `vaultbreak-lab` | <http://localhost:8080> | DVWA — the vulnerable web target |

**First-time DVWA setup (one manual step):** open <http://localhost:8080/setup.php>,
click **Create / Reset Database**, then log in at <http://localhost:8080/login.php>
with `admin` / `password`.

Stop everything with `docker compose down`.

### 4. The real lab — Kali attacker + DVWA + router + victim (Docker)

Real machines in containers, wired across EXT / VLAN10 DMZ / VLAN20 INTERNAL /
VLAN99 MGMT.

```bash
cd VaultBreak/lab/compose
docker compose up --build -d

docker exec -it vb-attacker bash     # attacker console (Kali, all tools installed)
docker exec -it vb-victim sh         # victim console (Employee-PC1)
```

Do the one-time DVWA setup as in [section 3](#3-docker--the-site--a-real-dvwa-target),
then run the real attacks from inside the attacker container:

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
sh /home/victim/scripts/renew.sh   # asks for a new DHCP lease (fails when pool is starved)
```

The attacker banner prints a full cheat sheet on login. Full instructions:
`lab/README.md`.

### 5. The real network — GNS3 + Cisco IOSv/IOSvL2 (advanced)

The same topology as real Cisco devices, so the **switch-only** defenses
(Port Security, DHCP snooping, DAI, BPDU Guard) can fight real traffic.
Set-up time ~30 minutes; you supply the images:

1. Download your own licensed/eval images:
   - `IOSv-15.6.qcow2` and `IOSvL2-15.2.qcow2` → Cisco (IOSv is available as eval on
     cisco.com).
   - `kali-linux-2026.qcow2` → kali.org.
   - `dvwa-ubuntu.qcow2` → any Ubuntu cloud image with DVWA installed
     (`lab/compose/dvwa/README.md` shows the container equivalent).
2. Put them in `~/.config/GNS3/images/QEMU/` (Linux) or
   `%USERPROFILE%\.config\GNS3\images\QEMU\` (Windows).
3. GNS3 → **File → New Project → Import** → `VaultBreak/lab/gns3/VaultBreak.gns3project`.
4. Pick the image for each node when prompted.
5. Wire it per `lab/gns3/README.md` if GNS3 asks — 9 links, takes 2 minutes.

Each device ships in its **hardened** form; the README explains how to strip the
defenses to replay each attack's "before" state. Attack commands for Kali are in
`lab/gns3/README.md`.

---

## The three case files

`index.html` (mirrored as `VaultBreak.html`) is the full interactive walkthrough —
an animated topology with the three case files below. Every case has a ***Before
Hardening*** and an ***After Hardening*** mode: the exact same attack either succeeds
or gets blocked by the security control designed to stop it.

1. **THE FLOOD** — Layer 2 chaos: MAC flooding, VLAN hopping, DHCP starvation.
   Stopped by **Port Security**, **DTP hardening**, and **DHCP Snooping**.
   → browser lab [sim/layer2.html](sim/layer2.html) · real lab `macof-flood.sh` / `dhcp-starv.sh`
2. **THE GHOST IN THE WIRE** — ARP spoofing / man-in-the-middle.
   Stopped by **DAI**.
   → browser lab [sim/arp-mitm.html](sim/arp-mitm.html) · real lab `arp-mitm.sh`
3. **THE HIDDEN LEDGER** — SQL injection, XSS, hash cracking, and a file hidden
   inside a JPEG. Stopped by **parameterized queries**, **output encoding**, and
   longer password hashes.
   → browser lab [sim/web-impl.html](sim/web-impl.html) · real lab `sqli.sh` + `hashcat-run.sh` + `stegseek-run.sh`

Each case maps to a chapter of the walkthrough's built-in terminal simulation and to
one of the standalone `sim/` labs below; the Docker and GNS3 sides replay the same
attacks against real machines.

---

## The lab simulations (`sim/`)

Each lab is a sandboxed, in-browser approximation of a case-file chapter. Nothing real is
attacked; packets, CAM tables, ARP caches and query plans are simulated in JavaScript so
you can flip the same hardening switches the walkthrough describes.

- `sim/layer2.html` — MAC flood + DHCP starvation, stopped by **Port Security** and **DHCP Snooping**.
- `sim/arp-mitm.html` — ARP spoofing MITM, stopped by **DAI**.
- `sim/web-impl.html` — SQLi / XSS, stopped by **parameterized queries** and **output encoding**.

Open them from the site's **Run the Labs** section, or go straight to `sim/index.html`.

## The real lab (`lab/`)

The sims are approximations — `lab/` is the **actually-run** version. Start with the
sims, then move here. Full instructions: `lab/README.md`.

- **`lab/compose/`** — real machines in containers (Kali, DVWA, edge router, victim PC).
- **`lab/gns3/`** — the same topology in GNS3 with Cisco IOSv / IOSvL2.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `docker: command not found` | Docker isn't installed / the daemon isn't running. See the Windows setup note above; open Docker Desktop and wait for it to say *Engine running*. |
| DVWA shows a DB connection error | The compose stack runs a MariaDB backend container alongside DVWA (`vaultbreak-db` / `dvwa-db`). It still needs one manual step: visit `/setup.php` → **Create / Reset Database** once. |
| `docker exec vb-attacker` not found | Run `docker compose ps` in `lab/compose/`. If missing, the stack didn't finish starting; re-run `docker compose up --build -d`. |
| The victim never gets a DHCP lease | The pool (192.168.20.100-200) was starved by a `dhcp-starv.sh` run — renew after the attack stops, or restart the stack. |
| Kali image download is slow | `kalilinux/kali-rolling` is large; this is normal on first run. |
| GitHub Pages shows a 404 | Pages can take up to a minute after enabling; also confirm the source is `main` / `(root)`. |

## Notes & ethics

This project is **educational**. All "attacks" run against simulated or intentionally
vulnerable sandbox targets. The whole point of the walkthrough is defense: every scenario
ends with the security control that stops the attack. Do not run any of this against
systems you don't own or don't have written permission to test.

## Credit

Built as a combined project for Linux, Information Security, and Network Security
coursework. Topology concepts: Cisco (IOSv / IOSvL2), GNS3; targets: DVWA; tools
referenced: Kali Linux, Wireshark, arpspoof, macof, yersinia, sqlmap, hashcat, stegseek.