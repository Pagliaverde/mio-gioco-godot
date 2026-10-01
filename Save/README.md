# 💾 Salvataggio

Un salvataggio solo, in `user://savegame.txt`. Nessuno slot, nessuna scelta
multipla: si sovrascrive sempre.

| File | Cosa fa |
|---|---|
| `save_game.gd` | `class_name SaveGame`: raccoglie, scrive, rilegge. Tutto statico |

> **Chi lo chiama:** il pulsante **Salva** del menu di pausa
> (vedi [`Pause/`](../Pause/README.md)) e la voce **Riprendi** del menu
> principale.

---

## L'idea

`SaveGame` **non sa niente del gioco**. Non conosce il player, le carte, i
nemici. Quando salvi, attraversa la scena aperta e chiede i dati ai nodi che si
sono iscritti al gruppo `save_state` e che sanno rispondere a due domande:

```gdscript
func get_save_data() -> Variant:
    return {"dove": position}

func apply_save_data(data: Variant) -> void:
    position = data["dove"]
```

Un nodo senza niente da salvare non si iscrive e fine. **Non c'è nessun elenco
da aggiornare**, né in questo file né altrove.

---

## Far partecipare un nodo

Tre righe, in `_ready()`:

```gdscript
func _ready() -> void:
    add_to_group(SaveGame.GROUP)
    SaveGame.apply_to(self)     # applica i dati se stavamo caricando
```

più i due metodi qui sopra.

`SaveGame.apply_to(self)` serve perché caricando si può **cambiare scena**, e in
quel momento i nodi non esistono ancora. Sono loro a farsi avanti quando nascono.

> **Un nodo già iscritto:** il `Player` (`Asset/Script/player.gd`). Salva
> posizione e direzione — non lo stato momentaneo, perché al caricamento deve
> ricominciare fermo, non a metà di una conversazione che non esiste più.

---

## Il formato

`var_to_str` e `str_to_var`, **non JSON**. Così `Vector2`, `Color`, `NodePath`,
dizionari e array si scrivono e si rileggono da soli, senza conversioni a mano.
Un file leggibile, utile anche solo per curiosare.

```gdscript
{
    "version": 1,
    "scene": "res://Scene/Main.tscn",
    "time": 1759312345.0,          # ora Unix, serve per "2 ore fa"
    "nodes": {
        "Player": {"position": Vector2(320, 180), "direction": Vector2(1, 0)},
    },
}
```

### La versione

`VERSION` è la versione del formato. **Alzala quando cambia la forma dei dati.**
Un file con una versione diversa viene ignorato con un avviso in Output: meglio
una partita nuova che dati letti male.

### L'ora

`time` è l'ora Unix, e serve solo a `describe()`, che produce la riga mostrata
nei menu ("3 elementi, 2 ore fa"). Non c'è niente di più delicato di così.

---

## Le funzioni

| Funzione | Cosa fa |
|---|---|
| `has_save()` | C'è un file su disco? |
| `save_now(tree)` | Salva. Ritorna `{"ok", "nodes", "reason", "scene"}` |
| `load_into(tree)` | Carica, cambiando scena se serve. Ritorna `{"ok", "nodes", "changed"}` |
| `read()` | Il salvataggio come dizionario, o `{}` |
| `describe()` | "3 elementi, 2 ore fa", per i menu |
| `saved_node_count()` | Quanti nodi ci sono dentro |
| `erase()` | Cancella il file |
| `apply_to(node)` | Un nodo si presenta coi suoi dati |

---

## `nodes` uguale a zero non è un errore

Se nessun nodo risponde, il file viene scritto lo stesso: è un salvataggio
valido, solo vuoto. Succede in tutte le scene dove non c'è ancora niente da
ricordare.

Per questo il menu di pausa lo dice apertamente:

| Situazione | Messaggio |
|---|---|
| Salvato, `nodes` > 0 | "Partita salvata." |
| Salvato, `nodes` = 0 | "Salvato, ma in questa scena non c'e' ancora niente da ricordare." |
| Scrittura fallita | "Salvataggio non riuscito." |

Un pulsante "Salva" che tace quando non ha salvato niente è peggio di un
pulsante che lo dice.

---

## Caricare da un'altra scena

`load_into()` guarda la scena scritta nel salvataggio:

1. **È la stessa in cui siamo già** → applica i dati e basta, `changed = false`.
2. **È un'altra** → mette i dati in attesa, chiama `change_scene_to_file()`, e
   i nodi della scena nuova se li prendono da soli con `apply_to`.
3. **La scena non esiste più** (l'hai rinominata) → non fa niente e avvisa in
   Output.

### I dati in attesa scadono

Nel caso 2 nessuno sa quando i nodi nuovi saranno pronti. Quindi i dati restano
in attesa e si fanno avanti i nodi. La rete di sicurezza è `PENDING_TIMEOUT_MS`
(5 secondi): passato quel tempo i dati vengono buttati, invece di restare appesi
e riapplicarsi per sbaglio dieci minuti dopo.

---

## Cosa farne adesso

Il sistema è pronto ma **quasi vuoto**: c'è solo il `Player`. Quando avrai deck,
inventario e progressi, basta aggiungere i due metodi ai nodi che li tengono.

Quello che manca, e che vale la pena aggiungere quando servirà davvero:

- **più di un salvataggio** (oggi `SAVE_PATH` è una costante sola);
- **il salvataggio automatico**, sulla voce già presente in
  *Impostazioni → Gioco → Salvataggio automatico* (`auto_save`);
- **quando** salvare: adesso solo a mano, dal menu di pausa.
