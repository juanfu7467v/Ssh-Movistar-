FROM debian:bookworm-slim

# Instalar OpenSSH y dependencias requeridas
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    ca-certificates \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# Descargar e instalar wstunnel usando su script oficial
RUN curl -fSL https://raw.githubusercontent.com/erebe/wstunnel/main/install.sh | sh

EXPOSE 8080

# Comando de inicio: se cambió "wstunnel" por su ruta absoluta "/usr/local/bin/wstunnel"
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
    /usr/local/bin/wstunnel server --listen 0.0.0.0:8080 --default-target 127.0.0.1:22"
