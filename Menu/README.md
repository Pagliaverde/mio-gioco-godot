# Menu principale

Il menu principale del gioco: le voci **sono carte**, disposte a ventaglio.
Quella selezionata sta al centro e in primo piano; premi la freccia e il mazzo
scorre, con la carta nuova che si sfila fuori come quando apri un pacchetto.

Tutto e' costruito **in codice**, non in un file `.tscn` pieno di nodi. Cosi'
non si puo' rompere per un errore di formattazione, e tutte le cose che puoi
regolare stanno in un posto solo: l'inspector del nodo `MainMenu`.

## File

| File | Cosa e' |
|---|---|
| `Menu/main_menu.tscn` | La scena da aprire e premere F6 |
| `Menu/main_menu.gd` | Il menu: ventaglio, titolo, input, conferma |
| `Menu/menu_entry_card.gd` | **Una voce di menu a forma di carta** (il ventaglio) |
| `Menu/menu_action.gd` | Una voce di menu come dato |
| `Menu/menu_card.gd` | La carta dello sfondo animato (facoltativo) |
| `Menu/menu_card_backdrop.gd` | Fa scorrere quello sfondo animato (facoltativo) |

---

## Indice

1. [Da dove iniziare](#da-dove-iniziare)
2. [Com'e' fatto](#com-e-fatto)
3. [Provarlo](#provarlo)
4. [Mettere le immagini sulle carte](#mettere-le-immagini-sulle-carte)
5. [Regolare il ventaglio](#regolare-il-ventaglio)
6. [Aggiungere e togliere voci](#aggiungere-e-togliere-voci)
7. [Collegare una voce a una schermata](#collegare-una-voce-a-una-schermata)
8. [Gestire le voci dal codice](#gestire-le-voci-dal-codice)
9. [Metterlo come schermata iniziale](#metterlo-come-schermata-iniziale)
10. [Riferimento dei parametri](#riferimento-dei-parametri)
11. [Risoluzione problemi](#risoluzione-problemi)

---

## Da dove iniziare

Apri `res://Menu/main_menu.tscn` e premi **F6**.

Vedrai le carte uscire dal mazzo una per una, sistemarsi a ventaglio, e la voce
"Storia" al centro. Con le frecce il ventaglio scorre.

Siccome non hai ancora messo le immagini, ogni carta mostra la lettera iniziale
del titolo su un fondo del colore della voce. Funziona lo stesso: serve a
vedere la struttura. Per mettere le tue immagini salta a
[Mettere le immagini sulle carte](#mettere-le-immagini-sulle-carte): e' una
cosa sola da fare, un campo per voce.

---

## Com'e' fatto

```
MainMenu (Control)
├── ColorRect                    fondo pieno
├── TextureRect "sheen"          gradiente verticale appena accennato
├── MenuCardBackdrop             sfondo animato (spento di default)
├── Control  _card_layer         dove vivono le carte del menu
│   └── MenuEntryCard × 6        una carta per voce   ← menu_entry_card.gd
├── Label  titolo
├── Label  sottotitolo
├── Label  descrizione           descrizione della voce al centro
├── Label  "3 / 6"               dove sei nel mazzo
├── Label  aiuto
├── Label  piede (in basso a sinistra)
├── Label  toast                 messaggi temporanei
└── Control  pannello di conferma (nascosto)
```

### Il ventaglio

Il cuore del menu sta in una funzione sola, `_target_for()` in `main_menu.gd`.
Riceve un numero — quanto una carta dista dal centro — e restituisce dove
metterla e come.

Da quel numero solo derivano **cinque cose insieme**:

| Distanza dal centro | Dimensione | Rotazione | Altezza | Opacita' |
|---|---|---|---|---|
| 0 (selezionata) | 100% | 0° | piu' su | piena |
| 1 | 86% | 8° | un po' piu' giu' | -16% |
| 2 | 74% | 12,5° | piu' giu' | -32% |
| 3 | 64% | 17° | ancora piu' giu' | -48% |

E' questo che fa sembrare le carte un mazzo steso sul tavolo invece di una fila
di riquadri. Se avessero tutte la stessa dimensione e la stessa rotazione,
sarebbe un elenco puntato.

### L'animazione

Quando premi la freccia, ogni carta viene spostata con un `Tween`. Due dettagli
fanno la differenza:

- **`TRANS_BACK`**: la carta "sfora" un po' oltre la sua posizione e poi torna
  indietro. E' l'esitazione di una carta che esce dal mazzo. Si spegne con
  **Slide Overshoot** = `false`.
- **Il bordo si accende con 0,05 s di ritardo** rispetto alla carta: sembra che
  la carta si "apra" quando si ferma davanti a te.

L'accensione usa `tween_method(card.apply_accent, ...)`, cioe' una funzione che
riceve un numero da 0 a 1. Quel solo numero controlla bordo, spessore del bordo,
ombra, fascia del titolo e colore del testo. Cosi' l'aspetto di una carta
dipende sempre e solo da quel numero, e non ci sono due pezzi di codice che
litigano sugli stessi colori.

### L'ingresso a mazzo

All'avvio le carte partono tutte impilate fuori a destra, ruotate di -24° e
invisibili: e' il "mazzo chiuso". Da li' escono una per una, con un ritardo di
**Deal Stagger** fra l'una e l'altra (`_play_intro()` in `main_menu.gd`).

L'ordine e' per distanza dal centro: prima la carta che finira' al centro, poi
le vicine, poi le lontane. La selezione arriva per prima e le altre le si
mettono intorno.

### Perche' la UI e' in codice e non nell'editor

Un `.tscn` scritto a mano e' fragile: basta un campo sbagliato e la scena non
si apre. In codice, invece, i valori regolabili diventano parametri
nell'inspector, con il nome giusto e i limiti giusti (`@export_range`). Quindi
non perdi flessibilita': hai solo un posto diverso dove guardare.

### Perche' le carte non stanno in un contenitore

`_card_layer` e' un `Control` vuoto, non un `HBoxContainer`. Sembra una
complicazione, ma un contenitore **rimette in fila** i figli: annullerebbe
rotazione, scala e sovrapposizione, cioe' tutto il ventaglio. Le posizioni le
calcola il menu, una per una.

L'ordine di disegno lo sistema `_reorder_cards()`: le carte lontane prima,
quella selezionata per ultima. Cosi' la selezione sta sempre sopra alle altre.

---

## Provarlo

| Tasto | Cosa fa |
|---|---|
| `←` `→` | Scorre le carte |
| `↑` `↓` | Scorre le carte (identico, per comodita') |
| `A` `D` `W` `S` | Come le frecce |
| `Invio` / `Spazio` | Sceglie la carta al centro |
| Rotella del mouse | Scorre le carte |
| `Esc` | Porta la selezione su "Esci" e chiede conferma |

Con il mouse puoi anche cliccare una carta laterale: viene portata al centro.
Cliccare la carta **gia' al centro** equivale a sceglierla, come `Invio`.

La carta al centro e' l'unica senza rotazione, la piu' grande e con il bordo
acceso: e' sempre chiaro dove sei senza dover leggere niente.

---

## Mettere le immagini sulle carte

**Una strada sola, ed e' compilare un campo.**

Le immagini del menu non sono le carte del gioco: il menu non mostra le
`CardData`, mostra le sue voci. Quindi l'illustrazione va messa **sulla voce**,
non sulla carta del gioco.

1. Apri `res://Menu/main_menu.tscn`.
2. Seleziona il nodo **MainMenu**.
3. Nel gruppo **Voci di menu**, apri **Actions** e clicca su un elemento.
4. Nell'inspector dell'elemento, gruppo **Carta**, trascina l'immagine nel
   campo **Art**.
5. **Ctrl+S** e riapri il menu con **F6**.

Fatto: la carta di quella voce mostra la tua illustrazione, con il titolo nella
fascia chiara in basso.

> **Se le voci di default non compaiono in Actions** e' normale: finche' l'array
> **Actions** e' vuoto il menu usa `build_default_actions()`. Per modificare una
> voce di default devi prima ricrearla nell'array: vedi
> [Aggiungere e togliere voci](#aggiungere-e-togliere-voci).

### La stessa immagine su tutte le voci

Se non hai ancora le illustrazioni, assegna la stessa immagine a tutte le voci
compilando **Art** su ognuna. Le carte si distinguono lo stesso, perche' sopra
l'immagine il menu mette un **velo del colore della voce**: la stessa figura
sulla carta rossa e su quella blu appare diversa.

### Come scegliere il colore di una carta

Ogni voce ha il campo **Accent** (gruppo "Carta").

- **Lascialo com'e'** (alpha a 0): il menu prende il colore dalla tavolozza di
  `MenuEntryCard.palette_color()`, uno diverso per ogni voce. Ambra, azzurro,
  verde, viola, rosso, giallo, turchese, rosa.
- **Compilalo**: quella voce usa il tuo colore per bordo, fascia del titolo,
  ombra e velo sull'immagine.

### Come si adatta l'immagine

L'immagine riempie tutto lo spazio sopra la fascia del titolo, con
`STRETCH_KEEP_ASPECT_COVERED`: **non si deforma**, ma se ha proporzioni molto
diverse da quelle della carta (300x420, cioe' circa 5:7) viene tagliata ai
lati. Per un risultato pulito usa immagini verticali, con il soggetto al
centro.

---

## Regolare il ventaglio

Tutti questi parametri sono sul nodo **MainMenu**, gruppo **Carte**.

| Parametro | Cosa cambia | Default |
|---|---|---|
| **Card Size** | Dimensione di una carta | `300×420` |
| **Card Spacing** | Distanza fra i centri di due carte | `196` |
| **Visible Side** | Quante carte tenere visibili per lato | `3` |
| **Neighbour Scale** | Quanto rimpicciolisce ogni passo verso il lato | `0.86` |
| **Neighbour Fade** | Quanto sbiadisce ogni passo verso il lato | `0.16` |
| **Fan Rotation** | Rotazione in gradi della prima carta di lato | `8` |
| **Wrap Around** | Se la freccia riparte dall'inizio dopo l'ultima voce | `true` |

Nel gruppo **Animazione**:

| Parametro | Cosa cambia | Default |
|---|---|---|
| **Slide Duration** | Durata dello scorrimento, in secondi | `0.45` |
| **Slide Overshoot** | La carta sfora e poi torna indietro | `true` |
| **Deal Duration** | Durata dell'ingresso di una carta | `0.6` |
| **Deal Stagger** | Ritardo fra una carta e la successiva all'avvio | `0.07` |
| **Carousel Center Ratio** | Altezza del centro del ventaglio (0.5 = meta') | `0.47` |

### Ricette veloci

**"Le carte si sovrappongono troppo / non abbastanza."**
Alza **Card Spacing** per separarle, abbassalo per farle accavallare di piu'.
Se lo porti sopra la larghezza della carta non si toccano piu': diventa un
elenco e perde il senso di mazzo.

**"Il ventaglio e' troppo piatto."**
Alza **Fan Rotation** a 12-14 e abbassa **Neighbour Scale** a 0.80.

**"Voglio vedere piu' carte."**
Alza **Visible Side** a 4-5 e abbassa **Card Size** a `220×310`.

**"La carta nuova esce dal mazzo troppo in fretta."**
Alza **Slide Duration** a 0.6-0.7.

**"Non mi piace quel rimbalzo alla fine."**
Metti **Slide Overshoot** a `false`: il movimento diventa lineare e sobrio.

**"Le carte ci mettono troppo a entrare all'avvio."**
Abbassa **Deal Stagger** a `0.03`, oppure **Deal Duration** a `0.4`.

**"Le carte sono troppo in alto / troppo in basso."**
Muovi **Carousel Center Ratio**: `0.42` le alza, `0.52` le abbassa.

**"Non voglio il giro completo."**
Metti **Wrap Around** a `false`: a un estremo la freccia si ferma.

### Lo sfondo animato (facoltativo)

Nella cartella c'e' anche `menu_card_backdrop.gd`, quello che fa scorrere le
vere carte del gioco da destra a sinistra. Era l'idea sbagliata: il menu ora
funziona benissimo senza. Ma se ti piace l'idea di un fondo di carte dietro al
ventaglio, accendilo con **Ambient Cards** = `true` sul nodo **MainMenu**,
oppure selezionalo direttamente. I suoi parametri sono tutti sul nodo
`MenuCardBackdrop`.

---

## Aggiungere e togliere voci

Le voci di default sono definite in `main_menu.gd`, nella funzione
`build_default_actions()`:

| Voce | Porta a |
|---|---|
| Storia | `res://Scene/Main.tscn` (il gioco) |
| Il tuo deck | — non pronto — |
| Negozio | — non pronto — |
| Opzioni | — non pronto — |
| Prova una battaglia | `res://Cards/table/play_table.tscn` |
| Esci | chiude il gioco (con conferma) |

### Cambiare le voci dall'inspector (senza toccare il codice)

1. Seleziona il nodo **MainMenu**.
2. Nel gruppo **Voci di menu**, apri **Actions** e clicca **Add Element**.
3. Seleziona il nuovo elemento e premi **New MenuAction**.
4. Compila i suoi campi (vedi sotto).

> Attenzione: appena metti **anche una sola** voce in **Actions**, le voci di
> default vengono **ignorate del tutto**. Quindi se vuoi partire da quelle e
> cambiarne una, ricreale tutte.

### I campi di una voce

| Campo | Gruppo | Cosa fa |
|---|---|---|
| **Id** | — | Identificativo usato dal codice, es. `&"deck"` |
| **Label** | — | Il testo scritto sulla carta, in grande |
| **Description** | — | La riga sotto il ventaglio quando la voce e' al centro |
| **Enabled** | — | Se `false` la carta appare grigia e non si puo' scegliere |
| **Scene Path** | — | La scena da caricare quando scegli la voce |
| **Needs Confirmation** | — | Se `true` chiede "sei sicuro?" prima di eseguire |
| **Art** | Carta | L'illustrazione sulla carta |
| **Accent** | Carta | Il colore della carta. Alpha 0 = colore automatico |

> **Perche' `Enabled` e' utile:** puoi lasciare in elenco le voci che non hai
> ancora fatto, spente. Il giocatore le vede cosi' sai cosa manca, ma non puo'
> sceglierle e non si rompe niente.

---

## Collegare una voce a una schermata

Il modo piu' semplice: compila **Scene Path** con il percorso della scena.

Quando scegli la voce, il menu:

1. controlla che il file esista davvero (`ResourceLoader.exists`)
2. se esiste, fa `get_tree().change_scene_to_file()`
3. se **non** esiste, mostra un messaggio e scrive un avviso in console

Quel controllo ti evita l'errore classico: scena cancellata o rinominata, menu
che smette di funzionare senza spiegare perche'.

---

## Gestire le voci dal codice

Se preferisci fare tutto in codice, non compilare **Scene Path**. Il menu
emettera' un segnale con l'id della voce.

```gdscript
extends Control  # ... oppure lo script del tuo menu

@onready var menu: Control = $MainMenu  # o come lo chiami

func _ready() -> void:
    menu.action_selected.connect(_on_menu_action)
    menu.quit_requested.connect(_on_quit_requested)

func _on_menu_action(action_id: StringName) -> void:
    match action_id:
        &"deck":
            # apri la schermata del mazzo
            pass
        &"shop":
            # apri il negozio
            pass

func _on_quit_requested() -> void:
    # salva le impostazioni prima di uscire
    pass
```

### Segnali disponibili

| Segnale | Quando scatta |
|---|---|
| `action_selected(action_id)` | Il giocatore sceglie una voce senza scena e senza gestione interna |
| `quit_requested()` | Il giocatore conferma "Esci", **prima** che il gioco si chiuda |

`quit_requested` e' utile per salvare: scatta un istante prima di
`get_tree().quit()`, quindi hai il tempo di scrivere le impostazioni su disco.

---

## Metterlo come schermata iniziale

Il gioco adesso parte da `res://Scene/Main.tscn`. Se vuoi che parta dal menu:

1. Apri **Progetto → Impostazioni progetto → Generale**.
2. Cerca `Application / Run / Main Scene`.
3. Trascina `res://Menu/main_menu.tscn` nel campo.

La voce **Storia** del menu punta gia' a `Scene/Main.tscn`, quindi il cerchio
si chiude: menu → storia → gioco.

> Non l'ho fatto al posto tuo di proposito: cambiare la scena iniziale cambia
> come si avvia il progetto, e volevo che fosse una tua scelta.

---

## Riferimento dei parametri

### `MainMenu` (nodo radice)

**Testi**

| Parametro | Descrizione | Default |
|---|---|---|
| **Title** | Titolo grande. Vuoto = nome del progetto, in maiuscolo | vuoto |
| **Subtitle** | Riga sotto il titolo | "Un card game a turni" |
| **Hint** | Riga di aiuto in fondo. Vuoto = quella di default | vuoto |
| **Footer** | Riga in basso a sinistra. Vuoto = versione di Godot | vuoto |

**Voci di menu**

| Parametro | Descrizione | Default |
|---|---|---|
| **Actions** | Le voci. Vuoto = usa quelle di default | vuoto |
| **Show Placeholder Message** | Avvisa se la voce non e' pronta | `true` |

**Carte**

| Parametro | Descrizione | Default |
|---|---|---|
| **Card Size** | Dimensione di una carta | `300×420` |
| **Card Spacing** | Distanza fra i centri di due carte vicine | `196` |
| **Visible Side** | Quante carte tenere visibili per lato | `3` |
| **Neighbour Scale** | Rimpicciolimento per ogni passo verso il lato | `0.86` |
| **Neighbour Fade** | Dissolvenza per ogni passo verso il lato | `0.16` |
| **Fan Rotation** | Rotazione in gradi della prima carta di lato | `8` |
| **Wrap Around** | Se la freccia riparte dall'inizio dopo l'ultima voce | `true` |

**Animazione**

| Parametro | Descrizione | Default |
|---|---|---|
| **Slide Duration** | Durata dello scorrimento, in secondi | `0.45` |
| **Slide Overshoot** | Se true la carta sfora e poi torna indietro | `true` |
| **Deal Duration** | Durata dell'ingresso di una carta | `0.6` |
| **Deal Stagger** | Ritardo fra una carta e la successiva all'avvio | `0.07` |
| **Carousel Center Ratio** | Altezza del centro del ventaglio | `0.47` |

**Aspetto**

| Parametro | Descrizione | Default |
|---|---|---|
| **Title Size** | Dimensione del titolo | `68` |
| **Card Title Size** | Dimensione del testo scritto sulle carte | `32` |
| **Accent Color** | Colore del bordo del pannello di conferma | ambra |
| **Background Color** | Colore di fondo dello schermo | antracite |
| **Ambient Cards** | Accende lo sfondo animato dietro al ventaglio | `false` |

### Segnali

| Segnale | Quando scatta |
|---|---|
| `action_selected(action_id)` | Il giocatore sceglie una voce senza scena e senza gestione interna |
| `quit_requested()` | Il giocatore conferma "Esci", **prima** che il gioco si chiuda |

### `MenuEntryCard` (la carta)

| Nome | Descrizione |
|---|---|
| `MenuEntryCard.palette_color(i)` | Il colore della tavolozza in posizione `i` |
| `apply_accent(mix)` | Accende la carta: `0` spenta, `1` selezionata |
| `shake()` | Fa oscillare la carta (risposta "no") |

### `MenuAction` (la voce)

| Nome | Descrizione |
|---|---|
| `MenuAction.of(id, label, descrizione, scena)` | Costruisce una voce da codice |
| `has_scene()` | True se la voce porta a una schermata |
| `has_art()` | True se la voce ha un'illustrazione |
| `has_custom_accent()` | True se la voce ha un colore suo |

### `MenuCardBackdrop` (lo sfondo facoltativo)

Vedi i suoi parametri nell'inspector selezionandolo. `rebuild()` lo rigenera
se cambi i valori a runtime; per il resto scorre da solo.

---

## Risoluzione problemi

### Le carte sono tutte ammassate in un angolo

La dimensione della finestra non era ancora pronta quando il menu ha provato a
posizionarle. Non dovrebbe succedere: `_play_intro()` ci riprova da solo
finche' non ha una dimensione valida. Se persiste, controlla che il nodo
**MainMenu** sia un `Control` con gli anchor a tutto schermo.

### Le carte non si sovrappongono, sono in fila

**Card Spacing** e' piu' grande di **Card Size**: le carte non si toccano piu' e
il ventaglio diventa un elenco. Abbassa **Card Spacing** sotto la larghezza
della carta (con `300` di larghezza, un valore fra `150` e `220`).

### La carta al centro finisce dietro alle altre

Non dovrebbe succedere: `_reorder_cards()` rimette le carte nell'albero
dall'ordine giusto ad ogni scorrimento. Se hai modificato il menu, controlla di
non aver tolto quella chiamata da `_layout_cards()`.

### I click non funzionano / il menu non risponde

Le carte usano `MOUSE_FILTER_STOP` apposta, per ricevere i click. Il nodo
**MainMenu** invece e' a `IGNORE`, cosi' la rotella del mouse funziona anche
fuori dalle carte. Se aggiungi altri nodi sopra al ventaglio, mettili a
`IGNORE` anche loro, altrimenti si mangiano i click.

### La rotella del mouse non scorre le carte

La rotella e' gestita in `_input()` e non in `_unhandled_input()` per un motivo
preciso: le carte consumano gli eventi del mouse (`MOUSE_FILTER_STOP`), quindi
un evento rotella sopra una carta non arriverebbe mai a `_unhandled_input`.
Se hai spostato quel codice, rimettilo in `_input()`.

### Le carte sono troppo piatte / troppo strette

- Troppo piatte: alza **Fan Rotation** e abbassa **Neighbour Scale**.
- Troppo strette: alza **Card Spacing** o **Visible Side**.

### Il titolo o la descrizione finiscono sopra le carte

Sono posizionati in proporzione all'altezza dello schermo (`_layout_ui()`). Se
ingrandisci molto **Card Size**, la descrizione sotto il ventaglio resta al suo
posto e le carte la coprono. In quel caso alza **Carousel Center Ratio** un po'
verso l'alto, oppure abbassa **Card Size**.

### Con poche voci il ventaglio sembra strano

Con 2 o 3 voci il giro completo (`Wrap Around`) non entra in gioco: il menu
disattiva da solo il calcolo della "strada piu' corta" sotto le 3 carte. Con
una voce sola il ventaglio non ha senso e le frecce non fanno niente. E'
previsto: con una sola voce non c'e' niente da scorrere.

### Una carta non si accende mentre le altre si

Una voce **disabilitata** (`Enabled` = `false`) non si accende e resta grigia:
e' voluto, serve a far vedere cosa manca senza farlo scegliere. Se vuoi che si
possa scegliere, rimetti la spunta.

### "Scena non trovata: ..."

Il **Scene Path** di una voce punta a un file che non esiste. Il messaggio
mostra il percorso esatto: copialo e verificalo nel pannello File. Il menu
controlla con `ResourceLoader.exists()` prima di caricare, quindi non si rompe:
ti avvisa e basta.

### Una voce non fa niente e compare un messaggio

Vuol dire che la voce non ha **Scene Path** e non e' gestita internamente.
E' il comportamento previsto per le voci non ancora pronte: la carta al centro
oscilla e compare il messaggio. Vedi
[Gestire le voci dal codice](#gestire-le-voci-dal-codice).

### Ho messo la spunta a "Ambient Cards" e ora vedo due mazzi di carte

E' voluto: il ventaglio del menu piu' lo sfondo animato dietro. Se ti sembra
troppo carico, rimetti **Ambient Cards** a `false`, oppure abbassa la
trasparenza del backdrop (è il campo `modulate` del nodo `MenuCardBackdrop`,
impostato a `0.55` nel codice).

### Errore di parsing su `for ... in [...]` con un enum

Se aggiungi codice con `for x: MioEnum in [...]` o `var a: Array[MioEnum]`,
Godot da' errore. Usa il tipo `Variant` nel loop e converti dentro:

```gdscript
# ERRORE
# for element: CardTypes.Element in [CardTypes.Element.FIRE, ...]:

# CORRETTO
for raw: Variant in [CardTypes.Element.FIRE, CardTypes.Element.ICE]:
    var element: CardTypes.Element = raw
    # ...
```

E' un limite di GDScript, non un tuo errore. Nel progetto ci sono casi di
questo tipo: cerca `raw: Variant` per vedere il pattern.

### Un'immagine appare tagliata ai lati

E' `STRETCH_KEEP_ASPECT_COVERED`: l'immagine riempie tutto lo spazio senza
deformarsi, quindi se il rapporto e' diverso da quello della carta (circa 5:7)
viene ritagliata. Usa immagini verticali, oppure ingrandisci la carta in modo
che il rapporto si avvicini a quello delle tue immagini.
