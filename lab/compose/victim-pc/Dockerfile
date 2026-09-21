# VaultBreak victim — Employee-PC1 on VLAN 20.
#   busybox udhcpc  : real DHCP client, talks to r1's dnsmasq pool (Case 01)
#   curl/wget       : can log into DVWA so the MITM has something to steal (Case 02)
FROM alpine:3.20

RUN apk add --no-cache curl iproute2 busybox-extras

COPY scripts /home/victim/scripts
RUN chmod +x /home/victim/scripts/*.sh

# run.sh: wait for NIC, get a lease from r1 (.100-.200 pool),
# then point our default gateway at r1 (192.168.20.1) so ARP MITM has a target.
CMD ["/bin/sh", "/home/victim/scripts/run.sh"]