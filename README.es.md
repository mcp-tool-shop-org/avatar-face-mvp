<p align="center">
  <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png" alt="Avatar Face MVP" width="280" />
</p>

[![Página de inicio](https://img.shields.io/badge/Landing_Page-en_funcionamiento-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

**Prototipo:** Demostración de concepto, no software de producción.
Consulte [Hoja de ruta para la versión 0.1.0](#hoja-de-ruta-para-la-version-010) para ver qué pasos deben seguirse antes de una versión oficial.

Sincronización labial en tiempo real para avatares VRM, expresiones faciales, animaciones de reposo y texto a voz (TTS), todo construido con Godot 4.3 o superior y una interfaz Node.js para la síntesis de voz.

## Lo que esto demuestra

1. **Entrada de micrófono -> el rostro se mueve de forma realista** a 60 fotogramas por segundo, con visemes de transformada rápida de Fourier (FFT) sin latencia.
2. **Entrada de cámara web -> seguimiento completo del rostro** a través de OpenSeeFace (52 formas de mezcla de ARKit).
3. **Escriba texto -> el avatar habla** con sincronización labial mediante TTS (text-to-speech) a través de KokoroSharp.
4. **Descargue cualquier modelo VRM con licencia CC0 -> simplemente funciona** con perfiles de mapeo detectados automáticamente.
5. **Todo está basado en datos**: se intercambian archivos JSON de mapeo, no código.

## Estado

| Característica. | Estado. |
| Please provide the English text you would like me to translate. I am ready to translate it into Spanish. | Please provide the English text you would like me to translate. I am ready to translate it into Spanish. |
| Sincronización labial mediante análisis de Fourier (FFT) (micrófono/WAV). | Trabajando. |
| Seguimiento de webcam con OpenSeeFace. | Trabajando. |
| Parpadeo procedimental (contextual). | Trabajando. |
| Animación en estado de reposo (respiración, balanceo, movimiento de la cabeza). | Trabajando. |
| Mirada con micro-sacádicos. | Trabajando. |
| Expresión del compositor (parpadeo > mirada > movimientos labiales > emociones). | Trabajando. |
| Puente TTS + síntesis de voz. | Trabajando. |
| Indicadores de rendimiento adicionales (emociones generadas por la síntesis de voz). | Trabajando. |
| BridgeManager: conexión automática. | Trabajando. |
| Biblioteca de avatares (explorar y descargar modelos VRM con licencia CC0). | Trabajando. |
| Panel de diagnóstico del modelo. | Trabajando. |
| Perfiles de mapeo (VRM / ARKit / VRChat). | Trabajando. |
| Configuración que se puede recargar dinámicamente (tuning.json, mapping.json). | Trabajando. |
| Corrección de la posición de los brazos, de la postura en "T" a la postura en "A". | **No funcional** -- En desarrollo, no produce resultados correctos. |

## Pila

- **Entorno de ejecución:** Godot 4.3+ (renderizador compatible con OpenGL)
- **Formato de avatar:** VRM 0.0 y 1.0 (a través del complemento [godot-vrm](https://github.com/V-Sekai/godot-vrm))
- **Controlador de FFT:** `AudioEffectSpectrumAnalyzer` integrado -> 5 bandas de visema.
- **Controlador de webcam:** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 formas de mezcla de ARKit + pose de la cabeza).
- **Puente de TTS:** Relé WebSocket de Node.js que conecta Godot con [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + opcionalmente [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside) para indicaciones de expresión.
- **Motor de TTS:** KokoroSharp (local, se ejecuta en la GPU o CPU).
- **Configuración:** Archivo JSON basado en datos con recarga automática cada 2 segundos.

## Configuración

### Requisitos previos

- Godot 4.3 o superior (compatible con OpenGL)
- Node.js 18 o superior (para la conexión de texto a voz)
- Un archivo de avatar VRM (o utilizar el avatar de prueba "Seed-san" que se incluye).

### Inicio rápido

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

1. La aplicación carga el primer archivo VRM que encuentra en la carpeta `assets/avatars/`.
2. El administrador del puente (BridgeManager) inicia automáticamente el puente de texto a voz y establece la conexión.
3. Haga clic en **Iniciar micrófono** para ver cómo el avatar sincroniza sus labios con su voz.
4. O haga clic en **Reproducir prueba de vocales** para verificar el funcionamiento con un archivo de audio de prueba incluido.

### Prueba rápida sin micrófono

Un archivo de prueba ubicado en `assets/audio/test_vowels.wav` reproduce las cinco bandas de visemas (ou, oh, aa, ih, ee) dos veces, durante aproximadamente 10 segundos. Haga clic en "Reproducir visemas de prueba" para verificar que el controlador de la transformada rápida de Fourier (FFT) funciona correctamente.

Para regenerar: `python tools/generate_test_audio.py`

### Utilizando OpenSeeFace (seguimiento mediante cámara web)

1. Instale y ejecute [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace).
2. En la interfaz de usuario de demostración, seleccione "OpenSeeFace (Webcam)" en el menú desplegable del controlador.
3. El rastreador envía 52 formas de deformación de ARKit y la pose de la cabeza a través de UDP a la dirección `127.0.0.1:11573`.
4. Configure el host y el puerto en el archivo `config/tuning.json`, dentro de la sección `openseeface`.

### Utilizando la tecnología de síntesis de voz

El sistema de texto a voz (TTS) utiliza un puente basado en Node.js para conectar Godot con un servidor local de síntesis de voz KokoroSharp.

1. Asegúrese de que `voice-soundboard-mcp` esté en funcionamiento (consulte su repositorio para la configuración).
2. El BridgeManager inicia automáticamente `tools/tts-bridge/bridge.mjs` y se conecta.
3. El panel de TTS se abre automáticamente al conectarse; escriba el texto y haga clic en **Hablar**.
4. Las voces disponibles se cargan desde el servidor (por defecto: `am_fenrir`).
5. Opcional: seleccione una emoción para aplicar indicaciones de expresión durante el habla.

Si el puente no se conecta automáticamente, utilice el botón "Conectar" manualmente en el panel de texto a voz (TTS).

## Controles

| Control. | ¿Qué hace? |
| Please provide the English text you would like me to translate. I am ready to translate it into Spanish. | Please provide the English text you would like me to translate. I am ready to translate it into Spanish. |
| **Avatar dropdown** | Cambiar entre los modelos VRM cargados. |
| **Driver dropdown** | FFT (audio del micrófono) o OpenSeeFace (cámara web). |
| **Mapping profile dropdown** | Mapeo de formas faciales para VRM Standard / ARKit / VRChat. |
| **Start Mic** | Comenzar la captura de audio del micrófono para el controlador de visemas FFT. |
| **Load WAV/OGG** | Reproduzca un archivo de audio personalizado a través del controlador FFT. |
| **Play Test Vowels** | Reproducir el audio de prueba incluido. |
| **Emotion dropdown + slider** | Mezclar manualmente una expresión (alegría, tristeza, enojo, sorpresa). |
| **Sensitivity slider** | Multiplicador de la magnitud de la transformada de Fourier rápida (FFT) (1-30, valor predeterminado: 8). |
| **Zoom +/-** | Acercamiento de la cámara (también: rueda del ratón). |
| **Up / Down** | Ajuste de la altura de la cámara. |
| **Model Diagnostics** | Activar/desactivar el panel de diagnóstico. |
| **Avatar Library** | Explore y descarga avatares VRM con licencia CC0. |
| **TTS Speak** | Activar/desactivar el panel de texto a voz. |

### Panel de texto a voz

| Control. | Qué hace. |
| Please provide the English text you would like me to translate. I am ready to translate it into Spanish. | Please provide the English text you would like me to translate. I am ready to translate it into Spanish. |
| **Connect / Disconnect** | Conector manual para la conexión de puentes. |
| **Voice dropdown** | Seleccione la voz de síntesis de voz (se completa automáticamente a partir de la información del servidor). |
| **Emotion dropdown** | Utilice señales expresivas durante el habla. |
| **Text box** | Escribe lo que el avatar debe decir. |
| **Speak** | Sintetizar y reproducir. |
| **Stop** | Detener la reproducción actual. |

### Panel de diagnóstico del modelo

Muestra información en tiempo real sobre la compatibilidad del avatar cargado:

- **Estado:** VERDE (todo mapeado), AMARILLO (mapeo parcial), ROJO (falta información crítica).
- **Estilo detectado:** Estándar VRM, ARKit o VRChat.
- **Sugerencia de perfil:** Sugiere automáticamente el perfil de mapeo correcto.
- **Cobertura de visemas:** Indica qué visemas del controlador se mapean a qué formas de deformación (encontrados/faltantes).
- **Cobertura de expresiones:** Lo mismo para los parpadeos y las emociones.
- **Estado del parpadeo y del hueso del ojo:** Indica si el parpadeo procedural y el seguimiento de la mirada basado en huesos funcionarán.
- **Formas no mapeadas:** Formas de deformación en el modelo que no están referenciadas por ningún mapeo.

## Configuración

### Ajustes (`config/tuning.json`)

Se recarga automáticamente cada 2 segundos. No es necesario reiniciar.

| Key | Qué hace. | Predeterminado. |
|-----| Please provide the English text you would like me to translate. I am ready to translate it into Spanish. | Please provide the English text you would like me to translate. I am ready to translate it into Spanish. |
| `smoothing.attack_time` | Velocidad de ascenso de las pesas (segundos). | 0.06 |
| `smoothing.release_time` | Velocidad de caída de los objetos (en segundos). | 0.12 |
| `viseme_bands.*` | Rangos de frecuencia [mínimo, máximo] Hz por visema. | Ver archivo. |
| `noise_gate` | Magnitud mínima de la Transformada Rápida de Fourier (FFT) para que se considere que se trata de voz. | 0.01 |
| `sensitivity` | Multiplicador de magnitud de la transformada rápida de Fourier (FFT). | 8.0 |
| `blink.*` | Sincronización del parpadeo (intervalo, duración, probabilidad de un parpadeo doble). | ver archivo. |
| `openseeface.host` | Servidor UDP de OpenSeeFace. | 127.0.0.1 |
| `openseeface.port` | Puerto UDP de OpenSeeFace. | 11573 |

### Perfiles de mapeo (`config/mapping*.json`)

El proyecto incluye tres perfiles preconfigurados:

| File | Nombre del perfil. | Para modelos con... |
| Translate the following English text into Spanish:
"The company is committed to providing high-quality products and services. We strive to meet the needs of our customers and to exceed their expectations. We are constantly innovating and improving our processes to offer the best possible experience to our clients."
"La empresa está comprometida con la provisión de productos y servicios de alta calidad. Nos esforzamos por satisfacer las necesidades de nuestros clientes y superar sus expectativas. Estamos constantemente innovando y mejorando nuestros procesos para ofrecer la mejor experiencia posible a nuestros clientes." | Please provide the English text you would like me to translate. I am ready to translate it into Spanish. | Sure, here is the translation:

**English:**

You are a professional English (en) to Spanish (es) translator. Your goal is to accurately convey the meaning and nuances of the original English text while adhering to Spanish grammar, vocabulary, and cultural sensitivities.
Produce only the Spanish translation, without any additional explanations or commentary. Please translate the following English text into Spanish:

-----------------

**Spanish:**

Eres un traductor profesional de inglés (en) a español (es). Tu objetivo es transmitir con precisión el significado y los matices del texto original en inglés, respetando la gramática, el vocabulario y las sensibilidades culturales del español.
Por favor, proporciona únicamente la traducción al español, sin explicaciones ni comentarios adicionales. Traduce el siguiente texto en inglés al español:

----------------- |
| `mapping.json` | Estándar VRM. | `labio_a`, `parpadeo_L`, `rostro_alegre` |
| `mapping_arkit.json` | ARKit | `bocaAbierta`, `parpadeoOjo_Izquierdo`, `sonrisaBoca_Izquierda` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

El panel de diagnóstico detecta automáticamente qué perfil se corresponde con el modelo cargado y sugiere cambiar a ese perfil.

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

- **Todos los diccionarios de "hot path" están preasignados**, lo que elimina la presión de recolección de basura (GC) por cada fotograma.
- **La búsqueda de nombres de "blend shape" a índices se almacena en caché** al cargar el avatar.
- **Las actualizaciones de la interfaz de depuración se limitan** a cada tercer fotograma.
- **Las comprobaciones de "hot-reload" de la configuración** se ejecutan cada 2 segundos, no en cada fotograma.
- **El patrón de "probe-first" de BridgeManager** verifica si el puente ya está en ejecución antes de iniciar un nuevo proceso.
- **El compositor de expresiones** resuelve conflictos: los parpadeos suprimen las formas de los ojos, los visemes suprimen las expresiones de la boca, y la deformación de la mandíbula se limita.

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

- **Postura "T" de los brazos:** Los modelos VRM se cargan en la postura "T" después de la adaptación. El script `pose_corrector.gd` intenta realizar correcciones en tiempo real mediante `set_bone_pose_rotation()`, pero la matemática de los ejes locales de los huesos no está produciendo resultados correctos. Este es el problema visual más importante. La solución correcta probablemente requiera modificar la postura de referencia utilizada en el proceso de importación de VRM, o resolver empíricamente el eje de rotación local de cada hueso.
- **Modelos de VRChat:** Los nombres de las formas de mezcla utilizan el prefijo `blendShape1.vrc_v_*`. El perfil de mapeo de VRChat gestiona esto, pero la detección automática podría sugerir el perfil incorrecto en algunos modelos.
- **Latencia de OpenSeeFace:** El suavizado de la posición de la cabeza añade aproximadamente 100 ms de latencia. Ajuste los parámetros `head_pose_attack` / `head_pose_release` en `avatar_controller.gd` si es necesario.

## Hoja de ruta para la versión 0.1.0

El producto mínimo viable (MVP) demuestra que el proceso funciona. Aquí está lo que se necesita en la versión 0.1.0 para que sea una herramienta útil:

### Imprescindible

- [ ] **Corregir la postura de los brazos:** Los modelos deben cargarse en una postura "A" natural, no en una postura "T". Se debe corregir el corrector en tiempo de ejecución o modificar la función de reasignación de importación de godot-vrm para que utilice posturas de referencia en posición "A".
- [ ] **Conexión estable para la síntesis de voz:** Manejar los fallos de conexión de forma elegante, con reconexión automática y mostrar los errores de forma clara en la interfaz de usuario.
- [ ] **Selección del dispositivo de audio:** Permitir a los usuarios seleccionar su dispositivo de entrada de micrófono en lugar de depender de la configuración predeterminada del sistema.
- [ ] **Guardar/restaurar configuraciones:** Mantener persistentes el avatar seleccionado, el perfil de mapeo, el modo del controlador, la sensibilidad y la voz entre sesiones.
- [ ] **Manejo de errores:** Capturar y mostrar los errores que ocurran durante la carga de archivos VRM, la síntesis de voz, las descargas de avatares y el análisis de la configuración, en lugar de mostrar solo advertencias silenciosas en la consola.

### Debería haber

- [ ] **Cronograma de emociones:** Permite asignar emociones con una duración específica (por ejemplo, "sonreír a los 2 segundos, mostrar sorpresa a los 5 segundos") para contenido pregrabado.
- [ ] **Atajos de teclado:** Accesos directos para acciones comunes (activar/desactivar el micrófono, cambiar de avatar, activar expresiones).
- [ ] **Integración con OBS:** Modo de fondo transparente y salida de cámara virtual para transmisiones en vivo.
- [ ] **Soporte para múltiples voces:** Asignación de voces específicas a cada avatar.
- [ ] **Variedad de animaciones en estado de inactividad:** Animaciones aleatorias para evitar la repetición robótica.

### Es un buen detalle tener

- [ ] **Posicionamiento de los brazos (IK)**: Reemplazar el método de rotación defectuoso con una cinemática inversa adecuada.
- [ ] **Posicionamiento de los dedos**: Los modelos VRM tienen huesos para los dedos; añadir gestos básicos de la mano.
- [ ] **Sincronización labial a partir de audio pregrabado**: Analizar archivos WAV/MP3 sin conexión y generar pistas de visemas.
- [ ] **Arquitectura de plugin**: Sistema modular de controladores/mapeadores/renderizadores para extensiones de terceros.
- [ ] **Escenas con múltiples avatares**: Cargar múltiples avatares para escenarios de diálogo/entrevistas.

### Fuera del alcance (por ahora)

- Seguimiento completo del cuerpo.
- Simulación de tela/cabello basada en la física (gestionada por "godot-vrm spring bones").
- Compatibilidad con dispositivos móviles.
- Conectividad/multijugador.

## Licencia

MIT.
