#!/data/data/com.termux/files/usr/bin/bash
# Note: Not using set -e to prevent script from exiting on non-critical failures

# Parse arguments
INSTALL_TOOLS=false
for arg in "$@"; do
  case $arg in
    --tools)
      INSTALL_TOOLS=true
      shift
      ;;
  esac
done

# SolBot banner - display for 5 seconds
clear
echo ""
echo -e "\033[1;36m  ███████╗ ██████╗ ██╗     ██████╗  ██████╗ ████████╗\033[0m"
echo -e "\033[1;36m  ██╔════╝██╔═══██╗██║     ██╔══██╗██╔═══██╗╚══██╔══╝\033[0m"
echo -e "\033[1;36m  ███████╗██║   ██║██║     ██████╔╝██║   ██║   ██║   \033[0m"
echo -e "\033[1;36m  ╚════██║██║   ██║██║     ██╔══██╗██║   ██║   ██║   \033[0m"
echo -e "\033[1;36m  ███████║╚██████╔╝███████╗██████╔╝╚██████╔╝   ██║   \033[0m"
echo -e "\033[1;36m  ╚══════╝ ╚═════╝ ╚══════╝╚═════╝  ╚═════╝    ╚═╝   \033[0m"
echo ""
echo -e "\033[1;37m       ⚡ OpenClaw Android Installer ⚡\033[0m"
echo ""
echo -e "\033[1;35m            by Stephane Nathaniel 💋\033[0m"
echo -e "\033[1;31m                 (づ ̄ ³ ̄)づ\033[0m"
echo ""
if [ "$INSTALL_TOOLS" = true ]; then
  echo -e "\033[1;33m        🔧 AI Tools will be installed\033[0m"
  echo ""
fi
sleep 5

# Prompt user to install tools if not already specified via flag
if [ "$INSTALL_TOOLS" = false ]; then
  echo ""
  echo -e "\033[1;33m┌─────────────────────────────────────────────────────┐\033[0m"
  echo -e "\033[1;33m│  Install AI Tools?                                  │\033[0m"
  echo -e "\033[1;33m│  (Whisper, Chromium, yt-dlp, ImageMagick, etc)      │\033[0m"
  echo -e "\033[1;33m└─────────────────────────────────────────────────────┘\033[0m"
  echo ""
  # Read from /dev/tty to work when script is piped from curl
  read -p "Install tools? (y/n): " -n 1 -r REPLY < /dev/tty
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    INSTALL_TOOLS=true
  fi
fi

echo "[1/5] Termux: update + deps"
pkg update -y && pkg upgrade -y
pkg install -y proot-distro curl git jq ca-certificates

echo "[2/5] Termux: install Ubuntu (proot-distro)"
proot-distro install ubuntu || true

echo "[3/5] Ubuntu: bootstrap (Node 22 + OpenClaw)"
proot-distro login ubuntu --shared-tmp -- /bin/bash -lc '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

mkdir -p /root/openclaw-launcher/{bin,logs,state}

echo "[ubuntu] apt deps"
apt-get update -y
apt-get install -y ca-certificates curl git jq gnupg lsb-release

echo "[ubuntu] install Node.js 22"
curl -fsSL https://deb.nodesource.com/setup_22.x -o /tmp/nodesetup.sh
bash /tmp/nodesetup.sh
apt-get install -y nodejs
node -v
npm -v

# ============================================================
# FIX: Android 11+ os.networkInterfaces() permission error
# This creates a hijack script that overrides the problematic
# Node.js function that fails on Android due to security restrictions
# ============================================================
echo "[ubuntu] creating network interface fix for Android 11+"
cat > /root/openclaw-launcher/bin/network-hijack.js << '\''HIJACK'\''
const os = require("os");
os.networkInterfaces = () => ({});
HIJACK

# Add NODE_OPTIONS to bashrc so the fix persists across sessions
if ! grep -q "network-hijack.js" /root/.bashrc 2>/dev/null; then
  echo "" >> /root/.bashrc
  echo "# Fix for Android 11+ os.networkInterfaces() permission error" >> /root/.bashrc
  echo "export NODE_OPTIONS=\"--require /root/openclaw-launcher/bin/network-hijack.js\"" >> /root/.bashrc
fi

# Apply fix for current session
export NODE_OPTIONS="--require /root/openclaw-launcher/bin/network-hijack.js"
# ============================================================

echo "[ubuntu] install OpenClaw"
curl -fsSL https://openclaw.ai/install.sh -o /tmp/openclaw_install.sh
bash /tmp/openclaw_install.sh || true

echo "[ubuntu] onboarding (this may prompt you)"
openclaw onboard || true
'

# Install AI tools if --tools flag was passed
if [ "$INSTALL_TOOLS" = true ]; then
  echo "[4/5] Installing AI Tools..."
  proot-distro login ubuntu --shared-tmp -- /bin/bash -lc '
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive
  
  echo "[tools] Installing Python & pip..."
  apt-get install -y python3 python3-pip python3-venv ffmpeg
  
  echo "[tools] Installing Chromium browser..."
  apt-get install -y chromium-browser || apt-get install -y chromium || true
  
  echo "[tools] Installing OpenAI Whisper (tiny model)..."
  pip3 install --break-system-packages openai-whisper || pip3 install openai-whisper
  
  echo "[tools] Pre-downloading Whisper tiny model..."
  python3 -c "import whisper; whisper.load_model(\"tiny\")" || true
  
  echo "[tools] Installing additional AI utilities..."
  # yt-dlp for downloading media
  pip3 install --break-system-packages yt-dlp || pip3 install yt-dlp
  
  # httpie for API testing
  apt-get install -y httpie || pip3 install --break-system-packages httpie || true
  
  # jq already installed, add yq for YAML
  pip3 install --break-system-packages yq || pip3 install yq || true
  
  # ripgrep for fast searching
  apt-get install -y ripgrep || true
  
  # tmux for session management
  apt-get install -y tmux || true
  
  # imagemagick for image processing
  apt-get install -y imagemagick || true
  
  # sox for audio processing
  apt-get install -y sox || true
  
  echo "[tools] ✅ AI Tools installed!"
  echo ""
  echo "Installed tools:"
  echo "  🌐 Chromium - Web browser for automation"
  echo "  🎤 Whisper (tiny) - Speech-to-text"
  echo "  📹 yt-dlp - Media downloader"
  echo "  🔍 ripgrep - Fast text search"
  echo "  🖼️  ImageMagick - Image processing"
  echo "  🎵 sox/ffmpeg - Audio processing"
  echo "  📺 tmux - Terminal multiplexer"
  echo "  🔧 httpie, yq - API & YAML tools"
  '
else
  echo "[4/5] Skipping AI Tools (use --tools to install)"
fi

echo ""
echo "[5/5] Starting OpenClaw Gateway..."
proot-distro login ubuntu -- /bin/bash -lc 'openclaw gateway --port 18789 --verbose'
