check_public_folder() {
  if [[ "$(basename "$PWD")" != "public" ]]; then
    echo "❌ Error: You must run this command from the /public/ folder in your project ."
    echo "📁 Current directory: $(pwd)"
    exit 1
  fi
  if [[ ! -d "wp-content" ]]; then
    echo "❌ Error: 'wp-content' directory not found. Make sure you are in the root folder of your WordPress site."
	echo "📁 Current directory: $(pwd)"
    exit 1
  fi
}