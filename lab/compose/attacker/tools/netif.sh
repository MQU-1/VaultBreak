#!/bin/bash
# netif.sh <subnet-prefix> — print the interface carrying an address.
#   netif.sh 192.168.20.   ->  eth2  (the VLAN20 NIC)
usage() { echo "usage: $0 <ip-prefix>   e.g. $0 192.168.20." >&2; exit 1; }
[ $# -eq 1 ] || usage
ip -o -4 addr show | awk -v p="$1" '$4 ~ "^"p {print $2; exit}'