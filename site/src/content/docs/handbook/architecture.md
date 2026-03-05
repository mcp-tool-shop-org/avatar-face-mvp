---
title: Architecture
description: Pipeline design and key decisions.
sidebar:
  order: 4
---

The avatar face pipeline processes input through a series of controllers, each responsible for one concern.

## Pipeline

```
mic / wav / tracker → VisemeDriver (FFT → 5 viseme weights)
                    → OpenSeeFaceDriver (UDP → ARKit blendshapes)
                           ↓
                    BlinkController (procedural, context-aware)
                           ↓
                    GazeController (micro-saccades, eye bones)
                           ↓
                    ExpressionMapper (driver → VRM names, smoothing)
                           ↓
                    Expression Compositor (blinks > gaze > visemes > emotions)
                           ↓
                    MeshInstance3D.set_blend_shape_value()
                    IdleController.apply() (breathing, sway, head drift)
```

The TTS pipeline runs separately — Godot communicates with the TTS bridge via WebSocket, and synthesized audio is routed through the FFT capture bus for automatic lipsync.

## Key design decisions

- **All hot-path dictionaries are pre-allocated** — zero per-frame GC pressure
- **Blend shape name → index lookup is cached** on avatar load
- **Debug UI updates are throttled** to every 3rd frame
- **Config hot-reload checks** run every 2 seconds, not every frame
- **BridgeManager probe-first pattern** — checks if bridge is already running before spawning
- **Expression compositor** resolves conflicts: blinks suppress eye shapes, visemes suppress mouth emotions, jaw deformation is clamped

## Expression compositor priority

The compositor stacks layers with clear priority:

1. **Blinks** — highest priority, suppress all eye shapes
2. **Gaze** — eye direction, suppressed during blinks
3. **Visemes** — mouth shapes from audio
4. **Emotions** — lowest priority, suppressed by visemes on mouth shapes
