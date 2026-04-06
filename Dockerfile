FROM ghcr.io/tursodatabase/libsql-server:latest

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates wget \
  && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=20 \
  CMD wget --server-response --spider http://127.0.0.1:8080 2>&1 | grep -qE 'HTTP/[0-9.]+ [1-5][0-9][0-9]' || exit 1
