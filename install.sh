#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cat << 'EOF'

  ███████╗ ██████╗ ██╗     ██████╗  ██████╗ ████████╗
  ██╔════╝██╔═══██╗██║     ██╔══██╗██╔═══██╗╚══██╔══╝
  ███████╗██║   ██║██║     ██████╔╝██║   ██║   ██║   
  ╚════██║██║   ██║██║     ██╔══██╗██║   ██║   ██║   
  ███████║╚██████╔╝███████╗██████╔╝╚██████╔╝   ██║   
  ╚══════╝ ╚═════╝ ╚══════╝╚═════╝  ╚═════╝    ╚═╝   
                                                      
       ⚡ OpenClaw Android Installer ⚡
       
EOF

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

echo "[ubuntu] start gateway on :18789"
( nohup openclaw gateway --port 18789 --verbose >> /root/openclaw-launcher/logs/gateway.log 2>&1 & echo $! > /root/openclaw-launcher/state/gateway.pid )
sleep 1
echo "[ubuntu] gateway pid: $(cat /root/openclaw-launcher/state/gateway.pid)"
echo "[ubuntu] dashboard: http://127.0.0.1:18789/"
'

echo "[4/5] Done."
echo "Gateway dashboard: http://127.0.0.1:18789/"
echo "Logs (inside ubuntu): /root/openclaw-launcher/logs/gateway.log"
echo "To stop (in Termux): proot-distro login ubuntu -- /bin/bash -lc \"kill \$(cat /root/openclaw-launcher/state/gateway.pid)\""
echo ""
echo "To restart gateway later:"
echo "  proot-distro login ubuntu -- /bin/bash -lc 'openclaw gateway --port 18789 --verbose'"
