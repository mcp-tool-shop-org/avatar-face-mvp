<p align="center">
<strong>Languages:</strong> <a href="README.md">English</a> | <a href="README.ja.md">日本語</a> | <a href="README.zh.md">中文</a> | <a href="README.es.md">Español</a> | <a href="README.fr.md">Français</a> | <a href="README.hi.md">हिंदी</a> | <a href="README.it.md">Italiano</a> | <a href="README.pt-BR.md">Português</a>
</p>

<p align="center">
  
            <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png"
           alt="Avatar Face MVP" width="280" />
</p>

[![Landing Page](https://img.shields.io/badge/Landing_Page-live-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

> **Prototype** -- proof-of-concept, not production software.
> See [Roadmap to v0.1.0](#roadmap-to-v010) for what needs to happen before a real release.

Real-time VRM avatar lipsync, expressions, idle animation, and TTS -- built with Godot 4.3+ and a Node.js bridge for voice synthesis.

## What this proves

1. **Mic in -> face moves convincingly** at 60 fps with zero-latency FFT visemes
2. **Webcam in -> full face tracking** via OpenSeeFace (52 ARKit blendshapes)
3. **Type text -> avatar speaks** with lip-synced TTS via KokoroSharp
4. **Download any CC0 VRM -> it just works** with auto-detected mapping profiles
5. **Everything is data-driven** -- swap mapping JSON, not code

## Status

| Feature | Status |
|---------|--------|
| FFT viseme lipsync (mic/WAV) | Working |
| OpenSeeFace webcam tracking | Working |
| Procedural blink (context-aware) | Working |
| Idle animation (breathing, sway, head drift) | Working |
| Eye gaze with micro-saccades | Working |
| Expression compositor (blinks > gaze > visemes > emotions) | Working |
| TTS bridge + voice synthesis | Working |
| Aside performance cues (emotion from TTS) | Working |
| BridgeManager auto-connect | Working |
| Avatar library (browse + download CC0 VRMs) | Working |
| Model diagnostics panel | Working |
| Mapping profiles (VRM / ARKit / VRChat) | Working |
| Hot-reloadable config (tuning.json, mapping.json) | Working |
| T-pose to A-pose arm correction | **Broken** -- WIP, not producing correct results |

## Stack

- **Runtime:** Godot 4.3+ (GL Compatibility renderer)
- **Avatar format:** VRM 0.0 and 1.0 (via vendored [godot-vrm](https://github.com/V-Sekai/godot-vrm) addon)
- **FFT driver:** Built-in `AudioEffectSpectrumAnalyzer` -> 5 viseme bands
- **Webcam driver:** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 ARKit blendshapes + head pose)
- **TTS bridge:** Node.js WebSocket relay connecting Godot to [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + optional [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside) for expression cues
- **TTS engine:** KokoroSharp (local, runs on GPU or CPU)
- **Config:** Data-driven JSON with 2-second hot-reload

## Setup

### Prerequisites

- [Godot 4.3+](https://godotengine.org/download) (GL Compatibility)
- [Node.js 18+](https://nodejs.org/) (for TTS bridge)
- A VRM avatar file (or use the bundled Seed-san test avatar)

### Quick start

```bash
# Clone
git clone https://github.com/mcp-tool-shop-org/avatar-face-mvp.git
cd avatar-face-mvp

# Install TTS bridge dependencies
cd tools/tts-bridge
npm install
cd ../..

# Open in Godot
# File -> Open Project -> select project.godot
# Press F5 to run
```

### First run

1. The app loads the first VRM it finds in `assets/avatars/`
2. BridgeManager auto-starts the TTS bridge and connects
3. Click **Start Mic** to see the avatar lip-sync to your voice
4. Or click **Play Test Vowels** to verify with a bundled test audio

### Quick test without a mic

A test file at `assets/audio/test_vowels.wav` cycles through all five viseme bands (ou, oh, aa, ih, ee) twice over ~10 seconds. Click "Play Test Vowels" to verify the FFT driver works.

To regenerate: `python tools/generate_test_audio.py`

### Using OpenSeeFace (webcam tracking)

1. Install and run [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)
2. In the demo UI, switch the driver dropdown to **OpenSeeFace (Webcam)**
3. The tracker sends 52 ARKit blendshapes + head pose via UDP to `127.0.0.1:11573`
4. Configure host/port in `config/tuning.json` under `openseeface`

### Using TTS

The TTS system uses a Node.js bridge to connect Godot to a local KokoroSharp voice synthesis server.

1. Ensure `voice-soundboard-mcp` is running (see its repo for setup)
2. The BridgeManager auto-spawns `tools/tts-bridge/bridge.mjs` and connects
3. The TTS panel auto-opens when connected -- type text and click **Speak**
4. Available voices are populated from the server (default: `am_fenrir`)
5. Optional: select an emotion to apply expression cues during speech

If the bridge fails to auto-connect, use the manual **Connect** button in the TTS panel.

## Controls

| Control | What it does |
|---------|-------------|
| **Avatar dropdown** | Switch between loaded VRM models |
| **Driver dropdown** | FFT (Mic Audio) or OpenSeeFace (Webcam) |
| **Mapping profile dropdown** | VRM Standard / ARKit / VRChat blend shape mapping |
| **Start Mic** | Begin mic capture for FFT viseme driver |
| **Load WAV/OGG** | Play a custom audio file through the FFT driver |
| **Play Test Vowels** | Play the bundled test audio |
| **Emotion dropdown + slider** | Manually blend an expression (happy, sad, angry, surprised) |
| **Sensitivity slider** | FFT magnitude multiplier (1-30, default 8) |
| **Zoom +/-** | Camera zoom (also: mouse wheel) |
| **Up / Down** | Camera height adjustment |
| **Model Diagnostics** | Toggle the diagnostics panel |
| **Avatar Library** | Browse and download CC0 VRM avatars |
| **TTS Speak** | Toggle the TTS panel |

### TTS panel

| Control | What it does |
|---------|-------------|
| **Connect / Disconnect** | Manual bridge connection toggle |
| **Voice dropdown** | Select TTS voice (auto-populated from server) |
| **Emotion dropdown** | Apply expression cues during speech |
| **Text box** | Type what the avatar should say |
| **Speak** | Synthesize and play |
| **Stop** | Cancel current playback |

### Model diagnostics panel

Shows real-time compatibility info for the loaded avatar:

- **Status badge** -- GREEN (all mapped), YELLOW (partial), RED (missing critical shapes)
- **Detected style** -- VRM Standard, ARKit, or VRChat
- **Profile suggestion** -- auto-suggests the correct mapping profile
- **Viseme coverage** -- which driver visemes map to which blend shapes (found/missing)
- **Expression coverage** -- same for blinks and emotions
- **Blink + eye bone status** -- whether procedural blink and bone-based gaze will work
- **Unmapped shapes** -- blend shapes on the model that aren't referenced by any mapping

## Configuration

### Tuning (`config/tuning.json`)

Hot-reloaded every 2 seconds. No restart needed.

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

### Mapping profiles (`config/mapping*.json`)

Three profiles ship with the project:

| File | Profile name | For models with |
|------|-------------|-----------------|
| `mapping.json` | VRM Standard | `lip_a`, `blink_L`, `face_happy` |
| `mapping_arkit.json` | ARKit | `jawOpen`, `eyeBlink_L`, `mouthSmile_L` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

The diagnostics panel auto-detects which profile matches the loaded model and suggests switching.

## Architecture

```
                       +-- VisemeDriver (FFT bands -> 5 viseme weights)
mic / wav / tracker -->|
                       +-- OpenSeeFaceDriver (UDP -> ARKit blendshapes)
                            |
                            v
                       BlinkController (procedural, context-aware)
                            |
                            v
                       GazeController (micro-saccades, eye bone / blendshape)
                            |
                            v
                       ExpressionMapper (driver names -> VRM names, smoothing)
                            |
                            v
                       Expression Compositor (blinks > gaze > visemes > emotions)
                            |
                            v
                       MeshInstance3D.set_blend_shape_value()
                       IdleController.apply() (breathing, sway, head drift)

--- TTS pipeline (separate) ---

Godot TtsController <--WebSocket--> bridge.mjs <--MCP--> voice-soundboard-mcp
                                                 <--MCP--> mcp-aside (optional)
          |
          v
     AudioStreamPlayer (Capture bus -> FFT viseme driver -> lipsync)
     Performance cues -> AvatarController.set_expression_target()
```

### Key design decisions

- **All hot-path dictionaries are pre-allocated** -- zero per-frame GC pressure
- **Blend shape name -> index lookup is cached** on avatar load
- **Debug UI updates are throttled** to every 3rd frame
- **Config hot-reload checks** run every 2 seconds, not every frame
- **BridgeManager probe-first pattern** -- checks if bridge is already running before spawning a new process
- **Expression compositor** resolves conflicts: blinks suppress eye shapes, visemes suppress mouth emotions, jaw deformation is clamped

## Project structure

```
avatar-face-mvp/
  project.godot
  config/
    mapping.json              # VRM Standard mapping profile
    mapping_arkit.json        # ARKit mapping profile
    mapping_vrchat.json       # VRChat mapping profile
    tuning.json               # FFT bands, smoothing, sensitivity, blink timing
  scripts/
    main.gd                   # Scene bootstrap, VRM loading, camera, bridge wiring
    avatar_controller.gd      # Master controller: drivers + mapper + compositor + mesh
    viseme_driver.gd          # FFT-based viseme extraction from AudioEffectSpectrumAnalyzer
    openseeface_driver.gd     # OpenSeeFace UDP client (52 ARKit blendshapes + head pose)
    blink_controller.gd       # Context-aware procedural blink (speech-suppressed, saccade-triggered)
    expression_mapper.gd      # Name mapping + asymmetric exponential smoothing + clamping
    idle_controller.gd        # Breathing, micro-sway, head drift, shoulder animation
    gaze_controller.gd        # Eye gaze: camera / wander / cursor modes, micro-saccades
    config_loader.gd          # JSON config with hot-reload + profile scanning
    demo_ui.gd                # UI harness (all panels, diagnostics, library, TTS)
    bridge_manager.gd         # TTS bridge auto-spawn + WebSocket probe with backoff
    tts_controller.gd         # WebSocket TTS client (speak, dialogue, stop, voices, aside cues)
    pose_corrector.gd         # T-pose -> A-pose arm correction (WIP, not working)
    vrm_runtime_loader.gd     # Runtime VRM loading via GLTFDocument + VRM extensions
    avatar_catalog.gd         # HTTP client for opensourceavatars.com CC0 avatar catalog
    avatar_download_manager.gd # VRM file downloader with progress + thumbnail cache
    library_ui.gd             # Avatar library browse/download panel
  scenes/
    main.tscn                 # Full scene (lighting, camera, UI, all controller nodes)
  assets/
    avatars/                  # Drop VRM files here (Seed-san bundled)
    audio/
      test_vowels.wav         # Generated test audio (5 viseme bands x 2 cycles)
  tools/
    tts-bridge/
      bridge.mjs              # Node.js WebSocket bridge (Godot <-> MCP servers)
      package.json
    generate_test_audio.py    # Regenerate the test WAV
  addons/
    vrm/                      # Vendored godot-vrm addon (V-Sekai)
```

## Known issues

- **T-pose arms**: VRM models load in T-pose after retargeting. The `pose_corrector.gd` attempts runtime correction via `set_bone_pose_rotation()` but the bone-local axis math is not producing correct results. This is the single biggest visual issue. The correct fix likely requires either modifying the VRM import pipeline's retarget target pose, or solving the bone-local rotation axis empirically per skeleton.
- **VRChat models**: Blend shape names use `blendShape1.vrc_v_*` prefix convention. The VRChat mapping profile handles this, but auto-detection may suggest the wrong profile on some models.
- **OpenSeeFace latency**: Head pose smoothing adds ~100ms of latency. Tune `head_pose_attack` / `head_pose_release` in `avatar_controller.gd` if needed.

## Roadmap to v0.1.0

The MVP proves the pipeline works. Here's what v0.1.0 needs to be a usable tool:

### Must have

- [ ] **Fix arm pose** -- models should load in natural A-pose, not T-pose. Either fix the runtime corrector or modify the godot-vrm import retarget to target A-pose reference poses.
- [ ] **Stable TTS bridge** -- handle bridge crashes gracefully, auto-reconnect, surface errors clearly in UI.
- [ ] **Audio device selection** -- let users pick their mic input device instead of relying on system default.
- [ ] **Save/restore settings** -- persist selected avatar, mapping profile, driver mode, sensitivity, and voice across sessions.
- [ ] **Error handling** -- catch and display failures for VRM loading, TTS synthesis, avatar downloads, and config parsing instead of silent console warnings.

### Should have

- [ ] **Emotion timeline** -- queue emotions with timing (e.g., "smile at 2s, surprised at 5s") for pre-recorded content.
- [ ] **Hotkey bindings** -- keyboard shortcuts for common actions (toggle mic, switch avatar, trigger expressions).
- [ ] **OBS integration** -- transparent background mode + virtual camera output for streaming.
- [ ] **Multiple voice support** -- per-avatar voice assignment.
- [ ] **Better idle variation** -- randomized idle animations to avoid robotic repetition.

### Nice to have

- [ ] **IK arm posing** -- replace the broken rotation approach with proper inverse kinematics.
- [ ] **Finger posing** -- VRM models have finger bones; add basic hand gestures.
- [ ] **Lipsync from pre-recorded audio** -- analyze WAV/MP3 files offline and generate viseme tracks.
- [ ] **Plugin architecture** -- modular driver/mapper/renderer system for third-party extensions.
- [ ] **Multi-avatar scenes** -- load multiple avatars for dialogue/interview scenarios.

### Out of scope (for now)

- Full body tracking
- Physics-based cloth/hair (handled by godot-vrm spring bones)
- Mobile support
- Networking / multiplayer

## License

MIT
