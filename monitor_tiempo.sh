#!/bin/bash

# Mostrar estado actual del usuario cliente
FECHA_ACTUAL=$(date +%Y%m%d)
ARCHIVO_TIEMPO="/var/tmp/tiempo_sesion_cliente.dat"
ARCHIVO_BLOQUEO="/var/tmp/bloqueo_cliente.lock"

echo "═══════════════════════════════════════════"
echo "  📊 ESTADO DEL SISTEMA - $(date)"
echo "═══════════════════════════════════════════"

# Verificar si está bloqueado
if [ -f "$ARCHIVO_BLOQUEO" ]; then
    FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO")
    if [ "$FECHA_BLOQUEO" == "$FECHA_ACTUAL" ]; then
        echo "🔴 Estado: BLOQUEADO (límite alcanzado hoy)"
    else
        echo "🟡 Estado: Bloqueo de día anterior detectado"
    fi
else
    echo "🟢 Estado: ACTIVO"
fi

# Mostrar tiempo usado
if [ -f "$ARCHIVO_TIEMPO" ]; then
    FECHA_GUARDADA=$(cut -d':' -f1 "$ARCHIVO_TIEMPO")
    MINUTOS_USADOS=$(cut -d':' -f2 "$ARCHIVO_TIEMPO")
    
    if [ "$FECHA_GUARDADA" == "$FECHA_ACTUAL" ]; then
        echo "⏱️  Tiempo usado hoy: $((MINUTOS_USADOS / 60))h $((MINUTOS_USADOS % 60))m"
        echo "⏱️  Tiempo restante: $(((150 - MINUTOS_USADOS) / 60))h $(((150 - MINUTOS_USADOS) % 60))m"
        echo "📅 Última actualización: $(date -d @$(cut -d':' -f3 "$ARCHIVO_TIEMPO") 2>/dev/null || echo 'N/A')"
    else
        echo "📅 Datos del día anterior: $MINUTOS_USADOS minutos usados"
    fi
else
    echo "📝 Sin registros de uso hoy"
fi

# Mostrar procesos del usuario
echo ""
echo "🔍 Procesos del usuario cliente:"
ps -u cliente --no-headers 2>/dev/null | wc -l | xargs echo "  Total procesos:"
echo ""

# Mostrar últimas entradas del log
echo "📋 Últimas entradas del log:"
tail -n 5 /var/log/ciber_control.log 2>/dev/null || echo "  No hay log disponible"
echo "═══════════════════════════════════════════"
