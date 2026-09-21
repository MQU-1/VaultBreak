# Template rendered by run.sh, which substitutes __DHCPIF__ with the interface
# that owns the INTERNAL (VLAN 20) address. dnsmasq metrics below match the
# CSS "254 addresses" story in the walkthrough as closely as a /24 allows.

port=0
no-resolv
no-hosts

interface=__DHCPIF__
bind-interfaces
except-interface=lo

dhcp-range=set:internal,192.168.20.100,192.168.20.200,255.255.255.0,12h
dhcp-option=tag:internal,option:router,192.168.20.1
dhcp-option=tag:internal,option:dns-server,192.168.20.1

log-dhcp
log-queries=extra