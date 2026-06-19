#!/bin/bash
# Desinstalar el sistema de control

echo "🗑️  Desinstalando Sistema de Control de Ciber Café..."

# Detener y deshabilitar servicios
systemctl stop ciber-anti-escape.service 2>/dev/null
systemctl disable ciber-anti-escape.service 2>/dev/null
rm -f /etc/systemd/system/ciber-anti-escape.service

# Eliminar scripts
rm -f /usr/local/bin/control_tiempo.sh
rm -f /usr/local/bin/anti_escape.sh
rm -f /usr/local/bin/ciber_monitor.sh

# Eliminar configuraciones
rm -f /etc/sudoers.d/cliente
rm -f /etc/systemd/logind.conf.d/disable-vt.conf
rm -f /home/cliente/.config/autostart/control_tiempo.desktop

# Eliminar archivos de estado
rm -f /var/tmp/tiempo_sesion_cliente.dat
rm -f /var/tmp/bloqueo_cliente.lock
rm -f /var/log/ciber_control.log

# Restaurar bashrc del cliente
sed -i '/control_tiempo.sh/d' /home/cliente/.bashrc

# Reactivar Ctrl+Alt+Supr
systemctl unmask ctrl-alt-del.target 2>/dev/null

systemctl daemon-reload

echo "✅ Sistema desinstalado. Reinicia para completar."
