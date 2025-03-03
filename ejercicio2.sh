#!/bin/bash

# Paso 1: Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado. Por favor, instálalo primero."
    exit 1
fi

# Paso 2: Crear las redes
echo "🚀 Creando redes..."
docker network create red_a
docker network create red_b
docker network create red_c

# Paso 3: Crear los contenedores
echo "🚀 Creando contenedores..."
docker run -d --name alpha --network red_a alpine sleep infinity
docker run -d --name beta --network red_b alpine sleep infinity
docker run -d --name gamma --network red_c alpine sleep infinity
docker run -d --name delta alpine sleep infinity

# Paso 4: Conectar delta a todas las redes
echo "🚀 Conectando delta a todas las redes..."
docker network connect red_a delta
docker network connect red_b delta
docker network connect red_c delta

# Paso 5: Pruebas de conectividad
echo "🚀 Realizando pruebas de conectividad..."
echo "🔹 Alpha → Delta (debe funcionar)"
docker exec -it alpha ping -c 4 delta

echo "🔹 Beta → Delta (debe funcionar)"
docker exec -it beta ping -c 4 delta

echo "🔹 Gamma → Delta (debe funcionar)"
docker exec -it gamma ping -c 4 delta

echo "🔹 Alpha → Beta (NO debe funcionar)"
docker exec -it alpha ping -c 4 beta || echo "✅ No hay conexión, como se esperaba."

echo "🔹 Beta → Gamma (NO debe funcionar)"
docker exec -it beta ping -c 4 gamma || echo "✅ No hay conexión, como se esperaba."

echo "🔹 Gamma → Alpha (NO debe funcionar)"
docker exec -it gamma ping -c 4 alpha || echo "✅ No hay conexión, como se esperaba."

# Mostrar configuración de red de delta
echo "🚀 Inspeccionando la configuración de red de delta..."
docker inspect delta | grep "IPAddress"

echo "✅ Configuración completada con éxito."
