FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    STEAMCMDDIR=/opt/steamcmd \
    EN_DIR=/home/steam/enshrouded \
    WINEPREFIX=/home/steam/.wine \
    WINEDEBUG=-all

# Install deps + Wine (Jammy supports i386 multiarch)
RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget unzip \
      tini gosu \
      xvfb \
      winbind \
      wine \
      wine32 \
      lib32gcc-s1 \
      lib32stdc++6 \
    ; \
    command -v wine; \
    wine --version; \
    rm -rf /var/lib/apt/lists/*

# Install SteamCMD
RUN mkdir -p ${STEAMCMDDIR} && \
    curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
      | tar -xz -C ${STEAMCMDDIR}

# Create unprivileged user
RUN useradd -m -u 10000 -s /bin/bash steam && \
    mkdir -p ${EN_DIR} && \
    chown -R steam:steam /home/steam ${STEAMCMDDIR}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 15637/udp 27015/udp

ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/entrypoint.sh"]
