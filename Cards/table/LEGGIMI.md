# 🎮 Costruire il tavolo di battaglia

Come si divide il lavoro:

| Chi | Cosa |
|---|---|
| **Tu** | La **scena** in Godot: layout, colori, grafica, posizioni |
| **Lo script** (`battle_table.gd`) | Tutta la logica: turni, IA, carte, barre, log |

Non devi scrivere codice. Devi solo creare nodi **con il nome giusto**.

---

## La regola d'oro: i nomi unici

Lo script trova i nodi per **nome unico**. Per assegnarlo:

> Seleziona il nodo nel pannello **Scena** → tasto destro → **Accesso come nome univoco**
> *(Access as Unique Name)* → compare un **`%`** accanto al nome.

Il nome deve essere **esatto** (maiuscole comprese). Fatto questo, il nodo è collegato.

---

## Passo 1 — La scena minima (5 minuti)

Parti da qui: con questi pochi nodi **il gioco è già giocabile**.

```
BattleTable (Control)          ← aggancia battle_table.gd
├── PlayerHealth (ProgressBar)     ← %PlayerHealth
├── EnemyHealth (ProgressBar)      ← %EnemyHealth
├── PlayerPlayed (HBoxContainer)   ← %PlayerPlayed
├── EnemyPlayed (HBoxContainer)    ← %EnemyPlayed
├── RiskLabel (Label)              ← %RiskLabel
├── DrawButton (Button)            ← %DrawButton      testo: "PESCA"
├── StopButton (Button)            ← %StopButton      testo: "STOP"
└── LogLabel (RichTextLabel)       ← %LogLabel        bbcode attivo
```

Poi: **F6**. Se vedi i pulsanti, stai giocando.

> All'avvio lo script stampa in **Output** la lista dei nodi che non trova.
> È la tua checklist: aggiungi quelli che vuoi e si attivano da soli.

---

## Passo 2 — Tutti i nodi riconosciuti

Aggiungili quando vuoi, in qualsiasi ordine. Ognuno attiva una parte della UI.

### Generale

| Nome | Tipo | Cosa mostra |
|---|---|---|
| `TurnLabel` | `Label` | "Turno 12 · tocca a te" / esito finale |
| `NewGameButton` | `Button` | ricomincia (testo: "Nuova partita") |
| `ResultOverlay` | `Control` | pannello che appare a fine partita |
| `ResultLabel` | `Label` | "HAI VINTO!" / "HAI PERSO" / "PAREGGIO" |

### Pannello avversario

| Nome | Tipo | Cosa mostra |
|---|---|---|
| `EnemyPanel` | `PanelContainer` | si **scurisce** quando non è il suo turno |
| `EnemyName` | `Label` | nome |
| `EnemyHealth` | `ProgressBar` | barra vita (min 0, max automatico) |
| `EnemyHealthText` | `Label` | "320 / 400" |
| `EnemyMana` | `Label` | "Mana 42" |
| `EnemyShield` | `Label` | "Scudo 27" (si nasconde se 0) |
| `EnemyStatuses` | `HBoxContainer` | Brucia, Veleno… si generano da soli |
| `EnemyPlayed` | `HBoxContainer` | **le sue carte giocate** |

### Pannello giocatore

Stessi nodi con prefisso `Player`:

`PlayerPanel`, `PlayerName`, `PlayerHealth`, `PlayerHealthText`,
`PlayerMana`, `PlayerShield`, `PlayerStatuses`, `PlayerPlayed`

### Azioni

| Nome | Tipo | Cosa fa |
|---|---|---|
| `DrawButton` | `Button` | pesca (o tasto `Spazio`) |
| `StopButton` | `Button` | chiudi il turno (o tasto `S`) |
| `RiskLabel` | `Label` | "Rischio se peschi: 23%" — **cambia colore da solo** |

### Log

| Nome | Tipo | Note |
|---|---|---|
| `LogScroll` | `ScrollContainer` | contenitore che scorre |
| `LogLabel` | `RichTextLabel` | **dentro** LogScroll. `fit_content = true`, `scroll_active = false` |

`LogScroll` deve essere il **genitore** di `LogLabel`.

---

## Le carte sul tavolo

**Non devi creare nessun nodo per le carte.** Lo script crea da solo una
[CardView](../ui/card_view.gd) dentro `PlayerPlayed` / `EnemyPlayed`, per ogni
carta giocata. La grafica la prende da `Cards/art/<id>.png`.

Dimensione configurabile dall'Inspector, gruppo *Carte sul tavolo*:

| Campo | Default |
|---|---|
| `played_card_width` | 150 |
| `played_card_height` | 205 |
| `played_card_art_height` | 78 |

> Le carte restano visibili **tutto lo scambio**: le tue spariscono quando
> ricomincia il tuo turno, quelle dell'avversario quando ricomincia il suo.
> Così vedi sempre il confronto.

---

## Consigli pratici

**ProgressBar** — non impostare `Max Value` a mano: lo script lo prende dalla
vita del combattente (400). Metti solo min 0 e il colore del riempimento.

**PanelContainer vs Control** — per `PlayerPanel`/`EnemyPanel` va bene qualsiasi
nodo che estenda `Control`: vanno bene anche `PanelContainer` o `VBoxContainer`.

**Anchor e layout** — metti `PlayerPanel` in basso e `EnemyPanel` in alto, con
gli anchor (non a coordinate fisse), così funziona a ogni risoluzione.
La finestra del progetto è **1920×1080**.

**Ordine dei figli** — dentro `PlayerPlayed`/`EnemyPlayed` le carte si
**accodano**: usa un `HBoxContainer` con separazione 8, o un `HFlowContainer`
se vuoi che vadano a capo.

**Font e dimensioni** — lascia stare `RiskLabel` senza colore forzato: lo
script lo cambia in verde/giallo/rosso secondo il rischio.

---

## Cosa fa lo script da solo

- Pesca, STOP, bust, risoluzione, sinergie, status — tutto dal motore
- Turno dell'avversario con IA, **con pause** per poterlo seguire
- Aggiorna vita, mana, scudo, status di entrambi
- Crea le carte sul tavolo e le ripulisce al momento giusto
- Scrive il log (comprese le **decisioni spiegate** dell'IA)
- Blocca i pulsanti quando non è il tuo turno

Configurabile dall'Inspector:

| Gruppo | Campo | Cosa |
|---|---|---|
| Partita | `player_deck` | il tuo mazzo (vuoto = Equilibrato) |
| | `opponent_deck` | mazzo avversario (vuoto = Veterano) |
| | `battle_seed` | 0 = casuale |
| Avversario | `ai_risk_tolerance` | 0.40 = come il tavolo testuale |
| | `explain_opponent` | spiega perché l'IA si ferma |
| Ritmo | `opponent_step_delay` | secondi tra le mosse dell'IA |
| | `opponent_think_delay` | pausa prima che inizi |

---

## Riferimento: il tavolo testuale

Se qualcosa non torna, confronta con `play_table.gd` + `play_table.tscn`:
è la **versione testuale** dello stesso gioco, con la stessa logica di turni
e la stessa IA. Il nuovo tavolo è la stessa cosa, ma con le carte disegnate.
