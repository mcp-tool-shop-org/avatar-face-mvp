# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |
| < 1.0   | No        |

## Reporting a Vulnerability

**Email:** 64996768+mcp-tool-shop@users.noreply.github.com

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact

**Response timeline:**
- Acknowledgment: within 48 hours
- Assessment: within 7 days
- Fix (if confirmed): within 30 days

## Scope

Avatar Face MVP is a **Godot 4 desktop application** for real-time VRM avatar lipsync and expression control.
- **Data accessed:** Reads local VRM avatar files, audio input from microphone, webcam feed via OpenSeeFace (UDP on localhost). Optionally spawns a local Node.js TTS bridge process. Reads/writes JSON config files (`tuning.json`, mapping profiles) in the project directory.
- **Data NOT accessed:** No internet requests. No telemetry. No cloud services. No user account data. No credential storage. Webcam data is processed locally only and never transmitted.
- **Permissions required:** Microphone access for lipsync. Optional webcam access via OpenSeeFace (separate process). File system access for VRM models and configuration files.
