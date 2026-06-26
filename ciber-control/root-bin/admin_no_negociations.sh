#!/bin/bash
# admin_no_negociations.sh – Panel de administracion del sistema de control de sesion.
# Uso: sudo ./admin_no_negociations.sh [usuario]
#   Si no se especifica usuario, opera sobre el usuario actual (via SUDO_USER).

set -u

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Este script debe ejecutarse como root.${NC}"
    echo -e "${YELLOW}Uso: sudo $0 [usuario]${NC}"
    exit 1
fi

USUARIO="${1:-${SUDO_USER:-}}"
if [ -z "$USUARIO" ]; then
    echo -e "${RED}Error: No se pudo determinar el usuario. Especificalo como argumento.${NC}"
    echo -e "${YELLOW}Uso: sudo $0 <usuario>${NC}"
    exit 1
fi

if ! id "$USUARIO" &>/dev/null; then
    echo -e "${RED}Error: El usuario '$USUARIO' no existe.${NC}"
    exit 1
fi

USER_UID=$(id -u "$USUARIO")
ARCHIVO_TIEMPO="/var/tmp/tiempo_sesion_${USUARIO}.dat"
ARCHIVO_BLOQUEO="/var/tmp/bloqueo_${USUARIO}.lock"
LOG="/var/log/ciber_control.log"
TIEMPO_LIMITE=150

mostrar_estado() {
    clear
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Panel de Control - No Negociations${NC}"
    echo -e "${BLUE}  Usuario: ${USUARIO}${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""

    # ─── Servicio de sistema ───
    echo -e "${GREEN}SERVICIO DE SISTEMA (ciber-lockdown):${NC}"
    SYS_ACTIVE=$(systemctl is-active ciber-lockdown.service 2>/dev/null)
    SYS_ENABLED=$(systemctl is-enabled ciber-lockdown.service 2>/dev/null)
    if [ "$SYS_ACTIVE" = "active" ]; then
        echo -e "  Estado: ${GREEN}● activo${NC}  (enabled: $SYS_ENABLED)"
    else
        echo -e "  Estado: ${RED}● $SYS_ACTIVE${NC}  (enabled: $SYS_ENABLED)"
    fi

    # ─── Servicio de usuario ───
    echo -e "${GREEN}SERVICIO DE USUARIO (session-timer):${NC}"
    USR_ACTIVE=$(sudo -u "$USUARIO" env XDG_RUNTIME_DIR="/run/user/${USER_UID}" systemctl --user is-active session-timer.service 2>/dev/null)
    USR_ENABLED=$(sudo -u "$USUARIO" env XDG_RUNTIME_DIR="/run/user/${USER_UID}" systemctl --user is-enabled session-timer.service 2>/dev/null)
    if [ "$USR_ACTIVE" = "active" ]; then
        echo -e "  Estado: ${GREEN}● activo${NC}  (enabled: $USR_ENABLED)"
    else
        echo -e "  Estado: ${RED}● $USR_ACTIVE${NC}  (enabled: $USR_ENABLED)"
    fi

    # ─── Tiempo de sesion ───
    echo -e "${GREEN}TIEMPO DE SESION:${NC}"
    FECHA_ACTUAL=$(date +%Y%m%d)

    if [ -f "$ARCHIVO_BLOQUEO" ]; then
        FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO" 2>/dev/null)
        if [ "$FECHA_BLOQUEO" = "$FECHA_ACTUAL" ]; then
            echo -e "  ${RED}⚠  BLOQUEADO - Limite diario alcanzado${NC}"
        else
            echo -e "  ${YELLOW}⚠  Lock de fecha anterior detectado (${FECHA_BLOQUEO})${NC}"
        fi
    fi

    if [ -f "$ARCHIVO_TIEMPO" ]; then
        FECHA_GUARDADA=$(cut -d':' -f1 "$ARCHIVO_TIEMPO" 2>/dev/null)
        MINUTOS_USADOS=$(cut -d':' -f2 "$ARCHIVO_TIEMPO" 2>/dev/null)
        MINUTOS_USADOS=${MINUTOS_USADOS:-0}
        if [ "$FECHA_GUARDADA" = "$FECHA_ACTUAL" ]; then
            MINUTOS_RESTANTES=$((TIEMPO_LIMITE - MINUTOS_USADOS))
            if [ "$MINUTOS_RESTANTES" -lt 0 ]; then
                MINUTOS_RESTANTES=0
            fi
            PORCENTAJE=$((MINUTOS_USADOS * 100 / TIEMPO_LIMITE))
            echo -e "  Usados:   ${MINUTOS_USADOS} min  (${PORCENTAJE}% del limite)"
            echo -e "  Restante: ${YELLOW}${MINUTOS_RESTANTES} min${NC}"
            # Barra de progreso
            BARRA_LARGA=30
            LLENOS=$((PORCENTAJE * BARRA_LARGA / 100))
            VACIOS=$((BARRA_LARGA - LLENOS))
            if [ "$PORCENTAJE" -ge 90 ]; then
                COLOR_BARRA=$RED
            elif [ "$PORCENTAJE" -ge 60 ]; then
                COLOR_BARRA=$YELLOW
            else
                COLOR_BARRA=$GREEN
            fi
            BARRA="["
            for ((i=0; i<LLENOS; i++)); do BARRA+="█"; done
            for ((i=0; i<VACIOS; i++)); do BARRA+="░"; done
            BARRA+="]"
            echo -e "  ${COLOR_BARRA}${BARRA}${NC}"
        else
            echo -e "  ${GREEN}Sin datos de hoy. Sesion no iniciada o reiniciada.${NC}"
        fi
    else
        echo -e "  ${GREEN}Sin datos de hoy. Sesion no iniciada.${NC}"
    fi

    # ─── Lock file ───
    echo -e "${GREEN}ARCHIVOS DE CONTROL:${NC}"
    if [ -f "$ARCHIVO_BLOQUEO" ]; then
        echo -e "  Lock:  ${RED}${ARCHIVO_BLOQUEO}${NC} $(cat "$ARCHIVO_BLOQUEO" 2>/dev/null)"
    else
        echo -e "  Lock:  ${GREEN}No existe${NC}"
    fi
    if [ -f "$ARCHIVO_TIEMPO" ]; then
        echo -e "  Timer: ${ARCHIVO_TIEMPO} ($(cat "$ARCHIVO_TIEMPO" 2>/dev/null))"
    else
        echo -e "  Timer: No existe"
    fi

    # ─── Log ───
    echo -e "${GREEN}ULTIMOS EVENTOS (log):${NC}"
    grep "$USUARIO" "$LOG" 2>/dev/null | tail -5 | while read -r line; do
        echo "  $line"
    done
    echo ""
}

mostrar_menu() {
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}1)${NC} Reiniciar tiempo de sesion"
    echo -e "  ${GREEN}2)${NC} Bloquear sesion manualmente (lockdown inmediato)"
    echo -e "  ${GREEN}3)${NC} Desbloquear sesion (eliminar lock)"
    echo -e "  ${GREEN}4)${NC} Refrescar estado"
    echo -e "  ${GREEN}5)${NC} Ver log completo"
    echo -e "  ${GREEN}q)${NC} Salir"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -n -e "${YELLOW}Selecciona una opcion: ${NC}"
}

while true; do
    mostrar_estado
    mostrar_menu
    read -r OPCION
    case $OPCION in
        1)
            echo -e "${YELLOW}Reiniciando tiempo de sesion para ${USUARIO}...${NC}"
            /usr/local/bin/reset_sesion.sh "$USUARIO"
            echo -e "${GREEN}Hecho. Presiona Enter para continuar.${NC}"
            read -r
            ;;
        2)
            echo -e "${RED}Bloqueando sesion de ${USUARIO} inmediatamente...${NC}"
            echo "$(date +%Y%m%d)" > "$ARCHIVO_BLOQUEO"
            logger -t "admin[$$]" "Bloqueo manual para $USUARIO"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ADMIN: Bloqueo manual para $USUARIO" >> "$LOG"
            systemctl restart ciber-lockdown.service
            echo -e "${GREEN}Lockdown iniciado. Presiona Enter para continuar.${NC}"
            read -r
            ;;
        3)
            echo -e "${YELLOW}Desbloqueando sesion de ${USUARIO}...${NC}"
            rm -f "$ARCHIVO_BLOQUEO"
            logger -t "admin[$$]" "Desbloqueo manual para $USUARIO"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ADMIN: Desbloqueo manual para $USUARIO" >> "$LOG"
            echo -e "${GREEN}Sesion desbloqueada. Presiona Enter para continuar.${NC}"
            read -r
            ;;
        4)
            continue
            ;;
        5)
            clear
            echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
            echo -e "${BLUE}  Log completo${NC}"
            echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
            if [ -f "$LOG" ]; then
                cat "$LOG"
            else
                echo "No existe el archivo de log."
            fi
            echo ""
            echo -e "${YELLOW}Presiona Enter para volver al menu.${NC}"
            read -r
            ;;
        q|Q)
            echo -e "${GREEN}Saliendo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opcion invalida.${NC}"
            sleep 1
            ;;
    esac
done
