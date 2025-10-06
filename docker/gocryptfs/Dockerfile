FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gocryptfs \
        fuse \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /encrypted /decrypted

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
