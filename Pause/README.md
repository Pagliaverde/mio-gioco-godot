# ⏸️ Pausa

Il menu che compare quando premi **Esc** durante il gioco: il mondo si ferma,
lo sfondo si oscura e hai le opzioni davanti.

| File | Cosa fa |
|---|---|
| `pause.gd` | L'autoload `Pause`: ascolta Esc, apre e chiude, mette in pausa il gioco |
| `pause_menu.gd` | Il menu vero e proprio (`class_name PauseMenu`), costruito in codice |

---

## Le voci

| Voce | Cosa fa |
|---|---|
| **Riprendi** | Chiude il menu e fa ripartire il gioco |
| **Salva** | Scrive il salvataggio su disco (vedi [`Save/`](../Save/README.md)) |
| **Opzioni** | Apre la schermata delle impostazioni, sopra a questa |
| **Torna al menu principale** | Chiede conferma, poi va a `Menu/main_menu.tscn` |
| **Esci dal gioco** | Chiede conferma, poi chiude. La conferma si spegne da *Impostazioni → Gioco → Chiedi conferma* |

Sotto i pulsanti c'è una riga che dice se c'è un salvataggio e di quando è, così
si vede subito se "Riprendi" ha qualcosa da riprendere.

---

## Perché è un autoload

`Pause` è registrato in `project.godot`:

```ini
[autoload]

Settings="*res://Settings/settings.gd"
DialogueManager="*uid://c3rodes2l3gxb"
Pause="*res://Pause/pause.gd"
```

Così **funziona in ogni scena senza aggiungere niente**: il campo da gioco, il
tavolo di battaglia, una scena nuova che farai domani. Se invece fosse un nodo
da mettere in ogni scena, prima o poi una se ne dimenticherebbe.

Il menu vive su un `CanvasLayer`, e il livello conta perché sopra ci passa altra
roba:

| Livello | Cosa |
|---|---|
| 100 | Il balloon dei dialoghi (`Asset/Dialogue/DialoguePannel/balloon.tscn`) |
| **110** | **Il menu di pausa** |
| 120 | La schermata delle impostazioni |
| 128 | Filtri colore e contatore FPS (`Settings`) |

L'ordine non è casuale: la pausa deve coprire il gioco e il balloon, le
impostazioni devono coprire la pausa (si aprono da qui), e i filtri colore
devono coprire tutto, perché sono una lente sullo schermo intero.

---

## Chi vince quando premi Esc

Esc è conteso da tre schermate. La regola è che **vince chi sta davanti**, e
si regge sull'ordine dell'albero, non su condizioni sparse in giro:

| Situazione | Cosa succede |
|---|---|
| Sei in una scena di gioco | Si apre la pausa |
| Sei nel **menu principale** | Il menu porta su "Esci", come in ogni menu. La pausa non si apre |
| È aperto un **dialogo** | Esc salta il testo, come ha sempre fatto. La pausa non si apre |
| Sono aperte le **impostazioni** | Esc chiude le impostazioni. La pausa resta aperta dietro |
| La pausa è aperta, con la **conferma** visibile | Esc annulla la conferma |
| La pausa è aperta | Esc riprende |

Il motivo tecnico: Godot manda `_unhandled_input` partendo dal nodo più profondo
e risalendo, quindi l'ultimo arrivato nell'albero riceve il tasto per primo. Il
menu di pausa (creato a runtime ed è l'ultimo figlio della radice) e la scena
aperta vengono prima dell'autoload `Pause`. Ognuno di loro, quando usa il tasto,
lo segna come "già gestito", e chi viene dopo non lo vede più.

**Il caso del dialogo** merita una riga in più: il balloon ha
`will_block_other_input = true`, quindi mentre parli si prende **tutti** i tasti.
Non è una scelta di questo menu, è come funziona il Dialogue Manager: il
risultato è che durante una conversazione non puoi mettere in pausa, e Esc salta
il testo. Se un giorno lo vuoi diverso, si cambia quel campo nel balloon.

**Se una tua scena ha bisogno di Esc per conto suo**, gestiscilo lì: la pausa
non si aprirà. In alternativa:

```gdscript
Pause.enabled = false   # durante un filmato, per esempio
```

---

## Usarlo dal codice

```gdscript
Pause.open()          # apre la pausa (es. da un pulsante a schermo)
Pause.close()         # riprende
Pause.toggle()        # apre o chiude
Pause.is_open()       # true se il menu è aperto

Pause.opened.connect(...)
Pause.closed.connect(...)
```

---

## Cos'è fermato, esattamente

Quando la pausa è aperta vale `get_tree().paused = true`. Questo ferma tutto ciò
che ha il comportamento di processo normale (`_process`, `_physics_process`,
`_input`, i timer). Continuano a girare solo i nodi marcati
`PROCESS_MODE_ALWAYS`, che sono:

- l'autoload `Pause`
- il menu di pausa
- l'autoload `Settings` e la schermata delle impostazioni (c'era già, serviva
  per il menu di pausa)

**La musica non si ferma**, ed è voluto: la colonna sonora è l'unica cosa che
tiene in vita una schermata immobile.

---

## Aspetto

Il menu non ha un file `.tscn`: si costruisce in codice leggendo il **tema
globale** (`Settings/game_theme.tres`). Vuol dire che cambiando tema i colori
della pausa cambiano da soli, e non c'è un file di scena da rompere.

Il pannello entra con una comparsa breve (`POP_TIME`, 0,16 s) che viene
**annullata** se il giocatore ha attivo *Impostazioni → Accessibilità → Riduci
movimento*.

### Aggiungere o togliere una voce

Tutto dentro `_build()` in `pause_menu.gd`:

```gdscript
_add_button(box, "Riprendi", _on_resume_pressed)
_add_button(box, "Salva", _on_save_pressed)
```

I pulsanti sono in una `VBoxContainer`, quindi la navigazione con le frecce è
automatica: non c'è niente da collegare a mano. Il focus parte su **Riprendi**,
e sulla conferma parte su **No**, così premere Invio per abitudine non chiude
niente per sbaglio.
