#!/bin/bash
# reset_sesion.sh – admin tool: reset time counter and remove lock for a user.

set -u

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>" >&2
    exit 1
fi

USUARIO="$1"
ARCHIVO_TIEMPO="/var/tmp/tiempo_sesion_${USUARIO}.dat"
ARCHIVO_BLOQUEO="/var/tmp/bloqueo_${USUARIO}.lock"
LOG="/var/log/ciber_control.log"

rm -f "$ARCHIVO_TIEMPO" "$ARCHIVO_BLOQUEO"
echo "$(date '+%Y-%m-%d %H:%M:%S') - RESET: Sesion reiniciada para $USUARIO" >> "$LOG"
logger -t "reset-sesion[$$]" "Sesion reiniciada para $USUARIO"
echo "Sesion reiniciada para $USUARIO"
