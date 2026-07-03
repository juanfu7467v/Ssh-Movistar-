#!/bin/bash

# 1. Iniciar servicio OpenSSH estándar (Puerto 22)
/usr/sbin/sshd

# 2. Iniciar servicio Dropbear (Puerto 90)
/usr/sbin/dropbear -p 90 -E

# 3. Scripts mínimos en Python para simular los WebSockets (Escuchan en 80, 443, 8080 y envían al puerto 90)
python3 -c '
import socket, threading
def proxy(source, target_port):
    while True:
        client, addr = source.accept()
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.connect(("127.0.0.1", target_port))
        threading.Thread(target=lambda: [server.send(client.recv(4096)) or None for _ in iter(int, 1)]).start()
        threading.Thread(target=lambda: [client.send(server.recv(4096)) or None for _ in iter(int, 1)]).start()

for p in [80, 443, 8080]:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("0.0.0.0", p))
    s.listen(100)
    threading.Thread(target=proxy, args=(s, 90)).start()
' &

echo "Servidor de laboratorio SSH activo. Temporizador de 12 horas iniciado..."

# 4. Mecanismo de auto-vencimiento (12 horas = 43200 segundos)
(
    sleep 43200
    echo "Tiempo de laboratorio cumplido (12 horas). Deteniendo el servidor de forma segura..."
    kill -15 1
) &

# Mantener el contenedor vivo escuchando los logs de dropbear o ssh
tail -f /dev/null
