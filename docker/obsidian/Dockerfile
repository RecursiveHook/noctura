FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99
ENV RESOLUTION=1920x1080

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    wget \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    supervisor \
    openbox \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG OBSIDIAN_VERSION=1.7.7

RUN wget -O /tmp/obsidian.deb "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/obsidian_${OBSIDIAN_VERSION}_amd64.deb" && \
    apt-get update && \
    apt-get install -y /tmp/obsidian.deb && \
    rm /tmp/obsidian.deb && \
    rm -rf /var/lib/apt/lists/*

ARG LIVESYNC_VERSION=0.25.20
RUN mkdir -p /tmp/livesync && \
    cd /tmp/livesync && \
    wget "https://github.com/vrtmrz/obsidian-livesync/releases/download/${LIVESYNC_VERSION}/main.js" && \
    wget "https://github.com/vrtmrz/obsidian-livesync/releases/download/${LIVESYNC_VERSION}/manifest.json" && \
    wget "https://github.com/vrtmrz/obsidian-livesync/releases/download/${LIVESYNC_VERSION}/styles.css"

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /vault

EXPOSE 8080 5900

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
