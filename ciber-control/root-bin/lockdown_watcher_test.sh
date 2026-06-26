#!/bin/bash
# lockdown_watcher.sh – root service: watches for bloqueo_<user>.lock via inotify,
# then kills user processes, plays shutdown video, and powers off.
# Designed for Wayland (no xdotool/wmctrl/gsettings keybind hacks).

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

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG"
}

lockdown() {
    log "LOCKDOWN: Bloqueo iniciado para ${USUARIO}"

    # Kill all user processes
    log "LOCKDOWN: Matando procesos de ${USUARIO}..."
    pkill -9 -u "$USUARIO" 2>/dev/null || true
    sleep 2

    # Try to play video
    VIDEO=""
    if [ -d "$CARPETA_VIDEOS" ]; then
        VIDEO=$(find "$CARPETA_VIDEOS" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.mov" \) 2>/dev/null | shuf -n 1)
    fi

    if [ -n "$VIDEO" ] && [ -f "$VIDEO" ]; then
        log "LOCKDOWN: Reproduciendo $(basename "$VIDEO")"
        # Block until video ends (no loop – then poweroff)
        mpv --fs --no-input-default-bindings --no-terminal --really-quiet "$VIDEO"
        MPV_EXIT=$?
        log "LOCKDOWN: mpv termin\u00f3 con c\u00f3digo $MPV_EXIT"
    else
        log "LOCKDOWN: Sin videos en $CARPETA_VIDEOS, mostrando zenity fallback"
        if command -v zenity &>/dev/null; then
            timeout 30 zenity --info \
                --text="<span size='xx-large' weight='bold'>\u23f0 TIEMPO AGOTADO</span>\n\nEl sistema se apagar\u00e1..." \
                --title="SISTEMA BLOQUEADO" 2>/dev/null || true
        else
            sleep 30
        fi
    fi

    log "LOCKDOWN: Apagando sistema..."
    echo "TEST: poweroff bypassed -- would have powered off"
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
        # Double-check date
        if [ -f "$ARCHIVO_BLOQUEO" ]; then
            FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO" 2>/dev/null)
            if [ "$FECHA_BLOQUEO" = "$(date +%Y%m%d)" ]; then
                log "WATCHER: Lock file detectado via inotify. Ejecutando lockdown."
                lockdown
            fi
        fi
    fi
done
