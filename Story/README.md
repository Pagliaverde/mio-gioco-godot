# 🎭 Fuori Copione — la storia

> *"Non hai un volto. Hai un repertorio."*

La campagna del gioco: ti svegli in una stanza senza volto, attraversi un teatro
che è tutto il mondo, batti cinque attori che hanno provato a uscire prima di te,
e alla fine scegli come finire. È l'implementazione di
[`Docs/TRAMA_E_MASCHERE.md`](../Docs/TRAMA_E_MASCHERE.md).

**Per giocare:** menu principale → **Storia** → **Nuova Partita**: la storia
si gioca camminando nel teatro, vedi [`World/README.md`](../World/README.md).
I testi, i boss, le maschere e la battaglia sono quelli descritti qui sotto:
il mondo esplorabile li usa così come sono.

La versione "a pagine" (`Story/story.tscn`, apribile con **F6**) resta: è
quella che gioca `check_story` per controllare battaglie e testi senza mappe.

---

## 📑 Indice

1. [Come si gioca](#-come-si-gioca)
2. [Il percorso](#-il-percorso)
3. [Le maschere](#-le-maschere)
4. [I boss](#-i-boss)
5. [I finali](#-i-finali)
6. [Struttura dei file](#-struttura-dei-file)
7. [Cambiare testi, mazzi e numeri](#-cambiare-testi-mazzi-e-numeri)
8. [Verificare senza giocare](#-verificare-senza-giocare)
9. [Salvataggio](#-salvataggio)

---

## 🎮 Come si gioca

La storia è una sequenza di **pagine**: un testo a sinistra, un'immagine a destra
(una maschera, la platea, il cartello di un boss), i pulsanti sotto. Il primo
click mentre il testo sta comparendo lo completa; il secondo va avanti.

| Tasto | Cosa fa |
|---|---|
| `Invio` / click | Sceglie il pulsante evidenziato |
| `← →` | Cambia pulsante |
| `Esc` | Menu di pausa (Salva, Opzioni, Torna al menu principale) |
| **Torna al menu** | Salva e torna al menu principale |

Le **scene** (le battaglie) usano lo stesso motore di `Cards/table`, con le
parole del teatro:

| Nel motore | Nella storia |
|---|---|
| Mana | **Pubblico** |
| Scudo | **Favore** |
| Bust | **Fuori copione** |
| Critico | **Ti ruba la scena** |
| Brucia / Veleno / Congelato | **Riflettori / Maldicenza / Panico di scena** |
| Potenziato / Rigenerazione | **Ispirazione / Bis** |
| Livello | **Gavetta** |

| Tasto in scena | Cosa fa |
|---|---|
| `Spazio` / **PESCA** | Pesca una battuta (se puoi pagarla, la reciti) |
| `S` / **STOP** | Ti fermi: il pubblico non speso diventa Favore |

Il mazzo è sempre l'**Equilibrato** di `CardLibrary`: la storia è sulle
maschere, non sulle carte. A ogni boss battuto sali di **Gavetta** (più
pubblico a ogni scena).

---

## 🗺 Il percorso

```
IL CAMERINO  →  LA PIAZZA DIPINTA  →  LA GALLERIA DEGLI SPECCHI  →  IL PALCO
 (la stanza)      Boss I                  Boss II                    Boss III
                                                                        ↓
       IL FONDO  ←  L'AUDITORIUM  ←  I CORRIDOI
       (finale)       Boss V            Boss IV
```

In ogni zona, nell'ordine:

1. **L'ingresso**: qualche pagina di descrizione.
2. **Il Baule di Scena** (Camerino, Piazza, Galleria, Palco): una maschera base
   **a caso** tra quelle che non hai ancora. Quattro bauli, quattro maschere.
3. **La platea** (dalla Piazza in poi): la guardi. Un manichino è in un posto
   diverso ogni volta. Nessuno te lo dice: lo vedi.
4. **Il boss**: il cartello, la presentazione, la **scelta della maschera**,
   la scena. Se perdi, il teatro ripete la sera: scegli di nuovo la maschera
   e riprovi. Se vinci, prendi la sua maschera e sali di Gavetta.

---

## 🎭 Le maschere

Una maschera **non cambia le carte: cambia le regole intorno alle carte**.
Sono definite in [`Cards/mask/mask_library.gd`](../Cards/mask/mask_library.gd),
le regole sono hook in [`Cards/battle/battle_state.gd`](../Cards/battle/battle_state.gd).

Ogni maschera ha:

- **Affinità**: con la maschera addosso valgono **solo** le sinergie dei suoi
  elementi; quegli elementi fanno più danno (`affinity_multiplier`, ×1.3), gli
  altri un po' meno (`off_affinity_multiplier`, ×0.85). Le neutre non cambiano.
- **Regola dell'azzardo** (`CardTypes.MaskGambit`): tocca il rischio.
- **Postura**: ritocchi ai numeri (`damage_scale`, `mana_bonus`).
- **Il prezzo**, scritto in chiaro.

| Maschera | Dove | Affinità | Regola dell'azzardo | Il prezzo |
|---|---|---|---|---|
| **La Tragedia** | Baule | Fuoco, Oscuro | *Catarsi*: se vai fuori copione, il rivale ti ruba la scena **×3** | Danno +10%, ma il bust costa carissimo |
| **La Commedia** | Baule | Fulmine, Natura | *Improvvisazione*: il primo passo falso **di ogni turno** è perdonato | Danno −20% |
| **L'Inganno** | Baule | Veleno, Oscuro | *Doppio gioco*: lo scudo più grande del turno vale doppio; il rivale non vede il tuo pubblico | Danno −15% |
| **Il Presagio** | Baule | Ghiaccio, Veleno | *Presagio*: vedi sempre la prossima carta | Nessun bonus ai numeri |
| **La Comparsa** | Boss I | — | nessuna | Non fa niente |
| **Lo Specchio** | Boss II | Ghiaccio, Fulmine | *Riflesso*: le carte che il rivale ha giocato ti costano −30% il turno dopo | Contro chi gioca poco, non serve |
| **L'Essere Amato** | Boss III | Fuoco, Fulmine | *Perdono*: un bust perdonato, **una volta per incontro** | Il credito finisce |
| **Il Dovere** | Boss IV | Natura, Ghiaccio | *Guardia*: la prima volta che lo scudo assorbe, non si consuma | Diventi il muro |
| **Tutte** | Boss V | tutti | ogni regola buona insieme | L'hai pagata lasciando indietro qualcuno |

**Quando si sceglie:** prima di ogni scena, una sola maschera per incontro
(come consiglia il documento di design). "A volto scoperto" = nessuna maschera.

**Cosa succede nel motore** (`battle_state.gd`, cerca `has_gambit`):

| Regola | Dove | Cosa fa |
|---|---|---|
| Perdono / Improvvisazione | `draw_and_play()` | la carta troppo cara torna **in fondo** al mazzo, emette `forgiven`, il turno continua |
| Catarsi | `draw_and_play()` | il critico del rivale diventa 3.0 |
| Riflesso | `_apply_turn_gambits()` | `cost_modifier` negativo sulle copie delle carte in `last_played_ids` del rivale |
| Guardia | `BattlePlayer.take_damage()` | `guard_active`: assorbe senza consumare, una volta |
| Doppio gioco | `_resolve_turn()` | aggiunge di nuovo lo scudo più grande giocato |
| Presagio | `peek_next_card()` | ritorna `draw_pile.back()` solo se la maschera lo permette |
| Affinità | `_resolve_turn()` | `_rules_for(player)` sceglie le sinergie; moltiplicatori per elemento |

---

## ⚔️ I boss

Definiti in [`story_data.gd`](story_data.gd), uno per zona.

| # | Boss | Mazzo | Tratto | Gavetta | Rischio IA | Lascia |
|---|---|---|---|---|---|---|
| I | **La Comparsa** | `Fortezza` (difesa pura) | nessuno | 1 | 15% | La Comparsa |
| II | **Il Sostituto** | **il tuo**, con **la tua maschera** | copia | 1 | 40% | Lo Specchio |
| III | **La Prima Attrice** | `Prima Attrice` (Ghiaccio/Fulmine, tanto Panico) | indossa l'Essere Amato | 2 | 45% | L'Essere Amato |
| IV | **Il Carceriere** | `Carceriere` (scudo, Panico, status) | **gabbia**: −10 pubblico a ogni tuo turno; indossa il Dovere | 3 | 25% | Il Dovere |
| V | **L'Ultimo** | `Tutto` (ogni carta ×1) | vita ×1.4, danno ×0.75; indossa Tutte | 4 | 40% | Tutte |

La **difficoltà** delle impostazioni (Gioco → Difficoltà) sposta la Gavetta dei
boss di un passo: facile −1, difficile +1.

I tratti dei boss sono campi di `BattlePlayer`: `cage_strength`, `damage_scale`
e `max_health`. Li imposta `StoryBattle.begin()`.

---

## 🏁 I finali

Dopo L'Ultimo non c'è un sesto boss: la porta **EXIT** è dipinta sul fondale.
L'uscita è **dietro il pubblico**. Attraversi la platea, i manichini si girano
(tutti, insieme, una volta sola: `TheatreView.turn_all()`), e scegli:

| Finale | Scelta |
|---|---|
| **Esci vuoto** | Ti togli tutte le maschere e attraversi la porta senza niente |
| **Esci pieno** | Attraversi la porta con tutte le maschere addosso |
| **Non esci** | Ti togli le maschere, ma resti |

Nessuno è "quello giusto". I finali visti restano in memoria
(`StorySave.endings_seen()`), il salvataggio viene cancellato.

---

## 📂 Struttura dei file

```
Story/
├── README.md          ← questa guida
├── story.tscn         La scena: solo un Control con story.gd
├── story.gd           ★ StoryDirector: il filo della storia (pagine, bauli, boss, finale)
├── story_data.gd      ★ Zone, boss, mazzi dei boss, tutti i testi
├── story_battle.gd    Il tavolo di battaglia della storia (maschere, tratti, parole del teatro)
├── story_words.gd     Traduce il log del motore nelle parole del teatro
├── story_save.gd      Salvataggio in user://story.cfg
├── mask_card.gd       Una maschera disegnata come carta (faccia in pixel art)
└── theatre_view.gd    La platea: i manichini, quello che si sposta, quelli che si girano

Cards/mask/
├── mask_data.gd       ★ MaskData: affinità, regola dell'azzardo, postura, prezzo
└── mask_library.gd    ★ Le nove maschere
```

Tutto è costruito **in codice**, come il menu: niente nodi da sistemare a mano.

---

## ✏️ Cambiare testi, mazzi e numeri

| Vuoi cambiare… | Dove |
|---|---|
| Una frase della storia | `story_data.gd`: `intro`, `victory`, `defeat` di ogni zona/boss; `tutorial_pages()`, `audience_lines()`, `finale_pages()`, `endings()` |
| Il mazzo di un boss | `story_data.gd`: `build_diva_deck()`, `build_warden_deck()`, `build_everything_deck()` (o `deck_builder` del boss) |
| La forza di un boss | `story_data.gd`: `level`, `risk_tolerance`, `cage`, `health_scale`, `damage_scale` |
| Una maschera | `Cards/mask/mask_library.gd`: affinità, `gambit`, `damage_scale`, testi |
| Il mazzo del giocatore | `story.gd`, `_ready()`: `CardLibrary.build_starter_deck()` |
| I colori delle zone | `story_data.gd`: `_zone(...)`, quarto parametro |
| Le facce delle maschere | `mask_card.gd`, `paint_face()` (`MaskData.face`: `empty`, `smile`, `frown`, `half`, `eye`, `mirror`, `heart`, `bars`, `many`) |

Il numero sul muro del camerino è quante volte hai cominciato
(`StorySave.run_count()`).

---

## 🧪 Verificare senza giocare

Tre strumenti, da riga di comando (serve l'eseguibile di Godot):

```bash
# Le nove maschere e le loro regole, in battaglie IA contro IA
godot --headless --path . --script res://Cards/tools/check_masks.gd

# Tutta la storia da sola: pagine, bauli, cinque boss, finale
godot --headless --path . res://Cards/tools/check_story.tscn

# Screenshot delle schermate in user://screenshots/ (serve una finestra, anche virtuale)
xvfb-run -a godot --path . --rendering-driver opengl3 res://Cards/tools/screenshot_story.tscn
```

`check_story` usa `StoryDirector.auto_pilot`: sceglie sempre il primo pulsante
e fa giocare un'IA al posto tuo (con sei livelli di Gavetta in più, per non
restare bloccata su un boss). Stampa una riga per pagina.

---

## 💾 Salvataggio

Il progresso passa dal salvataggio del gioco, [`Save/`](../Save/README.md):
`StoryDirector` è iscritto al gruppo `save_state` e risponde a
`get_save_data()` / `apply_save_data()` con zona, gavetta, maschere e visite
alla platea. Quindi:

- la storia **salva da sola** a ogni zona, baule e boss battuto (`_save()`);
- **Salva** nel menu di pausa (`Esc`) fa la stessa cosa;
- **Riprendi** nel menu principale ricarica l'ultimo salvataggio e riparte
  dall'inizio della zona salvata (la scena in corso non viene salvata);
- al finale il salvataggio viene cancellato.

Quello che un salvataggio non deve toccare sta in `user://story.cfg`
(`StorySave`): quante volte hai cominciato (il numero sul muro del camerino)
e quali finali hai visto.
