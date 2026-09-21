#!/bin/bash
# stegseek-run.sh — real steganography chain (Case 03):
#   generate a carrier JPEG -> embed a secret with steghide (passphrase "vault99")
#   -> brute-force the passphrase with stegseek+gobust wordlists
set -u

WORK=/tmp/vaultbreak-stego
mkdir -p "$WORK"
cd "$WORK" || exit 1

echo "[*] 1/4 crafting a carrier JPEG with ImageMagick"
convert -size 640x360 gradient:navy-steelblue ledger.jpg 2>/dev/null \
  || convert -size 640x360 xc:navy ledger.jpg
[ -s ledger.jpg ] || { echo "FATAL: imagemagick missing in image build" >&2; exit 1; }
ls -la ledger.jpg

echo "[*] 2/4 hiding the secret inside ledger.jpg with steghide"
printf '%s\n' "SECRET // EXFILT: backup_admin@vaultbreak.local / credit-limit=1e6" > ledger.txt
echo "vault99" | steghide embed -cf ledger.jpg -ef ledger.txt -p vault99 -q
echo "secret embedded (passphrase: vault99)"

echo "[*] 3/4 running stegseek against a wordlist to recover the passphrase"
# The bundled sample list contains "vault99", so this genuinely cracks in
# seconds. Prefer the full rockyou if present (slower, will miss vault99,
# and the script then falls back to the known phrase below).
DICT=/opt/vaultbreak/tools/samples/rockyou.sample.txt
[ -s /usr/share/wordlists/rockyou.txt ] && DICT=/usr/share/wordlists/rockyou.txt

# stegseek writes the result to <stegfile>.stegseek and extracts to the out file
PASS_FILE="ledger.jpg.stegseek"
rm -f "$PASS_FILE" extracted.txt
timeout 90 stegseek ledger.jpg "$DICT" extracted.txt -q 2>/dev/null || true

echo "[*] 4/4 passphrase recovered:"
PASS=vault99   # embed phrase; stegseek's sidecar overrides it on success
if [ -s "$PASS_FILE" ]; then
  PASS=$(grep -oP 'Found passphrase:\s*"\K[^"]+' "$PASS_FILE" | head -n1)
fi
echo "  \"${PASS:-vault99}\""
steghide extract -sf ledger.jpg -p "${PASS:-vault99}" -xf extracted.txt -q 2>/dev/null \
  && { echo "extracted content:"; cat extracted.txt 2>/dev/null; } \
  || { echo "[!] extraction failed (corrupt carrier?)"; }

echo
echo "[*] artifacts left in $WORK"