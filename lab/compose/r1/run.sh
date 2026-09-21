#!/bin/sh
# VaultBreak r1 bootstrap — wires up DHCP + routing + the extended ACL.
set -e

echo "[r1] interfaces:"
ip -o -4 addr show

# --- locate NICs by address ------------------------------------------------
iface_for() { # $1 = ip prefix
  ip -o -4 addr show | awk -v p="$1" '$4 ~ "^"p {print $2; exit}'
}

DHCPIF=$(iface_for "$INTERNAL_IP")
DMZIF=$(iface_for "$DMZ_IP")

if [ -z "$DHCPIF" ]; then
  echo "[r1] FATAL: no interface carrying $INTERNAL_IP (is compose wiring right?)" >&2
  exit 1
fi

# --- DNS/DHCP ----------------------------------------------------------------
sed "s/__DHCPIF__/$DHCPIF/" /etc/dnsmasq.conf.tpl > /tmp/dnsmasq.conf
dnsmasq --conf-file=/tmp/dnsmasq.conf --no-daemon > /var/log/dnsmasq.vb 2>&1 &
echo "[r1] dnsmasq up on $DHCPIF -> DHCP pool 192.168.20.$LEASE_LO-192.168.20.$LEASE_HI"
echo "[r1] leases: docker exec vb-r1 cat /var/lib/dnsmasq/dnsmasq.leases"

# --- routing -----------------------------------------------------------------
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true
iptables -P FORWARD ACCEPT

# --- extended ACL: DMZ may NOT initiate into INTERNAL -------------------------
# mirrors:  "Extended ACL — the DMZ cannot initiate traffic into the Internal VLAN"
# ESTABLISHED,RELATED still flows (replies to legit internal->dmz requests).
#
# This namespace is the *router-perspective* mirror (what R1 does on the GNS3
# half). Note that inside Docker, traffic between two compose bridges is
# forwarded by the HOST, so the rule that actually blocks the demo command
# lives in the `forwarding` helper (host FORWARD chain, same policy).
if [ -n "$DMZIF" ] && [ -n "$DHCPIF" ]; then
  iptables -A FORWARD -i "$DMZIF" -o "$DHCPIF" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A FORWARD -i "$DMZIF" -o "$DHCPIF" -j DROP
  echo "[r1] extended ACL in-namespace: NEW traffic $DMZIF -> $DHCPIF is rejected"
  echo "[r1]   (host-side twin in vb-forward enforces it for real in Docker)"
  echo "[r1]   try:  docker exec vb-dvwa curl -m 3 http://192.168.20.66:80/"
else
  echo "[r1] WARN: could not find DMZ/INTERNAL NICs, ACL skipped"
fi

echo "[r1] ready."
wait