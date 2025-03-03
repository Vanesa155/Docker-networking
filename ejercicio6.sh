#!/bin/bash

# 🎨 Colores para mensajes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# 📦 Variables de configuración
VOLUME_NAME="mysql_data"
CONTAINER_NAME="mysql_server"
PASSWORD="rootpass"
BACKUP_PATH="/tmp/mysql_backup.tar.gz"

# 🔧 Configuración del servidor remoto
REMOTE_SERVER="192.168.18.79"  # Cambia esto por la IP real del servidor
REMOTE_USER="gloria"
REMOTE_DEST="/home/gloria/Escritorio"  # Cambia esto a la ruta donde guardar el backup

echo -e "🔎 ${YELLOW}[INFO] Iniciando diagnóstico de MySQL...${NC}"

# 1️⃣ Revisar si el contenedor ya existe
EXISTING_CONTAINER=$(docker ps -a --filter "name=$CONTAINER_NAME" --format '{{.Names}}')

if [ "$EXISTING_CONTAINER" == "$CONTAINER_NAME" ]; then
    echo -e "⚠️ ${YELLOW}[INFO] Se encontró un contenedor previo. Eliminándolo...${NC}"
    docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME
    echo -e "✅ ${GREEN}[SUCCESS] Contenedor eliminado.${NC}"
fi

# 2️⃣ Verificar si el volumen ya existe
EXISTING_VOLUME=$(docker volume ls --format '{{.Name}}' | grep -w "$VOLUME_NAME")

if [ -z "$EXISTING_VOLUME" ]; then
    echo -e "📦 ${YELLOW}[INFO] Creando volumen para MySQL...${NC}"
    docker volume create $VOLUME_NAME
    echo -e "✅ ${GREEN}[SUCCESS] Volumen creado.${NC}"
else
    echo -e "✅ ${GREEN}[INFO] El volumen ya existe.${NC}"
fi

# 3️⃣ Iniciar el contenedor con MySQL
echo -e "🚀 ${YELLOW}[INFO] Iniciando contenedor MySQL...${NC}"
docker run -d --name $CONTAINER_NAME \
    -e MYSQL_ROOT_PASSWORD=$PASSWORD \
    -e MYSQL_DATABASE=testdb \
    -v $VOLUME_NAME:/var/lib/mysql \
    mysql:5.7

# Verificar si el contenedor se inició correctamente
if [ $? -ne 0 ]; then
    echo -e "❌ ${RED}[ERROR] No se pudo iniciar MySQL.${NC}"
    docker logs $CONTAINER_NAME
    exit 1
fi

echo -e "✅ ${GREEN}[SUCCESS] Contenedor MySQL iniciado.${NC}"

# 4️⃣ Esperar a que MySQL se inicie
echo -e "⏳ ${YELLOW}[INFO] Esperando a que MySQL esté listo...${NC}"
sleep 10

# 5️⃣ Revisar si MySQL está corriendo
MYSQL_RUNNING=$(docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format '{{.Names}}')

if [ "$MYSQL_RUNNING" != "$CONTAINER_NAME" ]; then
    echo -e "❌ ${RED}[ERROR] MySQL no está corriendo. Revisando logs...${NC}"
    echo -e "📜 ${YELLOW}[INFO] Últimos 20 logs de MySQL:${NC}"
    docker logs --tail 20 $CONTAINER_NAME
    exit 1
fi

# 6️⃣ Verificar conexión a MySQL
echo -e "🔍 ${YELLOW}[INFO] Verificando conexión a MySQL...${NC}"
docker exec -i $CONTAINER_NAME mysql -uroot -p$PASSWORD -e "SELECT VERSION();" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "❌ ${RED}[ERROR] MySQL está corriendo pero no acepta conexiones.${NC}"
    docker logs --tail 50 $CONTAINER_NAME
    exit 1
fi

echo -e "✅ ${GREEN}[SUCCESS] MySQL está corriendo correctamente.${NC}"

# 7️⃣ Crear backup del volumen
echo -e "📦 ${YELLOW}[INFO] Creando backup del volumen...${NC}"
docker run --rm -v $VOLUME_NAME:/data -v /tmp:/backup ubuntu tar czf /backup/mysql_backup.tar.gz -C /data .

if [ $? -ne 0 ]; then
    echo -e "❌ ${RED}[ERROR] No se pudo crear el backup.${NC}"
    exit 1
fi

echo -e "✅ ${GREEN}[SUCCESS] Backup creado en $BACKUP_PATH.${NC}"

# 8️⃣ Verificar conexión al servidor remoto antes de transferir
echo -e "🔍 ${YELLOW}[INFO] Verificando conexión SSH con $REMOTE_SERVER...${NC}"
ssh -o ConnectTimeout=5 $REMOTE_USER@$REMOTE_SERVER "echo 'SSH conectado exitosamente'" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "❌ ${RED}[ERROR] No se pudo establecer conexión SSH con $REMOTE_SERVER.${NC}"
    echo -e "🔍 ${YELLOW}[INFO] Probando resolución de DNS...${NC}"
    nslookup $REMOTE_SERVER
    echo -e "🔍 ${YELLOW}[INFO] Probando conectividad con ping...${NC}"
    ping -c 4 $REMOTE_SERVER
    exit 1
fi

# 9️⃣ Transferir backup al servidor remoto
echo -e "🚀 ${YELLOW}[INFO] Transfiriendo backup al servidor remoto...${NC}"
scp $BACKUP_PATH $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DEST

if [ $? -ne 0 ]; then
    echo -e "❌ ${RED}[ERROR] No se pudo transferir el backup.${NC}"
    echo -e "📜 ${YELLOW}[INFO] Posibles causas:${NC}"
    echo -e "   🔹 El usuario '$REMOTE_USER' no tiene permisos en '$REMOTE_DEST'."
    echo -e "   🔹 La ruta '$REMOTE_DEST' no existe en el servidor."
    echo -e "   🔹 La conexión SSH está bloqueada o hay problemas de red."
    exit 1
fi

echo -e "✅ ${GREEN}[SUCCESS] Backup transferido exitosamente a $REMOTE_SERVER.${NC}"
