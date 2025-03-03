#!/bin/bash

# 🚀 **Paso 1: Verificar que Docker está instalado**  
echo "🔍 Verificando Docker..."
docker --version || { echo "❌ Docker no está instalado. 📌 Instálalo y vuelve a intentarlo."; exit 1; }

# 📌 **Paso 2: Crear el volumen de Docker**  
echo "🛠️ Creando volumen 🗄️ 'shared_data'..."
docker volume create shared_data

echo "📜 Lista de volúmenes disponibles:"
docker volume ls

# 📝 **Paso 3: Crear el contenedor que escribe en el volumen**  
echo "🚀 Iniciando contenedor 📝 'writer'..."
docker run -d --name writer \
  -v shared_data:/data \
  alpine sh -c "while true; do date >> /data/timestamp.log; sleep 10; done"

echo "🧐 Verificando que el contenedor 'writer' está corriendo..."
docker ps | grep writer || { echo "❌ El contenedor 'writer' no está en ejecución."; exit 1; }

# ⏳ **Esperar 15 segundos para que se generen datos**  
echo "⏳ Esperando 15 segundos para que 'writer' registre datos..."
sleep 15

# 🔍 **Paso 4: Verificar los datos generados**  
echo "📂 Mostrando contenido actual del archivo timestamp.log:"
docker exec -it writer cat /data/timestamp.log

# 📖 **Paso 5: Crear el contenedor lector**  
echo "👀 Ejecutando contenedor 'reader' para verificar los datos..."
docker run --rm -it -v shared_data:/data alpine cat /data/timestamp.log

# 🛑 **Paso 6: Detener y eliminar el contenedor 'writer'**  
echo "🛑 Deteniendo el contenedor 'writer'..."
docker stop writer

echo "🗑️ Eliminando el contenedor 'writer'..."
docker rm writer

# 📌 **Paso 7: Verificar que el volumen sigue existiendo**  
echo "🔎 Verificando que el volumen 'shared_data' aún existe..."
docker volume ls

echo "📂 Verificando el contenido del volumen tras eliminar 'writer'..."
docker run --rm -it -v shared_data:/data alpine cat /data/timestamp.log

echo "🎉✅ Prueba completada exitosamente. ¡El volumen persiste y los datos siguen disponibles! 🚀"
