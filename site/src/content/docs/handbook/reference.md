---
title: Reference
description: Controls, diagnostics panel, and known issues.
sidebar:
  order: 5
---

## Main controls

| Control | What it does |
|---------|-------------|
| Avatar dropdown | Switch between loaded VRM models |
| Driver dropdown | FFT (Mic Audio) or OpenSeeFace (Webcam) |
| Mapping profile | VRM Standard / ARKit / VRChat |
| Start Mic | Begin mic capture for FFT visemes |
| Load WAV/OGG | Play a custom audio file through FFT |
| Play Test Vowels | Verify with bundled test audio |
| Emotion + slider | Manually blend an expression |
| Sensitivity | FFT magnitude multiplier (1–30) |
| Zoom +/- | Camera zoom (also: mouse wheel) |

## TTS panel

| Control | What it does |
|---------|-------------|
| Connect / Disconnect | Manual bridge toggle |
| Voice dropdown | Select TTS voice |
| Emotion dropdown | Expression cues during speech |
| Text box | Type what the avatar should say |
| Speak / Stop | Start or cancel playback |

## Model diagnostics panel

Shows real-time compatibility info:

- **Status badge** — GREEN (all mapped), YELLOW (partial), RED (missing critical)
- **Detected style** — VRM Standard, ARKit, or VRChat
- **Profile suggestion** — auto-suggests the correct mapping
- **Viseme coverage** — which driver visemes map to blend shapes
- **Expression coverage** — blinks and emotions mapping status
- **Unmapped shapes** — blend shapes not referenced by any mapping

## Known issues

- **T-pose arms** — VRM models load in T-pose. The `pose_corrector.gd` is WIP and not producing correct results
- **VRChat models** — auto-detection may suggest the wrong profile on some models
- **OpenSeeFace latency** — head pose smoothing adds ~100ms; tune `head_pose_attack`/`head_pose_release` if needed

## Links

- [GitHub Repository](https://github.com/mcp-tool-shop-org/avatar-face-mvp)
- [godot-vrm addon](https://github.com/V-Sekai/godot-vrm)
- [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)
