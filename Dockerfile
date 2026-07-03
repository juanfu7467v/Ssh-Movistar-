FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias esenciales: OpenSSH, Dropbear, Python3 y dependencias de red
RUN apt-get update && apt-get install -y \
    openssh-server \
    dropbear \
    python3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configurar directorios para SSH
RUN mkdir /var/run/sshd

# Crear el usuario de laboratorio con la contraseña solicitada
RUN useradd -m -s /bin/bash JoseRivas && \
    echo 'JoseRivas:Jose7028392@' | chpasswd

# Permitir autenticación por contraseña en OpenSSH
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Copiar el script de inicio
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Exponer los puertos internos que se van a mapear
EXPOSE 22 90 80 443 8080

CMD ["/start.sh"]
