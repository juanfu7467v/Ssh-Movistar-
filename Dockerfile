FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    dropbear \
    python3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# CAMBIO AQUÍ: Forzar a OpenSSH interno a escuchar en el puerto 2222 en lugar del 22
RUN sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

RUN useradd -m -s /bin/bash JoseRivas && \
    echo 'JoseRivas:Jose7028392@' | chpasswd

RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

COPY start.sh /start.sh
RUN chmod +x /start.sh

# Exponer el nuevo puerto interno 2222
EXPOSE 2222 90 80 443 8080

CMD ["/start.sh"]
