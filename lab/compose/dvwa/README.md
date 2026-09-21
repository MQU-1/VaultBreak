# DVWA (DockerizedDVWA) — setup notes for the Docker lab.

The `dvwa` service already pins the exact image referenced in the project's
original `docker-compose.yml`. First-time setup (needed before the sqli tool
works):

1. Open <http://localhost:8080/setup.php> in a browser.
2. Click **Create / Reset Database**.
3. Log in at the login page with `admin` / `password`.
4. From inside the attacker container, the target is `http://192.168.10.20`.

That is the only manual step. Everything else is scripted in
`lab/compose/attacker/tools/`.

Security note: DVWA is intentionally vulnerable. It is exposed on
`localhost:8080` for convenience only. Remove the `ports:` block from
`docker-compose.yml` if you want it reachable only from inside the lab
namespace.