#!/bin/bash
# hashcat-run.sh — real MD5 cracking on the dumped user table (Case 03).
#
# Uses rockyou.txt when the wordlists package provides it, otherwise a small
# bundled sample wordlist. Just a few seconds for these five hashes.
#
# Modern hashcat (v4+) stores the potfile in ~/.local/share/hashcat by default,
# so we pin --potfile-path to a known location and read it back from there.
set -u

HASHES=/opt/vaultbreak/tools/samples/hashes.txt
DICT=/usr/share/wordlists/rockyou.txt
POT=/tmp/vaultbreak-hashes.pot

if [ ! -s "$DICT" ]; then
  DICT=/opt/vaultbreak/tools/samples/rockyou.sample.txt
  echo "[*] full rockyou not present - using bundled sample wordlist"
fi

# strip usernames -> bare hash list (skip the # comment header lines)
awk -F: '!/^#/ && NF>=2 {print $2}' "$HASHES" > /tmp/hashes-only.txt

echo "======================================================================"
echo "[*] cracking /tmp/hashes-only.txt (MD5, mode 0) against $DICT"
echo "======================================================================"
hashcat -m 0 -a 0 /tmp/hashes-only.txt "$DICT" \
  --potfile-path "$POT" --force --quiet 2>/dev/null

echo
echo "======================================================================"
echo "[*] recovered:"
echo "======================================================================"
for u in $(awk -F: '!/^#/ && NF>=2 {print $1}' "$HASHES"); do
  hash=$(awk -F: -v u="$u" '!/^#/ && $1==u {print $2}' "$HASHES")
  crack=$(grep "^$hash:" "$POT" 2>/dev/null | cut -d: -f2-)
  printf "  %-12s %s  ->  %s\n" "$u" "$hash" "${crack:-???}"
done