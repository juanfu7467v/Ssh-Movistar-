FROM ghcr.io/erebe/wstunnel:latest AS wstunnel

FROM debian:bookworm-slim

# Instalar OpenSSH y dependencias necesarias
RUN apt-get update && apt-get install -y openssh-server && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# Copiar el binario de wstunnel
COPY --from=wstunnel /wstunnel /usr/local/bin/wstunnel

EXPOSE 8080

# Comando de inicio: crea el usuario dinámicamente usando las variables antes de encender el SSH
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
