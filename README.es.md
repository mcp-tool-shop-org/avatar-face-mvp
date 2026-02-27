<p align="center">
  <a href="README.zh.md">中文</a> | <a href="README.md">English</a> | <a href="README.fr.md">Français</a> | <a href="README.pt-BR.md">Português (BR)</a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png" alt="Avatar Face MVP" width="280" />
</p>

[![Landing Page](https://img.shields.io/badge/Landing_Page-live-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

> **Prototipo** -- software de prueba de concepto, no para producción.
> Consulte [Hoja de ruta para la versión 0.1.0](#roadmap-to-v010) para saber qué se necesita antes de una versión real.

Sincronización labial VRM en tiempo real, expresiones, animaciones de inactividad y síntesis de voz -- construido con Godot 4.3+ y un puente Node.js para la síntesis de voz.

## Lo que esto demuestra

1. **Micrófono -> la cara se mueve de forma convincente** a 60 fps con visemas FFT de latencia cero.
2. **Cámara web -> seguimiento facial completo** a través de OpenSeeFace (52 formas de mezcla ARKit).
3. **Escribir texto -> el avatar habla** con síntesis de voz sincronizada con los labios a través de KokoroSharp.
4. **Descargar cualquier avatar VRM con licencia CC0 -> simplemente funciona** con perfiles de mapeo detectados automáticamente.
5. **Todo está basado en datos** -- cambie el JSON de mapeo, no el código.

## Estado

| Función | Estado |
|---------|--------|
| Sincronización labial FFT (micrófono/WAV) | En funcionamiento |
| Seguimiento de cámara web OpenSeeFace | En funcionamiento |
| Parpadeo procedural (consciente del contexto) | En funcionamiento |
| Animación de inactividad (respiración, balanceo, movimiento de cabeza) | En funcionamiento |
| Mirada con micro-sacádicos | En funcionamiento |
| Compilador de expresiones (parpadeo > mirada > visemas > emociones) | En funcionamiento |
| Puente de síntesis de voz + síntesis de voz | En funcionamiento |
| Pistas de rendimiento adicionales (emoción de la síntesis de voz) | En funcionamiento |
| Conexión automática de BridgeManager | En funcionamiento |
| Biblioteca de avatares (explorar y descargar avatares VRM con licencia CC0) | En funcionamiento |
| Panel de diagnóstico del modelo | En funcionamiento |
| Perfiles de mapeo (VRM / ARKit / VRChat) | En funcionamiento |
| Configuración con recarga automática (tuning.json, mapping.json) | En funcionamiento |
| Corrección de la postura de los brazos de T a A | **No funciona** -- en desarrollo, no produce resultados correctos. |

## Pila

- **Entorno de ejecución:** Godot 4.3+ (renderizador de compatibilidad con GL)
- **Formato de avatar:** VRM 0.0 y 1.0 (a través del complemento [godot-vrm](https://github.com/V-Sekai/godot-vrm) incluido)
- **Controlador FFT:** `AudioEffectSpectrumAnalyzer` integrado -> 5 bandas de visemas
- **Controlador de cámara web:** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 formas de mezcla ARKit + pose de la cabeza)
- **Puente de síntesis de voz:** Relé WebSocket de Node.js que conecta Godot con [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + opcional [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside) para pistas de expresión.
- **Motor de síntesis de voz:** KokoroSharp (local, se ejecuta en GPU o CPU)
- **Configuración:** Basada en datos JSON con recarga automática de 2 segundos.

## Configuración

### Requisitos previos

- [Godot 4.3+](https://godotengine.org/download) (Compatibilidad con GL)
- [Node.js 18+](https://nodejs.org/) (para el puente de síntesis de voz)
- Un archivo de avatar VRM (o use el avatar de prueba Seed-san incluido)

### Comienzo rápido

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

### Primera ejecución

1. La aplicación carga el primer avatar VRM que encuentra en `assets/avatars/`.
2. BridgeManager inicia automáticamente el puente de síntesis de voz y se conecta.
3. Haga clic en **Iniciar micrófono** para ver cómo el avatar sincroniza los labios con su voz.
4. O haga clic en **Reproducir vocales de prueba** para verificarlo con un audio de prueba incluido.

### Prueba rápida sin micrófono

Un archivo de prueba en `assets/audio/test_vowels.wav` reproduce todas las cinco bandas de visemas dos veces durante unos 10 segundos. Haga clic en "Reproducir vocales de prueba" para verificar que el controlador FFT funciona.

Para regenerar: `python tools/generate_test_audio.py`

### Usando OpenSeeFace (seguimiento de cámara web)

1. Instale y ejecute [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace).
2. En la interfaz de usuario de la demostración, cambie el menú desplegable del controlador a **OpenSeeFace (Cámara web)**.
3. El rastreador envía 52 formas de mezcla ARKit + pose de la cabeza a través de UDP a `127.0.0.1:11573`.
4. Configure el host/puerto en `config/tuning.json` bajo `openseeface`.

### Usando la síntesis de voz

El sistema TTS utiliza un puente Node.js para conectar Godot con un servidor local de síntesis de voz KokoroSharp.

1. Asegúrese de que `voice-soundboard-mcp` esté en ejecución (consulte el repositorio correspondiente para la configuración).
2. El administrador del puente crea automáticamente el archivo `tools/tts-bridge/bridge.mjs` y se conecta.
3. El panel TTS se abre automáticamente al conectarse; escriba el texto y haga clic en **Hablar**.
4. Las voces disponibles se obtienen del servidor (por defecto: `am_fenrir`).
5. Opcional: seleccione una emoción para aplicar indicaciones de expresión durante el habla.

Si el puente no se conecta automáticamente, utilice el botón **Conectar** manualmente en el panel TTS.

## Controles

| Control | Función |
|---------|-------------|
| **Avatar dropdown** | Cambiar entre los modelos VRM cargados. |
| **Driver dropdown** | FFT (audio del micrófono) o OpenSeeFace (cámara web). |
| **Mapping profile dropdown** | Mapeo de formas de mezcla VRM Standard / ARKit / VRChat. |
| **Start Mic** | Iniciar la captura de audio del micrófono para el controlador de visemas FFT. |
| **Load WAV/OGG** | Reproducir un archivo de audio personalizado a través del controlador FFT. |
| **Play Test Vowels** | Reproducir el audio de prueba incluido. |
| **Emotion dropdown + slider** | Mezclar manualmente una expresión (feliz, triste, enojado, sorprendido). |
| **Sensitivity slider** | Multiplicador de magnitud FFT (1-30, por defecto 8). |
| **Zoom +/-** | Zoom de la cámara (también: rueda del ratón). |
| **Up / Down** | Ajuste de la altura de la cámara. |
| **Model Diagnostics** | Alternar el panel de diagnóstico. |
| **Avatar Library** | Explorar y descargar avatares VRM CC0. |
| **TTS Speak** | Alternar el panel TTS. |

### Panel TTS

| Control | Función |
|---------|-------------|
| **Connect / Disconnect** | Alternar la conexión manual del puente. |
| **Voice dropdown** | Seleccionar la voz TTS (se obtiene automáticamente del servidor). |
| **Emotion dropdown** | Aplicar indicaciones de expresión durante el habla. |
| **Text box** | Escribir lo que el avatar debe decir. |
| **Speak** | Sintetizar y reproducir. |
| **Stop** | Cancelar la reproducción actual. |

### Panel de diagnóstico del modelo

Muestra información de compatibilidad en tiempo real para el avatar cargado:

- **Insignia de estado** -- VERDE (todo mapeado), AMARILLO (parcial), ROJO (falta de formas críticas).
- **Estilo detectado** -- VRM Standard, ARKit o VRChat.
- **Sugerencia de perfil** -- sugiere automáticamente el perfil de mapeo correcto.
- **Cobertura de visemas** -- qué controladores de visemas se mapean a qué formas de mezcla (encontrado/faltante).
- **Cobertura de expresiones** -- lo mismo para parpadeos y emociones.
- **Estado del parpadeo y el hueso del ojo** -- si el parpadeo procedural y la mirada basada en huesos funcionarán.
- **Formas no mapeadas** -- formas de mezcla en el modelo que no están referenciadas por ningún mapeo.

## Configuración

### Ajustes (`config/tuning.json`)

Se recarga cada 2 segundos. No es necesario reiniciar.

| Clave | Función | Valor predeterminado |
|-----|-------------|---------|
| `smoothing.attack_time` | Velocidad de aumento de los pesos (segundos) | 0.06 |
| `smoothing.release_time` | Velocidad de disminución de los pesos (segundos) | 0.12 |
| `viseme_bands.*` | Rangos de frecuencia [mínimo, máximo] Hz por visema | ver archivo |
| `noise_gate` | Magnitud mínima de FFT para registrarse como habla. | 0.01 |
| `sensitivity` | Multiplicador de magnitud FFT. | 8.0 |
| `blink.*` | Temporización del parpadeo procedural (intervalo, duración, probabilidad de doble parpadeo). | ver archivo |
| `openseeface.host` | Host UDP de OpenSeeFace. | 127.0.0.1 |
| `openseeface.port` | Puerto UDP de OpenSeeFace. | 11573 |

### Perfiles de mapeo (`config/mapping*.json`)

Se incluyen tres perfiles con el proyecto:

| Archivo | Nombre del perfil | Para modelos con |
|------|-------------|-----------------|
| `mapping.json` | VRM Standard | `lip_a`, `blink_L`, `face_happy` |
| `mapping_arkit.json` | ARKit | `jawOpen`, `eyeBlink_L`, `mouthSmile_L` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

El panel de diagnóstico detecta automáticamente qué perfil coincide con el modelo cargado y sugiere cambiarlo.

## Arquitectura

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

### Decisiones clave de diseño

- **Todos los diccionarios de acceso frecuente están pre-asignados** -- sin sobrecarga de GC por fotograma.
- **La búsqueda del nombre de la forma de mezcla a su índice se almacena en caché** al cargar el avatar.
- **Las actualizaciones de la interfaz de depuración se limitan** a cada tercer fotograma.
- **Las comprobaciones de recarga de la configuración se realizan** cada 2 segundos, no por fotograma.
- **El patrón de "sondeo primero" de BridgeManager** comprueba si el puente ya se está ejecutando antes de iniciar un nuevo proceso.
- **El compositor de expresiones** resuelve conflictos: los parpadeos suprimen las formas de los ojos, los visemas suprimen las expresiones de la boca, la deformación de la mandíbula está limitada.

## Estructura del proyecto

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

## Problemas conocidos

- **Brazos en pose T**: Los modelos VRM se cargan en pose T después de la reasignación. El script `pose_corrector.gd` intenta corregir en tiempo de ejecución mediante `set_bone_pose_rotation()`, pero la matemática de los ejes locales de los huesos no produce resultados correctos. Este es el problema visual más importante. La solución correcta probablemente requiere modificar la canalización de importación de VRM para reasignar la pose de referencia a la pose A, o resolver los ejes de rotación locales de los huesos empíricamente para cada esqueleto.
- **Modelos de VRChat**: Los nombres de las formas de mezcla utilizan el prefijo `blendShape1.vrc_v_*`. El perfil de mapeo de VRChat gestiona esto, pero la detección automática puede sugerir el perfil incorrecto en algunos modelos.
- **Latencia de OpenSeeFace**: El suavizado de la pose de la cabeza añade aproximadamente 100 ms de latencia. Ajuste `head_pose_attack` / `head_pose_release` en `avatar_controller.gd` si es necesario.

## Hoja de ruta para la versión 0.1.0

El MVP demuestra que la canalización funciona. Esto es lo que la versión 0.1.0 necesita para ser una herramienta utilizable:

### Imprescindible

- [ ] **Corregir la pose de los brazos** -- los modelos deben cargarse en la pose A natural, no en la pose T. Ya sea corrigiendo el corrector en tiempo de ejecución o modificando la reasignación de importación de godot-vrm para apuntar a poses de referencia A.
- [ ] **Puente TTS estable** -- gestionar los fallos del puente de forma elegante, reconexión automática, mostrar errores claramente en la interfaz de usuario.
- [ ] **Selección del dispositivo de audio** -- permitir a los usuarios elegir su dispositivo de entrada de micrófono en lugar de depender de la configuración predeterminada del sistema.
- [ ] **Guardar/restaurar la configuración** -- mantener seleccionado el avatar, el perfil de mapeo, el modo del controlador, la sensibilidad y la voz en cada sesión.
- [ ] **Manejo de errores** -- capturar y mostrar los fallos de la carga de VRM, la síntesis de TTS, las descargas de avatares y el análisis de la configuración en lugar de mostrar advertencias silenciosas en la consola.

### Debería tener

- [ ] **Línea de tiempo de emociones** -- programar emociones con temporización (por ejemplo, "sonreír a los 2 segundos, sorprenderse a los 5 segundos") para contenido pregrabado.
- [ ] **Enlace de teclas de acceso** -- atajos de teclado para acciones comunes (activar/desactivar el micrófono, cambiar de avatar, activar expresiones).
- [ ] **Integración con OBS** -- modo de fondo transparente + salida de cámara virtual para la transmisión.
- [ ] **Soporte para múltiples voces** -- asignación de voz por avatar.
- [ ] **Mejor variación en reposo** -- animaciones de reposo aleatorias para evitar la repetición robótica.

### Sería bueno tener

- [ ] **Poseo de brazos con IK** -- reemplazar el enfoque de rotación defectuoso con cinemática inversa adecuada.
- [ ] **Poseo de dedos** -- modelos VRM tienen huesos de dedos; añadir gestos básicos de la mano.
- [ ] **Sincronización labial a partir de audio pregrabado** -- analizar archivos WAV/MP3 sin conexión y generar pistas de visemas.
- [ ] **Arquitectura de plugin** -- sistema modular de controladores/mapeadores/renderizadores para extensiones de terceros.
- [ ] **Escenas con múltiples avatares** -- cargar múltiples avatares para escenarios de diálogo/entrevistas.

### Fuera del alcance (por ahora)

- Seguimiento del cuerpo completo
- Tejido/pelo basados en la física (gestionados por los huesos de resorte de godot-vrm)
- Soporte para dispositivos móviles
- Redes / multijugador

## Seguridad y alcance de los datos

Avatar Face MVP funciona **completamente localmente** sin realizar solicitudes de red.

- **Datos accedidos:** Lee archivos de avatar VRM locales, entrada de audio desde el micrófono, la transmisión de la cámara web a través de OpenSeeFace (UDP en localhost). Lee/escribe archivos de configuración JSON en el directorio del proyecto. Opcionalmente, inicia un proceso local de puente TTS (Text-to-Speech) de Node.js.
- **Datos NO accedidos:** No hay solicitudes a Internet. No hay telemetría. No hay servicios en la nube. No hay almacenamiento de credenciales. Los datos de la cámara web se procesan localmente únicamente.
- **Permisos requeridos:** Acceso al micrófono para la sincronización labial. Acceso opcional a la cámara web a través de OpenSeeFace. Acceso al sistema de archivos para modelos VRM y configuración.

Consulte [SECURITY.md](SECURITY.md) para informar sobre vulnerabilidades.

---

## Cuadro de evaluación

| Categoría | Puntuación |
|----------|-------|
| Seguridad | 10/10 |
| Manejo de errores | 10/10 |
| Documentación para el usuario | 10/10 |
| Higiene en el desarrollo | 10/10 |
| Identidad | 10/10 |
| **Overall** | **50/50** |

---

## Licencia

MIT

---

Creado por <a href="https://mcp-tool-shop.github.io/">MCP Tool Shop</a>
