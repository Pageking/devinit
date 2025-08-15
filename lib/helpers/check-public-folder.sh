check_public_folder() {
  if [[ "$(basename "$PWD")" != "public" ]]; then
    echo "❌ Error: You must run this command from the /public/ folder in your project ."
    echo "📁 Current directory: $(pwd)"
    exit 1
  fi
}