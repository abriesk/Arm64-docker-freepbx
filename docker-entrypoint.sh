#!/bin/bash
set -e

echo "=== FreePBX Container Starting ==="

# Initialize config directories if empty (first run with volumes)
if [ ! -f "/etc/asterisk/asterisk.conf" ]; then
    echo "Initializing /etc/asterisk from defaults..."
    cp -a /etc/asterisk.default/* /etc/asterisk/
    chown -R asterisk:asterisk /etc/asterisk
fi

if [ ! -d "/var/lib/asterisk/sounds" ]; then
    echo "Initializing /var/lib/asterisk from defaults..."
    cp -a /var/lib/asterisk.default/* /var/lib/asterisk/
    chown -R asterisk:asterisk /var/lib/asterisk
fi

# Wait for MariaDB
echo "Waiting for Database..."
while ! mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" --silent 2>/dev/null; do
    sleep 1
done
echo "Database ready."
# Start cron daemon
echo "Starting cron..."
cron
# Start Asterisk (FreePBX installer needs it running)
echo "Starting Asterisk..."
/usr/sbin/asterisk -U asterisk -G asterisk

# Wait for Asterisk to be responsive
echo "Waiting for Asterisk CLI..."
for i in {1..30}; do
    if asterisk -rx "core show version" &>/dev/null; then
        echo "Asterisk ready."
        break
    fi
    sleep 1
done

# Install FreePBX if not already installed
if [ ! -f "/etc/freepbx.conf" ]; then
    echo "Installing FreePBX..."
    
    cd /usr/src/freepbx
    
    ./install -n \
        --dbhost=$DB_HOST \
        --dbuser=$DB_USER \
        --dbpass=$DB_PASS \
        --dbname=$DB_NAME \
        --user=asterisk \
        --group=asterisk \
        --webroot=/var/www/html

    echo "Installing FreePBX modules..."
    fwconsole ma installall || true
    fwconsole reload || true
    
    echo "FreePBX installation complete."
else
    echo "FreePBX already installed."
    fwconsole reload || true
fi

# Start Apache in foreground
echo "Starting Apache..."
rm -f /var/run/apache2/apache2.pid
exec /usr/sbin/apache2ctl -D FOREGROUND