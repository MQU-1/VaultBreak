#!/bin/sh
# renew.sh — ask r1 for a new DHCP lease. When the pool is exhausted (Case 01
# attack is running) this times out, which is exactly the payoff.
set -e
echo "[victim] requesting a new lease from 192.168.20.1"
if udhcpc -i eth0 -t 4 -T 2 -q -R -p /tmp/udhcpc.pid > /tmp/udhcpc-renew.log 2>&1; then
  echo "[victim] lease renewed: $(ip -o -4 addr show dev eth0 | awk '{print $4}' | cut -d/ -f1)"
else
  echo "[victim] !! No DHCPOFFER — pool exhausted / snooping-rate-limited !!" >&2
  tail -n 5 /tmp/udhcpc-renew.log >&2 || true
fi