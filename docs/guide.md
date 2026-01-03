# Guide — Enshrouded Dedicated Server (Docker)

This guide explains how to deploy the Enshrouded Dedicated Server using Docker with **runtime SteamCMD auto-updates**, **persistent storage**, and a **production-style workflow**.

## What This Project Guarantees

- ✅ **Always up-to-date** server on container start (SteamCMD `app_update 2278520 validate`)
- ✅ **Immutable container** pattern (image stays stable; game updates happen at runtime)
- ✅ **Persistent saves, logs, and config** via volume mounts
- ✅ Runs as a **non-root user**
- ✅ Works well for homelabs and “infra-as-a-product” style repositories

## Ports

Typical UDP ports:

- `15637/udp` — game port  
- `27015/udp` — query port (commonly used for server discovery)

Ensure these ports are allowed through your firewall and forwarded on your router if hosting publicly.

## Quick Start (Docker Compose)

Create a folder on your host and add this `docker-compose.yml`:

```yaml
services:
  enshrouded:
    image: ghcr.io/<your-username>/<repo>:latest
    restart: unless-stopped
    ports:
      - "15637:15637/udp"
      - "27015:27015/udp"
    environment:
      - UPDATE_ON_START=1
      - SERVER_NAME=My Enshrouded Server
      - SERVER_SLOTS=16
      # - SERVER_PASSWORD=ChangeMe
    volumes:
      - ./data:/home/steam/enshrouded
```

Start the server:

```bash
docker compose up -d
docker logs -f enshrouded
```

## Persistence Model (What Gets Saved)

All persistent data lives in the `./data` directory on your host:

```text
data/
 ├─ savegame/
 ├─ logs/
 ├─ enshrouded_server.json
```

You can rebuild images, switch tags, or move hosts without losing world data.

## Runtime Updates (How “Latest” Works)

On container start, the entrypoint runs SteamCMD to pull the latest Enshrouded dedicated server:

```text
+@sSteamCmdForcePlatformType windows
+app_update 2278520 validate
```

The Docker image itself remains unchanged, while the server binaries update automatically whenever Steam publishes a new build.

To temporarily disable updates:

```bash
UPDATE_ON_START=0
```

## Troubleshooting

### Server Not Visible In-Game

- Confirm UDP port forwarding is correct
- Check host firewall rules (allow UDP 15637 and 27015)
- Verify Docker is publishing UDP ports correctly (`docker ps`)

### Permission Issues in `./data`

Ensure the directory is writable by Docker. On Linux hosts:

```bash
sudo chown -R $USER:$USER ./data
```

### Container Starts but Server Doesn’t Launch

Check logs:

```bash
docker logs -f enshrouded
```

If you see Wine or X-related errors, ensure Xvfb is started by the entrypoint. If SteamCMD fails, it is often transient network or Steam-side—restart the container.

## Security Notes

- Runs as a **non-root user**
- Avoids privileged container mode
- Exposes only required UDP ports
- Stores state only in mounted volumes

This aligns with baseline container hardening practices and reduces host risk.

## Recommended Ops Practices

- Use `restart: unless-stopped`
- Back up the `./data` directory periodically
- Pin to a specific image tag if you want more control than `latest`
- Run behind a host firewall with explicit UDP rules

Treat this service like production infrastructure: automate it, back it up, and keep it observable.
