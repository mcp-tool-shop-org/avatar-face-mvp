# Avatar Face MVP

Real-time VRM avatar lipsync from mic input, built with Godot 4.x.

## What this proves

Mic (or WAV) in -> face moves convincingly -> 60 fps stable -> screen-capture demo.

## Stack

- **Runtime:** Godot 4.3+ (GL Compatibility)
- **Avatar format:** VRM 1.0
- **Driver phase 1:** FFT-based viseme extraction (built-in AudioEffectSpectrumAnalyzer)
- **Driver phase 2:** OpenSeeFace UDP for live webcam expressions + head pose
- **Expression mapping:** Dictionary-based driver output -> VRM blendshapes with per-weight smoothing

## Setup

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Install the [godot-vrm](https://github.com/V-Sekai/godot-vrm) addon (copy `addons/vrm/` into this project)
3. Place your VRM 1.0 file in `assets/avatars/`
4. Open `project.godot` in Godot
5. Run the scene

## Required VRM blendshapes

Your avatar must have at minimum:
- Visemes: `aa`, `ih`, `ou`, `ee`, `oh` (VRM standard names)
- Blink: `blinkLeft`, `blinkRight`
- Emotions: `happy`, `sad`, `angry` (or equivalent)

## Controls

- **Mic Toggle:** Start/stop mic capture
- **Load WAV:** Play a test audio file
- **Emotion Slider:** Manually blend an emotion expression
- **Expression dropdown:** Select which emotion to drive

## Architecture

```
mic/wav -> AudioEffectSpectrumAnalyzer -> FFT bands
  -> VisemeDriver (band -> viseme weight mapping)
  -> ExpressionMapper (driver names -> VRM blendshape names, smoothing, clamping)
  -> VRM blendshape updates every _process frame
```

## License

MIT
