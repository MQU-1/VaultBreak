# DVWA (cytopia/dvwa) — setup notes for the Docker lab.

The `dvwa` service in `lab/compose/docker-compose.yml` runs `cytopia/dvwa`, the
modern, maintained build of the app referenced in Case 03. It needs a MySQL
backend, which the compose stack provides as a sibling `dvwa-db` (MariaDB)
container. First-time setup (needed before the sqli tool works):

1. Open <http://localhost:8080/setup.php> in a browser.
2. Click **Create / Reset Database**.
3. Log in at the login page with `admin` / `password`.
4. From inside the attacker container, the target is `http://192.168.10.20`.

That is the only manual step. Everything else is scripted in
`lab/compose/attacker/tools/`.

Notes:

- The database lives at `192.168.10.21` on the DMZ and is reachable only from
  inside the lab (it is **not** published to the host loopback).
- DVWA defaults to `SECURITY_LEVEL=low` here (the walkthrough's documented
  exploit level). Raise it to `impossible` in `docker-compose.yml` to watch the
  attacks fail.

Security note: DVWA is intentionally vulnerable. It is exposed on
`localhost:8080` for convenience only. Remove the `ports:` block from
`docker-compose.yml` if you want it reachable only from inside the lab
namespace.