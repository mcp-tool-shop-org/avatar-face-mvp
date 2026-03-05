---
title: Getting Started
description: Prerequisites, setup, and first run.
sidebar:
  order: 1
---

Avatar Face MVP is a Godot 4.3+ project with a Node.js TTS bridge.

## Prerequisites

- [Godot 4.3+](https://godotengine.org/download) (GL Compatibility renderer)
- [Node.js 18+](https://nodejs.org/) (for the TTS bridge)
- A VRM avatar file (or use the bundled Seed-san test avatar)

## Setup

```bash
git clone https://github.com/mcp-tool-shop-org/avatar-face-mvp.git
cd avatar-face-mvp

# Install TTS bridge dependencies
cd tools/tts-bridge
npm install
cd ../..
```

Open in Godot: File → Open Project → select `project.godot`. Press F5 to run.

## First run

1. The app loads the first VRM it finds in `assets/avatars/`
2. BridgeManager auto-starts the TTS bridge and connects
3. Click **Start Mic** to see the avatar lip-sync to your voice
4. Or click **Play Test Vowels** to verify with a bundled test audio

## Quick test without a mic

A test file at `assets/audio/test_vowels.wav` cycles through all five viseme bands twice over ~10 seconds. Click "Play Test Vowels" to verify the FFT driver works.

## Next steps

- Learn about the [input drivers](/avatar-face-mvp/handbook/drivers/) (mic, webcam, TTS)
- Customize [tuning and mapping profiles](/avatar-face-mvp/handbook/configuration/)
- Understand the [architecture](/avatar-face-mvp/handbook/architecture/)
