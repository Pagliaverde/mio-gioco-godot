# 🌱 Mio Gioco Godot

Un gioco 2D top-down in pixel art, ambientato in un piccolo villaggio di campagna, sviluppato con **Godot 4**.
Il progetto è in fase iniziale: c'è un protagonista che si muove e attacca, una mappa costruita a tile e un primo NPC (uno slime) con cui dialogare.

![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/linguaggio-GDScript-355570)
![Stato](https://img.shields.io/badge/stato-in%20sviluppo-orange)

---

## 📑 Indice

- [Funzionalità](#-funzionalità)
- [Comandi](#-comandi)
- [Come avviare il progetto](#-come-avviare-il-progetto)
- [Struttura del progetto](#-struttura-del-progetto)
- [Dialoghi](#-dialoghi)
- [Roadmap](#-roadmap)
- [Contribuire (workflow Git)](#-contribuire-workflow-git)
- [Crediti](#-crediti)

---

## ✨ Funzionalità

- **Movimento in 8 direzioni** del protagonista, con animazioni `idle` / `run` per ogni direzione
- **Attacco con la spada**, con animazione dedicata ed effetto sonoro
- **Suono dei passi** che parte e si ferma in base al movimento
- **Mappa a tile** (erba, colline, acqua, recinzioni, case in legno, sentieri)
- **NPC Slime** che vaga per la mappa in modo casuale alternando pause e brevi spostamenti
- **Sistema di dialoghi** basato sul plugin [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager), con balloon personalizzato
- Grafica pixel-perfect (filtro texture *Nearest*) e finestra ridimensionabile

## 🎮 Comandi

| Azione               | Tastiera                  |
| -------------------- | ------------------------- |
| Muoversi             | `W` `A` `S` `D` / frecce  |
| Attaccare            | `Spazio`                  |
| Avviare il dialogo   | `Invio`                   |
| Avanzare nel dialogo | `Invio` / click           |

> ⚠️ Al momento il dialogo con lo slime è legato all'azione `ui_accept`, che in Godot include anche `Spazio`: premendo Spazio si attacca **e** si apre il dialogo. Vedi la [Roadmap](#-roadmap).

## 🚀 Come avviare il progetto

### Requisiti

- [Godot Engine **4.7**](https://godotengine.org/download) (versione standard, non serve la versione .NET)

### Passaggi

1. Clona il repository:
   ```bash
   git clone https://github.com/Pagliaverde/mio-gioco-godot.git
   ```
2. Apri Godot e, dal **Project Manager**, clicca su **Importa** e seleziona il file `project.godot` nella cartella clonata.
3. Al primo avvio Godot reimporterà tutti gli asset (può richiedere qualche secondo).
4. Premi **F5** (o il pulsante ▶️ in alto a destra) per avviare il gioco. La scena principale è `Scene/Main.tscn`.

> Il plugin **Dialogue Manager** è già incluso nella cartella `addons/` e abilitato in `project.godot`: non serve installarlo a parte.

## 📂 Struttura del progetto

```
mio-gioco-godot/
├── project.godot              # Configurazione del progetto (input, autoload, plugin)
├── Scene/
│   ├── Main.tscn              # Scena principale: mappa, camera, player e NPC
│   ├── Player.tscn            # Protagonista (sprite animati + suoni)
│   └── SlimeNpc.tscn          # NPC slime
├── Asset/
│   ├── Script/
│   │   ├── player.gd          # Movimento, animazioni e attacco del player
│   │   └── Slime.gd           # IA a movimento casuale + avvio dialogo
│   ├── Dialogue/
│   │   ├── DialogueChat/      # File .dialogue con i testi dei dialoghi
│   │   └── DialoguePannel/    # Balloon (UI) personalizzato dei dialoghi
│   ├── Sprite/
│   │   ├── MC/                # Sprite del protagonista
│   │   ├── NPC/               # Sprite di NPC e animali
│   │   └── Object/            # Oggetti, mobili, piante, strumenti
│   ├── TileMap/Map/           # Tileset della mappa
│   ├── tileset/               # Risorsa TileSet di Godot
│   └── audio/                 # Effetti sonori (passi, spada)
└── addons/
    └── dialogue_manager/      # Plugin Dialogue Manager (v4.1.0)
```

## 💬 Dialoghi

I dialoghi si scrivono in file `.dialogue` dentro `Asset/Dialogue/DialogueChat/`. Esempio (`Slime_Dialogue.dialogue`):

```
~ start
Slime: Ciao! Sono uno slime.
Slime: Posso muovermi in giro a caso!
=> END
```

Per avviare un dialogo da uno script:

```gdscript
const DIALOGO = preload("res://Asset/Dialogue/DialogueChat/Slime_Dialogue.dialogue")

DialogueManager.show_dialogue_balloon(DIALOGO, "start")
```

Il balloon usato di default è configurato in *Progetto → Impostazioni → Dialogue Manager* (`res://Asset/Dialogue/DialoguePannel/balloon.tscn`).
La sintassi completa è documentata nella [guida ufficiale di Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager/tree/main/docs).

## 🗺️ Roadmap

- [x] Movimento e animazioni del protagonista
- [x] Attacco con la spada ed effetti sonori
- [x] Prima mappa a tile
- [x] Primo NPC con dialogo
- [ ] Avviare il dialogo solo quando il player è vicino all'NPC (area di interazione)
- [ ] Tasto di interazione dedicato (es. `E`), separato dall'attacco
- [ ] Hitbox della spada e interazione con i nemici
- [ ] Animali (galline, mucche) già presenti negli asset
- [ ] Inventario e oggetti raccoglibili
- [ ] Menu principale e salvataggio

## 🤝 Contribuire (workflow Git)

Flusso di lavoro consigliato:

```bash
git pull                                   # 1. Scarica le ultime modifiche
git checkout -b nome-funzionalita          # 2. Crea un branch per il tuo lavoro
# ... lavora in Godot ...
git add .                                  # 3. Prepara le modifiche
git commit -m "Descrizione delle modifiche" # 4. Crea il commit
git push -u origin nome-funzionalita       # 5. Carica il branch su GitHub
```

Poi apri una **Pull Request** su GitHub verso `main`.

> 💡 Chiudi Godot (o salva tutto) prima di fare `git pull`, per evitare conflitti sui file `.tscn`. La cartella `.godot/` è già esclusa tramite `.gitignore`.

<details>
<summary><b>📘 Cheat sheet dei comandi Git</b></summary>

#### Configurazione iniziale

```bash
git config --global user.name "IlTuoNome"
git config --global user.email "la_tua_email@esempio.com"   # la stessa di GitHub
```

#### Collegare una cartella al repository

```bash
git init
git remote add origin https://github.com/Pagliaverde/mio-gioco-godot.git
git branch -M main
git remote -v                 # controlla l'URL remoto
git push -u origin main       # primo push
```

#### Uso quotidiano

| Comando | Cosa fa |
| --- | --- |
| `git status` | Mostra file modificati, non tracciati e pronti al commit |
| `git add .` | Mette in stage tutti i file modificati |
| `git add nome_file.gd` | Mette in stage un solo file |
| `git commit -m "msg"` | Crea un commit locale |
| `git push` | Invia i commit su GitHub |
| `git pull` | Scarica e unisce le modifiche da GitHub |
| `git log --oneline` | Cronologia sintetica dei commit |

#### Branch

| Comando | Cosa fa |
| --- | --- |
| `git branch` | Elenca i branch locali |
| `git checkout -b nome-branch` | Crea un branch e ci passa |
| `git checkout nome-branch` | Passa a un branch esistente |
| `git merge nome-branch` | Unisce `nome-branch` nel branch corrente |

#### Annullare modifiche

| Comando | Cosa fa |
| --- | --- |
| `git checkout -- nome_file.gd` | Scarta le modifiche non in stage di un file |
| `git reset` | Toglie tutto dallo stage (i file restano modificati) |
| `git reset --soft HEAD~1` | Annulla l'ultimo commit, mantenendo le modifiche |
| `git reset --hard HEAD~1` | ⚠️ Annulla l'ultimo commit e **cancella** le modifiche |

</details>

## 🙏 Crediti

- **Motore:** [Godot Engine](https://godotengine.org/)
- **Dialoghi:** [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) di Nathan Hoad (licenza MIT, vedi `addons/dialogue_manager/LICENSE`)
- **Grafica:** asset pixel art di terze parti (sprite del personaggio, tileset della fattoria, animali, slime). <!-- TODO: indicare autori e link degli asset pack usati -->
- **Audio:** effetti sonori di terze parti. <!-- TODO: indicare la fonte -->
