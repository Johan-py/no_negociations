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

# Función ULTRA-BLOQUEO - Bloquea absolutamente todo
bloquear_sistema_total() {
    echo "🔒 Activando BLOQUEO TOTAL del sistema..."
    
    # 1. CERRAR TODAS LAS VENTANAS Y APLICACIONES
    echo "  → Cerrando todas las aplicaciones..."
    
    # Matar navegadores
    pkill -9 firefox 2>/dev/null
    pkill -9 chrome 2>/dev/null
    pkill -9 chromium 2>/dev/null
    pkill -9 opera 2>/dev/null
    pkill -9 brave 2>/dev/null
    
    # Matar editores y ofimática
    pkill -9 libreoffice 2>/dev/null
    pkill -9 soffice.bin 2>/dev/null
    pkill -9 gedit 2>/dev/null
    pkill -9 kate 2>/dev/null
    pkill -9 vscode 2>/dev/null
    pkill -9 code 2>/dev/null
    
    # Matar gestores de archivos
    pkill -9 nautilus 2>/dev/null
    pkill -9 thunar 2>/dev/null
    pkill -9 dolphin 2>/dev/null
    pkill -9 pcmanfm 2>/dev/null
    
    # Matar reproductores multimedia
    pkill -9 vlc 2>/dev/null
    pkill -9 mpv 2>/dev/null
    pkill -9 totem 2>/dev/null
    pkill -9 rhythmbox 2>/dev/null
    
    # Matar terminales (TODAS)
    pkill -9 gnome-terminal 2>/dev/null
    pkill -9 xterm 2>/dev/null
    pkill -9 konsole 2>/dev/null
    pkill -9 terminator 2>/dev/null
    pkill -9 xfce4-terminal 2>/dev/null
    pkill -9 qterminal 2>/dev/null
    pkill -9 lxterminal 2>/dev/null
    pkill -9 mate-terminal 2>/dev/null
    pkill -9 tilix 2>/dev/null
    pkill -9 alacritty 2>/dev/null
    pkill -9 kitty 2>/dev/null
    
    # Matar clientes de chat/mensajería
    pkill -9 discord 2>/dev/null
    pkill -9 telegram 2>/dev/null
    pkill -9 slack 2>/dev/null
    pkill -9 skype 2>/dev/null
    pkill -9 whatsapp 2>/dev/null
    
    # Matar juegos
    pkill -9 steam 2>/dev/null
    pkill -9 minecraft 2>/dev/null
    
    # Matar cualquier otra aplicación visible
    pkill -9 gimp 2>/dev/null
    pkill -9 inkscape 2>/dev/null
    pkill -9 blender 2>/dev/null
    
    # Dar tiempo para que se cierren
    sleep 3
    
    # 2. DESHABILITAR COMPLETAMENTE LOS WORKSPACES
    echo "  → Bloqueando workspaces..."
    if command -v gsettings &> /dev/null; then
        # Deshabilitar cambio de workspace
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "[]" 2>/dev/null
        
        # Deshabilitar mover ventanas entre workspaces
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "[]" 2>/dev/null
        
        # Deshabilitar TODAS las combinaciones de teclas
        gsettings list-keys org.gnome.desktop.wm.keybindings | while read key; do
            gsettings set org.gnome.desktop.wm.keybindings "$key" "[]" 2>/dev/null
        done
        
        # Deshabilitar todo en GNOME Shell
        gsettings set org.gnome.shell.keybindings toggle-overview "[]" 2>/dev/null
        gsettings set org.gnome.shell.keybindings toggle-application-view "[]" 2>/dev/null
        gsettings set org.gnome.shell.keybindings focus-active-notification "[]" 2>/dev/null
        gsettings set org.gnome.shell.keybindings toggle-message-tray "[]" 2>/dev/null
        gsettings set org.gnome.shell.keybindings screenshot "[]" 2>/dev/null
        gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]" 2>/dev/null
        
        # Deshabilitar menú de actividades
        gsettings set org.gnome.shell.keybindings toggle-overview "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "[]" 2>/dev/null
        gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "[]" 2>/dev/null
    fi
    
    # 3. DESHABILITAR TERMINALES VIRTUALES (Ctrl+Alt+F1-F7)
    echo "  → Bloqueando terminales virtuales..."
    for i in {1..12}; do
        if [ -e "/dev/tty$i" ]; then
            sudo chmod 000 "/dev/tty$i" 2>/dev/null
        fi
    done
    
    # 4. DESHABILITAR TODAS LAS SEÑALES DE TECLADO
    echo "  → Capturando señales del sistema..."
    trap '' SIGINT SIGTERM SIGHUP SIGQUIT SIGTSTP SIGSTOP SIGKILL SIGUSR1 SIGUSR2
    
    # 5. DESHABILITAR ENTRADAS DE TECLADO A BAJO NIVEL
    echo "  → Bloqueando entrada de teclado..."
    stty intr "" 2>/dev/null
    stty quit "" 2>/dev/null
    stty susp "" 2>/dev/null
    stty stop "" 2>/dev/null
    stty start "" 2>/dev/null
    stty eof "" 2>/dev/null
    stty erase "" 2>/dev/null
    stty kill "" 2>/dev/null
    
    # 6. BLOQUEAR DIRECTORIOS TEMPORALES
    sudo chmod 000 /tmp 2>/dev/null
    sudo chmod 000 /var/tmp 2>/dev/null
    
    # 7. MATAR PROCESOS DEL GESTOR DE VENTANAS (CUIDADO - Esto puede reiniciar X)
    # Solo matamos componentes que no sean críticos
    pkill -9 gnome-shell-extension 2>/dev/null
    pkill -9 xdg-desktop-portal 2>/dev/null
    
    # 8. DESHABILITAR ALT+F4, ALT+TAB, etc.
    if command -v dconf &> /dev/null; then
        dconf write /org/gnome/desktop/wm/keybindings/close "['']" 2>/dev/null
        dconf write /org/gnome/desktop/wm/keybindings/switch-applications "['']" 2>/dev/null
        dconf write /org/gnome/desktop/wm/keybindings/switch-windows "['']" 2>/dev/null
        dconf write /org/gnome/desktop/wm/keybindings/switch-group "['']" 2>/dev/null
    fi
    
    echo "✅ Sistema completamente bloqueado"
}

# Función para video en pantalla completa SIN ESCAPE
reproducir_video_bloqueante() {
    echo "🎬 Iniciando video de cierre en MODO BLOQUEO TOTAL..."
    
    # Matar cualquier instancia previa
    pkill -9 vlc 2>/dev/null
    pkill -9 mpv 2>/dev/null
    
    if [ -d "$CARPETA_VIDEOS" ] && [ "$(ls -A $CARPETA_VIDEOS 2>/dev/null)" ]; then
        VIDEO=$(find "$CARPETA_VIDEOS" -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mkv" -o -name "*.webm" -o -name "*.mov" \) 2>/dev/null | shuf -n 1)
        
        if [ -n "$VIDEO" ]; then
            echo "  ▶ Reproduciendo: $(basename "$VIDEO")"
            
            # Usar MPV con TODAS las opciones de bloqueo
            if command -v mpv &> /dev/null; then
                mpv --fs \
                    --no-input-default-bindings \
                    --no-input-cursor \
                    --no-input-vo-keyboard \
                    --no-input-builtin-bindings \
                    --no-input-test \
                    --no-terminal \
                    --really-quiet \
                    --no-stop-screensaver \
                    --no-osc \
                    --no-osd-bar \
                    --no-window-dragging \
                    --no-border \
                    --no-keepaspect-window \
                    --ontop \
                    --loop-file=inf \
                    --idle=no \
                    --no-input-ipc-server \
                    --no-input-appevent \
                    "$VIDEO" 2>/dev/null &
                
                MPV_PID=$!
                
            # Alternativa con VLC
            elif command -v vlc &> /dev/null; then
                vlc --fullscreen \
                    --no-keyboard-events \
                    --no-mouse-events \
                    --no-osd \
                    --no-video-title-show \
                    --play-and-exit \
                    --loop \
                    --qt-fullscreen-screennumber=1 \
                    --qt-key-press-events=0 \
                    --qt-mouse-events=0 \
                    --no-qt-fs-controller \
                    --no-qt-system-tray \
                    --disable-screensaver \
                    "$VIDEO" 2>/dev/null &
                    
                VLC_PID=$!
            fi
            
            # Esperar a que termine (o no, está en loop)
            sleep 10
            return 0
        fi
    fi
    
    # Si no hay video, mostrar pantalla negra
    echo "  ⚠️ Sin videos, mostrando pantalla negra..."
    if command -v xdg-screensaver &> /dev/null; then
        xdg-screensaver activate 2>/dev/null
    fi
    
    return 1
}

# Función para apantallar completamente
pantalla_muerte() {
    # Crear una ventana negra que cubra todo
    if command -v xdotool &> /dev/null; then
        # Obtener dimensiones de la pantalla
        SCREEN_WIDTH=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f1)
        SCREEN_HEIGHT=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f2)
        
        # Crear ventana negra enorme
        xdotool search --name "CiberControl-Bloqueo" windowkill 2>/dev/null
        
        # Usar zenity como pantalla de bloqueo si está disponible
        if command -v zenity &> /dev/null; then
            zenity --info \
                   --text="<span size='xx-large' weight='bold'>⏰ TIEMPO AGOTADO</span>\n\nEl sistema se apagará en breve..." \
                   --title="SISTEMA BLOQUEADO" \
                   --width=$SCREEN_WIDTH \
                   --height=$SCREEN_HEIGHT \
                   --no-wrap \
                   --timeout=30 2>/dev/null &
        fi
    fi
}

# Función principal mejorada
main() {
    # Verificar bloqueo por límite alcanzado
    if [ -f "$ARCHIVO_BLOQUEO" ]; then
        FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO")
        if [ "$FECHA_BLOQUEO" == "$FECHA_ACTUAL" ]; then
            echo "⛔ ACCESO DENEGADO: Límite diario alcanzado."
            bloquear_sistema_total
            reproducir_video_bloqueante
            pantalla_muerte
            sleep 30
            sudo shutdown -h now
            exit 1
        else
            rm -f "$ARCHIVO_BLOQUEO"
        fi
    fi
    
    # Inicializar o cargar tiempo
    if [ ! -f "$ARCHIVO_TIEMPO" ]; then
        MINUTOS_USADOS=0
        guardar_estado 0
    else
        FECHA_GUARDADA=$(cut -d':' -f1 "$ARCHIVO_TIEMPO")
        if [ "$FECHA_GUARDADA" != "$FECHA_ACTUAL" ]; then
            MINUTOS_USADOS=0
            guardar_estado 0
        else
            MINUTOS_USADOS=$(cut -d':' -f2 "$ARCHIVO_TIEMPO")
        fi
    fi
    
    # Loop principal
    while true; do
        # Verificar cambio de día
        if [ "$(date +%Y%m%d)" != "$FECHA_ACTUAL" ]; then
            FECHA_ACTUAL=$(date +%Y%m%d)
            MINUTOS_USADOS=0
            rm -f "$ARCHIVO_BLOQUEO"
        fi
        
        MINUTOS_USADOS=$((MINUTOS_USADOS + 1))
        MINUTOS_RESTANTES=$((TIEMPO_LIMITE_MINUTOS - MINUTOS_USADOS))
        
        guardar_estado $MINUTOS_USADOS
        
        # ¿Tiempo agotado?
        if [ $MINUTOS_USADOS -ge $TIEMPO_LIMITE_MINUTOS ]; then
            echo "⏰ ¡TIEMPO AGOTADO! Bloqueando sistema..."
            echo "$FECHA_ACTUAL" > "$ARCHIVO_BLOQUEO"
            
            # BLOQUEO TOTAL
            bloquear_sistema_total
            
            # Cerrar TODO
            pantalla_muerte
            
            # Video bloqueante
            reproducir_video_bloqueante
            
            # Esperar y apagar
            sleep 30
            sudo shutdown -h now
            exit 0
        fi
        
        # Advertencias
        case $MINUTOS_RESTANTES in
            60) 
                notify-send "⏰ 1 hora restante" "Te queda 1 hora de uso." -t 10000 -u normal 2>/dev/null
                ;;
            30) 
                notify-send "⏰ 30 minutos" "Te quedan 30 minutos." -t 10000 -u critical 2>/dev/null
                ;;
            15) 
                notify-send "🚨 15 minutos" "¡Solo 15 minutos!" -t 15000 -u critical 2>/dev/null
                ;;
            5) 
                notify-send "🚨 5 MINUTOS" "¡Últimos 5 minutos! Guarda tu trabajo." -t 20000 -u critical 2>/dev/null
                ;;
            1) 
                notify-send "💀 ÚLTIMO MINUTO" "¡Se apagará el sistema!" -t 30000 -u critical 2>/dev/null
                ;;
        esac
        
        sleep 60
    done
}

# Asegurar archivos
sudo touch "$ARCHIVO_TIEMPO" 2>/dev/null
sudo chmod 666 "$ARCHIVO_TIEMPO" 2>/dev/null

# Ejecutar
main
