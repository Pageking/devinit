#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers/check-public-folder.sh"
check_public_folder

CONFIG_PATH="$HOME/.config/devinit/config.json"


# === CONFIGURATION ===
SERVER=$(jq -r '.servers.server_1.server' "$CONFIG_PATH")
DOMAIN=$(jq -r '.servers.server_1.domain' "$CONFIG_PATH")
IP=$(jq -r '.servers.server_1.ip' "$CONFIG_PATH")
DB_PREFIX=$(jq -r '.wp.db_prefix' "$CONFIG_PATH")
WP_ADMIN=$(jq -r '.wp.admin_username' "$CONFIG_PATH")
WP_ADMIN_PASS=$(jq -r '.wp.admin_password' "$CONFIG_PATH")
WP_ADMIN_EMAIL=$(jq -r '.wp.admin_email' "$CONFIG_PATH")

WWW_ROOT=$(jq -r '.servers.server_1.www_root' "$CONFIG_PATH")

read -p "Enter the new Plesk project name: " PROJECT_NAME
if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "Invalid project name. Use only lowercase letters, numbers, and hyphens (no spaces or special characters)."
  exit 1
fi
DB_NAME="${DB_PREFIX}_${PROJECT_NAME}"
DB_USER="${DB_NAME}_user"
DB_PASS="$(openssl rand -base64 12)"

GIT_REPO="git@github.com-info:$(jq -r '.github.org' "$CONFIG_PATH")/pk-theme.git"
TARGET_DIR="/var/www/vhosts/${PROJECT_NAME}.${DOMAIN}/${WWW_ROOT}/wp-content/themes"

echo "👷 Creating domain on Plesk with project name '$PROJECT_NAME'"
SUFFIX=$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 10)
PLESK_USER="${DOMAIN}_${SUFFIX}"
PLESK_PASS=$(openssl rand -base64 16)


ssh "$SERVER" bash <<EOF
# Exit on first failure
set -e 

# Creating Domain
plesk bin domain --create ${PROJECT_NAME}.${DOMAIN} -ip $IP -hosting true -www-root $WWW_ROOT -login $PLESK_USER -passwd $PLESK_PASS

# Create database
plesk bin database --create $DB_NAME -domain ${PROJECT_NAME}.${DOMAIN} -type mysql

# Create database user
plesk bin database --create-dbuser $DB_USER -passwd $DB_PASS -domain ${PROJECT_NAME}.${DOMAIN} -server localhost:3306 -database $DB_NAME

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
	
# Clone main theme into created 
git clone -b test $GIT_REPO $TARGET_DIR/pk-theme

git clone git@github.com-info:$(jq -r '.github.org' "$CONFIG_PATH")/${PROJECT_NAME}.git /var/www/vhosts/${PROJECT_NAME}.${DOMAIN}/httpdocs/wp-content/themes/$(jq -r '.github.template_repo' "$CONFIG_PATH")
EOF

# TODO: dit script op elke plek in project folder structuur laten werken
# Find the wp-content directory relative to the current directory
WP_CONTENT_DIR=$(find . -type d -name "wp-content" -print -quit)

if [ -z "$WP_CONTENT_DIR" ]; then
	echo "❌ wp-content directory not found in this project."
	exit 1
fi

rsync -avzh --progress --delete-after --update "${WP_CONTENT_DIR}/plugins" root@136.144.237.148:/var/www/vhosts/${PROJECT_NAME}.pk1.pageking.dev/httpdocs/wp-content/

echo "✅ Domain created"