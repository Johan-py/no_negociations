#!/bin/bash

# Este script se ejecuta continuamente para detectar y matar intentos de escape
# Se ejecuta en segundo plano junto con el control principal

while true; do
    # Si el video está corriendo, monitorear intentos de escape
    if pgrep -f "cierre" > /dev/null || [ -f "/var/tmp/bloqueo_cliente.lock" ]; then
        
        # Matar cualquier terminal que intente abrirse
        pkill -9 gnome-terminal 2>/dev/null
        pkill -9 xterm 2>/dev/null
        pkill -9 konsole 2>/dev/null
        pkill -9 terminator 2>/dev/null
        
        # Matar cualquier gestor de tareas
        pkill -9 gnome-system-monitor 2>/dev/null
        pkill -9 htop 2>/dev/null
        pkill -9 top 2>/dev/null
        
        # Matar cualquier explorador de archivos
        pkill -9 nautilus 2>/dev/null
        pkill -9 thunar 2>/dev/null
        
        # Forzar foco en el video
        if command -v wmctrl &> /dev/null; then
            wmctrl -a "mpv" 2>/dev/null || wmctrl -a "VLC" 2>/dev/null
        fi
        
        # Si alguien mató el video, volver a iniciarlo
        if ! pgrep -f "mpv.*cierre" > /dev/null && ! pgrep -f "vlc.*cierre" > /dev/null; then
            if [ -d "/home/cliente/Videos/cierre" ]; then
                VIDEO=$(find "/home/cliente/Videos/cierre" -type f -name "*.mp4" | shuf -n 1)
                if [ -n "$VIDEO" ]; then
                    mpv --fs --no-input-default-bindings --no-terminal --really-quiet "$VIDEO" 2>/dev/null &
                fi
            fi
        fi
    fi
    
    sleep 2
done
