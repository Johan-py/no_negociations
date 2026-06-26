#!/bin/bash
# lockdown_watcher.sh – root service: watches for bloqueo_<user>.lock via inotify,
# then plays shutdown video as user, kills user processes, and powers off.
# Designed for Wayland (GNOME).

set -u

USUARIO="$1"
if [ -z "$USUARIO" ]; then
    echo "Usage: $0 <username>" >&2
    exit 1
fi

ARCHIVO_BLOQUEO="/var/tmp/bloqueo_${USUARIO}.lock"
CARPETA_VIDEOS="/home/${USUARIO}/Videos/cierre"
LOG="/var/log/ciber_control.log"
FECHA_ACTUAL=$(date +%Y%m%d)
USER_UID=$(id -u "$USUARIO")
XDG_RT="/run/user/${USER_UID}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG"
}

get_user_env() {
    local session_id
    session_id=$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$USUARIO" '$3 == u {print $1; exit}')
    if [ -n "$session_id" ]; then
        local display
        display=$(loginctl show-session "$session_id" -p Display --value 2>/dev/null)
        echo "${display:-wayland-0}"
    else
        echo "wayland-0"
    fi
}

run_as_user() {
    local wayland_disp
    wayland_disp=$(get_user_env)
    sudo -u "$USUARIO" env \
        XDG_RUNTIME_DIR="$XDG_RT" \
        WAYLAND_DISPLAY="$wayland_disp" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RT/bus" \
        "$@"
}

lockdown() {
    log "LOCKDOWN: Bloqueo iniciado para ${USUARIO}"

    # Try to play shutdown video as user (before killing processes)
    VIDEO=""
    if [ -d "$CARPETA_VIDEOS" ]; then
        VIDEO=$(find "$CARPETA_VIDEOS" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) 2>/dev/null | shuf -n 1)
    fi

    if [ -n "$VIDEO" ] && [ -f "$VIDEO" ]; then
        log "LOCKDOWN: Reproduciendo $(basename "$VIDEO") como $USUARIO"
        run_as_user mpv --fs --no-input-default-bindings --no-terminal --really-quiet "$VIDEO" 2>/dev/null || \
        log "LOCKDOWN: mpv fallo (probablemente sin sesion activa)"
    else
        log "LOCKDOWN: Sin videos en $CARPETA_VIDEOS, mostrando zenity fallback"
        run_as_user timeout 30 zenity --info \
            --text="<span size='xx-large' weight='bold'>⏰ TIEMPO AGOTADO</span>\n\nEl sistema se apagará..." \
            --title="SISTEMA BLOQUEADO" 2>/dev/null || true
    fi

    # Kill all user processes
    log "LOCKDOWN: Matando procesos de ${USUARIO}..."
    pkill -9 -u "$USUARIO" 2>/dev/null || true
    sleep 2

    log "LOCKDOWN: Apagando sistema..."
    systemctl poweroff || shutdown -h now
}

# On startup, check if lock exists for today
if [ -f "$ARCHIVO_BLOQUEO" ]; then
    FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO" 2>/dev/null)
    if [ "$FECHA_BLOQUEO" = "$FECHA_ACTUAL" ]; then
        log "WATCHER: Bloqueo existente detectado. Ejecutando lockdown inmediato."
        lockdown
    fi
fi

log "WATCHER: Iniciado. Monitoreando ${ARCHIVO_BLOQUEO} via inotify."

# Watch directory for lock file creation
inotifywait -m /var/tmp -e create -e moved_to --format '%f' 2>/dev/null | while read -r filename; do
    if [ "$filename" = "bloqueo_${USUARIO}.lock" ]; then
        if [ -f "$ARCHIVO_BLOQUEO" ]; then
            FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO" 2>/dev/null)
            if [ "$FECHA_BLOQUEO" = "$(date +%Y%m%d)" ]; then
                log "WATCHER: Lock file detectado via inotify. Ejecutando lockdown."
                lockdown
            fi
        fi
    fi
done
