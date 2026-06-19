#!/bin/bash
# install_arch_gnome.sh - Sistema de Control de Ciber Café para Arch Linux + GNOME

set -e  # Detener en caso de error

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🔧 Instalando Sistema de Control de Ciber Café${NC}"
echo -e "${BLUE}  🖥️  Arch Linux + GNOME - MODO BLOQUEO TOTAL${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Este script debe ejecutarse como root${NC}"
    echo -e "${YELLOW}💡 Usa: sudo $0${NC}"
    exit 1
fi

# Verificar que es Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}❌ Este script está diseñado para Arch Linux${NC}"
    exit 1
fi

# Verificar que GNOME está instalado
if ! command -v gnome-shell &> /dev/null; then
    echo -e "${YELLOW}⚠️  GNOME no detectado. Instalando...${NC}"
    pacman -S --noconfirm gnome gnome-extra
fi

echo -e "${GREEN}📦 Paso 1: Instalando dependencias necesarias...${NC}"
# Actualizar repositorios
pacman -Syu --noconfirm

# Instalar paquetes necesarios
pacman -S --noconfirm \
    mpv \
    vlc \
    zenity \
    xdotool \
    xorg-xdpyinfo \
    wmctrl \
    xdg-utils \
    xorg-xrandr \
    xorg-xset \
    bash \
    coreutils \
    procps-ng \
    util-linux \
    findutils \
    sudo \
    systemd

# Instalar paquetes AUR opcionales (si yay está disponible)
if command -v yay &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando paquetes adicionales desde AUR...${NC}"
    sudo -u $SUDO_USER yay -S --noconfirm \
        gnome-shell-extension-no-annoyance 2>/dev/null || true
fi

echo -e "${GREEN}✅ Dependencias instaladas${NC}"
echo ""

# Crear usuario cliente si no existe
echo -e "${GREEN}👤 Paso 2: Configurando usuario cliente...${NC}"
if ! id "cliente" &>/dev/null; then
    useradd -m -G wheel,audio,video -s /bin/bash cliente
    echo -e "${YELLOW}🔑 Establece una contraseña para el usuario 'cliente':${NC}"
    passwd cliente
    
    # Configurar directorios del usuario
    mkdir -p /home/cliente/{Videos/cierre,Descargas,Documentos,Escritorio}
    chown -R cliente:cliente /home/cliente
    
    # Configurar bashrc para cliente
    cat >> /home/cliente/.bashrc << 'EOF'
# Control de tiempo del ciber café
if [ -f /usr/local/bin/control_tiempo.sh ]; then
    /usr/local/bin/control_tiempo.sh &
fi
EOF
else
    echo -e "${GREEN}✅ Usuario 'cliente' ya existe${NC}"
fi
echo ""

# Crear directorios del sistema
echo -e "${GREEN}📁 Paso 3: Creando estructura de directorios...${NC}"
mkdir -p /var/tmp
mkdir -p /var/log
mkdir -p /home/cliente/Videos/cierre
mkdir -p /usr/local/bin

# Configurar permisos
touch /var/log/ciber_control.log
chmod 666 /var/log/ciber_control.log
chmod 777 /var/tmp
chown -R cliente:cliente /home/cliente/Videos

echo -e "${GREEN}✅ Directorios creados${NC}"
echo ""

# Instalar script principal
echo -e "${GREEN}📜 Paso 4: Instalando script de control...${NC}"

cat > /usr/local/bin/control_tiempo.sh << 'SCRIPTEOF'
#!/bin/bash

# Configuración
USUARIO_PERMITIDO="cliente"
TIEMPO_LIMITE_MINUTOS=150  # 2h 30min
CARPETA_VIDEOS="/home/$USUARIO_PERMITIDO/Videos/cierre"
ARCHIVO_TIEMPO="/var/tmp/tiempo_sesion_${USUARIO_PERMITIDO}.dat"
ARCHIVO_BLOQUEO="/var/tmp/bloqueo_${USUARIO_PERMITIDO}.lock"
FECHA_ACTUAL=$(date +%Y%m%d)

# Verificar usuario
if [ "$USER" != "$USUARIO_PERMITIDO" ]; then
    echo "❌ Este script solo puede ejecutarse como usuario $USUARIO_PERMITIDO"
    exit 1
fi

# Función de bloqueo total
bloquear_sistema_total() {
    echo "🔒 Activando BLOQUEO TOTAL del sistema..."
    
    # Cerrar todas las aplicaciones
    pkill -9 -u cliente 2>/dev/null || true
    
    # Esperar a que se cierren
    sleep 3
    
    # Deshabilitar workspaces en GNOME
    if command -v gsettings &> /dev/null; then
        # Deshabilitar cambio de workspace
        for i in {1..12}; do
            gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "[]" 2>/dev/null || true
            gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "[]" 2>/dev/null || true
        done
        
        # Deshabilitar todas las keybindings de GNOME
        gsettings list-keys org.gnome.desktop.wm.keybindings | while read key; do
            gsettings set org.gnome.desktop.wm.keybindings "$key" "[]" 2>/dev/null || true
        done
        
        gsettings list-keys org.gnome.shell.keybindings | while read key; do
            gsettings set org.gnome.shell.keybindings "$key" "[]" 2>/dev/null || true
        done
        
        # Deshabilitar acceso a actividades
        gsettings set org.gnome.shell.keybindings toggle-overview "[]" 2>/dev/null || true
        gsettings set org.gnome.shell.keybindings toggle-application-view "[]" 2>/dev/null || true
        
        # Deshabilitar menú y ejecutar
        gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "[]" 2>/dev/null || true
        gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "[]" 2>/dev/null || true
        
        # Deshabilitar Alt+F4, Alt+Tab, etc.
        gsettings set org.gnome.desktop.wm.keybindings close "[]" 2>/dev/null || true
        gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]" 2>/dev/null || true
        gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]" 2>/dev/null || true
        gsettings set org.gnome.desktop.wm.keybindings switch-group "[]" 2>/dev/null || true
    fi
    
    # Bloquear terminales virtuales
    for i in {1..12}; do
        if [ -e "/dev/tty$i" ]; then
            chmod 000 "/dev/tty$i" 2>/dev/null || true
        fi
    done
    
    # Capturar señales
    trap '' SIGINT SIGTERM SIGHUP SIGQUIT SIGTSTP
    
    # Bloquear entrada de teclado
    stty intr "" 2>/dev/null || true
    stty quit "" 2>/dev/null || true
    stty susp "" 2>/dev/null || true
    
    echo "✅ Sistema completamente bloqueado"
}

# Reproducir video de cierre
reproducir_video_bloqueante() {
    echo "🎬 Iniciando video de cierre..."
    
    if [ -d "$CARPETA_VIDEOS" ] && [ "$(ls -A $CARPETA_VIDEOS 2>/dev/null)" ]; then
        VIDEO=$(find "$CARPETA_VIDEOS" -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mkv" -o -name "*.webm" -o -name "*.mov" \) 2>/dev/null | shuf -n 1)
        
        if [ -n "$VIDEO" ]; then
            echo "  ▶ Reproduciendo: $(basename "$VIDEO")"
            
            # Intentar con MPV (más ligero y mejor bloqueo)
            if command -v mpv &> /dev/null; then
                mpv --fs \
                    --no-input-default-bindings \
                    --no-input-cursor \
                    --no-input-vo-keyboard \
                    --no-terminal \
                    --really-quiet \
                    --no-osc \
                    --no-osd-bar \
                    --ontop \
                    --loop-file=inf \
                    --idle=no \
                    "$VIDEO" 2>/dev/null &
                return 0
            fi
            
            # Alternativa con VLC
            if command -v vlc &> /dev/null; then
                vlc --fullscreen \
                    --no-keyboard-events \
                    --no-mouse-events \
                    --no-osd \
                    --no-video-title-show \
                    --loop \
                    --qt-fullscreen-screennumber=1 \
                    --no-qt-fs-controller \
                    "$VIDEO" 2>/dev/null &
                return 0
            fi
        fi
    fi
    
    # Si no hay video, mostrar pantalla negra con mensaje
    if command -v zenity &> /dev/null; then
        zenity --info \
               --text="<span size='xx-large' weight='bold'>⏰ TIEMPO AGOTADO</span>\n\nEl sistema se apagará en breve..." \
               --title="SISTEMA BLOQUEADO" \
               --timeout=30 2>/dev/null &
    fi
    
    return 1
}

# Guardar estado
guardar_estado() {
    echo "$FECHA_ACTUAL:$1:$(date +%s)" > "$ARCHIVO_TIEMPO"
}

# Función principal
main() {
    # Verificar bloqueo
    if [ -f "$ARCHIVO_BLOQUEO" ]; then
        FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO")
        if [ "$FECHA_BLOQUEO" == "$FECHA_ACTUAL" ]; then
            echo "⛔ ACCESO DENEGADO: Límite diario alcanzado."
            bloquear_sistema_total
            reproducir_video_bloqueante
            sleep 30
            shutdown -h now
            exit 1
        else
            rm -f "$ARCHIVO_BLOQUEO"
        fi
    fi
    
    # Inicializar o cargar tiempo
    if [ ! -f "$ARCHIVO_TIEMPO" ]; then
        MINUTOS_USADOS=0
        guardar_estado 0
        echo "✅ Nueva sesión iniciada. Tienes $((TIEMPO_LIMITE_MINUTOS / 60)) horas y $((TIEMPO_LIMITE_MINUTOS % 60)) minutos."
    else
        FECHA_GUARDADA=$(cut -d':' -f1 "$ARCHIVO_TIEMPO")
        if [ "$FECHA_GUARDADA" != "$FECHA_ACTUAL" ]; then
            MINUTOS_USADOS=0
            guardar_estado 0
            echo "🌅 Nuevo día. Contador reiniciado."
        else
            MINUTOS_USADOS=$(cut -d':' -f2 "$ARCHIVO_TIEMPO")
            MINUTOS_RESTANTES=$((TIEMPO_LIMITE_MINUTOS - MINUTOS_USADOS))
            echo "🔄 Sesión restaurada. Te quedan $((MINUTOS_RESTANTES / 60))h $((MINUTOS_RESTANTES % 60))m"
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
            echo "⏰ ¡TIEMPO AGOTADO!"
            echo "$FECHA_ACTUAL" > "$ARCHIVO_BLOQUEO"
            
            bloquear_sistema_total
            reproducir_video_bloqueante
            sleep 30
            shutdown -h now
            exit 0
        fi
        
        # Advertencias
        case $MINUTOS_RESTANTES in
            60) 
                DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u cliente)/bus" \
                    notify-send "⏰ 1 hora restante" "Te queda 1 hora de uso." -t 10000 -u normal 2>/dev/null || true
                ;;
            30) 
                DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u cliente)/bus" \
                    notify-send "⏰ 30 minutos" "Te quedan 30 minutos." -t 10000 -u critical 2>/dev/null || true
                ;;
            15) 
                DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u cliente)/bus" \
                    notify-send "🚨 15 minutos" "¡Solo 15 minutos!" -t 15000 -u critical 2>/dev/null || true
                ;;
            5) 
                DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u cliente)/bus" \
                    notify-send "🚨 5 MINUTOS" "¡Últimos 5 minutos!" -t 20000 -u critical 2>/dev/null || true
                ;;
        esac
        
        # Mostrar tiempo cada 10 minutos
        if [ $((MINUTOS_USADOS % 10)) -eq 0 ]; then
            echo "⏱️  Tiempo restante: $((MINUTOS_RESTANTES / 60))h $((MINUTOS_RESTANTES % 60))m"
        fi
        
        sleep 60
    done
}

# Configurar permisos iniciales
touch "$ARCHIVO_TIEMPO" 2>/dev/null || true
chmod 666 "$ARCHIVO_TIEMPO" 2>/dev/null || true

# Ejecutar
main
SCRIPTEOF

chmod +x /usr/local/bin/control_tiempo.sh
echo -e "${GREEN}✅ Script principal instalado${NC}"
echo ""

# Configurar sudoers
echo -e "${GREEN}🔐 Paso 5: Configurando permisos sudo...${NC}"
cat > /etc/sudoers.d/cliente << EOF
# Permisos para el sistema de control de ciber café
cliente ALL=(ALL) NOPASSWD: /usr/bin/pkill, /bin/chmod, /usr/bin/touch
cliente ALL=(ALL) NOPASSWD: /usr/bin/shutdown, /usr/bin/systemctl poweroff, /usr/bin/systemctl reboot
EOF
chmod 440 /etc/sudoers.d/cliente
echo -e "${GREEN}✅ Permisos sudo configurados${NC}"
echo ""

# Configurar auto-inicio en GNOME
echo -e "${GREEN}🚀 Paso 6: Configurando auto-inicio en GNOME...${NC}"

# Crear directorio de autostart si no existe
mkdir -p /home/cliente/.config/autostart

# Crear archivo .desktop para autostart
cat > /home/cliente/.config/autostart/control_tiempo.desktop << EOF
[Desktop Entry]
Type=Application
Name=CiberCafé - Control de Tiempo
Comment=Sistema de control de tiempo para ciber café
Exec=/usr/local/bin/control_tiempo.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=true
Categories=System;
EOF

chown -R cliente:cliente /home/cliente/.config
chmod +x /home/cliente/.config/autostart/control_tiempo.desktop
echo -e "${GREEN}✅ Auto-inicio configurado${NC}"
echo ""

# Deshabilitar terminales virtuales
echo -e "${GREEN}🔒 Paso 7: Deshabilitando escapes del sistema...${NC}"

# Crear configuración de systemd-logind
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/disable-vt.conf << EOF
[Login]
NAutoVTs=0
ReserveVT=0
EOF

# Deshabilitar Ctrl+Alt+Supr
systemctl mask ctrl-alt-del.target 2>/dev/null || true

# Deshabilitar cambio de usuario rápido
if [ -f /etc/gdm/custom.conf ]; then
    sed -i 's/#EnableUserSwitch=false/EnableUserSwitch=false/' /etc/gdm/custom.conf
fi

echo -e "${GREEN}✅ Escapes deshabilitados${NC}"
echo ""

# Crear script de monitoreo para admin
echo -e "${GREEN}📊 Paso 8: Instalando herramientas de administración...${NC}"

cat > /usr/local/bin/ciber_monitor.sh << 'MONEOF'
#!/bin/bash
# Herramienta de monitoreo para administradores

FECHA_ACTUAL=$(date +%Y%m%d)
ARCHIVO_TIEMPO="/var/tmp/tiempo_sesion_cliente.dat"
ARCHIVO_BLOQUEO="/var/tmp/bloqueo_cliente.lock"

clear
echo "═══════════════════════════════════════════"
echo "  📊 MONITOR DE CIBER CAFÉ - $(date '+%H:%M:%S')"
echo "═══════════════════════════════════════════"

# Estado del sistema
if [ -f "$ARCHIVO_BLOQUEO" ]; then
    echo "🔴 Estado: BLOQUEADO"
else
    echo "🟢 Estado: ACTIVO"
fi

# Tiempo
if [ -f "$ARCHIVO_TIEMPO" ]; then
    FECHA_GUARDADA=$(cut -d':' -f1 "$ARCHIVO_TIEMPO")
    MINUTOS_USADOS=$(cut -d':' -f2 "$ARCHIVO_TIEMPO")
    
    if [ "$FECHA_GUARDADA" == "$FECHA_ACTUAL" ]; then
        echo "⏱️  Tiempo usado: $((MINUTOS_USADOS / 60))h $((MINUTOS_USADOS % 60))m"
        echo "⏱️  Tiempo restante: $(((150 - MINUTOS_USADOS) / 60))h $(((150 - MINUTOS_USADOS) % 60))m"
    fi
fi

# Sesión activa
if who | grep -q cliente; then
    echo "👤 Usuario 'cliente' conectado"
    echo "🖥️  Terminal: $(who | grep cliente | awk '{print $2}')"
fi

echo "═══════════════════════════════════════════"
echo ""
echo "Comandos útiles:"
echo "  pkill -9 -u cliente         # Cerrar sesión del cliente"
echo "  rm /var/tmp/bloqueo_cliente.lock  # Desbloquear"
echo "  rm /var/tmp/tiempo_sesion_cliente.dat  # Reiniciar tiempo"
MONEOF

chmod +x /usr/local/bin/ciber_monitor.sh

# Crear alias para el monitor
echo "alias ciber='sudo /usr/local/bin/ciber_monitor.sh'" >> /etc/bash.bashrc

echo -e "${GREEN}✅ Herramientas de administración instaladas${NC}"
echo ""

# Crear servicio systemd para anti-escape
echo -e "${GREEN}🛡️  Paso 9: Instalando protección anti-escape...${NC}"

cat > /etc/systemd/system/ciber-anti-escape.service << 'SERVEOF'
[Unit]
Description=Ciber Café - Anti-Escape Protection
After=graphical.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/anti_escape.sh
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
SERVEOF

cat > /usr/local/bin/anti_escape.sh << 'ANTIEOF'
#!/bin/bash
# Monitoreo continuo para prevenir escapes

while true; do
    # Si el sistema está bloqueado
    if [ -f "/var/tmp/bloqueo_cliente.lock" ]; then
        
        # Matar cualquier terminal nueva
        pkill -9 -u cliente gnome-terminal 2>/dev/null || true
        pkill -9 -u cliente xterm 2>/dev/null || true
        pkill -9 -u cliente konsole 2>/dev/null || true
        pkill -9 -u cliente alacritty 2>/dev/null || true
        pkill -9 -u cliente kitty 2>/dev/null || true
        
        # Matar gestores de archivos
        pkill -9 -u cliente nautilus 2>/dev/null || true
        pkill -9 -u cliente thunar 2>/dev/null || true
        
        # Matar monitores de sistema
        pkill -9 -u cliente gnome-system-monitor 2>/dev/null || true
        pkill -9 -u cliente htop 2>/dev/null || true
        
        # Asegurar que el video sigue corriendo
        if ! pgrep -f "mpv.*cierre" > /dev/null && ! pgrep -f "vlc.*cierre" > /dev/null; then
            # Reiniciar video
            if [ -d "/home/cliente/Videos/cierre" ]; then
                VIDEO=$(find "/home/cliente/Videos/cierre" -type f -name "*.mp4" | shuf -n 1)
                if [ -n "$VIDEO" ]; then
                    sudo -u cliente mpv --fs --no-input-default-bindings --no-terminal --really-quiet "$VIDEO" 2>/dev/null &
                fi
            fi
        fi
    fi
    
    sleep 2
done
ANTIEOF

chmod +x /usr/local/bin/anti_escape.sh
systemctl daemon-reload
systemctl enable ciber-anti-escape.service
systemctl start ciber-anti-escape.service

echo -e "${GREEN}✅ Protección anti-escape instalada${NC}"
echo ""

# Mensaje final
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ INSTALACIÓN COMPLETADA EXITOSAMENTE${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 RESUMEN DE LA INSTALACIÓN:${NC}"
echo -e "  ${GREEN}✔${NC} Dependencias instaladas"
echo -e "  ${GREEN}✔${NC} Usuario 'cliente' configurado"
echo -e "  ${GREEN}✔${NC} Script de control: /usr/local/bin/control_tiempo.sh"
echo -e "  ${GREEN}✔${NC} Monitor de admin: /usr/local/bin/ciber_monitor.sh"
echo -e "  ${GREEN}✔${NC} Anti-escape: /usr/local/bin/anti_escape.sh"
echo -e "  ${GREEN}✔${NC} Servicio systemd: ciber-anti-escape.service"
echo -e "  ${GREEN}✔${NC} Log del sistema: /var/log/ciber_control.log"
echo ""
echo -e "${YELLOW}⚠️  ACCIONES PENDIENTES:${NC}"
echo -e "  1. ${RED}REINICIA EL SISTEMA${NC} para aplicar todos los cambios"
echo -e "  2. Agrega videos MP4 en: ${GREEN}/home/cliente/Videos/cierre/${NC}"
echo -e "  3. Inicia sesión como 'cliente' para probar"
echo ""
echo -e "${YELLOW}📖 COMANDOS ÚTILES:${NC}"
echo -e "  ${GREEN}sudo ciber_monitor.sh${NC}     # Ver estado del sistema"
echo -e "  ${GREEN}sudo pkill -9 -u cliente${NC}  # Forzar cierre de sesión"
echo -e "  ${GREEN}sudo systemctl status ciber-anti-escape${NC}  # Ver anti-escape"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
