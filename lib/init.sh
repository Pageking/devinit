#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers/check-public-folder.sh"
check_public_folder

read -p "Enter the project name: " PROJECT_NAME
if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "Invalid project name. Use only lowercase letters, numbers, and hyphens (no spaces or special characters)."
  exit 1
fi

cd "wp-content/themes"

if [ ! -d "pk-theme" ];
then
  echo "❌ Error: This command must be run in a theme folder where 'pk-theme/' exists."
  echo "📁 Current directory: $(pwd)"
  exit 1
fi
if [ -d "pk-theme-child" ];
then
  echo "❌ Error: This command must be run without an existing pk-theme-child folder."
  exit 1
fi

CONFIG_PATH="$HOME/.config/devinit/config.json"
# TODO: make deploy key per user instead of master for everyone
SERVER=$(jq -r '.servers.server_1.server' "$CONFIG_PATH")
DOMAIN=$(jq -r '.servers.server_1.domain' "$CONFIG_PATH")
GITHUB_ORG=$(jq -r '.github.org' "$CONFIG_PATH")
TEMPLATE_REPO=$(jq -r '.github.template_repo' "$CONFIG_PATH")
DEPLOY_KEY=$(ssh "$SERVER" 'cat /opt/deploy_keys/info-deploy')

echo "📦 Creating repo '$PROJECT_NAME' from template '$TEMPLATE_REPO'..."

gh repo create "$GITHUB_ORG/$PROJECT_NAME" \
  --template "$GITHUB_ORG/$TEMPLATE_REPO" \
  --private
gh secret set "PLESK_SSH_KEY" --body "$DEPLOY_KEY" --repo "$GITHUB_ORG/$PROJECT_NAME"
gh secret set "PLESK_SERVER" --body "$SERVER" --repo "$GITHUB_ORG/$PROJECT_NAME"
gh secret set "PLESK_DOMAIN" --body "$DOMAIN" --repo "$GITHUB_ORG/$PROJECT_NAME"

# Wait for repo to be ready
echo "⏳ Waiting for main branch to be created..."
until git ls-remote "https://github.com/$GITHUB_ORG/$PROJECT_NAME.git" | grep -q "refs/heads/main"; do
  sleep 1
done

CLONE_DIR="pk-theme-child"
git clone "https://github.com/$GITHUB_ORG/$PROJECT_NAME.git" "$CLONE_DIR"
cd "$CLONE_DIR"

# Rename and push branches
git checkout -b development
git push -u origin development
gh api -X PATCH "repos/$GITHUB_ORG/$PROJECT_NAME" -f default_branch="development">/dev/null
git push origin --delete main 2>/dev/null || true

for BRANCH in test staging production; do
  git checkout -b "$BRANCH"
  git push -u origin "$BRANCH"
done

git checkout development
echo "✅ Project '$PROJECT_NAME' initialized with branches: development, test, staging, production"
