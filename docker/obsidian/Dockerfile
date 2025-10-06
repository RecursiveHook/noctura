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
    fuse \
    libfuse2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG OBSIDIAN_VERSION=1.7.7
ARG TARGETARCH

RUN if [ "$TARGETARCH" = "amd64" ]; then \
      OBSIDIAN_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}.AppImage"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      OBSIDIAN_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}-arm64.AppImage"; \
    else \
      echo "Unsupported architecture: $TARGETARCH"; exit 1; \
    fi && \
    wget -O /opt/Obsidian.AppImage "$OBSIDIAN_URL" && \
    chmod +x /opt/Obsidian.AppImage

RUN cd /opt && \
    /opt/Obsidian.AppImage --appimage-extract && \
    mv squashfs-root obsidian && \
    rm /opt/Obsidian.AppImage && \
    ln -s /opt/obsidian/obsidian /usr/local/bin/obsidian

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
