FROM debian:bookworm-slim

# Instalar OpenSSH, curl para descargar el binario y ca-certificates para conexiones SSL seguras
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# Descargar la última versión estable de wstunnel (v9.7.2) directamente desde GitHub
# Se descarga la versión Linux AMD64 de forma estática
RUN curl -L -o /usr/local/bin/wstunnel https://github.com/erebe/wstunnel/releases/download/v9.7.2/wstunnel-linux-amd64 && \
    chmod +x /usr/local/bin/wstunnel

EXPOSE 8080

# Comando de inicio: crea el usuario dinámicamente usando tus Secrets de Fly.io
CMD sh -c "\
    if [ -n \"\$SSH_USER\" ] && [ -n \"\$SSH_PASSWORD\" ]; then \
        useradd -m -s /bin/bash \$SSH_USER && \
        echo \"\$SSH_USER:\$SSH_PASSWORD\" | chpasswd && \
        echo 'Usuario configurado exitosamente desde Secrets.'; \
    else \
        echo 'ERROR: Las variables SSH_USER o SSH_PASSWORD no están definidas.' && exit 1; \
    fi && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    service ssh start && \
    wstunnel server --listen 0.0.0.0:8080 --default-target 127.0.0.1:22"
