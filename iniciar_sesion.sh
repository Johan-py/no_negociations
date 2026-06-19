#!/bin/bash

echo "🔄 Iniciando nueva sesión para cliente..."

# Verificar si es un nuevo día antes de reiniciar
FECHA_ACTUAL=$(date +%Y%m%d)
ARCHIVO_TIEMPO="/var/tmp/tiempo_sesion_cliente.dat"

if [ -f "$ARCHIVO_TIEMPO" ]; then
    FECHA_GUARDADA=$(cut -d':' -f1 "$ARCHIVO_TIEMPO")
    MINUTOS_USADOS=$(cut -d':' -f2 "$ARCHIVO_TIEMPO")
    
    if [ "$FECHA_GUARDADA" == "$FECHA_ACTUAL" ]; then
        echo "⚠️  ATENCIÓN: El usuario ya ha usado $MINUTOS_USADOS minutos hoy."
        echo "⏱️  Tiempo restante: $((150 - MINUTOS_USADOS)) minutos"
        echo ""
        read -p "¿Realmente deseas reiniciar el contador? (s/N): " CONFIRMAR
        if [ "$CONFIRMAR" != "s" ] && [ "$CONFIRMAR" != "S" ]; then
            echo "❌ Reinicio cancelado. Se mantiene el tiempo actual."
            exit 0
        fi
        echo "⚠️  Registrando reinicio manual en log..."
        echo "$(date): Reinicio manual por admin - Tiempo anterior: $MINUTOS_USADOS min" >> /var/log/ciber_control.log
    fi
fi

# Eliminar solo si es apropiado
rm -f "$ARCHIVO_TIEMPO"
rm -f "/var/tmp/bloqueo_cliente.lock"

echo "✅ Contador reiniciado correctamente."
echo "⏱️  Nueva sesión: 2 horas 30 minutos disponibles."

# Registrar en log
echo "$(date): Nueva sesión iniciada" >> /var/log/ciber_control.log
