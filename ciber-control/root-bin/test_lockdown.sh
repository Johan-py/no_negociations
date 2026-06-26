#!/bin/bash
# test_lockdown.sh – Simula el lockdown completo al alcanzar el limite de tiempo.
# Uso: sudo ./test_lockdown.sh <usuario> [--no-poweroff]
#   --no-poweroff  Skips the actual shutdown (for testing).

set -u

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Debe ejecutarse como root.${NC}"
    echo -e "${YELLOW}Uso: sudo $0 <usuario> [--no-poweroff]${NC}"
    exit 1
fi

USUARIO="${1:-}"
if [ -z "$USUARIO" ]; then
    echo -e "${RED}Error: Debe especificar el nombre de usuario.${NC}"
    echo -e "${YELLOW}Uso: sudo $0 <usuario> [--no-poweroff]${NC}"
    exit 1
fi

NO_POWEROFF=false
if [ "${2:-}" = "--no-poweroff" ]; then
    NO_POWEROFF=true
fi

USER_UID=$(id -u "$USUARIO")
CARPETA_VIDEOS="/home/${USUARIO}/Videos/cierre"
LOG="/var/log/ciber_control.log"
XDG_RT="/run/user/${USER_UID}"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST - Simulacion de Lockdown${NC}"
echo -e "${BLUE}  Usuario: ${USUARIO}${NC}"
if $NO_POWEROFF; then
    echo -e "${YELLOW}  Modo: --no-poweroff (no se apagara el sistema)${NC}"
else
    echo -e "${RED}  ⚠  EL SISTEMA SE APAGARA AL FINALIZAR${NC}"
fi
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - TEST: $*" | tee -a "$LOG"
}

# ─── Paso 1: Crear lock file ───
echo -e "${YELLOW}[1/4] Creando lock file...${NC}"
echo "$(date +%Y%m%d)" > "/var/tmp/bloqueo_${USUARIO}.lock"
log "Lock file creado para ${USUARIO}"
echo -e "${GREEN}  OK${NC}"
sleep 1

# ─── Paso 2: Reproducir video ───
echo -e "${YELLOW}[2/4] Buscando y reproduciendo video de cierre...${NC}"
VIDEO=""
if [ -d "$CARPETA_VIDEOS" ]; then
    VIDEO=$(find "$CARPETA_VIDEOS" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) 2>/dev/null | shuf -n 1)
fi

if [ -n "$VIDEO" ] && [ -f "$VIDEO" ]; then
    log "Reproduciendo $(basename "$VIDEO") como $USUARIO"
    echo -e "${GREEN}  Video: $(basename "$VIDEO")${NC}"
    echo -e "${YELLOW}  Reproduciendo en 3 segundos...${NC}"
    sleep 3
    sudo -u "$USUARIO" env \
        XDG_RUNTIME_DIR="$XDG_RT" \
        WAYLAND_DISPLAY="wayland-0" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RT/bus" \
        mpv --fs --no-input-default-bindings --no-terminal "$VIDEO" 2>/dev/null || \
    echo -e "${RED}  mpv fallo. Probando como root...${NC}" && \
    mpv --fs --no-input-default-bindings --no-terminal "$VIDEO" 2>/dev/null || \
    echo -e "${RED}  Error: No se pudo reproducir el video.${NC}"
else
    echo -e "${RED}  No hay videos en $CARPETA_VIDEOS${NC}"
    log "No se encontraron videos"
    sleep 2
fi

# ─── Paso 3: Matar procesos del usuario ───
echo -e "${YELLOW}[3/4] Matando procesos de ${USUARIO}...${NC}"
log "Matando procesos de ${USUARIO}"
pkill -9 -u "$USUARIO" 2>/dev/null || true
sleep 2
echo -e "${GREEN}  OK${NC}"

# ─── Paso 4: Apagar ───
echo -e "${YELLOW}[4/4] Apagando sistema...${NC}"
if $NO_POWEROFF; then
    log "TEST: Sistema NO apagado (modo --no-poweroff)"
    echo -e "${GREEN}  [SKIP] --no-poweroff activo${NC}"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Simulacion completada. Sistema no se apago.${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Lock file creado en /var/tmp/bloqueo_${USUARIO}.lock"
    echo -e "  Para desbloquear: sudo rm -f /var/tmp/bloqueo_${USUARIO}.lock"
    echo -e "  Para reiniciar tiempo: sudo /usr/local/bin/reset_sesion.sh ${USUARIO}"
else
    log "TEST: Apagando sistema"
    echo -e "${RED}  APAGANDO EN 5 SEGUNDOS... (Ctrl+C para cancelar)${NC}"
    sleep 5
    systemctl poweroff || shutdown -h now
fi
