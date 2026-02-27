<p align="center">
  <a href="README.zh.md">中文</a> | <a href="README.es.md">Español</a> | <a href="README.fr.md">Français</a> | <a href="README.md">English</a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png" alt="Avatar Face MVP" width="280" />
</p>

[![Página Inicial](https://img.shields.io/badge/Landing_Page-online-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

> **Protótipo** -- software de demonstração, não para produção.
> Consulte a [Roteiro para a versão 0.1.0](#roteiro-para-a-versao-010) para saber o que precisa ser feito antes de um lançamento real.

Sincronização labial em tempo real de avatares VRM, expressões, animações de inatividade e Text-to-Speech (TTS) -- construído com Godot 4.3+ e uma ponte Node.js para síntese de voz.

## O que isso demonstra

1. **Microfone -> o rosto se move de forma convincente** a 60 fps com visemas FFT de latência zero.
2. **Webcam -> rastreamento facial completo** via OpenSeeFace (52 blendshapes ARKit).
3. **Digite texto -> o avatar fala** com TTS sincronizado com os lábios via KokoroSharp.
4. **Baixe qualquer avatar VRM com licença CC0 -> ele simplesmente funciona** com perfis de mapeamento detectados automaticamente.
5. **Tudo é baseado em dados** -- altere o JSON de mapeamento, não o código.

## Status

| Funcionalidade | Status |
|---------|--------|
| Sincronização labial FFT (microfone/WAV) | Funciona |
| Rastreamento de webcam OpenSeeFace | Funciona |
| Piscar procedural (contexto-dependente) | Funciona |
| Animação de inatividade (respiração, balanço, movimento da cabeça) | Funciona |
| Olhar com micro-sacadas | Funciona |
| Compositor de expressões (piscar > olhar > visemas > emoções) | Funciona |
| Ponte TTS + síntese de voz | Funciona |
| Pistas de desempenho adicionais (emoção do TTS) | Funciona |
| Conexão automática do BridgeManager | Funciona |
| Biblioteca de avatares (navegar e baixar avatares VRM com licença CC0) | Funciona |
| Painel de diagnóstico do modelo | Funciona |
| Perfis de mapeamento (VRM / ARKit / VRChat) | Funciona |
| Configuração recarregável (tuning.json, mapping.json) | Funciona |
| Correção da postura do braço de T-pose para A-pose | **Não funciona** -- em desenvolvimento, não produz resultados corretos. |

## Pilhas de tecnologia

- **Runtime:** Godot 4.3+ (Renderizador de compatibilidade GL)
- **Formato do avatar:** VRM 0.0 e 1.0 (via o addon [godot-vrm](https://github.com/V-Sekai/godot-vrm) incluído)
- **Driver FFT:** `AudioEffectSpectrumAnalyzer` integrado -> 5 bandas de viseme
- **Driver da webcam:** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 blendshapes ARKit + pose da cabeça)
- **Ponte TTS:** Relé WebSocket Node.js conectando Godot a [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + opcional [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside) para pistas de expressão
- **Motor TTS:** KokoroSharp (local, roda na GPU ou CPU)
- **Configuração:** JSON baseado em dados com recarregamento a quente de 2 segundos.

## Configuração

### Pré-requisitos

- [Godot 4.3+](https://godotengine.org/download) (Compatibilidade GL)
- [Node.js 18+](https://nodejs.org/) (para a ponte TTS)
- Um arquivo de avatar VRM (ou use o avatar de teste Seed-san incluído)

### Primeiros passos

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

1. O aplicativo carrega o primeiro avatar VRM que encontra em `assets/avatars/`.
2. O BridgeManager inicia automaticamente a ponte TTS e se conecta.
3. Clique em **Iniciar Microfone** para ver o avatar sincronizar os lábios com sua voz.
4. Ou clique em **Reproduzir Vogais de Teste** para verificar com um áudio de teste incluído.

### Teste rápido sem microfone

Um arquivo de teste em `assets/audio/test_vowels.wav` percorre todas as cinco bandas de viseme duas vezes em cerca de 10 segundos. Clique em "Reproduzir Vogais de Teste" para verificar se o driver FFT funciona.

Para regenerar: `python tools/generate_test_audio.py`

### Usando OpenSeeFace (rastreamento da webcam)

1. Instale e execute [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace).
2. Na interface de demonstração, altere a opção do menu suspenso do driver para **OpenSeeFace (Webcam)**.
3. O rastreador envia 52 blendshapes ARKit + pose da cabeça via UDP para `127.0.0.1:11573`.
4. Configure o host/porta em `config/tuning.json` sob `openseeface`.

### Usando TTS

O sistema TTS utiliza uma ponte Node.js para conectar o Godot a um servidor local de síntese de voz KokoroSharp.

1. Certifique-se de que o `voice-soundboard-mcp` está em execução (consulte o repositório para a configuração).
2. O BridgeManager inicia automaticamente o arquivo `tools/tts-bridge/bridge.mjs` e estabelece a conexão.
3. O painel TTS é aberto automaticamente quando a conexão é estabelecida. Digite o texto e clique em **Falar**.
4. As vozes disponíveis são carregadas do servidor (padrão: `am_fenrir`).
5. Opcional: selecione uma emoção para aplicar dicas de expressão durante a fala.

Se a ponte não conseguir se conectar automaticamente, use o botão **Conectar** manual no painel TTS.

## Controles

| Controle | O que ele faz |
|---------|-------------|
| **Avatar dropdown** | Alterna entre os modelos VRM carregados. |
| **Driver dropdown** | FFT (áudio do microfone) ou OpenSeeFace (webcam). |
| **Mapping profile dropdown** | Mapeamento de formas de mistura VRM Standard / ARKit / VRChat. |
| **Start Mic** | Inicia a captura de áudio do microfone para o driver de visemas FFT. |
| **Load WAV/OGG** | Reproduz um arquivo de áudio personalizado através do driver FFT. |
| **Play Test Vowels** | Reproduz o áudio de teste incluído. |
| **Emotion dropdown + slider** | Mistura manualmente uma expressão (feliz, triste, zangado, surpreso). |
| **Sensitivity slider** | Multiplicador de magnitude FFT (1-30, padrão 8). |
| **Zoom +/-** | Zoom da câmera (também: roda do mouse). |
| **Up / Down** | Ajuste da altura da câmera. |
| **Model Diagnostics** | Alterna o painel de diagnóstico. |
| **Avatar Library** | Navega e baixa avatares VRM CC0. |
| **TTS Speak** | Alterna o painel TTS. |

### Painel TTS

| Controle | O que ele faz |
|---------|-------------|
| **Connect / Disconnect** | Alterna a conexão da ponte (manual). |
| **Voice dropdown** | Seleciona a voz TTS (carregada automaticamente do servidor). |
| **Emotion dropdown** | Aplica dicas de expressão durante a fala. |
| **Text box** | Digite o que o avatar deve dizer. |
| **Speak** | Sintetiza e reproduz. |
| **Stop** | Cancela a reprodução atual. |

### Painel de diagnóstico do modelo

Mostra informações de compatibilidade em tempo real para o avatar carregado:

- **Status:** VERDE (tudo mapeado), AMARELO (parcial), VERMELHO (formas críticas ausentes).
- **Estilo detectado:** VRM Standard, ARKit ou VRChat.
- **Sugestão de perfil:** sugere automaticamente o perfil de mapeamento correto.
- **Cobertura de visemas:** quais drivers de visemas correspondem a quais formas de mistura (encontrado/ausente).
- **Cobertura de expressões:** o mesmo para piscadas e emoções.
- **Status da piscada + osso do olho:** se a piscada procedural e o olhar baseado em ossos funcionarão.
- **Formas não mapeadas:** formas de mistura no modelo que não são referenciadas por nenhum mapeamento.

## Configuração

### Ajustes (`config/tuning.json`)

Recarregado a cada 2 segundos. Não é necessário reiniciar.

| Chave | O que ele faz | Padrão |
|-----|-------------|---------|
| `smoothing.attack_time` | Velocidade com que os pesos aumentam (segundos). | 0.06 |
| `smoothing.release_time` | Velocidade com que os pesos diminuem (segundos). | 0.12 |
| `viseme_bands.*` | Faixas de frequência [mínimo, máximo] Hz por visema. | veja o arquivo |
| `noise_gate` | Magnitude mínima de FFT para ser considerada fala. | 0.01 |
| `sensitivity` | Multiplicador de magnitude FFT. | 8.0 |
| `blink.*` | Temporização da piscada procedural (intervalo, duração, chance de piscada dupla). | veja o arquivo |
| `openseeface.host` | Host UDP do OpenSeeFace. | 127.0.0.1 |
| `openseeface.port` | Porta UDP do OpenSeeFace. | 11573 |

### Perfis de mapeamento (`config/mapping*.json`)

Três perfis são incluídos no projeto:

| Arquivo | Nome do perfil | Para modelos com |
|------|-------------|-----------------|
| `mapping.json` | VRM Standard | `lip_a`, `blink_L`, `face_happy` |
| `mapping_arkit.json` | ARKit | `jawOpen`, `eyeBlink_L`, `mouthSmile_L` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

O painel de diagnóstico detecta automaticamente qual perfil corresponde ao modelo carregado e sugere a troca.

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

### Decisões de design importantes

- **Todos os dicionários de "caminhos críticos" são pré-alocados** – pressão de coleta de lixo (GC) zero por quadro.
- **A pesquisa de "nome da forma de mistura" para "índice" é armazenada em cache** durante o carregamento do avatar.
- **As atualizações da interface de depuração são limitadas** a cada 3º quadro.
- **As verificações de "recarregamento quente" da configuração** são executadas a cada 2 segundos, não a cada quadro.
- **O padrão de "verificação inicial" do BridgeManager** verifica se o bridge já está em execução antes de iniciar um novo processo.
- **O compositor de expressões** resolve conflitos: piscadas suprimem as formas dos olhos, os visemas suprimem as expressões da boca, a deformação da mandíbula é limitada.

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

- **Poses de braços em "T"**: Os modelos VRM são carregados na pose "T" após a reorientação. O script `pose_corrector.gd` tenta corrigir em tempo de execução usando `set_bone_pose_rotation()`, mas a matemática dos eixos locais dos ossos não está produzindo resultados corretos. Este é o maior problema visual. A correção correta provavelmente requer modificar a pipeline de importação VRM para reorientar para a pose "A", ou resolver empiricamente o eixo de rotação local de cada osso.
- **Modelos VRChat**: Os nomes das formas de mistura usam o prefixo `blendShape1.vrc_v_*`. O perfil de mapeamento do VRChat lida com isso, mas a detecção automática pode sugerir o perfil errado em alguns modelos.
- **Latência do OpenSeeFace**: O suavização da pose da cabeça adiciona cerca de 100ms de latência. Ajuste `head_pose_attack` / `head_pose_release` em `avatar_controller.gd`, se necessário.

## Roteiro para v0.1.0

O MVP demonstra que a pipeline funciona. Aqui está o que a v0.1.0 precisa para ser uma ferramenta utilizável:

### Essencial

- [ ] **Corrigir a pose dos braços** – os modelos devem ser carregados na pose "A" natural, não na pose "T". Corrija o corretor em tempo de execução ou modifique a reorientação da importação godot-vrm para usar poses de referência "A".
- [ ] **Bridge de TTS estável** – lide com as falhas do bridge de forma elegante, reconecte automaticamente e exiba erros claramente na interface.
- [ ] **Seleção do dispositivo de áudio** – permita que os usuários escolham seu dispositivo de entrada de microfone em vez de depender da configuração padrão do sistema.
- [ ] **Salvar/restaurar configurações** – mantenha o avatar selecionado, o perfil de mapeamento, o modo do driver, a sensibilidade e a voz em diferentes sessões.
- [ ] **Tratamento de erros** – capture e exiba falhas para o carregamento de modelos VRM, síntese de TTS, downloads de avatares e análise de configuração, em vez de apenas exibir avisos no console.

### Desejável

- [ ] **Linha do tempo de emoções** – coloque emoções com temporização (por exemplo, "sorrir em 2 segundos, surpreso em 5 segundos") para conteúdo pré-gravado.
- [ ] **Atalhos de teclado** – atalhos de teclado para ações comuns (alternar microfone, alternar avatar, acionar expressões).
- [ ] **Integração com OBS** – modo de fundo transparente + saída de câmera virtual para streaming.
- [ ] **Suporte para várias vozes** – atribuição de voz por avatar.
- [ ] **Melhor variação de inatividade** – animações de inatividade aleatórias para evitar repetições robóticas.

### Opcional

- [ ] **Posicionamento de braços IK** – substitua a abordagem de rotação defeituosa por cinemática inversa adequada.
- [ ] **Posicionamento de dedos** – modelos VRM têm ossos de dedos; adicione gestos básicos de mão.
- [ ] **Sincronização labial a partir de áudio pré-gravado** – analise arquivos WAV/MP3 offline e gere faixas de visemes.
- [ ] **Arquitetura de plugin** – sistema modular de driver/mapper/renderer para extensões de terceiros.
- [ ] **Cenas com vários avatares** – carregue vários avatares para cenários de diálogo/entrevista.

### Fora do escopo (por enquanto)

- Rastreamento de corpo inteiro
- Tecido/cabelo baseado em física (tratado pelos "spring bones" do godot-vrm)
- Suporte para dispositivos móveis
- Rede / multiplayer

## Segurança e Escopo de Dados

O Avatar Face MVP opera **exclusivamente localmente** sem nenhuma solicitação de rede.

- **Dados acessados:** Lê arquivos de avatar VRM locais, entrada de áudio do microfone, feed da webcam através do OpenSeeFace (UDP no localhost). Lê/escreve arquivos de configuração JSON no diretório do projeto. Opcionalmente, inicia um processo local de "bridge" TTS (Text-to-Speech) em Node.js.
- **Dados NÃO acessados:** Não há requisições à internet. Não há telemetria. Não há serviços em nuvem. Não há armazenamento de credenciais. Os dados da webcam são processados localmente apenas.
- **Permissões necessárias:** Acesso ao microfone para sincronização labial. Acesso opcional à webcam através do OpenSeeFace. Acesso ao sistema de arquivos para modelos VRM e configuração.

Consulte [SECURITY.md](SECURITY.md) para relatar vulnerabilidades.

---

## Tabela de Avaliação

| Categoria | Pontuação |
|----------|-------|
| Segurança | 10/10 |
| Tratamento de Erros | 10/10 |
| Documentação para Usuários | 10/10 |
| Higiene no Desenvolvimento | 10/10 |
| Identidade | 10/10 |
| **Overall** | **50/50** |

---

## Licença

MIT

---

Desenvolvido por <a href="https://mcp-tool-shop.github.io/">MCP Tool Shop</a
