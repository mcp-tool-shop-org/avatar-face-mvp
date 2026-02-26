<p align="center">
  <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png" alt="Avatar Face MVP" width="280" />
</p>

[![Página de Abertura](https://img.shields.io/badge/Landing_Page-online-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

**Protótipo** – demonstração de conceito, não um software para produção.
Consulte [Roteiro para a versão 0.1.0](#roteiro-para-a-versao-010) para saber o que precisa ser feito antes de um lançamento oficial.

Sincronização labial em tempo real para avatares VRM, expressões faciais, animações de repouso e texto para fala (TTS) – desenvolvido com Godot 4.3 ou superior e uma ponte Node.js para a síntese de voz.

## O que isso demonstra

1. **Microfone de entrada -> o rosto se move de forma convincente** a 60 quadros por segundo, com visemes de transformada rápida de Fourier (FFT) sem latência.
2. **Webcam de entrada -> rastreamento completo do rosto** através do OpenSeeFace (52 formas de mistura ARKit).
3. **Digite texto -> o avatar fala** com sincronização labial usando TTS (Text-to-Speech) através do KokoroSharp.
4. **Baixe qualquer modelo VRM com licença CC0 -> ele funciona perfeitamente** com perfis de mapeamento detectados automaticamente.
5. **Tudo é baseado em dados** – altere os arquivos JSON de mapeamento, não o código.

## Status

| Característica. | Status. |
| Please provide the English text you would like me to translate. I am ready to translate it into Portuguese. | Please provide the English text you would like me to translate. I am ready to translate it into Portuguese. |
| Sincronização labial com base em visemas, utilizando a Transformada Rápida de Fourier (FFT) para áudio (microfone/WAV). | Trabalhando. |
| Rastreamento de webcam com OpenSeeFace. | Trabalhando. |
| Piscar procedural (contextualmente adaptável). | Trabalhando. |
| Animação em repouso (respiração, balanço, movimento da cabeça). | Trabalhando. |
| Movimentos oculares que envolvem micro-sacadas. | Trabalhando. |
| Expressão compositorial (piscar de olhos > olhar > visemas > emoções). | Trabalhando. |
| Ponte TTS + síntese de voz. | Trabalhando. |
| Além dos sinais de desempenho (emoção gerada pela síntese de voz), | Trabalhando. |
| BridgeManager: conexão automática. | Trabalhando. |
| Biblioteca de avatares (navegue e faça download de modelos VRM com licença CC0). | Trabalhando. |
| Painel de diagnóstico do modelo. | Trabalhando. |
| Perfis de mapeamento (VRM / ARKit / VRChat). | Trabalhando. |
| Configuração recarregável em tempo real (arquivos tuning.json e mapping.json). | Trabalhando. |
| Correção da posição dos braços, de "T" para "A". | **Inativo** -- Em desenvolvimento, não está produzindo resultados corretos. |

## Pilha

- **Ambiente de execução:** Godot 4.3+ (renderizador compatível com OpenGL)
- **Formato do avatar:** VRM 0.0 e 1.0 (através do plugin [godot-vrm](https://github.com/V-Sekai/godot-vrm))
- **Driver de FFT:** Análise de espectro de áudio integrada (`AudioEffectSpectrumAnalyzer`) -> 5 bandas de viseme.
- **Driver da webcam:** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) via UDP (52 formas de mistura ARKit + pose da cabeça).
- **Conexão de texto para fala (TTS):** Relé WebSocket Node.js que conecta o Godot ao [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + opcionalmente [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside) para dicas de expressão.
- **Motor de TTS:** KokoroSharp (local, funciona na GPU ou CPU).
- **Configuração:** Arquivo JSON com dados configuráveis e recarregamento automático a cada 2 segundos.

## Configuração

### Pré-requisitos

- Godot 4.3+ (compatibilidade com OpenGL)
- Node.js 18+ (para a ponte de texto para fala)
- Um arquivo de avatar VRM (ou utilize o avatar de teste "Seed-san" que já vem incluído).

### Início rápido

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

### Primeira execução

1. O aplicativo carrega o primeiro arquivo VRM que encontra na pasta `assets/avatars/`.
2. O BridgeManager inicia automaticamente a ponte de Text-to-Speech (TTS) e estabelece a conexão.
3. Clique em "**Iniciar Microfone**" para ver o avatar sincronizar os movimentos labiais com a sua voz.
4. Ou clique em "**Reproduzir Teste de Vogais**" para verificar o funcionamento com um áudio de teste incluído.

### Teste rápido sem microfone

Um arquivo de teste localizado em `assets/audio/test_vowels.wav` percorre todas as cinco faixas de visemas (ou, oh, aa, ih, ee) duas vezes, durante aproximadamente 10 segundos. Clique em "Reproduzir Sons de Teste" para verificar se o driver FFT está funcionando corretamente.

Para regenerar: `python tools/generate_test_audio.py`

### Utilizando o OpenSeeFace (rastreamento por webcam)

1. Instale e execute o [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace).
2. Na interface de demonstração, altere o menu suspenso do driver para **OpenSeeFace (Webcam)**.
3. O rastreador envia 52 formas de deformação ARKit e a pose da cabeça via UDP para o endereço `127.0.0.1:11573`.
4. Configure o host/porta no arquivo `config/tuning.json`, na seção `openseeface`.

### Utilizando a tecnologia de conversão de texto em fala (TTS)

O sistema de Text-to-Speech (TTS) utiliza uma ponte Node.js para conectar o Godot a um servidor local de síntese de voz KokoroSharp.

1. Certifique-se de que o `voice-soundboard-mcp` está em execução (consulte o repositório para a configuração).
2. O BridgeManager inicia automaticamente o arquivo `tools/tts-bridge/bridge.mjs` e estabelece a conexão.
3. O painel de TTS é aberto automaticamente quando a conexão é estabelecida. Digite o texto e clique em **Falar**.
4. As vozes disponíveis são carregadas do servidor (padrão: `am_fenrir`).
5. Opcional: selecione uma emoção para aplicar efeitos de expressão durante a fala.

Se a conexão automática da ponte não funcionar, utilize o botão "Conectar" manualmente no painel de controle de texto para fala (TTS).

## Controles

| Controle. | O que ele faz. |
| Please provide the English text you would like me to translate. I am ready to translate it into Portuguese. | "Please provide the text you would like me to translate." |
| **Avatar dropdown** | Alternar entre modelos de VRM carregados. |
| **Driver dropdown** | FFT (áudio do microfone) ou OpenSeeFace (webcam). |
| **Mapping profile dropdown** | Mapeamento de formas de rosto para VRM Standard / ARKit / VRChat. |
| **Start Mic** | Iniciar a captura de áudio do microfone para o driver de visemes FFT. |
| **Load WAV/OGG** | Reproduzir um arquivo de áudio personalizado através do driver FFT. |
| **Play Test Vowels** | Reproduzir o áudio de teste incluído. |
| **Emotion dropdown + slider** | Combine manualmente uma expressão (feliz, triste, zangado, surpreso). |
| **Sensitivity slider** | Multiplicador de magnitude da FFT (1-30, padrão: 8). |
| **Zoom +/-** | Zoom da câmera (ou: roda do mouse). |
| **Up / Down** | Ajuste da altura da câmera. |
| **Model Diagnostics** | Alternar o painel de diagnóstico. |
| **Avatar Library** | Navegue e faça o download de avatares VRM com licença CC0. |
| **TTS Speak** | Ativar/desativar o painel de conversão de texto em fala. |

### Painel TTS

| Controle. | O que ele faz. |
| Please provide the English text you would like me to translate. I am ready to translate it into Portuguese. | "Please provide the text you would like me to translate." |
| **Connect / Disconnect** | Interruptor manual de conexão de ponte. |
| **Voice dropdown** | Selecione a voz de síntese de voz (preenchida automaticamente a partir do servidor). |
| **Emotion dropdown** | Utilize sinais de expressão durante a fala. |
| **Text box** | Digite o que o avatar deve dizer. |
| **Speak** | Sintetizar e reproduzir. |
| **Stop** | Cancelar a reprodução atual. |

### Painel de diagnóstico do modelo

Exibe informações em tempo real sobre a compatibilidade do avatar carregado:

- **Status:** VERDE (tudo mapeado), AMARELO (mapeamento parcial), VERMELHO (falta mapeamento de elementos críticos).
- **Estilo detectado:** Padrão VRM, ARKit ou VRChat.
- **Sugestão de perfil:** Sugere automaticamente o perfil de mapeamento correto.
- **Cobertura de visemas:** Indica quais visemas do driver correspondem a quais formas de deformação (encontrados/faltantes).
- **Cobertura de expressões:** O mesmo para piscadas e emoções.
- **Status da piscada e do osso ocular:** Indica se a piscada procedural e o rastreamento ocular baseado em ossos funcionarão.
- **Formas não mapeadas:** Formas de deformação no modelo que não são referenciadas por nenhum mapeamento.

## Configuração

### Ajustes (`config/tuning.json`)

Recarregamento automático a cada 2 segundos. Não é necessário reiniciar o sistema.

| Key | O que ele faz. | Padrão. |
|-----| "Please provide the text you would like me to translate." | Please provide the English text you would like me to translate. I am ready to translate it into Portuguese. |
| `smoothing.attack_time` | Velocidade com que os pesos sobem (em segundos). | 0.06 |
| `smoothing.release_time` | Velocidade com que os pesos caem (em segundos). | 0.12 |
| `viseme_bands.*` | Faixas de frequência [mínimo, máximo] Hz por visema. | Consulte o arquivo. |
| `noise_gate` | Magnitude mínima da Transformada Rápida de Fourier (FFT) para ser classificada como fala. | 0.01 |
| `sensitivity` | Multiplicador de magnitude da Transformada Rápida de Fourier (FFT). | 8.0 |
| `blink.*` | Sincronização do piscar dos olhos (intervalo, duração, probabilidade de piscar duas vezes). | Consulte o arquivo. |
| `openseeface.host` | Servidor UDP do OpenSeeFace. | 127.0.0.1 |
| `openseeface.port` | Porta UDP do OpenSeeFace. | 11573 |

### Perfis de mapeamento (`config/mapping*.json`)

O projeto inclui três perfis pré-configurados:

| File | Nome do perfil. | Para modelos com... |
| Please provide the English text you would like me to translate. I am ready to translate it into Portuguese. | "Please provide the text you would like me to translate." | Absolutely! Please provide the English text you would like me to translate into Portuguese. I will do my best to provide an accurate and natural-sounding translation. |
| `mapping.json` | Padrão VRM. | `lábio_aberto`, `pálpebra_esquerda_fechada`, `rosto_feliz` |
| `mapping_arkit.json` | ARKit | `bocaAberta`, `piscarOlho_Esquerdo`, `bocaSorriso_Esquerdo` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

O painel de diagnóstico detecta automaticamente qual perfil corresponde ao modelo carregado e sugere a alteração.

## Arquitetura

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

### Decisões-chave de design

- **Todos os dicionários de "hot path" são pré-alocados** – sem pressão adicional no coletor de lixo (GC) a cada quadro.
- **A pesquisa entre o nome da forma de deformação e seu índice é armazenada em cache** durante o carregamento do avatar.
- **As atualizações da interface de depuração são limitadas** a cada 3º quadro.
- **As verificações de recarregamento automático da configuração** são executadas a cada 2 segundos, e não a cada quadro.
- **O padrão de "probe-first" do BridgeManager** verifica se a ponte já está em execução antes de iniciar um novo processo.
- **O compositor de expressões** resolve conflitos: piscadas suprimem as formas dos olhos, os fonemas suprimem as expressões da boca, e a deformação da mandíbula é limitada.

## Estrutura do projeto

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

## Problemas conhecidos

- **Posição "T" dos braços:** Os modelos VRM são carregados na posição "T" após a reatribuição. O script `pose_corrector.gd` tenta corrigir a posição em tempo real usando `set_bone_pose_rotation()`, mas a matemática dos eixos locais das articulações não está produzindo resultados corretos. Este é o problema visual mais significativo. A correção correta provavelmente exige modificar a pose de referência para a reatribuição no processo de importação do VRM, ou resolver empiricamente os eixos de rotação locais de cada articulação.
- **Modelos para VRChat:** Os nomes das formas de mistura (blend shapes) usam o prefixo `blendShape1.vrc_v_*`. O perfil de mapeamento do VRChat lida com isso, mas a detecção automática pode sugerir o perfil incorreto em alguns modelos.
- **Latência do OpenSeeFace:** O suavização da pose da cabeça adiciona aproximadamente 100ms de latência. Ajuste os parâmetros `head_pose_attack` / `head_pose_release` no script `avatar_controller.gd`, se necessário.

## Roteiro para a versão 0.1.0

O MVP (Produto Mínimo Viável) demonstra que o processo funciona. Para que a versão 0.1.0 seja uma ferramenta utilizável, é necessário o seguinte:

### Obrigatório

- [ ] **Corrigir a pose dos braços** – os modelos devem ser carregados na pose "A" natural, e não na pose "T". É necessário corrigir o corretor em tempo de execução ou modificar a importação e o retargeting do formato VRM para usar a pose "A" como referência.
- [ ] **Conexão estável para síntese de voz** – tratar as falhas de conexão de forma elegante, com reconexão automática e exibição clara dos erros na interface do usuário.
- [ ] **Seleção do dispositivo de áudio** – permitir que os usuários escolham o dispositivo de entrada do microfone, em vez de depender das configurações padrão do sistema.
- [ ] **Salvar/restaurar configurações** – manter as configurações selecionadas do avatar, perfil de mapeamento, modo do driver, sensibilidade e voz entre as sessões.
- [ ] **Tratamento de erros** – detectar e exibir erros durante o carregamento de arquivos VRM, a síntese de voz, o download de avatares e a análise de configurações, em vez de apenas exibir avisos silenciosos no console.

### Devia ter.
Teria de.
Seria preciso ter

- [ ] **Linha do tempo de emoções:** Permite programar a exibição de emoções em momentos específicos (por exemplo, "sorrir aos 2 segundos, demonstrar surpresa aos 5 segundos") para conteúdo pré-gravado.
- [ ] **Atalhos de teclado:** Atalhos para ações comuns (ativar/desativar o microfone, trocar de avatar, acionar expressões).
- [ ] **Integração com OBS:** Modo de fundo transparente e saída de câmera virtual para transmissões.
- [ ] **Suporte para múltiplas vozes:** Atribuição de voz individual para cada avatar.
- [ ] **Variação aprimorada do estado de inatividade:** Animações de inatividade aleatórias para evitar repetições robóticas.

### Bom ter

- [ ] **Posicionamento dos braços (IK)** – substituir o método de rotação defeituoso por uma cinemática inversa adequada.
- [ ] **Posicionamento dos dedos** – os modelos VRM possuem ossos para os dedos; adicionar gestos básicos das mãos.
- [ ] **Sincronização labial a partir de áudio pré-gravado** – analisar arquivos WAV/MP3 offline e gerar faixas de visemas.
- [ ] **Arquitetura de plugin** – sistema modular de drivers/mapeadores/renderizadores para extensões de terceiros.
- [ ] **Cenas com múltiplos avatares** – carregar múltiplos avatares para cenários de diálogo/entrevistas.

### Fora do escopo (por enquanto)

- Rastreamento completo do corpo.
- Simulação de tecidos/cabelos baseada em física (gerenciada pelos "spring bones" do Godot-VRM).
- Suporte para dispositivos móveis.
- Conectividade/multijogador.

## Licença

MIT.
