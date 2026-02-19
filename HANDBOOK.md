# Avatar Face MVP -- Handbook

Practical guide to working with the codebase. Read the [README](README.md) first for setup and features.

## How the lipsync pipeline works

### FFT mode (default)

1. **Mic capture** -- Godot's `AudioStreamMicrophone` feeds the "Capture" audio bus
2. **Spectrum analysis** -- `AudioEffectSpectrumAnalyzer` (1024-sample FFT, 50ms buffer) extracts frequency magnitudes
3. **Viseme extraction** (`viseme_driver.gd`) -- five frequency bands map to five visemes:
   - `ou` (200-400 Hz) -- round mouth
   - `oh` (400-700 Hz) -- open round
   - `aa` (700-1200 Hz) -- wide open
   - `ih` (1200-2500 Hz) -- narrow
   - `ee` (2500-4000 Hz) -- spread
4. **Name mapping** (`expression_mapper.gd`) -- driver names like `aa` map to VRM names like `lip_a` via `mapping.json`
5. **Smoothing** -- asymmetric exponential: fast attack (60ms), slow release (120ms)
6. **Compositor** (`avatar_controller.gd:_apply_compositor`) -- resolves conflicts:
   - Blinks suppress eye-open shapes
   - Active visemes suppress mouth emotions (smile, frown)
   - Total jaw deformation clamped to 1.2
7. **Application** -- `MeshInstance3D.set_blend_shape_value()` via cached index lookup

### OpenSeeFace mode

Same pipeline from step 4 onward, but steps 1-3 are replaced by:

1. **Webcam** -- OpenSeeFace tracks the face and sends 52 ARKit blendshapes + head rotation via UDP
2. **UDP client** (`openseeface_driver.gd`) -- parses the binary protocol, extracts weights and pose
3. Head pose is smoothed with asymmetric exponential and applied via `IdleController.apply_head_pose()`
4. Large head movements trigger sympathetic blinks + eye saccades

### TTS mode

Separate pipeline that feeds into the FFT driver:

1. **User types text** in the TTS panel
2. **TtsController** sends `speak` command via WebSocket to `bridge.mjs`
3. **bridge.mjs** relays to `voice-soundboard-mcp` which synthesizes audio via KokoroSharp
4. Bridge returns the audio file path
5. **TtsController** loads the WAV and plays it through `AudioStreamPlayer` on the Capture bus
6. **The audio hits the FFT driver** automatically -- same spectrum analyzer, same viseme extraction
7. Optionally, `mcp-aside` sends performance cues (emotion + intensity) which `AvatarController.set_expression_target()` ramps smoothly

## Adding a new VRM model

1. Place the `.vrm` file in `assets/avatars/`
2. Run the project -- the model appears in the avatar dropdown
3. Select it and open **Model Diagnostics** to check compatibility
4. If the diagnostics panel suggests a different profile, switch the **Mapping Profile** dropdown
5. If the model has non-standard blend shape names, create a new `config/mapping_custom.json` (it will auto-appear in the profile dropdown)

### Mapping profile format

```json
{
  "profile_name": "My Custom Profile",
  "visemes": {
    "aa": "myModel_mouthOpen",
    "ih": "myModel_mouthNarrow",
    "ou": "myModel_mouthRound",
    "ee": "myModel_mouthWide",
    "oh": "myModel_mouthO"
  },
  "expressions": {
    "blink_left": "myModel_eyeCloseL",
    "blink_right": "myModel_eyeCloseR",
    "happy": "myModel_smile",
    "sad": "myModel_sad",
    "angry": "myModel_angry",
    "surprised": "myModel_surprised"
  }
}
```

Save as `config/mapping_mymodel.json`. The filename after `mapping_` becomes the profile name if `profile_name` is omitted.

## Downloading avatars at runtime

The **Avatar Library** panel fetches a catalog from [opensourceavatars.com](https://opensourceavatars.com) (CC0-licensed VRM files).

1. Click **Avatar Library** to open the panel
2. Browse available avatars
3. Click **Download** -- the VRM is saved to `user://avatars/`
4. Once downloaded, click **Load** to switch to it
5. Downloaded avatars persist across sessions

Downloads are single-threaded (one at a time) with progress reporting. Thumbnails are cached to `user://avatars/thumbs/`.

## The TTS bridge

### What it is

`tools/tts-bridge/bridge.mjs` is a Node.js process that translates between Godot's WebSocket messages and two MCP (Model Context Protocol) servers:

- **voice-soundboard-mcp** -- text-to-speech synthesis via KokoroSharp
- **mcp-aside** (optional) -- pushes expression cues ("smile now", "look surprised") that the avatar reacts to in real-time

### How auto-connect works

1. On startup, `BridgeManager` probes `ws://127.0.0.1:9200` to see if a bridge is already running
2. If not, it spawns `node tools/tts-bridge/bridge.mjs` as a child process
3. It retries the WebSocket probe with exponential backoff (up to 5 attempts)
4. When connected, `main.gd` auto-triggers `TtsController.connect_to_bridge()`
5. The TTS panel auto-opens and populates available voices

### Manual fallback

If auto-connect fails (no Node.js, no voice server, etc.):

1. Start the bridge manually: `cd tools/tts-bridge && node bridge.mjs`
2. Click **TTS Speak** to show the TTS panel
3. Click **Connect**

### Bridge protocol

All messages are JSON over WebSocket:

```
Godot -> Bridge:
  { "type": "speak", "text": "Hello", "voice": "am_fenrir", "speed": 1.0 }
  { "type": "dialogue", "script": "Alice: Hi\nBob: Hello", "cast": {...} }
  { "type": "stop" }
  { "type": "status" }

Bridge -> Godot:
  { "type": "speak_result", "path": "/path/to/audio.wav" }
  { "type": "voices", "voices": [{ "id": "am_fenrir", "name": "Fenrir" }, ...] }
  { "type": "status", "tts": "connected", "aside": "connected" }
  { "type": "error", "message": "..." }
  { "type": "aside_inbox", "items": [{ "text": "...", "meta": { "emotion": "happy" } }] }
```

## Tuning guide

### Viseme sensitivity

If the avatar barely moves its mouth:
- Increase **Sensitivity** slider (or `sensitivity` in `tuning.json`)
- Lower `noise_gate` (default 0.01)

If the mouth is jittery or moves during silence:
- Decrease sensitivity
- Raise `noise_gate`

### Blink timing

In `config/tuning.json` under `blink`:

| Key | What it does | Default |
|-----|-------------|---------|
| `min_interval` | Minimum seconds between blinks | 2.0 |
| `max_interval` | Maximum seconds between blinks | 6.0 |
| `duration` | How long a blink takes (seconds) | 0.15 |
| `double_chance` | Probability of a double-blink | 0.15 |

During speech, blinks are suppressed to avoid the "nervous blinker" look. Large head movements trigger sympathetic blinks (natural behavior).

### Expression smoothing

In `config/tuning.json` under `smoothing`:

- `attack_time` (0.06s) -- how fast a blend shape ramps up. Lower = snappier but jittery.
- `release_time` (0.12s) -- how fast it ramps down. Higher = smoother but laggy.

These are exponential time constants, not linear interpolation.

### Idle animation

Controlled by constants in `idle_controller.gd`:

- `BREATH_SPEED` -- breathing cycle speed
- `SWAY_SPEED` / `SWAY_AMOUNT` -- micro body sway
- `HEAD_DRIFT_SPEED` / `HEAD_DRIFT_AMOUNT` -- subtle head movement
- `SHOULDER_SPEED` / `SHOULDER_AMOUNT` -- shoulder breathing

The idle controller detects bone formats automatically (VRM standard, ARKit, VRChat, or Mixamo naming).

## Expression compositor rules

The compositor in `avatar_controller.gd:_apply_compositor()` enforces these priority rules:

1. **Blinks always win** -- when blink_L or blink_R > 0.1, all eye-look/eye-wide/eye-squint shapes are suppressed proportionally
2. **Visemes suppress mouth emotions** -- when total viseme weight > 0.1, smile/frown shapes are reduced by up to 80%
3. **Jaw clamp** -- total jaw + viseme + lip deformation is clamped to 1.2 to prevent mesh distortion
4. **Aside expressions ramp smoothly** -- performance cues from TTS use asymmetric attack (300ms) / release (1000ms) to avoid popping

## Bone and blend shape detection

The system auto-detects three model styles based on blend shape naming:

| Style | Detection markers | Mapping profile |
|-------|------------------|-----------------|
| VRM Standard | `lip_a`, `blink_L`, `face_happy` | VRM Standard |
| ARKit | `jawOpen`, `eyeBlink_L`, `mouthSmile_L` | ARKit |
| VRChat | `vrc_v_aa`, `vrc_blink` | VRChat |

Bone detection for idle animation and gaze works similarly, checking multiple naming conventions (VRM standard, Mixamo, Blender, generic).

## The T-pose problem

### What happens

VRM models are authored in T-pose (arms horizontal). The godot-vrm addon retargets the skeleton to match Godot's `SkeletonProfileHumanoid` reference pose, which is also T-pose. So models load with arms sticking out.

### What we tried

1. `set_bone_pose_rotation()` with computed quaternions -- correct idea but the bone-local axis conventions vary per model, and spring bones were suspected of overwriting (they don't -- spring bones only affect hair/tail/skirt)
2. `set_bone_rest()` with global-to-local space conversion -- breaks skin vertex bindings (arms disappear or fold into body)
3. Brute-force axis search -- tests all 6 cardinal axes at multiple angles, measures actual bone positions. Included in `pose_corrector.gd` but not producing correct visual results.

### Probable root causes

- `get_bone_global_pose()` may not update immediately after `set_bone_pose_rotation()` within the same frame, making the brute-force measurement unreliable
- The bone rest basis after retargeting may have non-trivial orientation that doesn't align with any cardinal axis
- Something else in the pipeline (idle controller, animation system) may be overwriting the pose

### Possible solutions for v0.1.0

1. **Modify the godot-vrm retarget target** -- change `skeleton_rotate()` in `vrm_utils.gd` to use an A-pose reference instead of T-pose
2. **Use a SkeletonModifier3D** -- Godot 4.2+ has a modifier system that runs at the right time in the bone update pipeline
3. **Pre-bake in Blender** -- rotate upper arms -45/+45 degrees and "Apply Pose as Rest Pose" before exporting as VRM
4. **Port to Unity** -- UniVRM handles this out of the box

## Performance notes

- All hot-path dictionaries are pre-allocated and reused (zero per-frame allocations)
- Blend shape name -> index lookup is cached in a Dictionary on avatar load
- Debug text updates are throttled to every 3rd frame
- Config hot-reload checks run every 2 seconds, not every frame
- `_process()` early-returns if no mesh is loaded
- BridgeManager uses exponential backoff to avoid spamming connection attempts
