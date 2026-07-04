FROM debian:bookworm-slim

# Instalar OpenSSH y dependencias requeridas
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    ca-certificates \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# Instalar wstunnel con el script oficial y asegurar su enlace en ambas rutas posibles
RUN curl -fSL https://raw.githubusercontent.com/erebe/wstunnel/main/install.sh | sh && \
    if [ -f /usr/bin/wstunnel ]; then ln -s /usr/bin/wstunnel /usr/local/bin/wstunnel; fi && \
    if [ -f /usr/local/bin/wstunnel ]; then ln -s /usr/local/bin/wstunnel /usr/bin/wstunnel; fi

EXPOSE 8080

# Comando de inicio seguro utilizando invocación directa del comando global
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
