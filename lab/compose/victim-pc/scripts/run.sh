#!/bin/sh
# Employee-PC1 bootstrap — obtain a fresh DHCP lease from r1 (192.168.20.1),
# then re-pin the default route to r1 so the ARP MITM lab works.
set -e

R1=192.168.20.1

echo "[victim] Employee-PC1 booting..."
sleep 3   # let the bridges settle

# lease ourselves an address from r1's pool (192.168.20.100-200)
if udhcpc -i eth0 -t 6 -T 3 -q -R -p /tmp/udhcpc.pid > /tmp/udhcpc.log 2>&1; then
  IPv4=$(ip -o -4 addr show dev eth0 | awk '{print $4}' | cut -d/ -f1)
  echo "[victim] DHCP lease obtained: eth0 = $IPv4 (from $R1)"
else
  echo "[victim] !! NO DHCP LEASE — pool is exhausted or r1 is down !!" >&2
  echo "[victim]    (check: docker exec vb-r1 cat /var/lib/dnsmasq/dnsmasq.leases)" >&2
  ip -o -4 addr show dev eth0
fi

# re-pin default route through r1 so victim->dvwa traffic crosses the MITM hop
ip route delete default 2>/dev/null || true
if ip route add default via "$R1" 2>/dev/null; then
  echo "[victim] default route -> $R1"
else
  echo "[victim] (kept compose default gateway)"
fi

echo "[victim] ready.  common actions:"
echo "   renew lease : sh /home/victim/scripts/renew.sh"
echo "   log in      : sh /home/victim/scripts/login.sh"
echo "   victim IP   : $(ip -o -4 addr show dev eth0 | awk '{print $4}' | cut -d/ -f1)"

# stay alive so the attacker can target this container
tail -f /dev/null