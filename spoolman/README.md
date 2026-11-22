# Spoolman

Filament spool manager for 3D printers. See the [Spoolman wiki](https://github.com/Donkie/Spoolman/wiki).

## Connecting a Printer

Klipper/Moonraker talks to the Spoolman API directly, not through the reverse proxy. Bind the port to the
host's LAN IP in `.env`:

```bash
SPOOLMAN_BIND=192.168.1.10   # LAN IP of the host
SPOOLMAN_PORT=7912
```

and point Moonraker at it (`moonraker.conf`):

```ini
[spoolman]
server: http://192.168.1.10:7912
```

Binding to a specific IP instead of `0.0.0.0` keeps the port off other interfaces (e.g. VPN or Docker
networks). With the default `127.0.0.1`, Spoolman is only reachable through the reverse proxy.

Spoolman then no longer listens on `127.0.0.1`: point the reverse proxy at the LAN IP as well
(`http://192.168.1.10:7912`), not at `localhost`.

## Reverse Proxy

Set `SPOOLMAN_CORS_ORIGIN` to the public URL of the web interface (e.g. `https://spoolman.example.com`).

## Data and Backups

The SQLite database lives in `data/`. Spoolman creates a backup every night at midnight in
`data/backups/` and keeps the last five.

The image contains no `wget` or `curl`, so the health check uses Python.
