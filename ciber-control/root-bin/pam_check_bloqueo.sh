#!/bin/bash
# pam_check_bloqueo.sh – PAM hook: if user's lock file exists for today,
# restart the lockdown service to immediately re-apply the block.
# Called by pam_exec.so on session open.

set -u

USUARIO="${PAM_USER:-}"
if [ -z "$USUARIO" ]; then
    exit 0
fi

ARCHIVO_BLOQUEO="/var/tmp/bloqueo_${USUARIO}.lock"
FECHA_ACTUAL=$(date +%Y%m%d)

if [ -f "$ARCHIVO_BLOQUEO" ]; then
    FECHA_BLOQUEO=$(cat "$ARCHIVO_BLOQUEO" 2>/dev/null)
    if [ "$FECHA_BLOQUEO" = "$FECHA_ACTUAL" ]; then
        systemctl restart ciber-lockdown.service 2>/dev/null
        # Brief pause to let lockdown start
        sleep 1
    fi
fi

exit 0
