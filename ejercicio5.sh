#!/bin/bash

TEST_SIZE_MB=100
BIND_MOUNT_DIR="$HOME/docker_test_data"

echo -e "\n📦 \e[1;36mIniciando pruebas de almacenamiento...\e[0m\n"

# Crear volumen de Docker y carpeta para Bind Mount
docker volume create storage_test_volume >/dev/null
mkdir -p "$BIND_MOUNT_DIR"

run_test() {
    local type=$1
    local option=$2
    local emoji=$3
    local time_taken

    echo -e "🛠️  \e[1;35mProbando $type...\e[0m $emoji"
    time_taken=$(docker run --rm $option debian sh -c "
        apt update -qq > /dev/null
        apt install -y time coreutils > /dev/null
        sync
        /usr/bin/time -f '%e' dd if=/dev/zero of=/data/testfile bs=1M count=$TEST_SIZE_MB oflag=sync 2>&1" | tail -n 1)
    
    echo -e "⏳  \e[1;33mTiempo en $type:\e[0m \e[1;32m$time_taken segundos\e[0m\n"
    echo "$time_taken"
}

time_volume=$(run_test "Volumen de Docker" "-v storage_test_volume:/data" "📂")
time_bind=$(run_test "Bind Mount" "-v $BIND_MOUNT_DIR:/data" "📁")
time_tmpfs=$(run_test "tmpfs (RAM)" "--tmpfs /data" "⚡")

echo -e "\n📊 \e[1;34mComparación de tiempos:\e[0m"
echo -e "📂 Volumen de Docker: \e[1;32m$time_volume s\e[0m"
echo -e "📁 Bind Mount: \e[1;32m$time_bind s\e[0m"
echo -e "⚡ tmpfs (RAM): \e[1;32m$time_tmpfs s\e[0m\n"

# Limpiar recursos
docker volume rm storage_test_volume >/dev/null
rm -rf "$BIND_MOUNT_DIR"
echo -e "✅ \e[1;32mPruebas completadas.\e[0m 🎉\n"
