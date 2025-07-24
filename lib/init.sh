#!/bin/bash
if ! command -v git >/dev/null 2>&1
then
	echo "❌ Git is not installed"
	exit 1
fi
if ! command -v gh >/dev/null 2>&1
then
	echo "❌ GitHub CLI is not installed"
	exit 1
fi

# === CONFIGURATION ===
GITHUB_ORG="Pageking"
TEMPLATE_REPO="pk-theme-child"
CLONE_DIR="pk-theme-child"

# === Ask for project name ===
read -p "Enter the new GitHub repository name: " REPO_NAME

# === Create new repo from template using GitHub CLI ===
echo "📦 Creating repo '$REPO_NAME' from template '$TEMPLATE_REPO' under org '$GITHUB_ORG'..."
gh repo create "$GITHUB_ORG/$REPO_NAME" \
  --template "$GITHUB_ORG/$TEMPLATE_REPO" \
  --private

# === Wait until repo has contents ===
echo "⏳ Waiting for repo to be populated..."
REPO_READY=0
while [[ $REPO_READY -eq 0 ]]; do
  git ls-remote "https://github.com/$GITHUB_ORG/$REPO_NAME.git" | grep "refs/heads/main" > /dev/null && REPO_READY=1 || sleep 2
done

# === Clone into fixed folder name ===
echo "📁 Cloning '$REPO_NAME' into ./$CLONE_DIR ..."
git clone "https://github.com/$GITHUB_ORG/$REPO_NAME.git" "$CLONE_DIR"
cd "$CLONE_DIR" || exit

# Wait until files are present
echo "⏳ Waiting for files to appear in the cloned repo..."
until [ "$(ls | wc -l)" -gt 0 ]; do
  sleep 1
done
echo "✅ Files are present in the folder"

# === Rename main → development ===
echo "🔀 Renaming 'main' to 'development'..."
git checkout main
git branch -m development
git push -u origin development

# === Set 'development' as default branch on GitHub ===
gh api -X PATCH "repos/$GITHUB_ORG/$REPO_NAME" -f default_branch="development"

# === Now delete 'main' from remote ===
git push origin --delete main


# === Create and push other environment branches ===
for BRANCH in test staging production; do
  git checkout -b "$BRANCH"
  git push -u origin "$BRANCH"
done

git checkout development

echo "✅ Repo '$REPO_NAME' created and cloned to '$CLONE_DIR' with branches: development (default), test, staging, production"
