<p align="center">
  <a href="README.zh.md">中文</a> | <a href="README.es.md">Español</a> | <a href="README.md">English</a> | <a href="README.pt-BR.md">Português (BR)</a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/mcp-tool-shop-org/brand/main/logos/avatar-face-mvp/readme.png" alt="Avatar Face MVP" width="280" />
</p>

[![Page d'accueil](https://img.shields.io/badge/Landing_Page-live-blue)](https://mcp-tool-shop-org.github.io/avatar-face-mvp/)

> **Prototype** -- prototype, pas un logiciel de production.
> Consultez la [feuille de route vers la version 0.1.0](#roadmap-to-v010) pour connaître les étapes nécessaires avant une version finale.

Synchronisation labiale VRM en temps réel, expressions, animations d'inactivité et synthèse vocale -- développé avec Godot 4.3+ et une passerelle Node.js pour la synthèse vocale.

## Ce que cela démontre

1. **Micro entré -> le visage bouge de manière convaincante** à 60 images par seconde avec une latence nulle grâce à l'analyse FFT des visèmes.
2. **Webcam entré -> suivi complet du visage** via OpenSeeFace (52 formes de mélange ARKit).
3. **Saisie de texte -> l'avatar parle** avec une synthèse vocale synchronisée avec les lèvres via KokoroSharp.
4. **Téléchargez n'importe quel avatar VRM sous licence CC0 -> il fonctionne simplement** grâce aux profils de mappage détectés automatiquement.
5. **Tout est basé sur des données** -- échangez les fichiers JSON de mappage, pas le code.

## Statut

| Fonctionnalité | Statut |
|---------|--------|
| Synchronisation labiale FFT (micro/WAV) | Fonctionnel |
| Suivi de la webcam OpenSeeFace | Fonctionnel |
| Clignement simulé (contextuel) | Fonctionnel |
| Animation d'inactivité (respiration, balancement, mouvement de la tête) | Fonctionnel |
| Regard avec micro-saccades | Fonctionnel |
| Compositeur d'expressions (clignements > regard > visèmes > émotions) | Fonctionnel |
| Passerelle de synthèse vocale + synthèse vocale | Fonctionnel |
| Indices de performance (émotion de la synthèse vocale) | Fonctionnel |
| Passerelle auto-connectée | Fonctionnel |
| Bibliothèque d'avatars (parcourir et télécharger des avatars VRM sous licence CC0) | Fonctionnel |
| Panneau de diagnostic du modèle | Fonctionnel |
| Profils de mappage (VRM / ARKit / VRChat) | Fonctionnel |
| Configuration chargeable à chaud (tuning.json, mapping.json) | Fonctionnel |
| Correction de la position des bras (T-pose vers A-pose) | **Non fonctionnel** -- En cours de développement, ne produit pas les résultats corrects. |

## Environnement

- **Environnement d'exécution:** Godot 4.3+ (rendu compatible GL)
- **Format de l'avatar:** VRM 0.0 et 1.0 (via l'extension [godot-vrm](https://github.com/V-Sekai/godot-vrm) intégrée)
- **Pilote FFT:** `AudioEffectSpectrumAnalyzer` intégré -> 5 bandes de visèmes
- **Pilote de webcam:** [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) UDP (52 formes de mélange ARKit + pose de la tête)
- **Passerelle de synthèse vocale:** Relais WebSocket Node.js reliant Godot à [voice-soundboard-mcp](https://github.com/mcp-tool-shop-org/voice-soundboard-mcp) + optionnel [mcp-aside](https://github.com/mcp-tool-shop-org/mcp-aside) pour les indices d'expression.
- **Moteur de synthèse vocale:** KokoroSharp (local, fonctionne sur GPU ou CPU)
- **Configuration:** Basée sur des données, avec un rechargement à chaud en 2 secondes.

## Installation

### Prérequis

- [Godot 4.3+](https://godotengine.org/download) (rendu compatible GL)
- [Node.js 18+](https://nodejs.org/) (pour la passerelle de synthèse vocale)
- Un fichier d'avatar VRM (ou utilisez l'avatar de test Seed-san fourni)

### Premiers pas

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

### Premier lancement

1. L'application charge le premier avatar VRM qu'elle trouve dans le dossier `assets/avatars/`.
2. La passerelle de synthèse vocale démarre automatiquement et se connecte.
3. Cliquez sur **Démarrer le micro** pour voir l'avatar synchroniser ses lèvres avec votre voix.
4. Ou cliquez sur **Lire les voyelles de test** pour vérifier avec un fichier audio de test fourni.

### Test rapide sans micro

Un fichier situé à `assets/audio/test_vowels.wav` fait défiler les cinq bandes de visèmes (ou, oh, aa, ih, ee) deux fois en environ 10 secondes. Cliquez sur "Lire les voyelles de test" pour vérifier que le pilote FFT fonctionne.

Pour régénérer : `python tools/generate_test_audio.py`

### Utilisation d'OpenSeeFace (suivi de la webcam)

1. Installez et exécutez [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace).
2. Dans l'interface utilisateur de démonstration, sélectionnez **OpenSeeFace (Webcam)** dans le menu déroulant du pilote.
3. Le tracker envoie 52 formes de mélange ARKit + la pose de la tête via UDP à l'adresse `127.0.0.1:11573`.
4. Configurez l'hôte/le port dans `config/tuning.json` sous la section `openseeface`.

### Utilisation de la synthèse vocale

Le système TTS utilise un pont Node.js pour connecter Godot à un serveur de synthèse vocale local KokoroSharp.

1. Assurez-vous que `voice-soundboard-mcp` est en cours d'exécution (consultez le référentiel correspondant pour la configuration).
2. Le gestionnaire de pont démarre automatiquement le fichier `tools/tts-bridge/bridge.mjs` et établit la connexion.
3. Le panneau TTS s'ouvre automatiquement une fois la connexion établie. Tapez le texte et cliquez sur **Parler**.
4. Les voix disponibles sont récupérées depuis le serveur (par défaut : `am_fenrir`).
5. Facultatif : sélectionnez une émotion pour appliquer des indications d'expression pendant le discours.

Si le pont ne parvient pas à se connecter automatiquement, utilisez le bouton **Connecter** manuellement dans le panneau TTS.

## Commandes

| Commande | Fonction |
|---------|-------------|
| **Avatar dropdown** | Basculer entre les modèles VRM chargés |
| **Driver dropdown** | FFT (audio du microphone) ou OpenSeeFace (webcam) |
| **Mapping profile dropdown** | Mappage des formes de mélange VRM Standard / ARKit / VRChat |
| **Start Mic** | Démarrer l'enregistrement du microphone pour le pilote visème FFT |
| **Load WAV/OGG** | Lire un fichier audio personnalisé via le pilote FFT |
| **Play Test Vowels** | Lire l'audio de test fourni |
| **Emotion dropdown + slider** | Appliquer manuellement une expression (heureux, triste, en colère, surpris) |
| **Sensitivity slider** | Multiplicateur d'amplitude FFT (1-30, par défaut 8) |
| **Zoom +/-** | Zoom de la caméra (également : molette de la souris) |
| **Up / Down** | Réglage de la hauteur de la caméra |
| **Model Diagnostics** | Afficher ou masquer le panneau de diagnostic |
| **Avatar Library** | Parcourir et télécharger des avatars VRM CC0 |
| **TTS Speak** | Afficher ou masquer le panneau TTS |

### Panneau TTS

| Commande | Fonction |
|---------|-------------|
| **Connect / Disconnect** | Basculer la connexion du pont manuellement |
| **Voice dropdown** | Sélectionner la voix TTS (récupérée automatiquement depuis le serveur) |
| **Emotion dropdown** | Appliquer des indications d'expression pendant le discours |
| **Text box** | Entrez le texte que l'avatar doit prononcer |
| **Speak** | Synthétiser et lire |
| **Stop** | Annuler la lecture en cours |

### Panneau de diagnostic du modèle

Affiche des informations de compatibilité en temps réel pour l'avatar chargé :

- **Indicateur d'état** -- VERT (tout mappé), JAUNE (partiellement), ROUGE (formes critiques manquantes)
- **Style détecté** -- VRM Standard, ARKit ou VRChat
- **Suggestion de profil** -- suggère automatiquement le profil de mappage correct
- **Couverture des visèmes** -- indique quels visèmes du pilote correspondent à quelles formes de mélange (trouvés/manquants)
- **Couverture des expressions** -- même chose pour les clignements et les émotions
- **État du clignement + de l'os de l'œil** -- indique si le clignement procédural et le suivi du regard basé sur les os fonctionneront
- **Formes non mappées** -- formes de mélange sur le modèle qui ne sont référencées par aucun mappage

## Configuration

### Réglages (`config/tuning.json`)

Rechargés automatiquement toutes les 2 secondes. Pas besoin de redémarrer.

| Clé | Fonction | Valeur par défaut |
|-----|-------------|---------|
| `smoothing.attack_time` | Vitesse d'augmentation des poids (en secondes) | 0.06 |
| `smoothing.release_time` | Vitesse de diminution des poids (en secondes) | 0.12 |
| `viseme_bands.*` | Plages de fréquences [min, max] Hz par visème | voir le fichier |
| `noise_gate` | Amplitude FFT minimale pour être considérée comme de la parole | 0.01 |
| `sensitivity` | Multiplicateur d'amplitude FFT | 8.0 |
| `blink.*` | Timing du clignement procédural (intervalle, durée, probabilité de double clignement) | voir le fichier |
| `openseeface.host` | Hôte UDP d'OpenSeeFace | 127.0.0.1 |
| `openseeface.port` | Port UDP d'OpenSeeFace | 11573 |

### Profils de mappage (`config/mapping*.json`)

Trois profils sont fournis avec le projet :

| Fichier | Nom du profil | Pour les modèles avec |
|------|-------------|-----------------|
| `mapping.json` | VRM Standard | `lip_a`, `blink_L`, `face_happy` |
| `mapping_arkit.json` | ARKit | `jawOpen`, `eyeBlink_L`, `mouthSmile_L` |
| `mapping_vrchat.json` | VRChat | `vrc_v_aa`, `vrc_blink` |

Le panneau de diagnostic détecte automatiquement quel profil correspond au modèle chargé et suggère de basculer.

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

### Décisions de conception clés

- **Tous les dictionnaires utilisés pour les opérations fréquentes sont pré-alloués**, ce qui réduit la pression sur le ramasse-miettes (GC) à chaque image.
- **La recherche de l'index correspondant au nom de la forme de morphage est mise en cache** lors du chargement de l'avatar.
- **Les mises à jour de l'interface de débogage sont limitées** à une image sur trois.
- **Les vérifications de rechargement automatique de la configuration sont effectuées toutes les 2 secondes**, et non à chaque image.
- **Le "BridgeManager" utilise une approche de vérification préalable** : il vérifie si le pont est déjà en cours d'exécution avant de lancer un nouveau processus.
- **Le compositeur d'expressions résout les conflits :** les clignements suppriment les formes de morphage des yeux, les visèmes suppriment les expressions faciales, et la déformation de la mâchoire est limitée.

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

- **Positions des bras en "T" :** Les modèles VRM se chargent en position "T" après le remappage. Le script `pose_corrector.gd` tente une correction au moment de l'exécution en utilisant `set_bone_pose_rotation()`, mais les calculs d'axes locaux aux os ne donnent pas les résultats corrects. C'est le problème visuel le plus important. La correction correcte nécessiterait probablement de modifier soit la pipeline d'importation VRM pour cibler la position de référence "A" lors du remappage, soit de résoudre empiriquement les axes de rotation locaux des os pour chaque squelette.
- **Modèles VRChat :** Les noms des formes de morphage utilisent le préfixe `blendShape1.vrc_v_*`. Le profil de mappage VRChat gère cela, mais la détection automatique peut suggérer le mauvais profil pour certains modèles.
- **Latence d'OpenSeeFace :** Le lissage de la pose de la tête ajoute environ 100 ms de latence. Ajustez `head_pose_attack` / `head_pose_release` dans `avatar_controller.gd` si nécessaire.

## Feuille de route vers la version 0.1.0

La version MVP démontre que la pipeline fonctionne. Voici ce qui est nécessaire pour que la version 0.1.0 soit un outil utilisable :

### Indispensable

- [ ] **Corriger la position des bras** : les modèles doivent se charger dans une position "A" naturelle, et non en position "T". Soit corriger le correcteur au moment de l'exécution, soit modifier le remappage de godot-vrm pour cibler la position de référence "A".
- [ ] **Pont TTS stable** : gérer les plantages du pont de manière élégante, se reconnecter automatiquement et afficher clairement les erreurs dans l'interface utilisateur.
- [ ] **Sélection de l'appareil audio** : permettre aux utilisateurs de choisir leur périphérique d'entrée microphone au lieu de se baser sur le paramètre par défaut du système.
- [ ] **Sauvegarde/restauration des paramètres** : conserver l'avatar sélectionné, le profil de mappage, le mode du pilote, la sensibilité et la voix entre les sessions.
- [ ] **Gestion des erreurs** : intercepter et afficher les erreurs de chargement des modèles VRM, de synthèse vocale, de téléchargement des avatars et d'analyse de la configuration, au lieu d'afficher simplement des avertissements dans la console.

### Souhaitable

- [ ] **Chronologie des émotions** : mettre en file d'attente les émotions avec un timing (par exemple, "sourire à 2 secondes, surprise à 5 secondes") pour le contenu pré-enregistré.
- [ ] **Attributions de touches** : raccourcis clavier pour les actions courantes (activer le microphone, changer d'avatar, déclencher des expressions).
- [ ] **Intégration OBS** : mode d'arrière-plan transparent + sortie de caméra virtuelle pour le streaming.
- [ ] **Prise en charge de plusieurs voix** : attribution de voix par avatar.
- [ ] **Variations d'état inactif améliorées** : animations d'état inactif aléatoires pour éviter les répétitions robotiques.

### Bienvenu

- [ ] **Positionnement des bras par IK** : remplacer l'approche de rotation défectueuse par une cinématique inverse appropriée.
- [ ] **Positionnement des doigts** : les modèles VRM ont des os de doigts ; ajouter des gestes de base des mains.
- [ ] **Synchronisation labiale à partir d'audio pré-enregistré** : analyser les fichiers WAV/MP3 hors ligne et générer des pistes de visèmes.
- [ ] **Architecture de plugin** : système modulaire de pilotes/mappeurs/rendus pour les extensions tierces.
- [ ] **Scènes multi-avatars** : charger plusieurs avatars pour les scénarios de dialogue/entretien.

### Hors du champ (pour l'instant)

- Suivi du corps entier
- Tissu/cheveux basés sur la physique (gérés par les "spring bones" de godot-vrm)
- Prise en charge des appareils mobiles
- Réseau / multijoueur

## Sécurité et portée des données

Avatar Face MVP fonctionne **entièrement localement** et ne fait aucune requête réseau.

- **Données auxquelles on accède :** Lecture des fichiers d'avatar VRM locaux, entrée audio du microphone, flux de la webcam via OpenSeeFace (UDP sur localhost). Lecture/écriture de fichiers de configuration JSON dans le répertoire du projet. Optionnellement, lancement d'un processus local de pont TTS Node.js.
- **Données auxquelles on N'accède PAS :** Aucune requête internet. Aucune télémétrie. Aucun service cloud. Aucun stockage d'informations d'identification. Les données de la webcam sont traitées localement uniquement.
- **Autorisations requises :** Accès au microphone pour la synchronisation labiale. Accès optionnel à la webcam via OpenSeeFace. Accès au système de fichiers pour les modèles VRM et la configuration.

Consultez [SECURITY.md](SECURITY.md) pour signaler les vulnérabilités.

---

## Tableau de bord

| Catégorie | Score |
|----------|-------|
| Sécurité | 10/10 |
| Gestion des erreurs | 10/10 |
| Documentation pour les utilisateurs | 10/10 |
| Hygiène de développement | 10/10 |
| Identité | 10/10 |
| **Overall** | **50/50** |

---

## Licence

MIT

---

Créé par <a href="https://mcp-tool-shop.github.io/">MCP Tool Shop</a
