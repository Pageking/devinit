#!/bin/bash

# === CONFIGURATION ===
SERVER="root@136.144.237.148"
IP="136.144.237.148"
DB_PREFIX="wp"
WP_ADMIN="admin"
WP_ADMIN_PASS="Pageking123!"
WP_ADMIN_EMAIL="wouter@pageking.nl"

# IDEA: de gebruiker keuze laten maken tussen de pk1 en pk2
DOMAIN="pk1.pageking.dev"
USERNAME="pageking"
PASSWORD="Pageking123!"
WWW_ROOT="httpdocs"

read -p "Enter the new Plesk project name: " PROJECT_NAME
DB_NAME="${DB_PREFIX}_${PROJECT_NAME}"
DB_USER="${DB_NAME}_user"
DB_PASS="$(openssl rand -base64 12)"

echo "Creating domain on PK1 with project name '$PROJECT_NAME'"

ssh "$SERVER" bash <<EOF
# Creating Domain
plesk bin domain --create ${PROJECT_NAME}.pk1.pageking.dev -ip $IP -hosting true -www-root $WWW_ROOT -login $USERNAME -passwd $PASSWORD

# Create database
plesk bin database --create $DB_NAME -domain ${PROJECT_NAME}.pk1.pageking.dev -type mysql -passwd $DB_PASS -login $DB_USER

# Install WP
plesk ext wp-toolkit --install \
    -domain-name ${PROJECT_NAME}.pk1.pageking.dev \
    -installation-path /$WWW_ROOT \
    -admin-email $WP_ADMIN_EMAIL \
    -admin-user $WP_ADMIN \
    -admin-password $WP_ADMIN_PASS \
    -db-name $DB_NAME \
    -db-user $DB_USER \
    -db-password $DB_PASS

# TODO: pk-theme binnenhalen
# TODO: project-repo binnenhalen op de test branch
# TODO: plugins 
EOF

echo "✅ Domain created"