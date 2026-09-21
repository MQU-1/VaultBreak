# VaultBreak — Real Lab (machines, not just simulations)

This folder is the **actually-run** part of the project. The `sim/` HTML labs
approximate the attacks; here the attacks really happen against real machines.

```
lab/
├─ compose/                  ← Docker Compose lab (real containers)
│  ├─ docker-compose.yml        EXT / VLAN10 DMZ / VLAN20 INTERNAL / VLAN99 MGMT
│  ├─ r1/                       edge router: dnsmasq DHCP pool + ip_forward + ACL
│  ├─ attacker/                 Kali Linux image + real tool scripts
│  ├─ victim-pc/                Employee-PC1 (DHCP client that gets MITM'd)
│  └─ dvwa/                     DVWA target setup
└─ gns3/                     ← GNS3 topology (real Cisco IOSv / IOSvL2 + Kali + DVWA)
   ├─ VaultBreak.gns3project    importable project
   └─ devices/{R1,SW1,SW2,SW3}.cfg
```

## Which half should I use?

| You want | Use |
| --- | --- |
| A lab that boots with one command, zero Cisco images | `compose/` |
| Real switching security (CAM flood, DAI, DHCP snooping, port security) | `gns3/` |
| Both worlds | run `compose/`, study the `gns3/` configs |

The Docker half cannot emulate switch features — there is no CAM table to
fill, so **Port Security / DAI / DHCP Snooping are taught in the GNS3 half**,
and the Docker half teaches the *attacker's* side (real tooling, real target).

## Docker lab quick start

```bash
cd lab/compose
docker compose up --build -d

docker exec -it vb-attacker bash      # attacker console — tool scripts are $PATH
docker exec -it vb-victim sh          # victim console (get its IP here)
```

One-time DVWA setup: open <http://localhost:8080/setup.php> → **Create /
Reset Database** → log in `admin`/`password`.

Then run the walks, e.g.:

```bash
# attacker container (replace VICTIM_IP with vb-victim's current lease; the
# pool hands out 192.168.20.100-200, so `docker exec vb-victim ip addr` it):
tools/arp-mitm.sh 192.168.20.150 192.168.20.1 20     # MITM + sniff (Case 02)
# ...meanwhile in victim container:
sh /home/victim/scripts/login.sh                     # gives the MITM credentials
```

> The extended ACL (Case 03: DMZ may not initiate into INTERNAL) is enforced at
> the host's FORWARD chain by the `forwarding` helper — in Docker, cross-bridge
> traffic never passes through r1's own namespace, so `r1`'s in-container rules
> are the router-perspective mirror. To watch the block land:
> `docker exec vb-dvwa curl -m 3 http://192.168.20.66:80/` (times out / reset).

See `compose/attacker/tools/` for `macof-flood.sh`, `dhcp-starv.sh`,
`sqli.sh`, `hashcat-run.sh`, `stegseek-run.sh`.

## Ethics

These are sandboxed targets (DVWA, your own bindings, your own GNS3 VMs).
Nothing here attacks anything you don't own. Don't run any of it elsewhere.