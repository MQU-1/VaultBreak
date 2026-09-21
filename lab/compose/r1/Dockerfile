# VaultBreak r1 — edge router for the Docker lab
#   dnsmasq  = R1's DHCP server (pool on VLAN 20, the target of Case 01 starvation)
#   iptables = extended ACL mirror (DMZ may not initiate into INTERNAL, Case 03 defense)
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      dnsmasq iptables iproute2 iputils-ping curl \
 && rm -rf /var/lib/apt/lists/*

COPY dnsmasq.conf.tpl /etc/dnsmasq.conf.tpl
COPY run.sh /run.sh

ENV INTERNAL_NET=192.168.20.0/24 \
    INTERNAL_IP=192.168.20.1 \
    DMZ_IP=192.168.10.1 \
    LEASE_LO=100 \
    LEASE_HI=200

EXPOSE 53/udp 67/udp

ENTRYPOINT ["/bin/sh", "/run.sh"]