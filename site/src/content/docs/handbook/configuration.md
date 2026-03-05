---
title: Configuration
description: Tuning parameters, mapping profiles, and hot-reload.
sidebar:
  order: 3
---

All configuration is data-driven JSON with 2-second hot-reload — no restart needed.

## Tuning (`config/tuning.json`)

| Key | What it does | Default |
|-----|-------------|---------|
| `smoothing.attack_time` | How fast weights rise (seconds) | 0.06 |
| `smoothing.release_time` | How fast weights fall (seconds) | 0.12 |
| `viseme_bands.*` | Frequency ranges [min, max] Hz per viseme | see file |
| `noise_gate` | Minimum FFT magnitude to register as speech | 0.01 |
| `sensitivity` | FFT magnitude multiplier | 8.0 |
| `blink.*` | Procedural blink timing (interval, duration, double-blink chance) | see file |
| `openseeface.host` | OpenSeeFace UDP host | 127.0.0.1 |
| `openseeface.port` | OpenSeeFace UDP port | 11573 |

## Mapping profiles

Three profiles ship with the project, matching different VRM blend shape naming conventions:

| File | Profile | For models with |
|------|---------|-----------------|
| `mapping.json` | VRM Standard | `lip_a`, `blink_L`, `face_happy` |
| `mapping_arkit.json` | ARKit | `jawOpen`, `eyeBlink_L`, `mouthSmile_L` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

The diagnostics panel auto-detects which profile matches the loaded model and suggests switching.

## Hot-reload

Both tuning and mapping files are checked every 2 seconds. Edit the JSON, save, and see the change in real-time — no restart needed. This makes it easy to tune FFT sensitivity, smoothing curves, and blink timing while watching the avatar respond.
