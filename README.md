# libsql-server-healthcheck

Tiny wrapper image around `ghcr.io/tursodatabase/libsql-server` that adds the minimal tooling needed for a Docker healthcheck.

## Why this exists

The upstream `libsql-server` image currently does not publish a built-in Docker `HEALTHCHECK`, and it also does not include common probe tools like `wget` or `curl`.

If you want this upstream, please upvote the open libsql discussion here: https://github.com/tursodatabase/libsql/pull/1559

That makes `depends_on: condition: service_healthy` awkward in Docker Compose setups where other services should wait for libsql before starting.

This image keeps the upstream runtime and adds:

- `ca-certificates`
- `wget`
- a Docker `HEALTHCHECK` probing `http://127.0.0.1:8080`

The default healthcheck probes every 250ms during startup for 5 seconds, then every 5 seconds after startup.

## Image

```text
ghcr.io/beeman/libsql-server-healthcheck:latest
```

## Usage

```yaml
services:
  libsql:
    image: ghcr.io/beeman/libsql-server-healthcheck:latest
    command:
      [
        "sqld",
        "--http-listen-addr",
        "0.0.0.0:8080",
        "--db-path",
        "/var/lib/sqld",
      ]
    volumes:
      - libsql-data:/var/lib/sqld

  api:
    depends_on:
      libsql:
        condition: service_healthy
```

See [`compose.yml`](./compose.yml) for a runnable local example that builds this repo and delays `api` until `libsql` is healthy using the image defaults.

## Local test

```bash
docker build -t libsql-server-healthcheck .
docker run --rm -p 8080:8080 libsql-server-healthcheck \
  sqld --http-listen-addr 0.0.0.0:8080 --db-path /var/lib/sqld
```

For even more aggressive test-suite startup, override the healthcheck when you run the container:

```bash
docker run \
  --health-cmd="wget --server-response --spider http://127.0.0.1:8080 2>&1 | grep -qE 'HTTP/[0-9.]+ [1-5][0-9][0-9]' || exit 1" \
  --health-interval=1s \
  --health-retries=20 \
  --health-start-interval=100ms \
  --health-start-period=5s \
  --health-timeout=500ms \
  --rm \
  -p 8080:8080 \
  libsql-server-healthcheck \
  sqld --http-listen-addr 0.0.0.0:8080 --db-path /var/lib/sqld
```

Then in another terminal:

```bash
docker inspect --format '{{json .State.Health}}' <container>
```

## compose.yml

[`compose.yml`](./compose.yml) shows the default behavior:

- `libsql` is built from this repo, so it uses the `HEALTHCHECK` baked into the image.
- `api` depends on `libsql` with `condition: service_healthy`.
- When you start the stack, Compose waits for `libsql` to report `healthy` before it starts `api`.

To test the Compose flow end to end:

```bash
docker compose up --build
```

The `api` container should start only after `libsql` becomes healthy.

You can inspect the health status while it is running:

```bash
docker compose ps
docker inspect --format '{{json .State.Health}}' libsql-server-healthcheck-libsql-1
```

To clean up:

```bash
docker compose down -v
```

## Notes

- This is a downstream compatibility image, not a fork of libsql itself.
- If upstream adds a built-in healthcheck later, this repo can likely disappear.
