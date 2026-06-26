#!/bin/bash
# session_timer.sh – user service: counts active session minutes, creates lock at limit
# Flow: runs as unprivileged user, writes /var/tmp/tiempo_sesion_<user>.dat,
#       at limit creates /var/tmp/bloqueo_<user>.lock for root watcher.
# No destructive actions – only counting and signaling.

set -u

USUARIO=$(whoami)
TIEMPO_LIMITE_MINUTOS=2
ARCHIVO_TIEMPO="/var/tmp/tiempo_sesion_${USUARIO}.dat"
ARCHIVO_BLOQUEO="/var/tmp/bloqueo_${USUARIO}.lock"
FECHA_ACTUAL=$(date +%Y%m%d)

# If lock exists for today, refuse to run (exit silently)
if [ -f "$ARCHIVO_BLOQUEO" ]; then
    FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO" 2>/dev/null)
    if [ "$FECHA_BLOQUEO" = "$FECHA_ACTUAL" ]; then
        exit 0
    fi
    # Stale lock from previous day
    rm -f "$ARCHIVO_BLOQUEO"
fi

# Load or initialize counter
if [ ! -f "$ARCHIVO_TIEMPO" ]; then
    MINUTOS_USADOS=0
else
    FECHA_GUARDADA=$(cut -d':' -f1 "$ARCHIVO_TIEMPO" 2>/dev/null)
    if [ "$FECHA_GUARDADA" != "$FECHA_ACTUAL" ]; then
        MINUTOS_USADOS=0
    else
        MINUTOS_USADOS=$(cut -d':' -f2 "$ARCHIVO_TIEMPO" 2>/dev/null)
        MINUTOS_USADOS=${MINUTOS_USADOS:-0}
    fi
fi

guardar_estado() {
    echo "${FECHA_ACTUAL}:${1}:$(date +%s)" > "$ARCHIVO_TIEMPO"
}

guardar_estado "$MINUTOS_USADOS"

# Loop principal: cada 60 segundos
while true; do
    NUEVA_FECHA=$(date +%Y%m%d)
    if [ "$NUEVA_FECHA" != "$FECHA_ACTUAL" ]; then
        FECHA_ACTUAL=$NUEVA_FECHA
        MINUTOS_USADOS=0
        rm -f "$ARCHIVO_BLOQUEO"
    fi

    MINUTOS_USADOS=$((MINUTOS_USADOS + 1))
    guardar_estado "$MINUTOS_USADOS"

    if [ "$MINUTOS_USADOS" -ge "$TIEMPO_LIMITE_MINUTOS" ]; then
        echo "$FECHA_ACTUAL" > "$ARCHIVO_BLOQUEO"
        exit 0
    fi

    MINUTOS_RESTANTES=$((TIEMPO_LIMITE_MINUTOS - MINUTOS_USADOS))
    case $MINUTOS_RESTANTES in
        60) notify-send "\u23f0 1 hora restante" "Te queda 1 hora de uso." -t 10000 -u normal 2>/dev/null || true ;;
        30) notify-send "\u23f0 30 minutos" "Te quedan 30 minutos." -t 10000 -u critical 2>/dev/null || true ;;
        15) notify-send "\U0001f6a8 15 minutos" "\u00a1Solo 15 minutos!" -t 15000 -u critical 2>/dev/null || true ;;
        5)  notify-send "\U0001f6a8 5 MINUTOS" "\u00a1\u00daltimos 5 minutos!" -t 20000 -u critical 2>/dev/null || true ;;
    esac

    sleep 60
done
