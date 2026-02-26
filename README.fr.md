<p align="center">
  
            <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png"
           alt="Avatar Face MVP" width="280" />
</p>

[Page d'accueil](https://img.shields.io/badge/Landing_Page-en_ligne-blue) (lien vers : https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

**Prototype** : version de démonstration, et non un logiciel destiné à la production.
Consultez [la feuille de route vers la version 0.1.0](#roadmap-to-v010) pour connaître les étapes nécessaires avant une version officielle.

Synchronisation labiale en temps réel pour les avatars VRM, expressions faciales, animations d'inactivité et synthèse vocale textuelle (TTS) – développés avec Godot 4.3 et une interface Node.js pour la synthèse vocale.

## Ce que cela démontre

1. **Microphone en entrée -> le visage bouge de manière réaliste** à 60 images par seconde, avec des visemes FFT sans latence.
2. **Webcam en entrée -> suivi complet du visage** via OpenSeeFace (52 formes de morphage ARKit).
3. **Saisie de texte -> l'avatar parle** avec une synthèse vocale synchronisée aux mouvements des lèvres, via KokoroSharp.
4. **Téléchargez n'importe quel modèle VRM sous licence CC0 -> il fonctionne immédiatement** grâce à des profils de mappage détectés automatiquement.
5. **Tout est basé sur des données** : modifiez les fichiers JSON de mappage, pas le code.

## Statut

| Fonctionnalité. | Statut. |
| Veuillez fournir le texte à traduire. | Veuillez fournir le texte à traduire. |
| Synchronisation labiale basée sur la transformée de Fourier rapide (FFT) (microphone/fichier WAV). | Travaillant. |
| Suivi vidéo par webcam avec OpenSeeFace. | Travaillant. |
| Clignotement procédural (contextuel). | Travaillant. |
| Animation au repos (respiration, mouvement de va-et-vient, léger mouvement de la tête). | Travaillant. |
| Fixation du regard avec de micro-mouvements saccadiques. | Travaillant. |
| Expression composite (clignements > regard > visèmes > émotions). | Travaillant. |
| Pont TTS + synthèse vocale. | Travaillant. |
| Outre les indications de performance (émotions générées par la synthèse vocale), il y a également... | Travaillant. |
| BridgeManager : connexion automatique. | Travaillant. |
| Bibliothèque d'avatars (parcourir et télécharger des modèles VRM sous licence CC0). | Travaillant. |
| Panneau de diagnostic du modèle. | Travaillant. |
| Profils de cartographie (VRM / ARKit / VRChat). | Travaillant. |
| Configuration pouvant être rechargée à chaud (fichiers tuning.json et mapping.json). | Travaillant. |
| Correction de la position des bras, passant de la position "T" à la position "A". | **Défectueux** -- En cours de développement, ne produit pas les résultats attendus. |

## Pile

- **Environnement d'exécution :** Godot 4.3+ (rendu compatible OpenGL)
- **Format d'avatar :** VRM 0.0 et 1.0 (via l'extension [godot-vrm](https://github.com/V-Sekai/godot-vrm) intégrée)
- **Pilote FFT :** Analyseur de spectre audio intégré (`AudioEffectSpectrumAnalyzer`) -> 5 bandes de visème
- **Pilote de webcam :** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 formes de morphage ARKit + pose de la tête)
- **Pont TTS :** Relais WebSocket Node.js reliant Godot à [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + optionnellement [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside) pour les indications d'expression.
- **Moteur TTS :** KokoroSharp (local, fonctionne sur le GPU ou le CPU)
- **Configuration :** Fichier JSON basé sur des données, avec rechargement automatique toutes les 2 secondes.

## Installation

### Prérequis

- Godot 4.3+ (compatible avec OpenGL) : [https://godotengine.org/download](https://godotengine.org/download)
- Node.js 18+ : [https://nodejs.org/](https:// intervenez pour la connexion de synthèse vocale)
- Un fichier d'avatar VRM (ou utilisez l'avatar de test Seed-san fourni).

### Démarrage rapide

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

### Première exécution

1. L'application charge le premier fichier VRM qu'elle trouve dans le dossier `assets/avatars/`.
2. Le gestionnaire de pont (BridgeManager) démarre automatiquement le pont de synthèse vocale et établit la connexion.
3. Cliquez sur **Démarrer le microphone** pour voir l'avatar synchroniser ses mouvements labiaux avec votre voix.
4. Ou cliquez sur **Lecture de test des voyelles** pour effectuer une vérification à l'aide d'un fichier audio de test fourni.

### Test rapide sans microphone

Un fichier de test situé à `assets/audio/test_vowels.wav` fait défiler les cinq bandes de visèmes (ou, oh, aa, ih, ee) deux fois, sur une durée d'environ 10 secondes. Cliquez sur "Lire les voyelles de test" pour vérifier que le pilote FFT fonctionne correctement.

Pour régénérer : `python tools/generate_test_audio.py`

### Utilisation de OpenSeeFace (suivi par webcam)

1. Installez et lancez [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace).
2. Dans l'interface utilisateur de démonstration, sélectionnez "OpenSeeFace (Webcam)" dans le menu déroulant du pilote.
3. Le système de suivi envoie 52 formes de déformation ARKit ainsi que la pose de la tête via UDP vers l'adresse `127.0.0.1:11573`.
4. Configurez l'hôte et le port dans le fichier `config/tuning.json`, sous la section `openseeface`.

### Utilisation de la synthèse vocale

Le système TTS utilise une interface Node.js pour connecter Godot à un serveur local de synthèse vocale KokoroSharp.

1. Assurez-vous que `voice-soundboard-mcp` est en cours d'exécution (consultez le référentiel correspondant pour l'installation).
2. Le gestionnaire de pont (BridgeManager) démarre automatiquement `tools/tts-bridge/bridge.mjs` et établit la connexion.
3. Le panneau TTS s'ouvre automatiquement une fois la connexion établie. Tapez le texte et cliquez sur **Parler**.
4. Les voix disponibles sont récupérées depuis le serveur (par défaut : `am_fenrir`).
5. Facultatif : sélectionnez une émotion pour appliquer des indications d'expression pendant la parole.

Si la connexion automatique du pont ne fonctionne pas, utilisez le bouton **Connecter** manuellement dans le panneau TTS.

## Commandes

| Contrôle. | Ce qu'il fait. |
| Veuillez fournir le texte à traduire. | Bien sûr, veuillez me fournir le texte que vous souhaitez que je traduise. |
| **Avatar dropdown** | Basculer entre les modèles VRM chargés. |
| **Driver dropdown** | FFT (microphone audio) ou OpenSeeFace (webcam). |
| **Mapping profile dropdown** | Correspondance des formes VRM / ARKit / VRChat. |
| **Start Mic** | Démarrer l'acquisition audio pour le pilote de visème FFT. |
| **Load WAV/OGG** | Lecture d'un fichier audio personnalisé via le pilote FFT. |
| **Play Test Vowels** | Lecture du fichier audio de test fourni. |
| **Emotion dropdown + slider** | Mélangez manuellement une expression (joie, tristesse, colère, surprise). |
| **Sensitivity slider** | Multiplicateur d'amplitude FFT (1-30, valeur par défaut : 8). |
| **Zoom +/-** | Zoom de la caméra (ou : molette de la souris). |
| **Up / Down** | Réglage de la hauteur de la caméra. |
| **Model Diagnostics** | Activer/désactiver le panneau de diagnostic. |
| **Avatar Library** | Parcourez et téléchargez les avatars VRM sous licence CC0. |
| **TTS Speak** | Activer/désactiver le panneau de synthèse vocale. |

### Panneau TTS

| Contrôle. | Ce qu'il डॉक्टरों. |
| Veuillez fournir le texte à traduire. | Bien sûr, veuillez me fournir le texte que vous souhaitez que je traduise. |
| **Connect / Disconnect** | Bouton de verrouillage pour connexion manuelle des ponts. |
| **Voice dropdown** | Sélectionnez la voix de synthèse vocale (la liste est automatiquement renseignée à partir du serveur). |
| **Emotion dropdown** | Utilisez des indices expressifs pendant la parole. |
| **Text box** | Saisissez le texte que l'avatar doit afficher. |
| **Speak** | Synthétiser et jouer. |
| **Stop** | Arrêter la lecture en cours. |

### Panneau de diagnostic du modèle

Affiche des informations en temps réel sur la compatibilité de l'avatar chargé.

- **Statut du modèle :** VERT (toutes les formes présentes), JAUNE (certaines formes manquantes), ROUGE (formes critiques manquantes).
- **Style détecté :** Standard VRM, ARKit ou VRChat.
- **Suggestion de profil :** Suggère automatiquement le profil de mappage correct.
- **Couverture des visèmes :** Indique quels visèmes du pilote correspondent à quelles formes de déformation (présents/manquants).
- **Couverture des expressions :** Même chose pour les clignements et les émotions.
- **Statut du clignement et de l'os de l'œil :** Indique si le clignement procédural et le suivi du regard basé sur les os fonctionneront.
- **Formes non mappées :** Formes de déformation présentes sur le modèle qui ne sont référencées par aucun mappage.

## Configuration

### Réglages (fichier `config/tuning.json`)

Rechargement automatique toutes les 2 secondes. Aucun redémarrage nécessaire.

| Key | Ce qu'il fait. | Par défaut. |
|-----| Bien sûr, veuillez me fournir le texte que vous souhaitez que je traduise. | Veuillez fournir le texte à traduire. |
| `smoothing.attack_time` | Vitesse de montée des poids (en secondes). | 0.06 |
| `smoothing.release_time` | Vitesse de chute des masses (en secondes). | 0.12 |
| `viseme_bands.*` | Plages de fréquences [minimum, maximum] Hz par visème. | voir le fichier. |
| `noise_gate` | Magnitude minimale de la transformée de Fourier rapide (FFT) pour être considérée comme de la parole. | 0.01 |
| `sensitivity` | Multiplicateur de magnitude pour la transformée de Fourier rapide (FFT). | 8.0 |
| `blink.*` | Synchronisation temporelle des clignements (intervalle, durée, probabilité de clignements doubles). | voir le fichier. |
| `openseeface.host` | Hôte UDP pour OpenSeeFace. | 127.0.0.1 |
| `openseeface.port` | Port UDP d'OpenSeeFace. | 11573 |

### Fichiers de configuration des correspondances (`config/mapping*.json`)

Trois profils sont fournis avec le projet :

| File | Nom du profil. | Pour les modèles suivants : |
| Veuillez fournir le texte à traduire. | Bien sûr, veuillez me fournir le texte que vous souhaitez que je traduise. |-----------------|
| `mapping.json` | Norme VRM. | `lip_a`, `blink_L`, `face_happy` |
| `mapping_arkit.json` | ARKit | `bouche_ouverte`, `clignement_des_yeux_gauche`, `sourire_gauche` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

Le panneau de diagnostic détecte automatiquement le profil qui correspond au modèle chargé et propose de le modifier.

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

### Décisions clés en matière de conception

- **Tous les dictionnaires utilisés pour les opérations critiques sont pré-alloués**, ce qui réduit la pression sur le ramasse-miettes (GC) à chaque image.
- **La correspondance entre le nom et l'index des formes de morphage est mise en cache** lors du chargement de l'avatar.
- **Les mises à jour de l'interface de débogage sont limitées** à une mise à jour toutes les trois images.
- **Les vérifications de rechargement automatique de la configuration** sont effectuées toutes les 2 secondes, et non à chaque image.
- **Le modèle de "vérification préalable" du gestionnaire de connexion** vérifie si une connexion est déjà établie avant de lancer un nouveau processus.
- **Le compositeur d'expressions** résout les conflits : les clignements suppriment les formes des yeux, les visèmes suppriment les expressions de la bouche, et la déformation de la mâchoire est limitée.

## Structure du projet

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

## Problèmes connus

- **Positionnement des bras en "T" :** Les modèles VRM sont chargés en position "T" après le transfert des animations. Le script `pose_corrector.gd` tente une correction en temps réel via la fonction `set_bone_pose_rotation()`, mais les calculs d'axes locaux aux os ne donnent pas les résultats corrects. C'est le problème visuel le plus important. La solution correcte nécessiterait probablement de modifier la pose cible du transfert d'animations dans le pipeline d'importation VRM, ou de déterminer empiriquement les axes de rotation locaux aux os pour chaque squelette.
- **Modèles VRChat :** Les noms des formes de morphage utilisent le préfixe `blendShape1.vrc_v_*`. Le profil de mappage VRChat gère cela, mais la détection automatique peut suggérer le mauvais profil pour certains modèles.
- **Latence d'OpenSeeFace :** Le lissage de la pose de la tête ajoute environ 100 ms de latence. Ajustez les paramètres `head_pose_attack` / `head_pose_release` dans le script `avatar_controller.gd` si nécessaire.

## Feuille de route vers la version 0.1.0

La version MVP (Minimum Viable Product) démontre que le processus fonctionne. Voici ce qui est nécessaire pour que la version 0.1.0 devienne un outil utilisable :

### Indispensable

- [ ] **Correction de la posture des bras** : Les modèles doivent être chargés dans une posture naturelle (A-pose), et non dans une posture en "T". Il faut soit corriger le correcteur en temps réel, soit modifier le système de remappage d'importation VRM pour qu'il utilise des poses de référence en A-pose.
- [ ] **Pont de synthèse vocale stable** : Gérer les plantages du pont de manière élégante, avec une reconnexion automatique et l'affichage clair des erreurs dans l'interface utilisateur.
- [ ] **Sélection du périphérique audio** : Permettre aux utilisateurs de choisir leur périphérique d'entrée microphone au lieu de se baser sur les paramètres par défaut du système.
- [ ] **Sauvegarde et restauration des paramètres** : Conserver les paramètres sélectionnés, tels que l'avatar, le profil de mappage, le mode du pilote, la sensibilité et la voix, entre les sessions.
- [ ] **Gestion des erreurs** : Intercepter et afficher les erreurs liées au chargement des modèles VRM, à la synthèse vocale, aux téléchargements d'avatars et à l'analyse des fichiers de configuration, au lieu d'afficher simplement des avertissements dans la console.

### Devrait avoir

- [ ] **Chronologie des émotions** : possibilité de programmer l'apparition des émotions avec un timing précis (par exemple, "sourire à 2 secondes, expression de surprise à 5 secondes") pour les contenus préenregistrés.
- [ ] **Raccourcis clavier** : touches de fonction pour les actions courantes (activer/désactiver le microphone, changer d'avatar, déclencher des expressions).
- [ ] **Intégration avec OBS** : mode d'arrière-plan transparent et sortie en tant que caméra virtuelle pour le streaming.
- [ ] **Prise en charge de plusieurs voix** : attribution de voix spécifiques à chaque avatar.
- [ ] **Variations d'animation au repos améliorées** : animations au repos aléatoires pour éviter les répétitions mécaniques.

### Bienvenu

- [ ] **Positionnement des bras en utilisant la cinématique inverse** – remplacer la méthode de rotation actuelle par une approche utilisant la cinématique inverse.
- [ ] **Positionnement des doigts** – les modèles VRM possèdent des os pour les doigts ; ajouter des gestes de base pour les mains.
- [ ] **Synchronisation labiale à partir d'audio préenregistré** – analyser les fichiers WAV/MP3 hors ligne et générer des pistes de visèmes.
- [ ] **Architecture de plugin** – système modulaire de pilotes/mappeurs/rendus pour les extensions tierces.
- [ ] **Scènes avec plusieurs avatars** – charger plusieurs avatars pour les scénarios de dialogue/entretien.

### Hors du champ d'application (pour le moment)

- Suivi complet du corps
- Simulation physique des vêtements et des cheveux (gérée par les "spring bones" de godot-vrm)
- Compatibilité avec les appareils mobiles
- Réseau / multijoueur

## Licence

MIT.
