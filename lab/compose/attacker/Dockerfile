# VaultBreak attacker — Kali Linux with the exact toolset the case files reference:
#   arpspoof / macof (dsniff)   L2 attacks (Case 01/02)
#   dhcpig / yersinia           DHCP starvation (Case 01)
#   sqlmap, netcat, curl, nmap  web exploitation (Case 03)
#   hashcat, steghide, stegseek cracking + stego (Case 03)
#   tcpdump, iptables           sniffing + forwarding for the MITM
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      dsniff dhcpig yersinia sqlmap nmap \
      netcat-traditional curl wget \
      hashcat steghide stegseek \
      wordlists imagemagick \
      pocl-opencl-icd ocl-icd-libopencl1 \
      tcpdump iptables iproute2 procps \
      vim less tree python3 strace \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && gunzip -kf /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || true

COPY tools /opt/vaultbreak/tools
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/vaultbreak/tools/*.sh /entrypoint.sh

ENV PATH="$PATH:/opt/vaultbreak/tools"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]