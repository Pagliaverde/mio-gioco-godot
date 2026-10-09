# 🗺️ Il mondo esplorabile

> *Il teatro è tutto il mondo. Adesso ci si cammina dentro.*

**Fuori Copione** si gioca camminando: le zone della storia sono stanze vere
di un teatro, il protagonista senza volto ci si muove con le sue animazioni,
i boss si incontrano per strada e le scene a carte partono quando li affronti.
Il motore delle carte non è cambiato: è lo stesso tavolo di `Story/story_battle.gd`,
con un palco al centro.

**Per giocare:** menu principale → **Storia** → **Nuova Partita**
(o apri `World/overworld.tscn` e premi **F6**).

---

## 📑 Indice

1. [Comandi](#-comandi)
2. [Come si gioca](#-come-si-gioca)
3. [La mappa del teatro](#-la-mappa-del-teatro)
4. [Struttura dei file](#-struttura-dei-file)
5. [Come è fatta una mappa](#-come-è-fatta-una-mappa)
6. [Le componenti](#-le-componenti)
7. [Cambiare mappe, negozi, oggetti, comparse](#-cambiare-mappe-negozi-oggetti-comparse)
8. [La grafica](#-la-grafica)
9. [Salvataggio](#-salvataggio)
10. [Verificare senza giocare](#-verificare-senza-giocare)

---

## 🎮 Comandi

| Tasto | Cosa fa |
|---|---|
| `W` `A` `S` `D` / frecce | Muoversi (8 direzioni) |
| `Maiusc` (tenuto) | Correre |
| `E` | Interagire: parlare, aprire un baule, comprare, guardare |
| `Invio` / `Spazio` / `E` / click | Andare avanti nei testi |
| `I` / `Tab` | Inventario (oggetti, maschere, repertorio) |
| `Esc` | Pausa (Riprendi, Salva, Opzioni, Menu, Esci) |
| In scena: `Spazio` / `S` | Pesca / Fermati (come prima) |

Tutti i tasti si cambiano in *Opzioni → Comandi* (anche *Corri* e *Inventario*).

---

## 🎭 Come si gioca

- **Esplori.** Ogni zona ha un'entrata, qualcuno con cui parlare, casse di
  attrezzeria, a volte un negozio, e un boss davanti alla porta per la zona dopo.
- **I boss sono nel mondo.** Stanno dove li incontri, con la maschera che non
  si sono più tolti. Se entri nel loro sguardo compare un **"!"** e ti vengono
  incontro, come gli allenatori dei giochi di mostri; oppure gli parli tu (`E`).
  Poi: il cartello, la presentazione, **la scelta della maschera**, il lampo
  rosso e la scena a carte. Il palco al centro del tavolo mostra i due attori
  sotto i riflettori.
  - **Vinci:** prendi la sua maschera, sali di **Gavetta**, la vita torna piena,
    trovi dei **Biglietti**. Il boss si sposta e la porta si apre. Resta
    battuto per sempre (anche nel salvataggio).
  - **Perdi:** *"Il sipario si chiude e si riapre"*: **Riprova** subito (vita
    piena) o **Ritirati** (torni all'ingresso della zona e perdi un quinto dei
    biglietti).
- **Le quinte.** I tratti di pavimento pieni di ritagli, costumi e vernice
  (con la polvere che galleggia) sono l'erba alta: camminandoci si incontrano
  le **comparse** (macchie di vernice, manichini da prova, riflessi,
  controfigure, attrezzisti). Scene brevi, con la maschera che **indossi**
  (si sceglie dall'inventario), che danno biglietti e a volte un tè.
- **La vita resta tra una scena e l'altra.** Si recupera con il **letto del
  camerino**, il **barista del Ridotto**, gli oggetti, o salendo di Gavetta.
- **I Bauli di Scena** danno una maschera base a caso tra quelle che non hai
  (come nella storia). Uno è segreto, in graticcia.
- **I negozi** vendono battute (entrano nel repertorio, nel rispetto del
  limite di copie per rarità), le maschere dei Bauli e oggetti.
- **La platea.** Da alcuni punti si guarda il pubblico. C'è un manichino che a
  ogni visita è in un posto diverso. Nessuno te lo dice: lo vedi.
- **Il finale.** Dietro L'Ultimo c'è la porta EXIT: è dipinta. L'uscita è in
  fondo alla platea. Attraversi le file; all'ultima, **i manichini si girano
  tutti insieme**. Poi scegli come finire.

### Gli oggetti

| Oggetto | Prezzo | Effetto |
|---|---|---|
| Tè caldo | 60 | +150 vita |
| Camomilla del suggeritore | 180 | Vita piena |
| Mazzo di fiori | 90 | La prossima scena cominci con 80 di Favore |

---

## 🗺 La mappa del teatro

```
                      SARTORIA (Spaccio)
                            │
 CAMERINO ── PIAZZA ── GALLERIA ── PALCO ── CORRIDOI ── AUDITORIUM ── FONDO
  (letto)    │ Boss I   │ Boss II   │ Boss III  Boss IV    Boss V     (finale)
           RIDOTTO    MAGAZZINO  GRATICCIA
        (bar, Biglietteria)       (baule segreto)
```

| Mappa | Cosa c'è |
|---|---|
| **Il Camerino** | Il letto (cura), lo specchio rotto, il numero sul muro, il primo Baule di Scena |
| **La Piazza Dipinta** | Facciate su cavalletti, lampioni, la Baracca del Burattinaio, le quinte, la platea, **La Comparsa** |
| **Il Ridotto** | Il barista (cura), la Biglietteria (negozio), una spettatrice che ha perso il posto |
| **La Galleria degli Specchi** | Pilastri di specchi, un riflesso gentile, la platea, **Il Sostituto** |
| **Il Magazzino delle Scene** | Casse e fondali, tante quinte, tre casse di attrezzeria |
| **Il Palco** | Il primo vero pubblico, il Suggeritore, riflettori, **La Prima Attrice** |
| **La Graticcia** | Passerelle sopra il palco, il Tecnico delle Luci, un Baule di Scena segreto |
| **I Corridoi** | Linoleum verde, le porte dei camerini degli altri, la gabbia, **Il Carceriere** |
| **La Sartoria** | Costumi appesi, manichini da sarto, lo Spaccio del Personale |
| **L'Auditorium** | Le file di manichini, il corridoio centrale, **L'Ultimo** |
| **Il Fondo** | La porta EXIT dipinta, l'ultima fila, la porta vera |

---

## 📂 Struttura dei file

```
World/
├── README.md             ← questa guida
├── game_state.gd         ★ GameState (autoload): mappa, posizione, maschere, boss, bauli,
│                           biglietti, vita, oggetti, repertorio. Partecipa al salvataggio
├── scene_transition.gd   Transition (autoload): dissolvenze e lampo + sipario prima delle scene
├── world_data.gd         ★ WorldData: mappe, stanze laterali, oggetti, negozi, comparse, prezzi
├── overworld.tscn/.gd    ★ Overworld: la scena di gioco (mappa corrente, giocatore, HUD, livelli UI)
├── world_director.gd     ★ WorldDirector: cosa succede (zone, boss, bauli, negozi, incontri, finale)
├── game_map.gd           GameMap: base di ogni mappa (palette, polvere, punti d'arrivo, limiti)
├── components/           I pezzi delle mappe (vedi sotto)
├── ui/                   Riquadro dei testi, HUD, negozio, inventario, scelta maschera, palco
├── maps/*.tscn           Le undici mappe (scene normali, si modificano nell'editor)
├── art/                  Mattonelle e oggetti dipinti in codice, TileSet
└── tools/
    ├── map_layouts.gd     Le mappe disegnate a lettere
    ├── build_maps.tscn    Costruisce le mappe dalle lettere
    ├── paint_world_art.gd Dipinge mattonelle e oggetti
    ├── check_world.tscn   Gioca tutto il mondo senza finestra
    └── screenshot_world.tscn  Fotografa mappe e momenti di gioco
```

**Chi parla con chi:** le componenti delle mappe chiamano `Overworld.instance.director`;
il regista usa `GameState` per i numeri e `StoryBattle` per le scene. Nessuna
componente conosce le altre.

---

## 🧱 Come è fatta una mappa

```
Mappa (GameMap)
├── Pavimento   TileMapLayer, solo grafica (z −10)
├── Muri        TileMapLayer, con collisione sul livello "mondo"
└── Entita      Node2D con Y-sort: oggetti, bauli, boss, porte… e il giocatore
```

**I livelli di fisica** (nominati in *Progetto → Impostazioni → Livelli*):

| Livello | Nome | Chi ci sta |
|---|---|---|
| 1 | mondo | muri (TileSet), oggetti di scena, bauli |
| 2 | interazioni | le aree `Interactable` (separate dalla collisione) |
| 3 | giocatore | il `Player` (maschera: mondo + personaggi) |
| 4 | personaggi | boss, abitanti, manichini |

**Collisione ai piedi:** ogni oggetto ha l'origine alla base e un rettangolo
solo dove tocca il pavimento. Si passa *dietro* a un lampione, non *attraverso*.

---

## 🧩 Le componenti

| Componente | Cos'è |
|---|---|
| `Interactable` | Area che risponde a `E`, con il fumetto. Separata dalla collisione |
| `WorldProp` (`@tool`) | Oggetto di scena: scegli `kind` nell'Ispettore, si costruisce sprite + ingombro + luce |
| `WorldCharacter` | Base dei personaggi: sprite (protagonista colorato, manichino, NPC), maschera dipinta, `walk_to`, `emote` |
| `WorldBoss` | Un boss: `boss_id`, sguardo (`sight_tiles`), dove si sposta battuto (`defeated_offset`) |
| `WorldNpc` | Un abitante: `lines` semplici o un file `.dialogue`; può curare e passeggiare |
| `StageChest` | Baule di Scena (`scena`: maschera) o cassa (`cassa`: biglietti, oggetto, battuta) |
| `ShopStall` | Un negozio: bancone + negoziante + `shop_id` |
| `Warp` | Porta verso un'altra mappa; con `requires_boss` resta chiusa finché il boss non è battuto |
| `WorldSpawn` | Punto d'arrivo (ogni mappa ha almeno `ingresso`) |
| `EncounterZone` | Le quinte: incontri a ogni passo con probabilità `chance` |
| `WorldAudience` | La platea: file di manichini, il manichino che si sposta, `turn_all()` |
| `StoryTrigger` | Un punto scritto: `platea`, `testo`, `porta_dipinta`, `ultima_fila` |
| `InspectPoint` | Qualcosa da guardare (lo specchio, il numero sul muro, il letto) |

Lo slime del prototipo (`Scene/Player/SlimeNpc.tscn`) è in piazza, con il suo
dialogo di Dialogue Manager.

---

## ✏️ Cambiare mappe, negozi, oggetti, comparse

| Vuoi cambiare… | Dove |
|---|---|
| Una mappa (a mano) | Apri `World/maps/<nome>.tscn` nell'editor: dipingi sul TileMapLayer `Muri`/`Pavimento`, sposta gli oggetti |
| Una mappa (dal disegno) | `World/tools/map_layouts.gd`, poi `godot --headless --path . res://World/tools/build_maps.tscn -- <nome>` ⚠️ riscrive la mappa |
| Un prezzo, un oggetto, un negozio | `world_data.gd`: `items()`, `shops()`, `card_price()`, `MASK_PRICE` |
| Chi si incontra nelle quinte | `world_data.gd`: `extras()`, `encounter_table()` |
| Quanto spesso | `EncounterZone.chance` (nell'Ispettore, o in `build_maps.gd`) |
| I testi delle zone e dei boss | `Story/story_data.gd` (sono gli stessi della storia) |
| Le stanze laterali | `world_data.gd`: `side_rooms()` |
| Un oggetto di scena nuovo | Una riga in `WorldProp.library()` |

---

## 🎨 La grafica

- **Mattonelle** (`art/theatre_tiles.png`, 32×32) e **oggetti** (`art/theatre_props.png`)
  sono dipinti in codice da `tools/paint_world_art.gd`, come le illustrazioni
  delle carte: assi viola, velluto, palco, linoleum, marmo, lastricato dipinto,
  sipario, specchi, cielo di tela, sbarre, poltrone; facciate viste di fronte su
  cavalletto, baracca del burattinaio, lampioni, Baule di Scena, specchio da
  camerino, riflettore, quinta, leggio, locandina, cassa, porta EXIT.
- **Stesso tileset, palette diverse**: ogni mappa ha un `CanvasModulate`
  (`GameMap.ambient`), come chiede il documento di design. Le luci
  (`PointLight2D`) dei lampioni, dei riflettori e dei bauli ci bucano dentro.
- **Personaggi**: il protagonista è il set MC2; i boss sono **lo stesso
  corpo senza volto**, di un altro colore, con la loro maschera dipinta da
  `MaskCard.paint_face()`; i manichini sono il set Manichino; gli abitanti lo
  spritesheet NPC.
- **Mobili**: dal pacchetto `Asset/Sprite/Object/Basic Furniture.png`.

---

## 💾 Salvataggio

`GameState` non è dentro la scena, e `SaveGame` raccoglie solo i nodi della
scena: per questo `Overworld` ha un nodo figlio **`Progresso`** nel gruppo
`save_state` (lo stesso schema della storia). Salva mappa, posizione,
direzione, gavetta, maschere (e quella indossata), vita, biglietti, oggetti,
battute comprate e messe da parte, boss battuti, bauli aperti, eventi visti,
visite alla platea.

- **Salva** nel menu di pausa salva lì dove sei.
- Con *Salvataggio automatico* attivo (Opzioni → Gioco) si salva a ogni cambio
  di stanza; si salva sempre dopo un boss, un baule, un negozio.
- **Riprendi** riporta nella mappa, nel punto esatto.
- Al finale il salvataggio viene cancellato; il numero sul muro e i finali
  visti restano in `user://story.cfg` (`StorySave`).

---

## 🧪 Verificare senza giocare

```bash
# Gioca tutto il mondo: porte, muri, bauli, negozio, incontro, cinque boss,
# salvataggio e ripresa, stanze laterali, finale. Esce con 1 se qualcosa non va.
godot --headless --path . res://World/tools/check_world.tscn

# Ricostruisce le mappe dal disegno a lettere (⚠️ riscrive World/maps/)
godot --headless --path . res://World/tools/build_maps.tscn

# Ridipinge mattonelle e oggetti (poi: godot --headless --path . --import)
godot --headless --path . --script res://World/tools/paint_world_art.gd

# Foto delle mappe e dei momenti di gioco in user://screenshots/world/
# (serve una finestra, anche virtuale; il progetto parte minimizzato,
#  quindi per xvfb serve un override.cfg con [display] window/size/mode=0)
xvfb-run -a godot --path . --rendering-driver opengl3 res://World/tools/screenshot_world.tscn
```
