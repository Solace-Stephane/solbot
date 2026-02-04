# SolBot ⚡

One-command installer for [OpenClaw](https://openclaw.ai) on Android via Termux + Ubuntu proot.

## Quick Install

Run this in Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/Solace-Stephane/solbot/main/install.sh | bash
```

**With AI Tools** (Whisper, Chromium, yt-dlp, ImageMagick, etc):

```bash
curl -fsSL https://raw.githubusercontent.com/Solace-Stephane/solbot/main/install.sh | bash -s -- --tools
```

## What it does

1. Updates Termux and installs dependencies
2. Installs Ubuntu via proot-distro
3. Sets up Node.js 22 inside Ubuntu
4. **Applies Android 11+ fix** for `os.networkInterfaces()` permission error
5. Installs and configures OpenClaw
6. Installs the `solbot` CLI for easy gateway management
7. Starts the OpenClaw gateway on port 18789

## SolBot CLI Commands

After installation, use the `solbot` command in Termux to manage the gateway:

| Command | Description |
|---------|-------------|
| `solbot --start` | Start the OpenClaw gateway |
| `solbot --stop` | Stop the gateway |
| `solbot --restart` | Restart the gateway |
| `solbot --fix` | Fix "gateway failed to start" issues |
| `solbot --reboot` | Restart the Ubuntu environment |
| `solbot --status` | Check if gateway is running |
| `solbot --onboard` | Run OpenClaw onboarding |
| `solbot --configure` | Run OpenClaw configuration |
| `solbot --shell` | Open Ubuntu shell |
| `solbot --logs` | View gateway logs |
| `solbot --help` | Show help |

**Examples:**

```bash
# Start the gateway
solbot --start

# Check status
solbot --status

# View logs
solbot --logs

# Open Ubuntu shell for advanced tasks
solbot --shell
```

## Gateway Access

- **Dashboard**: http://127.0.0.1:18789/
- **Logs**: `/root/openclaw-launcher/logs/gateway.log` (inside Ubuntu)

## Android 11+ Fix

This script includes a fix for the `SystemError [ERR_SYSTEM_ERROR]: uv_interface_addresses returned Unknown system error 13` that occurs on Android 11+ due to network interface access restrictions.

The fix creates a hijack script that overrides `os.networkInterfaces()` and sets `NODE_OPTIONS` to load it automatically.

## AI Tools (Optional)

When installed with `--tools`, you get:

- 🌐 **Chromium** - Web browser for automation
- 🎤 **Whisper** (tiny) - Speech-to-text
- 📹 **yt-dlp** - Media downloader
- 🔍 **ripgrep** - Fast text search
- 🖼️ **ImageMagick** - Image processing
- 🎵 **sox/ffmpeg** - Audio processing
- 📺 **tmux** - Terminal multiplexer
- 🔧 **httpie, yq** - API & YAML tools

## Requirements

- Android device with Termux installed
- ~2GB storage space (~4GB with AI tools)
- Internet connection

## License

MIT
