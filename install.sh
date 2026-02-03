#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Animated SolBot banner
animate_banner() {
  local colors=("\033[1;36m" "\033[1;35m" "\033[1;34m" "\033[1;33m" "\033[1;32m" "\033[1;31m")
  local reset="\033[0m"
  local banner=(
    "  ███████╗ ██████╗ ██╗     ██████╗  ██████╗ ████████╗"
    "  ██╔════╝██╔═══██╗██║     ██╔══██╗██╔═══██╗╚══██╔══╝"
    "  ███████╗██║   ██║██║     ██████╔╝██║   ██║   ██║   "
    "  ╚════██║██║   ██║██║     ██╔══██╗██║   ██║   ██║   "
    "  ███████║╚██████╔╝███████╗██████╔╝╚██████╔╝   ██║   "
    "  ╚══════╝ ╚═════╝ ╚══════╝╚═════╝  ╚═════╝    ╚═╝   "
  )
  
  clear
  local end_time=$((SECONDS + 5))
  local frame=0
  
  while [ $SECONDS -lt $end_time ]; do
    tput cup 0 0 2>/dev/null || true
    echo ""
    for i in "${!banner[@]}"; do
      local color_idx=$(( (frame + i) % ${#colors[@]} ))
      echo -e "${colors[$color_idx]}${banner[$i]}${reset}"
    done
    echo ""
    echo -e "\033[1;37m       ⚡ OpenClaw Android Installer ⚡\033[0m"
    echo ""
    
    # Animated loading dots
    local dots=""
    for ((d=0; d<(frame % 4); d++)); do dots+="●"; done
    for ((d=(frame % 4); d<3; d++)); do dots+="○"; done
    echo -e "\033[1;33m            Initializing $dots\033[0m"
    
    sleep 0.3
    ((frame++))
  done
  
  clear
  echo ""
  for line in "${banner[@]}"; do
    echo -e "\033[1;36m$line\033[0m"
  done
  echo ""
  echo -e "\033[1;37m       ⚡ OpenClaw Android Installer ⚡\033[0m"
  echo ""
}

animate_banner

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
bash /tmp/openclaw_install.sh

echo "[ubuntu] onboarding (this may prompt you)"
openclaw onboard
'

echo "[4/5] Done."
echo "Gateway dashboard: http://127.0.0.1:18789/"
echo ""

echo "[5/5] Starting OpenClaw Gateway..."
proot-distro login ubuntu -- /bin/bash -lc 'openclaw gateway --port 18789 --verbose'
