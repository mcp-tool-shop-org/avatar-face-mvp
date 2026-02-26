<p align="center">
<strong>Languages:</strong> <a href="README.md">English</a> | <a href="README.ja.md">日本語</a> | <a href="README.zh.md">中文</a> | <a href="README.es.md">Español</a> | <a href="README.fr.md">Français</a> | <a href="README.hi.md">हिंदी</a> | <a href="README.it.md">Italiano</a> | <a href="README.pt-BR.md">Português</a>
</p>

<p align="center">
  
            <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png"
           alt="Avatar Face MVP" width="280" />
</p>

[![Pagina di presentazione](https://img.shields.io/badge/Landing_Page-online-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

**Prototipo:** dimostrazione di concetto, non software destinato alla produzione.
Consultare [la tabella di marcia per la versione 0.1.0](#roadmap-to-v010) per vedere cosa deve essere realizzato prima di una vera e propria versione.

Sincronizzazione labiale in tempo reale per avatar VRM, espressioni facciali, animazioni di inattività e sintesi vocale (TTS), sviluppati con Godot 4.3+ e un'interfaccia Node.js per la sintesi vocale.

## Cosa dimostra questo

1. **Microfono in -> il viso si muove in modo realistico** a 60 fotogrammi al secondo, con visemi FFT a latenza zero.
2. **Webcam in -> tracciamento completo del viso** tramite OpenSeeFace (52 blendshapes di ARKit).
3. **Scrivi del testo -> l'avatar parla** con sintesi vocale sincronizzata alle labbra tramite KokoroSharp.
4. **Scarica qualsiasi modello VRM con licenza CC0 -> funziona immediatamente** grazie ai profili di mappatura rilevati automaticamente.
5. **Tutto è basato sui dati**: si modificano i file JSON di mappatura, non il codice.

## Stato

| Caratteristica. | Stato. |
| Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." | Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." |
| Sincronizzazione labiale basata sull'analisi FFT (microfono/file WAV). | Lavorando. |
| Tracciamento della webcam con OpenSeeFace. | Lavorando. |
| Lampeggiamento procedurale (sensibile al contesto). | Lavorando. |
| Animazioni inattive (respirazione, oscillazione, movimento del capo). | Lavorando. |
| Movimenti oculari caratterizzati da micro-scatti. | Lavorando. |
| Composizione di espressioni (ammiccamenti > sguardo > movimenti delle labbra > emozioni). | Lavorando. |
| Ponte TTS + sintesi vocale. | Lavorando. |
| Oltre agli indicatori di performance (come le emozioni generate dalla sintesi vocale), si considerano anche... | Lavorando. |
| BridgeManager: connessione automatica. | Lavorando. |
| Libreria di avatar (sfoglia e scarica modelli VRM con licenza CC0). | Lavorando. |
| Pannello di diagnostica del modello. | Lavorando. |
| Profili di mappatura (VRM / ARKit / VRChat). | Lavorando. |
| Configurazione ricaricabile a caldo (file tuning.json e mapping.json). | Lavorando. |
| Correzione della posizione delle braccia, da posizione "T" a posizione "A". | **Non funzionante** -- In fase di sviluppo, non produce risultati corretti. |

## Pila

- **Ambiente di esecuzione:** Godot 4.3+ (renderizzatore compatibile con OpenGL)
- **Formato avatar:** VRM 0.0 e 1.0 (tramite l'addon [godot-vrm](https://github.com/V-Sekai/godot-vrm))
- **Driver FFT:** Analizzatore di spettro audio integrato (`AudioEffectSpectrumAnalyzer`) -> 5 bande viseme
- **Driver webcam:** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 blendshapes di ARKit + posa della testa)
- **Ponte TTS:** Relay WebSocket Node.js che collega Godot a [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + opzionale [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside) per suggerimenti di espressione
- **Motore TTS:** KokoroSharp (locale, funziona su GPU o CPU)
- **Configurazione:** File JSON basato sui dati, con ricaricamento a caldo ogni 2 secondi.

## Configurazione

### Prerequisiti

- Godot 4.3 o superiore (compatibilità con OpenGL)
- Node.js 18 o superiore (per il collegamento con il sistema di sintesi vocale)
- Un file di avatar VRM (oppure utilizzare l'avatar di prova "Seed-san" incluso).

### Avvio rapido

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

### Prima esecuzione

1. L'applicazione carica il primo file VRM che trova nella cartella `assets/avatars/`.
2. BridgeManager avvia automaticamente il bridge di sintesi vocale e si connette.
3. Cliccare su **Avvia microfono** per vedere l'avatar sincronizzare le labbra con la propria voce.
4. Oppure, cliccare su **Riproduci test vocali** per effettuare una verifica con un file audio di esempio incluso.

### Test rapido senza microfono

Un file di test, situato in `assets/audio/test_vowels.wav`, riproduce tutte e cinque le bande dei visemi (ou, oh, aa, ih, ee) due volte, per una durata di circa 10 secondi. Cliccare su "Riproduci i visemi di test" per verificare il corretto funzionamento del driver FFT.

Per rigenerare: `python tools/generate_test_audio.py`

### Utilizzo di OpenSeeFace (tracciamento tramite webcam)

1. Installare ed eseguire [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace).
2. Nell'interfaccia utente di esempio, selezionare "OpenSeeFace (Webcam)" nel menu a tendina del driver.
3. Il tracker invia 52 deformazioni ARKit e la posizione della testa tramite UDP all'indirizzo `127.0.0.1:11573`.
4. Configurare l'host e la porta nel file `config/tuning.json`, nella sezione `openseeface`.

### Utilizzo della sintesi vocale

Il sistema TTS utilizza un'interfaccia Node.js per collegare Godot a un server locale di sintesi vocale KokoroSharp.

1. Assicurarsi che `voice-soundboard-mcp` sia in esecuzione (vedere il repository per le istruzioni di configurazione).
2. Il BridgeManager avvia automaticamente `tools/tts-bridge/bridge.mjs` e stabilisce la connessione.
3. Il pannello TTS si apre automaticamente una volta stabilita la connessione: digitare il testo e fare clic su **Parla**.
4. Le voci disponibili vengono caricate dal server (impostazione predefinita: `am_fenrir`).
5. Facoltativo: selezionare un'emozione per applicare indizi espressivi durante la riproduzione.

Se il collegamento automatico non avviene, utilizzare il pulsante "Connetti" manuale nel pannello TTS.

## Controlli

| Controllo. | Cosa fa. |
| Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." | Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." |
| **Avatar dropdown** | Passare da un modello VRM all'altro. |
| **Driver dropdown** | FFT (microfono) oppure OpenSeeFace (webcam). |
| **Mapping profile dropdown** | Mappatura delle forme facciali per VRM Standard, ARKit e VRChat. |
| **Start Mic** | Avvia la registrazione del microfono per il driver dei visemi FFT. |
| **Load WAV/OGG** | Riproduci un file audio personalizzato tramite il driver FFT. |
| **Play Test Vowels** | Riproduci il file audio di prova incluso. |
| **Emotion dropdown + slider** | Mescolare manualmente un'espressione (felicità, tristezza, rabbia, sorpresa). |
| **Sensitivity slider** | Moltiplicatore dell'ampiezza della trasformata di Fourier (da 1 a 30, valore predefinito: 8). |
| **Zoom +/-** | Zoom della fotocamera (o: rotella del mouse). |
| **Up / Down** | Regolazione dell'altezza della fotocamera. |
| **Model Diagnostics** | Attivare/disattivare il pannello di diagnostica. |
| **Avatar Library** | Esplora e scarica avatar VRM con licenza CC0. |
| **TTS Speak** | Attivare/disattivare il pannello di sintesi vocale. |

### Pannello TTS

| Controllo. | Cosa fa. |
| Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." | Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." |
| **Connect / Disconnect** | Interruttore manuale per la connessione di ponti. |
| **Voice dropdown** | Selezionare la voce di sintesi vocale (la lista viene popolata automaticamente dal server). |
| **Emotion dropdown** | Utilizzare segnali espressivi durante il discorso. |
| **Text box** | Immetere il testo che l'avatar deve pronunciare. |
| **Speak** | Sintetizzare e riprodurre. |
| **Stop** | Interrompere la riproduzione corrente. |

### Pannello di diagnostica del modello

Mostra informazioni in tempo reale sulla compatibilità dell'avatar caricato.

- **Stato:** VERDE (tutto mappato), GIALLO (mappatura parziale), ROSSO (mancano forme critiche)
- **Stile rilevato:** VRM Standard, ARKit o VRChat
- **Suggerimento del profilo:** suggerisce automaticamente il profilo di mappatura corretto.
- **Copertura dei visemi:** indica quali visemi del driver corrispondono a quali deformazioni (trovati/mancanti).
- **Copertura delle espressioni:** stessa cosa per gli ammiccamenti e le emozioni.
- **Stato dell'ammiccamento e dell'osso dell'occhio:** indica se l'ammiccamento procedurale e la direzione dello sguardo basata sull'osso funzioneranno.
- **Forme non mappate:** deformazioni presenti nel modello che non sono referenziate da nessuna mappatura.

## Configurazione

### Configurazione (`config/tuning.json`)

Ricarica automatica ogni 2 secondi. Non è necessario riavviare il sistema.

| Key | Cosa fa. | Predefinito. |
|-----| Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." | Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." |
| `smoothing.attack_time` | Velocità di salita dei pesi (in secondi). | 0.06 |
| `smoothing.release_time` | Quanto velocemente cadono i pesi (in secondi). | 0.12 |
| `viseme_bands.*` | Intervalli di frequenza [minimo, massimo] Hz per ogni visema. | vedere il file. |
| `noise_gate` | Valore minimo dell'ampiezza della trasformata di Fourier (FFT) necessario per classificare un segnale come voce. | 0.01 |
| `sensitivity` | Moltiplicatore di magnitudine per la trasformata di Fourier veloce (FFT). | 8.0 |
| `blink.*` | Sincronizzazione temporale degli ammiccamenti (intervallo, durata, probabilità di ammiccamento doppio). | vedere il file. |
| `openseeface.host` | Host UDP di OpenSeeFace. | 127.0.0.1 |
| `openseeface.port` | Porta UDP di OpenSeeFace. | 11573 |

### Profili di mappatura (`config/mapping*.json`)

Il progetto include tre profili predefiniti:

| File | Nome del profilo. | Per i modelli con... |
| Translate the following English text into Italian:

"The company is committed to providing high-quality products and services. We strive to meet the needs of our customers and to exceed their expectations. We are constantly innovating and improving our processes to offer the best possible solutions."
"L'azienda si impegna a fornire prodotti e servizi di alta qualità. Ci sforziamo di soddisfare le esigenze dei nostri clienti e di superare le loro aspettative. Innoviamo e miglioriamo costantemente i nostri processi per offrire le soluzioni migliori possibili." | Certo, ecco la traduzione:

"Please provide the English text you would like me to translate into Italian." | "The company is committed to providing high-quality products and services."

"We are looking for a motivated and experienced candidate."

"The meeting will be held on Tuesday at 10:00 AM."

"Please contact us for further information."

"We offer a wide range of products to meet your needs."
-----------------
"L'azienda si impegna a fornire prodotti e servizi di alta qualità."

"Siamo alla ricerca di un candidato motivato e con esperienza."

"La riunione si terrà martedì alle 10:00."

"Si prega di contattarci per ulteriori informazioni."

"Offriamo una vasta gamma di prodotti per soddisfare le vostre esigenze." |
| `mapping.json` | Standard VRM. | `labbra_aperte`, `ammiccamento_sinistro`, `faccia_felice` |
| `mapping_arkit.json` | ARKit | `mascella_aperta`, `sbattimento_palpebra_sinistra`, `sorriso_bocca_sinistra` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

Il pannello di diagnostica rileva automaticamente il profilo più adatto al modello caricato e suggerisce di effettuare la modifica.

## Architettura

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

### Decisioni chiave relative al progetto

- **Tutti i dizionari utilizzati per le operazioni critiche sono pre-allocati**, il che riduce al minimo il carico sulla garbage collection (GC) ad ogni fotogramma.
- **La ricerca tra il nome della forma e il suo indice è memorizzata nella cache** durante il caricamento dell'avatar.
- **Gli aggiornamenti dell'interfaccia di debug vengono limitati** a un fotogramma ogni tre.
- **I controlli per il ricaricamento automatico della configurazione** vengono eseguiti ogni 2 secondi, non ad ogni fotogramma.
- **Il "BridgeManager" utilizza un approccio "probe-first"**: verifica se il bridge è già in esecuzione prima di avviare un nuovo processo.
- **Il compositore di espressioni risolve i conflitti**: i movimenti delle palpebre sopprimono le forme degli occhi, i fonemi sopprimono le espressioni della bocca, e la deformazione della mascella viene limitata.

## Struttura del progetto

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

## Problemi noti

- **Posizione delle braccia in "T"**: I modelli VRM vengono caricati nella posizione "T" dopo il processo di retargeting. Lo script `pose_corrector.gd` tenta una correzione in tempo reale tramite la funzione `set_bone_pose_rotation()`, ma i calcoli relativi agli assi locali delle ossa non producono risultati corretti. Questo è il problema visivo più significativo. La soluzione corretta probabilmente richiedeohama modificare la posa di riferimento utilizzata nel processo di importazione dei modelli VRM, oppure risolvere empiricamente gli assi di rotazione locali per ogni scheletro.
- **Modelli per VRChat**: I nomi delle "blend shape" utilizzano il prefisso `blendShape1.vrc_v_*`. Il profilo di mappatura per VRChat gestisce questa convenzione, ma la rilevazione automatica potrebbe suggerire il profilo sbagliato per alcuni modelli.
- **Latenza di OpenSeeFace**: La correzione della posizione della testa aggiunge circa 100 millisecondi di latenza. Regolare i parametri `head_pose_attack` e `head_pose_release` nello script `avatar_controller.gd` se necessario.

## Roadmap per la versione 0.1.0

La versione MVP dimostra che il processo funziona. Ecco cosa è necessario per rendere la versione 0.1.0 uno strumento utilizzabile:

### Assolutamente necessario

- [ ] **Correzione della posa delle braccia:** i modelli devono essere caricati nella posa "A" naturale, non nella posa "T". È necessario correggere il correttore di runtime oppure modificare il sistema di retargeting dell'importazione VRM in Godot per utilizzare le pose di riferimento della posa "A".
- [ ] **Connessione stabile per la sintesi vocale:** gestire in modo elegante eventuali interruzioni della connessione, ripristinare automaticamente la connessione e visualizzare chiaramente gli errori nell'interfaccia utente.
- [ ] **Selezione del dispositivo audio:** consentire agli utenti di scegliere il proprio dispositivo di input del microfono, invece di affidarsi alle impostazioni predefinite del sistema.
- [ ] **Salvataggio e ripristino delle impostazioni:** salvare e ripristinare l'avatar selezionato, il profilo di mappatura, la modalità del driver, la sensibilità e la voce tra le sessioni.
- [ ] **Gestione degli errori:** intercettare e visualizzare gli errori relativi al caricamento dei file VRM, alla sintesi vocale, al download degli avatar e all'analisi dei file di configurazione, invece di limitarsi a visualizzare avvisi nella console.

### Avrebbe dovuto

- [ ] **Sequenza temporale delle emozioni:** possibilità di programmare l'espressione di emozioni con una tempistica precisa (ad esempio, "sorriso a 2 secondi, espressione sorpresa a 5 secondi") per contenuti pre-registrati.
- [ ] **Associazioni di tasti rapidi:** scorciatoie da tastiera per azioni comuni (attivazione/disattivazione del microfono, cambio avatar, attivazione di espressioni).
- [ ] **Integrazione con OBS:** modalità sfondo trasparente e output come webcam virtuale per lo streaming.
- [ ] **Supporto per più voci:** assegnazione di voci diverse a ciascun avatar.
- [ ] **Maggiore varietà nelle animazioni di inattività:** animazioni di inattività randomizzate per evitare ripetizioni robotiche.

### Utile da avere

- [ ] **Posizionamento del braccio IK** – sostituire il metodo di rotazione difettoso con una corretta cinematica inversa.
- [ ] **Posizionamento delle dita** – i modelli VRM hanno le ossa delle dita; aggiungere gesti delle mani di base.
- [ ] **Sincronizzazione labiale da audio preregistrato** – analizzare file WAV/MP3 offline e generare tracce di visemi.
- [ ] **Architettura a plugin** – sistema modulare di driver/mappers/render per estensioni di terze parti.
- [ ] **Scene con più avatar** – caricare più avatar per scenari di dialogo/intervista.

### Al di fuori dell'ambito (per ora)

- Tracciamento completo del corpo
- Simulazione fisica di tessuti e capelli (gestita da "godot-vrm spring bones")
- Supporto per dispositivi mobili
- Funzionalità di rete / multiplayer.

## Licenza

MIT.
