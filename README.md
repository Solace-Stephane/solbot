# OpenClaw Android Setup

One-command installer for [OpenClaw](https://openclaw.ai) on Android via Termux + Ubuntu proot.

## Quick Install

Run this in Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/Solace-Stephane/solbot/main/install.sh | bash
```

## What it does

1. Updates Termux and installs dependencies
2. Installs Ubuntu via proot-distro
3. Sets up Node.js 22 inside Ubuntu
4. **Applies Android 11+ fix** for `os.networkInterfaces()` permission error
5. Installs and configures OpenClaw
6. Starts the OpenClaw gateway on port 18789

## Android 11+ Fix

This script includes a fix for the `SystemError [ERR_SYSTEM_ERROR]: uv_interface_addresses returned Unknown system error 13` that occurs on Android 11+ due to network interface access restrictions.

The fix creates a hijack script that overrides `os.networkInterfaces()` and sets `NODE_OPTIONS` to load it automatically.

## After Installation

- **Gateway dashboard**: http://127.0.0.1:18789/
- **Logs**: `/root/openclaw-launcher/logs/gateway.log` (inside Ubuntu)

### Restart gateway
```bash
proot-distro login ubuntu -- /bin/bash -lc 'openclaw gateway --port 18789 --verbose'
```

### Stop gateway
```bash
proot-distro login ubuntu -- /bin/bash -lc 'kill $(cat /root/openclaw-launcher/state/gateway.pid)'
```

## Requirements

- Android device with Termux installed
- ~2GB storage space
- Internet connection

## License

MIT
