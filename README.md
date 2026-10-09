# 🎭 Fuori Copione

Un card game a turni con **pesca casuale**, sviluppato con **Godot 4**: non hai una mano,
peschi una carta alla volta e decidi se rischiare ancora o fermarti. La storia comincia
in una stanza senza volto e attraversa un teatro che è tutto il mondo: cinque boss,
nove maschere, tre finali.

**Si gioca camminando**, come nei giochi di mostri tascabili: il teatro è fatto di
stanze esplorabili dall'alto, i boss ti vedono e ti vengono incontro, nelle quinte
si incontrano le comparse, si compra nei negozi con i **Biglietti**. Le scene sono
il gioco di carte, sopra al mondo. Vedi [`World/README.md`](World/README.md),
[`Story/README.md`](Story/README.md) e [`Docs/TRAMA_E_MASCHERE.md`](Docs/TRAMA_E_MASCHERE.md).

Nel repository resta anche il primo prototipo 2D top-down (`Scene/Main.tscn`), con lo
slime da cui è nato il mondo.

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

- **Il mondo esplorabile** (`World/`): undici mappe (le sette zone della storia e quattro stanze laterali), boss nel mondo con lo sguardo da allenatore, incontri nelle quinte, negozi, Bauli di Scena, inventario, vita che resta tra le scene, transizioni a lampo prima delle battaglie, luci e palette per zona, collisioni su muri e oggetti
- **La storia** (`Story/`): dal camerino al fondo della platea, con i Bauli di Scena, la platea dei manichini, cinque boss e tre finali. Salvataggio, **Riprendi** dal menu
- **Le maschere** (`Cards/mask/`): affinità, regola dell'azzardo e postura; nove maschere, quattro nei bauli e cinque vinte dai boss
- **Il motore delle carte** (`Cards/`): mazzi, pubblico/mana, pesca, fuori copione/bust, elementi, status, sinergie, simulatore di bilanciamento
- **Le illustrazioni delle carte**, dipinte in pixel art in codice (`Cards/ui/card_art_painter.gd`) ed esportate in `Cards/art/`
- **Menu principale** a mazzo di carte e **impostazioni** complete (`Menu/`, `Settings/`)
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
| Correre              | `Maiusc` (tenuto)         |
| Interagire / parlare | `E`                       |
| Avanti nei testi     | `Invio` / `Spazio` / `E` / click |
| Inventario           | `I` / `Tab`               |
| Scena: pesca         | `Spazio`                  |
| Scena: fermati       | `S`                       |
| Attaccare (prototipo)| `Spazio`                  |
| **Pausa**            | `Esc`                     |

Premendo `Esc` durante il gioco il mondo si ferma e compare il menu di pausa
(Riprendi, Salva, Opzioni, Torna al menu, Esci). Vedi [`Pause/README.md`](Pause/README.md).

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
4. Premi **F5** (o il pulsante ▶️ in alto a destra) per avviare il gioco. La scena principale è il menu (`Menu/main_menu.tscn`): **Storia → Nuova Partita** comincia nel camerino, nel mondo esplorabile; **Riprendi** ricarica l'ultimo salvataggio, nel punto esatto in cui eri.

> Il plugin **Dialogue Manager** è già incluso nella cartella `addons/` e abilitato in `project.godot`: non serve installarlo a parte.

## 📂 Struttura del progetto

```
mio-gioco-godot/
├── project.godot              # Configurazione del progetto (input, autoload, plugin)
├── World/                     # Il mondo esplorabile: mappe, regista, negozi, HUD (vedi World/README.md)
├── Story/                     # La storia: testi, boss, battaglia con le maschere
├── Cards/                     # Il motore delle carte: dati, battaglia, effetti, simulatore
├── Menu/                      # Menu principale a mazzo di carte (vedi Menu/README.md)
├── Pause/                     # Menu di pausa (Esc): vedi Pause/README.md
├── Save/                      # Salvataggio della partita: vedi Save/README.md
├── Settings/                  # Impostazioni, tema globale e accessibilità
├── Docs/                      # Documenti di design (trama, maschere, prompt per l'IA)
├── Scene/
│   ├── Main.tscn              # Campo da gioco: mappa, camera, player e NPC
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
    ├── dialogue_manager/      # Plugin Dialogue Manager (v4.1.0)
    └── card_editor/           # Editor delle carte dentro Godot
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
- [x] Motore delle carte con pesca casuale e simulatore
- [x] Menu principale e impostazioni
- [x] La storia: camerino, zone, bauli, cinque boss, finali, salvataggio
- [x] Le maschere (affinità, regola dell'azzardo, postura)
- [x] Illustrazioni delle carte in pixel art
- [ ] Il Segno: l'abilità passiva firmata di ogni maschera (sistema F2)
- [x] Un baule segreto (in graticcia); altri nelle zone già battute
- [x] Il mondo esplorabile: mappe, boss nel mondo, incontri, transizioni
- [x] Negozio (battute, maschere, oggetti) e moneta (Biglietti)
- [ ] Pacchetti di carte
- [x] Avviare il dialogo solo quando il player è vicino all'NPC (area di interazione)
- [x] Tasto di interazione dedicato (es. `E`), separato dall'attacco
- [ ] Hitbox della spada e interazione con i nemici
- [ ] Animali (galline, mucche) già presenti negli asset
- [x] Inventario e oggetti (tè, camomilla, fiori)
- [x] Menu di pausa (`Esc`) e salvataggio della partita

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
