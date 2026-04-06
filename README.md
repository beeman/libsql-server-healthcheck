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

## Local test

```bash
docker build -t libsql-server-healthcheck .
docker run --rm -p 8080:8080 libsql-server-healthcheck \
  sqld --http-listen-addr 0.0.0.0:8080 --db-path /var/lib/sqld
```

Then in another terminal:

```bash
docker inspect --format '{{json .State.Health}}' <container>
```

## Notes

- This is a downstream compatibility image, not a fork of libsql itself.
- If upstream adds a built-in healthcheck later, this repo can likely disappear.
