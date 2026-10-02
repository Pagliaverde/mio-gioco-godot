## Il menu di pausa, disponibile in tutto il gioco.
##
## [b]E' un autoload[/b] (vedi [code]project.godot[/code]): vive sopra a tutte le
## scene, quindi non devi aggiungere niente a nessuna scena perche' funzioni.
##
## [b]Esc[/b] lo apre e lo chiude. Non si apre dove Esc serve gia' ad altro —
## menu principale, schermata delle impostazioni — perche' quelle schermate
## consumano il tasto prima che arrivi qui.
##
## Quando e' aperto il gioco e' fermo ([code]get_tree().paused = true[/code]):
## nessun nemico si muove, nessun timer scorre.
##
## [codeblock]
## Pause.open()      # da un pulsante tuo
## Pause.close()
## Pause.toggle()
## Pause.enabled = false   # es. durante un filmato
## [/codeblock]
##
## Vedi [code]Pause/README.md[/code].
extends Node


## Emesso quando il menu si apre.
signal opened()

## Emesso quando il menu si chiude (anche se poi si esce o si cambia scena).
signal closed()


## Il livello del menu, sopra al balloon dei dialoghi (100) e sotto alla
## schermata delle impostazioni (120): cosi' le impostazioni aperte da qui le
## stanno davanti, e il menu copre tutto il resto.
const LAYER := 110

## Dove porta "Torna al menu principale".
const MAIN_MENU_SCENE := "res://Menu/main_menu.tscn"


## Metti a false per disattivare la pausa (es. durante un filmato o una scena
## che usa Esc per conto suo).
var enabled: bool = true


var _layer: CanvasLayer = null
var _menu: PauseMenu = null


func _ready() -> void:
	# Deve funzionare proprio mentre il gioco e' in pausa: e' il suo mestiere.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or is_open():
		return
	if not event.is_action_pressed(&"ui_cancel"):
		return
	# Le impostazioni hanno la precedenza: con loro aperte, Esc chiude loro.
	if Settings.is_menu_open():
		return

	open()
	get_viewport().set_input_as_handled()


#region Aprire e chiudere


## Apre il menu di pausa e ferma il gioco. Se e' gia' aperto non fa niente.
func open() -> void:
	if is_open():
		return

	_layer = CanvasLayer.new()
	_layer.layer = LAYER
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_layer)

	_menu = PauseMenu.new()
	_menu.resume_requested.connect(close)
	_menu.main_menu_requested.connect(_go_to_main_menu)
	_menu.quit_requested.connect(_quit)
	_layer.add_child(_menu)

	get_tree().paused = true
	opened.emit()


## Chiude il menu e fa ripartire il gioco.
func close() -> void:
	if not is_open():
		return

	get_tree().paused = false
	_layer.queue_free()
	_layer = null
	_menu = null
	closed.emit()


## Apre o chiude, a seconda di com'e' adesso.
func toggle() -> void:
	if is_open():
		close()
	else:
		open()


## True se il menu di pausa e' aperto.
func is_open() -> bool:
	return _layer != null and is_instance_valid(_layer)


#endregion

#region Azioni del menu


func _go_to_main_menu() -> void:
	# Prima si riparte: se la scena nuova parte gia' in pausa non si muove piu'
	# niente e sembra un blocco.
	close()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _quit() -> void:
	close()
	get_tree().quit()


#endregion
