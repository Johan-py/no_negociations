#!/bin/bash

# Configuración
USUARIO_PERMITIDO="cliente"
TIEMPO_LIMITE_MINUTOS=150  # 2h 30min = 150 minutos
CARPETA_VIDEOS="/home/$USUARIO_PERMITIDO/Videos/cierre"
ARCHIVO_TIEMPO="/var/tmp/tiempo_sesion_${USUARIO_PERMITIDO}.dat"
ARCHIVO_BLOQUEO="/var/tmp/bloqueo_${USUARIO_PERMITIDO}.lock"
FECHA_ACTUAL=$(date +%Y%m%d)

# Verificar usuario
if [ "$USER" != "$USUARIO_PERMITIDO" ]; then
    echo "❌ Este script solo puede ejecutarse como usuario $USUARIO_PERMITIDO"
    exit 1
fi

# Función para bloquear completamente el sistema
bloquear_sistema() {
    echo "🔒 TIEMPO AGOTADO - Bloqueando sistema..."
    
    # Capturar todas las señales posibles
    trap '' SIGINT SIGTERM SIGHUP SIGQUIT SIGTSTP SIGSTOP SIGKILL
    
    # Bloquear terminales virtuales
    for tty in /dev/tty[0-9]*; do
        sudo chmod 000 "$tty" 2>/dev/null
    done
    
    # Matar procesos de terminal
    pkill -9 gnome-terminal 2>/dev/null
    pkill -9 xterm 2>/dev/null
    pkill -9 konsole 2>/dev/null
    pkill -9 terminator 2>/dev/null
    pkill -9 xfce4-terminal 2>/dev/null
    
    # Deshabilitar teclas en X11/GNOME
    if command -v gsettings &> /dev/null; then
        # Deshabilitar TODOS los atajos de teclado
        gsettings list-keys org.gnome.desktop.wm.keybindings | while read key; do
            gsettings set org.gnome.desktop.wm.keybindings "$key" "[]" 2>/dev/null
        done
        
        # Deshabilitar acceso a menú y actividades
        gsettings set org.gnome.shell.keybindings toggle-overview "[]" 2>/dev/null
        gsettings set org.gnome.shell.keybindings toggle-application-view "[]" 2>/dev/null
        gsettings set org.gnome.shell.keybindings focus-active-notification "[]" 2>/dev/null
        
        # Deshabilitar cambio de ventanas
        gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]" 2>/dev/null
    fi
    
    # Deshabilitar Alt+F2 y otras combinaciones
    if command -v dconf &> /dev/null; then
        dconf write /org/gnome/desktop/wm/keybindings/panel-run-dialog "['']" 2>/dev/null
    fi
    
    # Bloquear Ctrl+Alt+Supr (si existe)
    if [ -f /etc/systemd/system/ctrl-alt-del.target ]; then
        sudo systemctl mask ctrl-alt-del.target 2>/dev/null
    fi
    
    # Deshabilitar interrupciones en terminal
    stty intr "" 2>/dev/null
    stty quit "" 2>/dev/null
    stty susp "" 2>/dev/null
    stty stop "" 2>/dev/null
    stty start "" 2>/dev/null
    
    # Bloquear el directorio temporal
    sudo chmod 000 /tmp 2>/dev/null
    sudo chmod 000 /var/tmp 2>/dev/null
}

# Función para reproducir video aleatorio
reproducir_video_final() {
    if [ -d "$CARPETA_VIDEOS" ] && [ "$(ls -A $CARPETA_VIDEOS 2>/dev/null)" ]; then
        # Seleccionar video aleatorio
        VIDEO=$(find "$CARPETA_VIDEOS" -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mkv" -o -name "*.webm" -o -name "*.mov" \) 2>/dev/null | shuf -n 1)
        
        if [ -n "$VIDEO" ]; then
            echo "🎬 Reproduciendo video de cierre..."
            
            # Matar cualquier instancia previa
            pkill -9 vlc 2>/dev/null
            pkill -9 mpv 2>/dev/null
            
            # Intentar con VLC, si no está disponible usar mpv
            if command -v vlc &> /dev/null; then
                vlc --fullscreen \
                    --no-keyboard-events \
                    --no-mouse-events \
                    --no-osd \
                    --no-video-title-show \
                    --play-and-exit \
                    --loop \
                    "$VIDEO" 2>/dev/null &
            elif command -v mpv &> /dev/null; then
                mpv --fullscreen \
                    --no-input-default-bindings \
                    --no-terminal \
                    --really-quiet \
                    --loop-file=inf \
                    "$VIDEO" 2>/dev/null &
            fi
            
            # Dar tiempo para que el video comience
            sleep 5
        fi
    fi
}

# Función para mostrar mensaje gráfico
mostrar_mensaje_fin() {
    # Intentar con zenity
    if command -v zenity &> /dev/null; then
        zenity --warning \
               --text="⏰ ¡TIEMPO AGOTADO!\n\nHas alcanzado el límite diario de $((TIEMPO_LIMITE_MINUTOS / 60)) horas y $((TIEMPO_LIMITE_MINUTOS % 60)) minutos.\n\nEl sistema se apagará en 30 segundos..." \
               --title="⚠️ Tiempo Agotado" \
               --width=500 \
               --timeout=30 2>/dev/null &
    fi
    
    # También mostrar en terminal por si acaso
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║              ⚠️  ¡TIEMPO AGOTADO!  ⚠️                  ║"
    echo "║                                                        ║"
    echo "║  Has alcanzado el límite diario de uso.                ║"
    echo "║  Tiempo máximo: $((TIEMPO_LIMITE_MINUTOS / 60)) horas y $((TIEMPO_LIMITE_MINUTOS % 60)) minutos               ║"
    echo "║                                                        ║"
    echo "║  El sistema se apagará en 30 segundos.                 ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
}

# Función para guardar estado
guardar_estado() {
    local minutos_usados=$1
    echo "$FECHA_ACTUAL:$minutos_usados:$(date +%s)" > "$ARCHIVO_TIEMPO"
    sudo chmod 644 "$ARCHIVO_TIEMPO" 2>/dev/null
}

# Función para verificar si el día cambió
verificar_dia() {
    if [ -f "$ARCHIVO_TIEMPO" ]; then
        FECHA_GUARDADA=$(cut -d':' -f1 "$ARCHIVO_TIEMPO")
        if [ "$FECHA_GUARDADA" != "$FECHA_ACTUAL" ]; then
            # Es un nuevo día, reiniciar contador
            echo "🌅 Nuevo día detectado. Reiniciando contador..."
            rm -f "$ARCHIVO_TIEMPO"
            return 1
        fi
    fi
    return 0
}

# Función principal mejorada
main() {
    # Verificar bloqueo por límite alcanzado
    if [ -f "$ARCHIVO_BLOQUEO" ]; then
        FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO")
        if [ "$FECHA_BLOQUEO" == "$FECHA_ACTUAL" ]; then
            echo "⛔ ACCESO DENEGADO: Ya has alcanzado el límite diario."
            echo "⏰ Podrás volver a usar el sistema mañana."
            bloquear_sistema
            reproducir_video_final
            sleep 30
            sudo shutdown -h now
            exit 1
        else
            # Es un nuevo día, eliminar bloqueo
            rm -f "$ARCHIVO_BLOQUEO"
        fi
    fi
    
    # Verificar si es un nuevo día
    verificar_dia
    ES_NUEVO_DIA=$?
    
    # Inicializar o cargar tiempo usado
    if [ ! -f "$ARCHIVO_TIEMPO" ] || [ $ES_NUEVO_DIA -eq 1 ]; then
        MINUTOS_USADOS=0
        echo "✅ Nueva sesión iniciada. Tienes $((TIEMPO_LIMITE_MINUTOS / 60)) horas y $((TIEMPO_LIMITE_MINUTOS % 60)) minutos para hoy."
        guardar_estado 0
    else
        MINUTOS_USADOS=$(cut -d':' -f2 "$ARCHIVO_TIEMPO")
        MINUTOS_RESTANTES=$((TIEMPO_LIMITE_MINUTOS - MINUTOS_USADOS))
        echo "🔄 Sesión restaurada. Te quedan $((MINUTOS_RESTANTES / 60)) horas y $((MINUTOS_RESTANTES % 60)) minutos."
        
        # Verificar si ya se acabó el tiempo
        if [ $MINUTOS_USADOS -ge $TIEMPO_LIMITE_MINUTOS ]; then
            echo "$FECHA_ACTUAL" > "$ARCHIVO_BLOQUEO"
            echo "⏰ Ya has agotado tu tiempo por hoy."
            bloquear_sistema
            mostrar_mensaje_fin
            reproducir_video_final
            sleep 30
            sudo shutdown -h now
            exit 0
        fi
    fi
    
    # Loop principal de monitoreo
    while true; do
        # Verificar si cambió el día durante la sesión
        if [ "$(date +%Y%m%d)" != "$FECHA_ACTUAL" ]; then
            echo "🌅 Medianoche - Reiniciando contador para el nuevo día..."
            FECHA_ACTUAL=$(date +%Y%m%d)
            MINUTOS_USADOS=0
            rm -f "$ARCHIVO_BLOQUEO"
        fi
        
        MINUTOS_USADOS=$((MINUTOS_USADOS + 1))
        MINUTOS_RESTANTES=$((TIEMPO_LIMITE_MINUTOS - MINUTOS_USADOS))
        
        # Guardar estado periódicamente
        guardar_estado $MINUTOS_USADOS
        
        # Verificar si se acabó el tiempo
        if [ $MINUTOS_USADOS -ge $TIEMPO_LIMITE_MINUTOS ]; then
            echo "⏰ ¡TIEMPO AGOTADO!"
            echo "$FECHA_ACTUAL" > "$ARCHIVO_BLOQUEO"
            
            # Mostrar advertencias
            mostrar_mensaje_fin
            
            # Bloquear sistema
            bloquear_sistema
            
            # Reproducir video
            reproducir_video_final
            
            # Tiempo para ver el mensaje
            sleep 30
            
            # Apagar sistema
            echo "💀 Apagando sistema..."
            sudo shutdown -h now
            exit 0
        fi
        
        # Mostrar advertencias
        case $MINUTOS_RESTANTES in
            60)
                notify-send "⏰ 1 hora restante" "Te queda 1 hora de uso hoy." -t 10000 -u normal 2>/dev/null
                echo "⚠️  Queda 1 hora de sesión."
                ;;
            30)
                notify-send "⏰ 30 minutos" "Te quedan 30 minutos de uso." -t 10000 -u critical 2>/dev/null
                echo "⚠️  Quedan 30 minutos."
                ;;
            15)
                notify-send "🚨 15 minutos" "¡Solo te quedan 15 minutos!" -t 15000 -u critical 2>/dev/null
                echo "🚨 ¡Solo quedan 15 minutos!"
                ;;
            5)
                notify-send "🚨 ¡5 MINUTOS!" "¡La sesión está por terminar!" -t 20000 -u critical 2>/dev/null
                echo "🚨 ¡ÚLTIMOS 5 MINUTOS!"
                ;;
            1)
                notify-send "💀 ÚLTIMO MINUTO" "¡Guarda tu trabajo!" -t 30000 -u critical 2>/dev/null
                echo "💀 ¡ÚLTIMO MINUTO!"
                ;;
        esac
        
        # Mostrar tiempo cada 10 minutos
        if [ $((MINUTOS_USADOS % 10)) -eq 0 ]; then
            echo "⏱️  Tiempo restante: $((MINUTOS_RESTANTES / 60))h $((MINUTOS_RESTANTES % 60))m"
        fi
        
        sleep 60  # Verificar cada minuto
    done
}

# Asegurar que el archivo de tiempo existe y tiene permisos correctos
sudo touch "$ARCHIVO_TIEMPO" 2>/dev/null
sudo chmod 666 "$ARCHIVO_TIEMPO" 2>/dev/null

# Ejecutar función principal
main
