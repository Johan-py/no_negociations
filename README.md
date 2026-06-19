#!/bin/bash
# install_ciber_control.sh

echo "🔧 Instalando Sistema de Control de Ciber Café v2.0..."

# Crear directorios necesarios
sudo mkdir -p /var/tmp
sudo mkdir -p /var/log

# Configurar permisos
sudo touch /var/log/ciber_control.log
sudo chmod 666 /var/log/ciber_control.log

# Instalar scripts
sudo cp control_tiempo.sh /usr/local/bin/
sudo cp iniciar_sesion.sh /usr/local/bin/
sudo cp monitor_tiempo.sh /usr/local/bin/

sudo chmod +x /usr/local/bin/control_tiempo.sh
sudo chmod +x /usr/local/bin/iniciar_sesion.sh
sudo chmod +x /usr/local/bin/monitor_tiempo.sh

# Configurar sudoers para comandos específicos
echo "cliente ALL=(ALL) NOPASSWD: /sbin/shutdown, /usr/bin/pkill, /bin/chmod, /usr/bin/touch" | sudo tee /etc/sudoers.d/cliente

# Agregar al inicio automático
sudo -u cliente mkdir -p /home/cliente/.config/autostart
cat > /tmp/control_tiempo.desktop << EOF
[Desktop Entry]
Type=Application
Name=Control de Tiempo
Exec=/usr/local/bin/control_tiempo.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

sudo mv /tmp/control_tiempo.desktop /home/cliente/.config/autostart/
sudo chown cliente:cliente /home/cliente/.config/autostart/control_tiempo.desktop

echo "✅ Instalación completada."
echo ""
echo "📋 Resumen:"
echo "  - Script principal: /usr/local/bin/control_tiempo.sh"
echo "  - Reiniciar sesión: /usr/local/bin/iniciar_sesion.sh"
echo "  - Monitoreo admin: /usr/local/bin/monitor_tiempo.sh"
echo "  - Log del sistema: /var/log/ciber_control.log"
echo "  - Datos de sesión: /var/tmp/tiempo_sesion_cliente.dat"
