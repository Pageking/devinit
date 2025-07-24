#!/bin/bash

CONFIG_PATH="$HOME/.config/devinit/config.json"

# === CONFIGURATION ===
SERVER=$(jq -r '.servers.server_1.server' "$CONFIG_PATH")
IP=$(jq -r '.servers.server_1.ip' "$CONFIG_PATH")
DB_PREFIX=$(jq -r '.wp.db_prefix' "$CONFIG_PATH")
WP_ADMIN=$(jq -r '.wp.admin_username' "$CONFIG_PATH")
WP_ADMIN_PASS=$(jq -r '.wp.admin_password' "$CONFIG_PATH")
WP_ADMIN_EMAIL=$(jq -r '.wp.admin_email' "$CONFIG_PATH")

DOMAIN=$(jq -r '.servers.server_1.domain' "$CONFIG_PATH")
USERNAME=$(jq -r '.servers.server_1.user' "$CONFIG_PATH")
PASSWORD=$(jq -r '.servers.server_1.password' "$CONFIG_PATH")
WWW_ROOT=$(jq -r '.servers.server_1.www_root' "$CONFIG_PATH")

read -p "Enter the new Plesk project name: " PROJECT_NAME
DB_NAME="${DB_PREFIX}_${PROJECT_NAME}"
DB_USER="${DB_NAME}_user"
DB_PASS="$(openssl rand -base64 12)"

echo "Creating domain on Plesk with project name '$PROJECT_NAME'"

ssh "$SERVER" bash <<EOF
# Creating Domain
plesk bin domain --create ${PROJECT_NAME}.${DOMAIN} -ip $IP -hosting true -www-root $WWW_ROOT -login $USERNAME -passwd $PASSWORD

# Create database
plesk bin database --create $DB_NAME -domain ${PROJECT_NAME}.${DOMAIN} -type mysql -passwd $DB_PASS -login $DB_USER

# Install WP
plesk ext wp-toolkit --install \
    -domain-name ${PROJECT_NAME}.${DOMAIN} \
    -installation-path /$WWW_ROOT \
    -admin-email $WP_ADMIN_EMAIL \
    -admin-user $WP_ADMIN \
    -admin-password $WP_ADMIN_PASS \
    -db-name $DB_NAME \
    -db-user $DB_USER \
    -db-password $DB_PASS
	
EOF

echo "✅ Domain created"