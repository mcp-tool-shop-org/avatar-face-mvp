# Avatar Face MVP

Real-time VRM avatar lipsync from mic input, built with Godot 4.x.

## What this proves

Mic (or WAV) in -> face moves convincingly -> 60 fps stable -> screen-capture demo.

## Stack

- **Runtime:** Godot 4.3+ (GL Compatibility)
- **Avatar format:** VRM 1.0
- **Driver phase 1:** FFT-based viseme extraction (built-in AudioEffectSpectrumAnalyzer)
- **Driver phase 2:** OpenSeeFace UDP for live webcam expressions + head pose (`scripts/openseeface_driver.gd`)
- **Expression mapping:** Data-driven (JSON config) driver output -> VRM blendshapes with asymmetric exponential smoothing
- **Config:** Hot-reloadable `config/mapping.json` + `config/tuning.json`

## Setup

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Install the [godot-vrm](https://github.com/V-Sekai/godot-vrm) addon:
   - Download from [Godot Asset Library](https://godotengine.org/asset-library/asset/2031) or clone the repo
   - Copy `addons/vrm/` into this project's `addons/` directory
   - In Godot: Project Settings -> Plugins -> enable both "vrm" and "Godot-MToon-Shader"
3. Place your VRM 1.0 file in `assets/avatars/`
4. Open `project.godot` in Godot
5. Run the scene (F5)

### Quick test without a mic

A test audio file is included at `assets/audio/test_vowels.wav`. It cycles through
all five viseme frequency bands (ou, oh, aa, ih, ee) twice over ~10 seconds. Click
"Load WAV/OGG" and select it to verify the FFT driver works before plugging in a mic.

To regenerate: `python tools/generate_test_audio.py`

### Using OpenSeeFace (webcam tracking)

1. Install and run [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)
2. In the demo UI, switch the driver dropdown to "OpenSeeFace (Webcam)"
3. The tracker sends blendshapes via UDP to `127.0.0.1:11573` (configurable in `config/tuning.json`)

## Required VRM blendshapes

Your avatar must have at minimum:
- **Visemes:** `viseme_aa`, `viseme_ih`, `viseme_ou`, `viseme_ee`, `viseme_oh`
- **Blink:** `blinkLeft`, `blinkRight`
- **Emotions (optional):** `happy`, `sad`, `angry`, `surprised`

To verify: open your VRM in Godot, select the MeshInstance3D, and check the blend shape list in the inspector. The names must match (case-insensitive).

## Controls

- **Driver dropdown:** Switch between FFT (mic audio) and OpenSeeFace (webcam)
- **Mic Toggle:** Start/stop mic capture for FFT driver
- **Load WAV/OGG:** Play a test audio file through the FFT driver
- **Emotion dropdown:** Select which emotion expression to drive
- **Emotion Slider:** Manually blend the selected emotion (0-100%)
- **Sensitivity Slider:** Adjust FFT sensitivity (higher = more responsive, noisier)
- **Blend Debug panel:** Live view of all active blend shape weights

## Configuration

All tuning is in `config/tuning.json` (hot-reloaded every 2 seconds):

| Key | What it does |
|---|---|
| `smoothing.attack_time` | How fast weights rise (seconds, default 0.06) |
| `smoothing.release_time` | How fast weights fall (seconds, default 0.12) |
| `viseme_bands.*` | Frequency ranges [min, max] Hz for each viseme |
| `noise_gate` | Minimum FFT magnitude to register as speech |
| `sensitivity` | FFT magnitude multiplier |
| `blink.*` | Procedural blink timing |
| `openseeface.*` | UDP host and port for OpenSeeFace |

Expression name mapping is in `config/mapping.json`. Change this if your VRM uses non-standard blend shape names.

## Architecture

```
                    +--> VisemeDriver (FFT bands -> 5 viseme weights)
mic/wav/tracker --> |
                    +--> OpenSeeFaceDriver (UDP -> ARKit blendshapes -> viseme + expression weights)
                         |
                         v
                    BlinkController (procedural, used in FFT mode only)
                         |
                         v
                    ExpressionMapper (driver names -> VRM names, smoothing, clamping)
                         |
                         v
                    MeshInstance3D.set_blend_shape_value() (cached index lookup)
```

All drivers implement the same interface: `get_viseme_weights() -> Dictionary`. Swapping drivers means changing one line.

## Performance notes

- All hot-path dictionaries are pre-allocated and reused (zero per-frame allocations)
- Blend shape name -> index lookup is cached on avatar load
- Debug text updates are throttled to every 3rd frame
- Config hot-reload checks run every 2 seconds, not every frame

## Project structure

```
avatar-face-mvp/
  project.godot
  config/
    mapping.json          # Driver name -> VRM blendshape name
    tuning.json           # FFT bands, smoothing, sensitivity, blink timing
  scripts/
    avatar_controller.gd  # Main controller, wires drivers + mapper + mesh
    viseme_driver.gd      # FFT-based viseme extraction
    openseeface_driver.gd # OpenSeeFace UDP face tracking
    blink_controller.gd   # Procedural blink
    expression_mapper.gd  # Name mapping + smoothing
    config_loader.gd      # JSON config with hot-reload
    demo_ui.gd            # UI harness
    main.gd               # Scene bootstrap + VRM auto-loader
  scenes/
    main.tscn             # Full scene with lighting, camera, UI
  assets/
    avatars/              # Drop VRM files here
    audio/
      test_vowels.wav     # Generated test audio (5 viseme bands x2 cycles)
  tools/
    generate_test_audio.py  # Regenerate the test WAV
  addons/                 # Install godot-vrm here
```

## License

MIT
