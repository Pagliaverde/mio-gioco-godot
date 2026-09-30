## Plugin dell'editor: aggiunge il dock "Carte".
##
## [b]E' volutamente minuscolo:[/b] tutta l'interfaccia vive in
## [code]res://addons/card_editor/card_browser.gd[/code]. Qui c'e' solo
## l'aggancio al dock, cosi' il plugin resta facile da leggere e da aggiornare.
##
## Per attivarlo: Progetto > Impostazioni progetto > Plugin > "Card Editor".
##
## [b]PERCHE' IL DOCK SI AGGANCIA DOPO UN FRAME (non togliere questo rinvio).[/b]
##
## Aggiungere un dock dentro [method _enter_tree] sembra la cosa ovvia, ed e'
## quello che fanno quasi tutti i plugin. Ma chiedere un dock mentre Godot sta
## ancora caricando il layout fa partire un salvataggio del layout stesso
## ([code]save_editor_layout_delayed[/code]).
##
## In quel preciso istante il [b]pannello in basso[/b] (Output, Debugger,
## Animation...) non ha ancora ricevuto la sua scheda attiva. E Godot, quando
## salva un pannello che non ha una scheda attiva, non scrive "nessuna scheda":
## [b]cancella la riga[/b].
##
## Alla partita successiva quella riga manca, quindi il pannello in basso
## risulta collassato. E qui sta il guaio: quando il pannello e' collassato
## Godot nasconde [b]sia il pulsante di espansione sia il separatore da
## trascinare[/b], quindi non c'e' piu' nessun modo di riaprirlo dall'interfaccia.
## Si peggiora da solo ad ogni avvio.
##
## [b]Sintomo tipico:[/b] il pannello in basso c'e' per un istante all'avvio,
## poi sparisce e non torna piu'. Reinstallare Godot non serve, perche' il
## layout e' [i]per progetto[/i] e vive in
## [code]res://.godot/editor/editor_layout.cfg[/code].
##
## [b]Come si recupera[/b] un editor gia' rotto: chiudi Godot, cancella
## [code]res://.godot/editor/editor_layout.cfg[/code] (a Godot chiuso, o viene
## riscritto), e riapri. Oppure premi la scorciatoia di un pannello in basso,
## per esempio Ctrl+Shift+F per "Cerca nei file".
##
## Rimandando di un frame, il layout e' gia' stato ripristinato e il pannello
## in basso ha la sua scheda: il salvataggio non cancella piu' niente.
@tool
extends EditorPlugin


const CARD_BROWSER_SCRIPT: Script = preload("res://addons/card_editor/card_browser.gd")

var _browser: Control


func _enter_tree() -> void:
	_browser = CARD_BROWSER_SCRIPT.new()
	_browser.name = "Carte"

	# Vedi la spiegazione lunga sopra: questo rinvio e' la correzione di un bug
	# che rendeva inutilizzabile l'editor. Non spostare l'aggancio qui dentro.
	_add_browser.call_deferred()


## Aggancia il dock, un frame dopo l'avvio del plugin.
func _add_browser() -> void:
	# Il plugin puo' essere disattivato prima che il rinvio parta.
	if not is_instance_valid(_browser):
		return

	# Se e' gia' agganciato non facciamo niente: cosi' la funzione si puo'
	# chiamare piu' volte senza rischi.
	if _browser.get_parent() != null:
		return

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _browser)


func _exit_tree() -> void:
	if not is_instance_valid(_browser):
		_browser = null
		return

	# Se il rinvio non e' ancora partito il dock non esiste, e non c'e' niente
	# da staccare: chiamare remove_control_from_docks su un dock mai creato
	# darebbe solo un errore.
	if _browser.get_parent() != null:
		remove_control_from_docks(_browser)

	_browser.queue_free()
	_browser = null
