#!/bin/sh
# login.sh — the "victim logs in" action used by the Case 02 MITM.
# Post the DVWA login form so the attacker's tcpdump captures the credentials.
set -e
DVWA=http://192.168.10.20

echo "[victim] opening http://${DVWA#http://}/login.php (admin/password) ..."
curl -s -o /tmp/login-response.txt \
  -d "username=admin&password=password&Login=Login" \
  "$DVWA/login.php" || echo "[victim] DVWA unreachable (is it set up?)"
echo "[victim] request sent"
grep -o "Location: .*" /tmp/login-response.txt | head -n1 || true