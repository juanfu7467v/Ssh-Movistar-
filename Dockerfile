FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV WSTUNNEL_VERSION=10.6.1
ENV SSH_PORT=2222
ENV WS_PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    curl \
    ca-certificates \
    tar \
    bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd

# Configurar sshd para NO usar el puerto 22
RUN sed -ri 's/^#?Port .*/Port 2222/' /etc/ssh/sshd_config && \
    sed -ri 's/^#?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -ri 's/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    grep -q '^UsePAM no' /etc/ssh/sshd_config || echo 'UsePAM no' >> /etc/ssh/sshd_config && \
    grep -q '^PubkeyAuthentication yes' /etc/ssh/sshd_config || echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

# Descargar e instalar wstunnel correctamente según arquitectura
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) asset="wstunnel_${WSTUNNEL_VERSION}_linux_amd64.tar.gz" ;; \
      arm64) asset="wstunnel_${WSTUNNEL_VERSION}_linux_arm64.tar.gz" ;; \
      *) echo "Arquitectura no soportada: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/wstunnel.tar.gz "https://github.com/erebe/wstunnel/releases/download/v${WSTUNNEL_VERSION}/${asset}"; \
    tar -xzf /tmp/wstunnel.tar.gz -C /tmp; \
    install -m 0755 /tmp/wstunnel /usr/local/bin/wstunnel; \
    rm -rf /tmp/wstunnel /tmp/wstunnel.tar.gz

EXPOSE 8080

CMD ["/bin/bash", "-lc", "\
set -euo pipefail; \
: \"${SSH_USER:?ERROR: falta SSH_USER}\"; \
: \"${SSH_PASSWORD:?ERROR: falta SSH_PASSWORD}\"; \
if ! id -u \"$SSH_USER\" >/dev/null 2>&1; then \
  useradd -m -s /bin/bash \"$SSH_USER\"; \
fi; \
echo \"$SSH_USER:$SSH_PASSWORD\" | chpasswd; \
mkdir -p /home/$SSH_USER/.ssh; \
chown -R $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh; \
chmod 700 /home/$SSH_USER/.ssh; \
ssh-keygen -A; \
/usr/sbin/sshd; \
echo 'SSH interno levantado en 127.0.0.1:2222'; \
echo 'wstunnel escuchando en 0.0.0.0:8080'; \
exec /usr/local/bin/wstunnel server --listen 0.0.0.0:${WS_PORT} --default-target 127.0.0.1:${SSH_PORT} \
"]
