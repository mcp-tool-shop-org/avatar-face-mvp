<p align="center">
  <img src="assets/logo.png" alt="Avatar Face MVP" width="280" />
</p>

[![着陆页](https://img.shields.io/badge/Landing_Page-live-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

**原型**：仅为概念验证，并非正式产品软件。
请参考[发布路线图至 v0.1.0](#roadmap-to-v010)，了解在正式发布之前需要完成的工作。

实时VRM虚拟人物的口型同步、表情、闲置动画以及文本转语音功能，基于Godot 4.3及以上版本构建，并使用Node.js桥接技术实现语音合成。

## 这证明了什么

1. **麦克风输入 -> 面部表情逼真地变化**，帧率为 60fps，采用零延迟的 FFT 唇形同步技术。
2. **摄像头输入 -> 全面部追踪**，通过 OpenSeeFace 实现（支持 52 种 ARKit 混合形状）。
3. **输入文本 -> 虚拟形象会说话**，采用 KokoroSharp 实现唇形同步的文本转语音功能。
4. **下载任何 CC0 格式的 VRM 模型 -> 即可直接使用**，系统会自动检测并应用相应的映射配置。
5. **所有功能都基于数据驱动**，修改映射的 JSON 文件，而不是代码。

## 状态

| 特点。 | 状态。 |
| 好的，请提供需要翻译的英文文本。 | 好的，请提供需要翻译的英文文本。 |
| 基于快速傅里叶变换（FFT）的唇部同步技术（适用于麦克风/WAV音频）。 | 工作。 |
| OpenSeeFace 摄像头追踪功能。 | 工作。 |
| 程序级闪烁（基于上下文感知） | 工作。 |
| 静止状态动画（呼吸、摇晃、头部移动）。 | 工作。 |
| 微小眼动下的注视。 | 工作。 |
| 表情合成器（眨眼 > 凝视 > 口型变化 > 情感）。 | 工作。 |
| 文本转语音桥接 + 语音合成。 | 工作。 |
| 除了性能指标之外，还包括文本转语音系统所表现出的情感特征。 | 工作。 |
| BridgeManager 自动连接功能。 | 工作。 |
| 虚拟形象库（浏览并下载 CC0 格式的 VRM 文件）。 | 工作。 |
| 模型诊断面板。 | 工作。 |
| 设备配置文件（VRM / ARKit / VRChat）。 | 工作。 |
| 支持热重载的配置文件（tuning.json、mapping.json）。 | 工作。 |
| 将T字型姿势调整为A字型姿势，并进行手臂校正。 | **已损坏** -- 正在开发中，尚未产生正确的结果。 |

## 堆栈

- **运行环境：** Godot 4.3 及以上版本 (支持 GL 兼容渲染器)
- **角色模型格式：** VRM 0.0 和 1.0 (通过集成的 [godot-vrm](https://github.com/V-Sekai/godot-vrm) 插件)
- **FFT 驱动：** 内置 `AudioEffectSpectrumAnalyzer` -> 5 个可视音素频段
- **摄像头驱动：** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 个 ARKit 混合形状 + 头部姿态)
- **TTS 桥接：** Node.js WebSocket 代理，连接 Godot 与 [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + 可选的 [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside)，用于表情提示
- **TTS 引擎：** KokoroSharp (本地运行，可在 GPU 或 CPU 上运行)
- **配置：** 基于数据的 JSON 格式，支持 2 秒的热重载。

## 设置

### 先决条件

- Godot 4.3 及以上版本 (支持 OpenGL)
- Node.js 18 及以上版本 (用于文本转语音功能)
- 一个 VRM 格式的虚拟人物文件 (或者使用自带的 Seed-san 测试虚拟人物)

### 快速入门

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

### 首次运行

1. 该应用程序会加载 `assets/avatars/` 目录下找到的第一个 VRM 文件。
2. BridgeManager 会自动启动文本转语音（TTS）桥接程序并建立连接。
3. 点击“开始麦克风”按钮，您可以看到虚拟角色根据您的声音进行口型同步。
4. 或者，点击“播放测试音节”按钮，可以使用内置的测试音频进行验证。

### 无需麦克风的快速测试

一个测试文件位于 `assets/audio/test_vowels.wav`，它会在大约10秒内循环播放所有五个音素频段（"ou"、"oh"、"aa"、"ih"、"ee"），每个频段播放两次。点击“播放测试音素”按钮，以验证FFT驱动程序是否正常工作。

用于重新生成测试音频：`python tools/generate_test_audio.py`

### 使用 OpenSeeFace (摄像头追踪)

1. 安装并运行 [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)。
2. 在演示界面的用户界面中，将驱动程序下拉菜单切换到 **OpenSeeFace (摄像头)**。
3. 追踪器通过 UDP 将 52 个 ARKit 混合形状数据以及头部姿态发送到 `127.0.0.1:11573`。
4. 在 `config/tuning.json` 文件的 `openseeface` 目录下，配置主机和端口。

### 使用文本转语音 (TTS) 功能

该TTS系统使用一个Node.js桥接组件，将Godot引擎连接到本地的KokoroSharp语音合成服务器。

1. 确保 `voice-soundboard-mcp` 正在运行（请参考其仓库中的设置说明）。
2. BridgeManager 会自动启动 `tools/tts-bridge/bridge.mjs` 并建立连接。
3. 连接成功后，TTS 面板会自动打开——在文本框中输入文字，然后点击“说话”按钮。
4. 可用的语音将从服务器加载（默认语音：`am_fenrir`）。
5. 可选：可以选择一种情感，以便在语音播放时应用相应的表达效果。

如果连接无法自动建立，请在TTS控制面板中使用手动“连接”按钮。

## 控制装置；控制

| 控制。 | 它的作用。 |
| 好的，请提供需要翻译的英文文本。 | 好的，请提供需要翻译的英文文本。 |
| **Avatar dropdown** | 在已加载的VRM模型之间进行切换。 |
| **Driver dropdown** | FFT（麦克风音频）或 OpenSeeFace（摄像头）。 |
| **Mapping profile dropdown** | VRM 标准 / ARKit / VRChat 混合形状映射。 |
| **Start Mic** | 开始麦克风采集，用于FFT音素驱动程序。 |
| **Load WAV/OGG** | 通过 FFT 驱动播放自定义音频文件。 |
| **Play Test Vowels** | 播放捆绑提供的测试音频。 |
| **Emotion dropdown + slider** | 手动混合一种表情（例如：高兴、悲伤、愤怒、惊讶）。 |
| **Sensitivity slider** | FFT 幅度倍增器 (1-30，默认值为 8)。 |
| **Zoom +/-** | 相机变焦 (也可通过鼠标滚轮控制) |
| **Up / Down** | 相机高度调节。 |
| **Model Diagnostics** | 切换诊断面板。 |
| **Avatar Library** | 浏览并下载 CC0 许可的 VRM 虚拟形象。 |
| **TTS Speak** | 切换文本转语音（TTS）面板。 |

### TTS控制面板

| 控制。 | 它的作用。 |
| 好的，请提供需要翻译的英文文本。 | 好的，请提供需要翻译的英文文本。 |
| **Connect / Disconnect** | 手动桥接连接开关。 |
| **Voice dropdown** | 选择文本转语音（TTS）的声音（系统将从服务器自动填充可用选项）。 |
| **Emotion dropdown** | 在说话时，注意运用表情和语气。 |
| **Text box** | 请输入您希望虚拟形象说的话。 |
| **Speak** | 合成并播放。 |
| **Stop** | 停止当前播放。 |

### 模型诊断面板

显示已加载角色的实时兼容性信息：

- **状态标识：** 绿色（已完全映射），黄色（部分映射），红色（缺少关键形状）。
- **检测到的风格：** VRM 标准、ARKit 或 VRChat。
- **配置文件建议：** 自动推荐正确的映射配置文件。
- **唇形覆盖范围：** 显示哪些驱动唇形与哪些混合形状对应（已找到/缺失）。
- **表情覆盖范围：** 同样适用于眨眼和表情。
- **眨眼 + 眼睛骨骼状态：** 指示程序化眨眼和基于骨骼的视线追踪是否有效。
- **未映射的形状：** 模型上存在但未被任何映射引用的混合形状。

## 配置

### 调优配置 (`config/tuning.json`)

每2秒自动重新加载，无需重启。

| Key | 它的作用/功能。 | 默认设置。 |
|-----| 好的，请提供需要翻译的英文文本。 | 好的，请提供需要翻译的英文文本。 |
| `smoothing.attack_time` | 重量上升的速度（以秒为单位）。 | 0.06 |
| `smoothing.release_time` | 重量物体的下落速度（以秒为单位）。 | 0.12 |
| `viseme_bands.*` | 每个音素对应的频率范围：[最小值, 最大值] 赫兹。 | 请参考文件。 |
| `noise_gate` | 将快速傅里叶变换（FFT）的幅度值设为语音信号的最低阈值。 | 0.01 |
| `sensitivity` | 快速傅里叶变换幅度倍增器。 | 8.0 |
| `blink.*` | 程序性眨眼时序（间隔、持续时间、双重眨眼概率）。 | 请参考文件。 |
| `openseeface.host` | OpenSeeFace UDP 主机。 | 127.0.0.1 |
| `openseeface.port` | OpenSeeFace 的 UDP 端口。 | 11573 |

### 映射配置文件 (`config/mapping*.json`)

该项目包含三个预设配置方案。

| File | 配置文件名称。 | 适用于以下型号的产品： |
| 好的，请提供需要翻译的英文文本。 | 好的，请提供需要翻译的英文文本。 | 好的，请提供需要翻译的英文文本。 |
| `mapping.json` | VRM 标准。 | `lip_a`: 嘴唇 (A 状态)
`blink_L`: 左眼眨动
`face_happy`: 快乐的表情 |
| `mapping_arkit.json` | ARKit | `jawOpen`：张开嘴巴
`eyeBlink_L`：左眼眨动
`mouthSmile_L`：左侧嘴角上扬 (或 左侧微笑) |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`，`vrc_blink` |

诊断面板会自动检测已加载的模型，并匹配相应的配置方案，同时会提示用户进行切换。

## 架构

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

### 关键的设计决策

- **所有关键路径字典都已预先分配**，从而避免每帧产生的垃圾回收压力。
- **角色模型加载时，会将“混合形状名称”与“索引”的对应关系缓存起来。**
- **调试界面的更新频率被限制为每3帧一次。**
- **配置文件热重载的检查每2秒进行一次，而不是每帧。**
- **桥接管理器采用“先探测”模式**，即在启动新进程之前，会检查桥接是否已经运行。
- **表情合成器会解决冲突：眨眼会抑制眼睛的形状，音节会抑制嘴巴的情绪，下颌的变形会被限制在一定范围内。**

## 项目结构

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

## 已知问题

- **T字型姿势：** VRM模型在重新映射后会以T字型姿势加载。`pose_corrector.gd`脚本尝试在运行时通过`set_bone_pose_rotation()`进行姿势校正，但基于骨骼局部的坐标计算并未产生正确的结果。这是最主要的视觉问题。正确的解决方案可能需要修改VRM导入流水线中的目标姿势，或者针对每个骨骼，通过实验确定正确的骨骼局部旋转轴。
- **VRChat模型：** 混合形状名称使用`blendShape1.vrc_v_*`前缀。VRChat的映射配置文件会处理这种情况，但自动检测可能在某些模型上建议错误的配置文件。
- **OpenSeeFace延迟：**头部姿势平滑处理会增加约100毫秒的延迟。如果需要，请在`avatar_controller.gd`文件中调整`head_pose_attack`和`head_pose_release`参数。

## v0.1.0版本的开发路线图

MVP（最小可行产品）证明了流水线是可行的。以下是v0.1.0版本需要具备的特性，才能成为一个可用工具：

### 必备条件

- [ ] **修复人物姿势**：模型应以自然姿势（A 姿势）加载，而不是 T 姿势。要么修复运行时校正器，要么修改 godot-vrm 导入重定向功能，使其针对 A 姿势的参考姿势。
- [ ] **稳定 TTS 桥接**：优雅地处理桥接中断，自动重新连接，并在用户界面上清晰地显示错误信息。
- [ ] **音频设备选择**：允许用户选择麦克风输入设备，而不是依赖系统默认设置。
- [ ] **保存/恢复设置**：在不同会话之间保存和恢复所选的虚拟形象、映射配置文件、驱动模式、灵敏度和语音设置。
- [ ] **错误处理**：捕获并显示 VRM 加载、TTS 语音合成、虚拟形象下载和配置文件解析等过程中的错误，而不是在控制台中显示静默警告。

### 应该

- [ ] **情感时间轴**：为预录内容设置情感变化的时间点（例如：“在2秒时微笑，在5秒时表现惊讶”）。
- [ ] **快捷键绑定**：为常用操作设置键盘快捷键（例如：切换麦克风、切换头像、触发表情）。
- [ ] **OBS集成**：支持透明背景模式，并提供虚拟摄像头输出，方便直播。
- [ ] **多语音支持**：可以为每个头像分配不同的语音。
- [ ] **更丰富的待机动画**：采用随机化的待机动画，避免机械重复。

### 不错，值得拥有

- [ ] **IK 姿态控制** -- 替换现有的旋转方法，采用正确的逆运动学算法。
- [ ] **手指姿态** -- VRM 模型包含手指骨骼；添加基本的肢体动作。
- [ ] **从预录音频进行唇形同步** -- 离线分析 WAV/MP3 文件，生成唇形序列。
- [ ] **插件架构** -- 模块化的驱动程序/映射器/渲染系统，用于支持第三方扩展。
- [ ] **多角色场景** -- 加载多个角色，用于对话/访谈等场景。

### 目前不在讨论范围内

- 全身动作捕捉
- 基于物理的服装/头发模拟 (由 godot-vrm 的弹簧骨骼技术实现)
- 移动设备支持
- 网络/多人游戏功能

## 许可

麻省理工学院。
