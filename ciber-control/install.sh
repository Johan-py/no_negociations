#!/bin/bash
# install.sh – Instala el sistema de control de tiempo de sesion.
# Uso: sudo install.sh <nombre_de_usuario>

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# ─── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Instalando Sistema de Control de Tiempo de Sesion${NC}"
echo -e "${BLUE}  Archivo + GNOME (Wayland)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"

# ─── Validaciones previas ─────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Este script debe ejecutarse como root.${NC}"
    echo -e "${YELLOW}Uso: sudo $0 <usuario>${NC}"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo -e "${RED}Error: Debe especificar el nombre de usuario.${NC}"
    echo -e "${YELLOW}Uso: sudo $0 <usuario>${NC}"
    exit 1
fi

USERNAME="$1"

if ! id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Error: El usuario '$USERNAME' no existe.${NC}"
    exit 1
fi

if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}Error: Sistema no es Arch Linux.${NC}"
    exit 1
fi

# ─── Dependencias ─────────────────────────────────────────────────────────────
echo -e "${GREEN}Paso 1: Instalando dependencias...${NC}"
pacman -S --noconfirm --needed \
    inotify-tools \
    mpv \
    vlc \
    zenity \
    libnotify \
    procps-ng || {
    echo -e "${RED}Error: Fallo la instalacion de dependencias.${NC}"
    exit 1
}

# Verificar que los binarios necesarios existen
for cmd in mpv zenity notify-send inotifywait pkill; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${YELLOW}Advertencia: $cmd no encontrado. Algunas funciones pueden no estar disponibles.${NC}"
    fi
done

echo -e "${GREEN}Dependencias instaladas${NC}"

# ─── Crear carpeta de videos ─────────────────────────────────────────────────
echo -e "${GREEN}Paso 2: Creando carpeta de videos de cierre...${NC}"
mkdir -p "/home/${USERNAME}/Videos/cierre"
chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/Videos/cierre"
echo -e "${GREEN}Carpeta /home/${USERNAME}/Videos/cierre creada.${NC}"

# ─── Copiar scripts ──────────────────────────────────────────────────────────
echo -e "${GREEN}Paso 3: Instalando scripts...${NC}"
cp "$SCRIPT_DIR/root-bin/lockdown_watcher.sh" /usr/local/bin/
cp "$SCRIPT_DIR/root-bin/pam_check_bloqueo.sh" /usr/local/bin/
cp "$SCRIPT_DIR/root-bin/reset_sesion.sh" /usr/local/bin/
cp "$SCRIPT_DIR/user-bin/session_timer.sh" /usr/local/bin/

chmod 755 /usr/local/bin/lockdown_watcher.sh
chmod 755 /usr/local/bin/pam_check_bloqueo.sh
chmod 755 /usr/local/bin/reset_sesion.sh
chmod 755 /usr/local/bin/session_timer.sh

# ─── Servicio systemd (sistema) ──────────────────────────────────────────────
echo -e "${GREEN}Paso 4: Instalando servicio de sistema (ciber-lockdown)...${NC}"
sed "s/<USER>/${USERNAME}/g" "$SCRIPT_DIR/systemd-system/ciber-lockdown.service" > /etc/systemd/system/ciber-lockdown.service

systemctl daemon-reload
systemctl enable ciber-lockdown.service
systemctl start ciber-lockdown.service

# ─── Servicio systemd (usuario) ──────────────────────────────────────────────
echo -e "${GREEN}Paso 5: Instalando servicio de usuario (session-timer)...${NC}"
mkdir -p /usr/lib/systemd/user/
cp "$SCRIPT_DIR/systemd-user/session-timer.service" /usr/lib/systemd/user/

USER_UID=$(id -u "$USERNAME")
XDG_RUNTIME_DIR="/run/user/${USER_UID}"

loginctl enable-linger "$USERNAME" 2>/dev/null || true

mkdir -p "$XDG_RUNTIME_DIR"
chown "$USERNAME":"$USERNAME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

sudo -u "$USERNAME" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user daemon-reload
sudo -u "$USERNAME" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user enable session-timer.service

if sudo -u "$USERNAME" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user is-system-running >/dev/null 2>&1; then
    sudo -u "$USERNAME" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user start session-timer.service
else
    echo -e "${YELLOW}Usuario no tiene sesion activa. El servicio iniciara al próximo login.${NC}"
fi

# ─── Hook PAM ─────────────────────────────────────────────────────────────────
echo -e "${GREEN}Paso 6: Agregando hook PAM...${NC}"
PAM_FILE="/etc/pam.d/system-login"

if [ ! -f "$PAM_FILE" ]; then
    echo -e "${YELLOW}Advertencia: $PAM_FILE no existe. Buscando alternativa...${NC}"
    PAM_FILE="/etc/pam.d/system-auth"
    if [ ! -f "$PAM_FILE" ]; then
        echo -e "${YELLOW}Advertencia: No se encontro archivo PAM adecuado. El hook debera agregarse manualmente.${NC}"
        echo -e "${YELLOW}Linea a agregar: ${NC}"
        echo -e "    session   optional   pam_exec.so   /usr/local/bin/pam_check_bloqueo.sh"
    fi
fi

LINE="session   optional   pam_exec.so   /usr/local/bin/pam_check_bloqueo.sh"

if grep -q "pam_check_bloqueo.sh" "$PAM_FILE" 2>/dev/null; then
    echo -e "${YELLOW}Hook PAM ya existe en $PAM_FILE, omitiendo.${NC}"
else
    {
        echo ""
        echo "# Ciber-control: check session lock on login"
        echo "$LINE"
    } >> "$PAM_FILE"
    echo -e "${GREEN}Hook PAM agregado a $PAM_FILE.${NC}"
fi

# ─── Log ──────────────────────────────────────────────────────────────────────
echo -e "${GREEN}Paso 7: Creando archivo de log...${NC}"
touch /var/log/ciber_control.log
chmod 644 /var/log/ciber_control.log

# ─── Resumen ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Instalacion completada para usuario '$USERNAME'${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Servicios:${NC}"
echo -e "    systemctl status ciber-lockdown.service"
echo -e "    sudo -u $USERNAME env XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user status session-timer.service"
echo ""
echo -e "  ${GREEN}Log:${NC}"
echo -e "    tail -f /var/log/ciber_control.log"
echo ""
echo -e "  ${YELLOW}Videos de cierre:${NC}"
echo -e "    Pon archivos .mp4/.mkv/.webm en /home/${USERNAME}/Videos/cierre/"
echo ""
