---
title: Drivers
description: FFT visemes, OpenSeeFace tracking, and TTS pipeline.
sidebar:
  order: 2
---

Avatar Face MVP supports three input drivers that can be switched at runtime.

## FFT viseme driver (mic input)

The default driver uses Godot's built-in `AudioEffectSpectrumAnalyzer` to extract 5 viseme bands from microphone audio in real-time:

- **ou** — low frequencies
- **oh** — low-mid frequencies
- **aa** — mid frequencies
- **ih** — mid-high frequencies
- **ee** — high frequencies

Each band maps to mouth blend shapes on the VRM model. The sensitivity slider (1–30, default 8) controls the FFT magnitude multiplier.

## OpenSeeFace driver (webcam)

For full facial capture with 52 ARKit blendshapes plus head pose:

1. Install and run [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)
2. Switch the driver dropdown to **OpenSeeFace (Webcam)**
3. The tracker sends data via UDP to `127.0.0.1:11573`
4. Configure host/port in `config/tuning.json` under `openseeface`

This driver captures far more than just mouth shapes — eyebrows, cheeks, jaw, and full head rotation.

## TTS pipeline

The TTS system connects Godot to a local KokoroSharp voice synthesis server:

1. Ensure `voice-soundboard-mcp` is running
2. BridgeManager auto-spawns `tools/tts-bridge/bridge.mjs` and connects via WebSocket
3. The TTS panel opens when connected — type text and click **Speak**
4. Available voices are populated from the server
5. Optional: select an emotion for expression cues during speech

The audio from TTS is routed through the FFT capture bus, so the avatar lip-syncs to synthesized speech automatically.
