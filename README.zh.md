<p align="center">
  <a href="README.md">English</a> | <a href="README.es.md">Español</a> | <a href="README.fr.md">Français</a> | <a href="README.pt-BR.md">Português (BR)</a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png" alt="Avatar Face MVP" width="280" />
</p>

[![着陆页](https://img.shields.io/badge/Landing_Page-live-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

> **原型** -- 概念验证，不是生产环境的软件。
> 请参阅 [路线图](#roadmap-to-v010)，了解在正式发布之前需要完成的内容。

实时 VRM 角色的嘴唇同步、表情、闲置动画和文本转语音 -- 使用 Godot 4.3+ 构建，并使用 Node.js 桥接语音合成。

## 这证明了什么

1. **麦克风输入 -> 角色面部表情逼真**，帧率为 60 fps，延迟为零，使用 FFT 语音音素。
2. **摄像头输入 -> 全面部跟踪**，使用 OpenSeeFace (52 个 ARKit 混合形状)。
3. **输入文本 -> 角色说话**，使用 KokoroSharp 进行唇部同步的文本转语音。
4. **下载任何 CC0 VRM 角色 -> 它就能正常工作**，自动检测映射配置文件。
5. **所有内容都基于数据驱动** -- 交换映射 JSON 文件，而不是代码。

## 状态

| 功能 | 状态 |
|---------|--------|
| FFT 语音音素唇部同步 (麦克风/WAV) | 已完成 |
| OpenSeeFace 摄像头跟踪 | 已完成 |
| 程序化眨眼 (根据上下文) | 已完成 |
| 闲置动画 (呼吸、摇摆、头部晃动) | 已完成 |
| 眼神追踪 (带有微小抖动) | 已完成 |
| 表情合成器 (眨眼 > 眼神 > 语音音素 > 表情) | 已完成 |
| 文本转语音桥接 + 语音合成 | 已完成 |
| 辅助性能提示 (来自文本转语音的情绪) | 已完成 |
| BridgeManager 自动连接 | 已完成 |
| 角色库 (浏览 + 下载 CC0 VRM 角色) | 已完成 |
| 模型诊断面板 | 已完成 |
| 映射配置文件 (VRM / ARKit / VRChat) | 已完成 |
| 热重载配置 (tuning.json, mapping.json) | 已完成 |
| T 姿势到 A 姿势手臂校正 | **已损坏** -- 正在开发中，但未产生正确的结果。 |

## 技术栈

- **运行时:** Godot 4.3+ (GL 兼容渲染器)
- **角色格式:** VRM 0.0 和 1.0 (通过 vendored [godot-vrm](https://github.com/V-Sekai/godot-vrm) 插件)
- **FFT 驱动:** 内置 `AudioEffectSpectrumAnalyzer` -> 5 个语音音素频段
- **摄像头驱动:** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 个 ARKit 混合形状 + 头部姿态)
- **文本转语音桥接:** Node.js WebSocket 中继，连接 Godot 到 [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + 可选的 [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside)，用于表情提示。
- **文本转语音引擎:** KokoroSharp (本地，运行在 GPU 或 CPU 上)
- **配置:** 基于数据的 JSON 文件，支持 2 秒的热重载。

## 安装

### 先决条件

- [Godot 4.3+](https://godotengine.org/download) (GL 兼容)
- [Node.js 18+](https://nodejs.org/) (用于文本转语音桥接)
- 一个 VRM 角色文件 (或使用捆绑的 Seed-san 测试角色)

### 快速开始

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

1. 应用程序加载 `assets/avatars/` 目录中找到的第一个 VRM 角色。
2. BridgeManager 自动启动文本转语音桥接并连接。
3. 点击 **Start Mic** 按钮，让角色根据您的声音进行唇部同步。
4. 或者点击 **Play Test Vowels** 按钮，使用捆绑的测试音频进行验证。

### 无需麦克风的快速测试

`assets/audio/test_vowels.wav` 文件循环播放所有五个语音音素频段 (ou, oh, aa, ih, ee) 两次，持续约 10 秒。 点击 "Play Test Vowels" 按钮，以验证 FFT 驱动是否正常工作。

要重新生成：`python tools/generate_test_audio.py`

### 使用 OpenSeeFace (摄像头跟踪)

1. 安装并运行 [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)。
2. 在演示 UI 中，将驱动程序下拉菜单切换到 **OpenSeeFace (Webcam)**。
3. 跟踪器通过 UDP 将 52 个 ARKit 混合形状 + 头部姿态发送到 `127.0.0.1:11573`。
4. 在 `config/tuning.json` 文件的 `openseeface` 部分配置主机/端口。

### 使用文本转语音

该TTS系统使用Node.js桥接技术，将Godot与本地的KokoroSharp语音合成服务器连接起来。

1. 确保 `voice-soundboard-mcp` 正在运行（请参考其仓库以获取设置方法）。
2. BridgeManager会自动启动 `tools/tts-bridge/bridge.mjs` 并建立连接。
3. 连接成功后，TTS面板会自动打开——输入文本并点击 **Speak** 按钮。
4. 可用的语音将从服务器中加载（默认：`am_fenrir`）。
5. 可选：选择一种情感，以便在语音播放时应用表情提示。

如果桥接无法自动连接，请使用TTS面板中的手动 **Connect** 按钮。

## 控制

| 控制 | 功能描述 |
|---------|-------------|
| **Avatar dropdown** | 切换加载的VRM模型 |
| **Driver dropdown** | FFT（麦克风音频）或 OpenSeeFace（摄像头） |
| **Mapping profile dropdown** | VRM标准/ARKit/VRChat 混合形状映射 |
| **Start Mic** | 开始麦克风捕获，用于FFT唇形驱动 |
| **Load WAV/OGG** | 通过FFT驱动播放自定义音频文件 |
| **Play Test Vowels** | 播放内置的测试音频 |
| **Emotion dropdown + slider** | 手动混合表情（开心、悲伤、生气、惊讶） |
| **Sensitivity slider** | FFT幅度倍数（1-30，默认8） |
| **Zoom +/-** | 摄像头缩放（也可用鼠标滚轮） |
| **Up / Down** | 摄像头高度调整 |
| **Model Diagnostics** | 切换诊断面板 |
| **Avatar Library** | 浏览和下载CC0 VRM头像 |
| **TTS Speak** | 切换TTS面板 |

### TTS面板

| 控制 | 功能描述 |
|---------|-------------|
| **Connect / Disconnect** | 手动桥接连接切换 |
| **Voice dropdown** | 选择TTS语音（从服务器自动加载） |
| **Emotion dropdown** | 在语音播放时应用表情提示 |
| **Text box** | 输入虚拟角色要说的话 |
| **Speak** | 合成并播放 |
| **Stop** | 取消当前播放 |

### 模型诊断面板

显示加载的虚拟角色的实时兼容性信息：

- **状态标识** -- 绿色（所有形状已映射），黄色（部分映射），红色（缺少关键形状）
- **检测到的风格** -- VRM标准、ARKit或VRChat
- **配置文件建议** -- 自动建议正确的映射配置文件
- **唇形覆盖** -- 哪个驱动程序的唇形映射到哪个混合形状（已找到/缺失）
- **表情覆盖** -- 眨眼和表情的对应关系
- **眨眼 + 眼睛骨骼状态** -- 是否启用程序化眨眼和基于骨骼的凝视
- **未映射的形状** -- 模型上未被任何映射引用的混合形状

## 配置

### 调优 (`config/tuning.json`)

每2秒自动重新加载。无需重启。

| 键 | 功能描述 | 默认值 |
|-----|-------------|---------|
| `smoothing.attack_time` | 权重上升速度（秒） | 0.06 |
| `smoothing.release_time` | 权重下降速度（秒） | 0.12 |
| `viseme_bands.*` | 每个唇形的频率范围 [最小值, 最大值] Hz | 查看文件 |
| `noise_gate` | 将麦克风音频识别为语音的最小FFT幅度 | 0.01 |
| `sensitivity` | FFT幅度倍数 | 8.0 |
| `blink.*` | 程序化眨眼时间（间隔、持续时间、双重眨眼概率） | 查看文件 |
| `openseeface.host` | OpenSeeFace UDP主机 | 127.0.0.1 |
| `openseeface.port` | OpenSeeFace UDP端口 | 11573 |

### 映射配置文件 (`config/mapping*.json`)

该项目包含三个配置文件：

| 文件 | 配置文件名称 | 适用于以下模型 |
|------|-------------|-----------------|
| `mapping.json` | VRM标准 | `lip_a`, `blink_L`, `face_happy` |
| `mapping_arkit.json` | ARKit | `jawOpen`, `eyeBlink_L`, `mouthSmile_L` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

诊断面板会自动检测哪个配置文件与加载的模型匹配，并建议切换。

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

### 主要设计决策

- **所有关键数据字典都已预先分配**，从而减少每帧的垃圾回收压力。
- **面部表情名称到索引的映射关系**在加载角色时会被缓存。
- **调试界面的更新**频率限制为每3帧一次。
- **配置文件热重载的检查**每2秒进行一次，而不是每帧。
- **BridgeManager采用“先探测”模式**，即在启动新进程之前，先检查桥接程序是否已经运行。
- **表情合成器**会解决冲突：眨眼会抑制眼睛的变形，唇形会抑制面部表情，下颌变形会被限制。

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

- **T姿势的胳膊**: VRM模型在重新定向后会以T姿势加载。`pose_corrector.gd`脚本尝试通过`set_bone_pose_rotation()`进行运行时校正，但基于骨骼本地坐标轴的计算结果不正确。这是最大的视觉问题。正确的解决方案可能需要修改VRM导入流水线的重新定向目标姿势，或者针对每个骨骼，通过实验确定正确的骨骼本地旋转轴。
- **VRChat模型**: 面部表情名称使用`blendShape1.vrc_v_*`前缀。VRChat的映射配置文件可以处理这种情况，但自动检测可能在某些模型上建议错误的配置文件。
- **OpenSeeFace的延迟**: 头部姿势平滑会增加约100毫秒的延迟。如果需要，可以在`avatar_controller.gd`文件中调整`head_pose_attack` / `head_pose_release`参数。

## v0.1.0的开发计划

MVP（最小可行产品）证明了流水线可以工作。为了使v0.1.0成为一个可用工具，需要实现以下内容：

### 必须实现

- [ ] **修复胳膊姿势**：模型应该以自然的A姿势加载，而不是T姿势。要么修复运行时校正器，要么修改godot-vrm导入的重新定向功能，使其目标是A姿势的参考姿势。
- [ ] **稳定TTS桥接**：优雅地处理桥接程序崩溃，自动重新连接，并在UI中清晰地显示错误。
- [ ] **音频设备选择**：允许用户选择麦克风输入设备，而不是依赖系统默认设置。
- [ ] **保存/恢复设置**：在不同会话之间保存和恢复选定的角色、映射配置文件、驱动模式、灵敏度和语音设置。
- [ ] **错误处理**：捕获并显示VRM加载、TTS合成、角色下载和配置文件解析的失败情况，而不是在控制台中显示静默警告。

### 应该实现

- [ ] **情绪时间线**：为预录制内容设置带有时间轴的情绪（例如，“在2秒时微笑，在5秒时惊讶”）。
- [ ] **快捷键绑定**：键盘快捷键用于常用操作（例如，切换麦克风、切换角色、触发表情）。
- [ ] **OBS集成**：透明背景模式 + 虚拟摄像头输出，用于直播。
- [ ] **多语音支持**：为每个角色分配不同的语音。
- [ ] **更好的闲置动画**：随机化的闲置动画，以避免机械重复。

### 锦上添花

- [ ] **IK胳膊姿势**：用正确的逆运动学方法替换现有的旋转方法。
- [ ] **手指姿势**：VRM模型包含手指骨骼；添加基本的的手势。
- [ ] **从预录制音频进行唇形同步**：离线分析WAV/MP3文件，并生成唇形序列。
- [ ] **插件架构**：模块化的驱动程序/映射器/渲染器系统，用于第三方扩展。
- [ ] **多角色场景**：加载多个角色，用于对话/访谈场景。

### 当前不在计划范围内

- 全身跟踪
- 基于物理的布料/头发（由godot-vrm的弹簧骨骼处理）
- 移动设备支持
- 网络/多人游戏

## 安全与数据范围

Avatar Face MVP完全在本地运行，不涉及任何网络请求。

- **访问的数据：** 读取本地的VRM头像文件，从麦克风获取的音频输入，通过OpenSeeFace（本地主机的UDP协议）获取的网络摄像头画面。读取/写入项目目录中的JSON配置文件。可选地启动一个本地的Node.js文本转语音桥接进程。
- **未访问的数据：** 不进行任何互联网请求。不收集任何遥测数据。不使用任何云服务。不存储任何凭据。网络摄像头数据仅在本地进行处理。
- **所需权限：** 麦克风访问权限，用于唇形同步。可选的网络摄像头访问权限，通过OpenSeeFace实现。文件系统访问权限，用于VRM模型和配置。

请参考[SECURITY.md](SECURITY.md)文件，了解漏洞报告。

---

## 评分卡

| 类别 | 评分 |
|----------|-------|
| 安全性 | 10/10 |
| 错误处理 | 10/10 |
| 操作员文档 | 10/10 |
| 发布安全 | 10/10 |
| 身份验证 | 10/10 |
| **Overall** | **50/50** |

---

## 许可证

MIT

---

由<a href="https://mcp-tool-shop.github.io/">MCP Tool Shop</a>构建。
