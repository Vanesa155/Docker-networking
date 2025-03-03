#!/bin/bash

# 🔹 Paso 1: Crear las redes necesarias
echo "📡 Creando redes Docker..."
docker network create frontend_net
docker network create --internal backend_net
docker network create --internal db_net

# 🔹 Paso 2: Iniciar el frontend (nginx)
echo "🌐 Desplegando frontend..."
docker run -d --name frontend \
  --network frontend_net \
  -p 8080:80 \
  nginx:alpine

# 🔹 Paso 3: Iniciar el servicio API (httpd)
echo "🛠️ Desplegando API..."
docker run -d --name api \
  --network backend_net \
  httpd:alpine

# 🔹 Paso 4: Iniciar la base de datos (Redis)
echo "🗄️ Desplegando base de datos..."
docker run -d --name db \
  --network db_net \
  redis:alpine

# 🔹 Paso 5: Conectar el API al backend y a la DB (pero no al frontend)
docker network connect backend_net api
docker network connect db_net api

# 🔹 Paso 6: Conectar el frontend al API, pero sin acceso directo
docker network connect backend_net frontend

# 🔹 Paso 7: Verificar la conectividad
echo "✅ Arquitectura desplegada con éxito."
echo "👉 Puedes acceder al frontend en: http://localhost:8080"

echo "🔍 Ejecutando pruebas de conectividad..."

# 🔹 Función para probar conectividad
test_connection() {
    src=$1
    dst=$2
    expected=$3

    echo -n "🧪 Probando conexión desde '$src' hacia '$dst'... "
    
    if docker exec "$src" ping -c 1 -W 1 "$dst" &>/dev/null; then
        if [ "$expected" == "yes" ]; then
            echo "✅ ÉXITO"
        else
            echo "❌ FALLÓ (NO DEBERÍA CONECTARSE)"
        fi
    else
        if [ "$expected" == "no" ]; then
            echo "✅ ÉXITO (Bloqueado correctamente)"
        else
            echo "❌ FALLÓ (Debería conectarse)"
        fi
    fi
}

# 🔹 Pruebas de conectividad esperada
test_connection frontend api yes  # ✅ Frontend → API (Debe funcionar)
test_connection api db yes        # ✅ API → DB (Debe funcionar)

# 🔹 Pruebas de aislamiento
test_connection api frontend no   # 🚫 API NO debe ver al frontend
test_connection db api no         # 🚫 DB NO debe ver a la API
test_connection api 8.8.8.8 no    # 🚫 API NO debe salir a Internet
test_connection db 8.8.8.8 no     # 🚫 DB NO debe salir a Internet

echo "🏁 Pruebas finalizadas."


echo "🧹 Limpiando contenedores y redes Docker..."

# 🔹 Eliminar contenedores (forzando la eliminación)
docker rm -f frontend api db 2>/dev/null

# 🔹 Eliminar redes (ignorando errores si no existen)
docker network rm frontend_net backend_net db_net 2>/dev/null

echo "✅ Limpieza completada. Todo ha sido eliminado correctamente."
