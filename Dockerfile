FROM debian:bookworm-slim

# Instalar dependencias esenciales de red y OpenSSH
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# Descargar la versión binaria estática correcta directamente sin scripts intermediarios
RUN curl -L -o /usr/bin/wstunnel https://github.com/erebe/wstunnel/releases/download/v9.7.2/wstunnel_9.7.2_linux_amd64 && \
    chmod +x /usr/bin/wstunnel

EXPOSE 8080

# Comando de inicio: 
# 1. Configura el puerto de SSH al 2222 para que no choque con Fly.io
# 2. Redirige el tráfico por defecto de wstunnel al 127.0.0.1:2222
CMD sh -c "\
    if [ -n \"\$SSH_USER\" ] && [ -n \"\$SSH_PASSWORD\" ]; then \
        useradd -m -s /bin/bash \$SSH_USER && \
        echo \"\$SSH_USER:\$SSH_PASSWORD\" | chpasswd && \
        echo 'Usuario configurado exitosamente desde Secrets.'; \
    else \
        echo 'ERROR: Las variables SSH_USER o SSH_PASSWORD no están definidas.' && exit 1; \
    fi && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config && \
    service ssh start && \
    /usr/bin/wstunnel server --listen 0.0.0.0:8080 --default-target 127.0.0.1:2222"
