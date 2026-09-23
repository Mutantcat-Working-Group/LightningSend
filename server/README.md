# LightingSend Signaling Server

A signaling server for LightingSend. Using Rust and WebSockets.

## Docker

Build the image from the repository root:

```bash
docker build -f server/Dockerfile -t lightingsend-server .
```

Run the signaling server on port 3000:

```bash
docker run --rm -p 3000:3000 lightingsend-server
```

Release artifacts include per-architecture Linux binaries
(`LightingSend-Server-<version>-linux-*.tar.gz`) and saved Docker image
archives (`LightingSend-Server-<version>-docker-*.tar.gz`) for x86_64 and arm64.
