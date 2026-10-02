## Il menu di pausa: l'elenco che compare sopra al gioco fermo.
##
## [b]Non aprirlo a mano:[/b] usa [code]Pause.open()[/code]. Vedi
## [code]Pause/pause.gd[/code], che lo crea, lo mette sopra a tutto e ferma il
## gioco.
##
## Si costruisce da solo in codice, come il menu principale: nessun file
## [code].tscn[/code] da rompere e i colori vengono dal [Theme] globale, quindi
## un cambio di tema si vede subito anche qui.
class_name PauseMenu
extends Control


## Il giocatore vuole tornare a giocare.
signal resume_requested()

## Il giocatore vuole chiudere il gioco.
signal quit_requested()

## Il giocatore vuole tornare al menu principale.
signal main_menu_requested()


const TITLE_TEXT := "In Pausa"

## Quanto dura il "salta fuori" del pannello (secondi). Viene annullato se il
## giocatore ha chiesto meno movimento nelle impostazioni.
const POP_TIME := 0.16


var _panel: PanelContainer
var _status: Label
var _toast: Label
var _buttons: Array[Button] = []

var _confirm_layer: Control
var _confirm_text: Label
var _confirm_action: Callable = Callable()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Il gioco e' in pausa, ma questo menu deve continuare a funzionare.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build()
	_refresh_status()
	_pop_in()

	# Il focus sul primo pulsante: si comincia a navigare subito con i tasti,
	# senza dover prendere il mouse.
	_focus_first()


#region Costruzione


func _build() -> void:
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0, 0, 0, 0.78)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.pivot_offset = _panel.size * 0.5
	center.add_child(_panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)

	var title: Label = Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_status = Label.new()
	_status.theme_type_variation = &"DimLabel"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status)

	column.add_child(_make_spacer(10.0))

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	column.add_child(box)

	_add_button(box, "Riprendi", _on_resume_pressed)
	_add_button(box, "Salva", _on_save_pressed)
	_add_button(box, "Opzioni", _on_options_pressed)
	_add_button(box, "Torna al menu principale", _on_main_menu_pressed)
	_add_button(box, "Esci dal gioco", _on_quit_pressed)

	_toast = Label.new()
	_toast.theme_type_variation = &"DimLabel"
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.custom_minimum_size = Vector2(420.0, 0.0)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_toast)

	_build_confirm()


## Il pannello "sei sicuro?", nascosto finche' non serve.
##
## Sta sopra all'elenco, su un velo suo piu' chiaro: cosi' si vede ancora il
## menu dietro e si capisce che la domanda riguarda quello.
func _build_confirm() -> void:
	_confirm_layer = Control.new()
	_confirm_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_layer.visible = false
	_confirm_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm_layer)

	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0, 0, 0, 0.5)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_layer.add_child(veil)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_layer.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	center.add_child(panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)

	_confirm_text = Label.new()
	_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_text.add_theme_font_size_override("font_size", Settings.font_size(22))
	column.add_child(_confirm_text)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)

	var yes: Button = Button.new()
	yes.text = "Sì"
	yes.custom_minimum_size = Vector2(150.0, 48.0)
	yes.add_theme_font_size_override("font_size", Settings.font_size(22))
	yes.pressed.connect(_on_confirm_yes)
	row.add_child(yes)

	var no: Button = Button.new()
	no.text = "No"
	no.custom_minimum_size = Vector2(150.0, 48.0)
	no.add_theme_font_size_override("font_size", Settings.font_size(22))
	no.pressed.connect(_on_confirm_no)
	row.add_child(no)


func _add_button(parent: Node, text: String, handler: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420.0, 56.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", Settings.font_size(24))
	button.pressed.connect(handler)
	parent.add_child(button)
	_buttons.append(button)
	return button


func _make_spacer(height: float) -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


## Una comparsa breve del pannello, che parte rimpicciolita.
##
## Con "riduci movimento" attivo salta l'animazione: il menu compare e basta,
## perche' l'effetto non vale il disagio.
func _pop_in() -> void:
	if Settings.reduce_motion():
		return

	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.94, 0.94)
	_panel.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "scale", Vector2.ONE, POP_TIME)
	tween.tween_property(_panel, "modulate:a", 1.0, POP_TIME)


#endregion

#region Pulsanti


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_save_pressed() -> void:
	var report: Dictionary = SaveGame.save_now(get_tree())
	if not report.get("ok", false):
		_show_toast("Salvataggio non riuscito.")
		return

	# Se nessun nodo risponde, il file viene scritto lo stesso ma e' vuoto.
	# Meglio dirlo che far credere di aver salvato chissa' cosa.
	if int(report.get("nodes", 0)) > 0:
		_show_toast("Partita salvata.")
	else:
		_show_toast("Salvato, ma in questa scena non c'e' ancora niente da ricordare.")

	_refresh_status()


func _on_options_pressed() -> void:
	# La schermata delle impostazioni si mette sopra a questa e si gestisce da
	# sola. Il gioco resta fermo: e' lei a occuparsi di tutto.
	Settings.open_menu()


func _on_main_menu_pressed() -> void:
	_ask_confirmation("Tornare al menu principale?\nI progressi non salvati vanno persi.", func() -> void:
		main_menu_requested.emit()
	)


func _on_quit_pressed() -> void:
	# La conferma si puo' spegnere nelle impostazioni (Gioco → Chiedi conferma),
	# come per la voce "Esci" del menu principale.
	if not bool(Settings.get_value("game", "confirm_quit", true)):
		quit_requested.emit()
		return
	_ask_confirmation("Chiudere il gioco?\nI progressi non salvati vanno persi.", func() -> void:
		quit_requested.emit()
	)


#endregion

#region Conferma


func _ask_confirmation(question: String, action: Callable) -> void:
	_confirm_action = action
	_confirm_text.text = question
	_confirm_layer.visible = true

	# Il focus su "No": premere Invio per abitudine non deve chiudere niente.
	_focus_confirm_button("No")


func _on_confirm_yes() -> void:
	var action: Callable = _confirm_action
	_confirm_action = Callable()
	_confirm_layer.visible = false
	if action.is_valid():
		action.call()


func _on_confirm_no() -> void:
	_confirm_action = Callable()
	_confirm_layer.visible = false
	_focus_first()


#endregion

#region Testi


## Dice quanti nodi e quando: cosi' si vede se c'e' qualcosa da riprendere.
func _refresh_status() -> void:
	if not SaveGame.has_save():
		_status.text = "Nessun salvataggio."
		return

	var description: String = SaveGame.describe()
	if description.is_empty():
		_status.text = "C'e' un salvataggio."
	else:
		_status.text = "Ultimo salvataggio: %s." % description


func _show_toast(text: String) -> void:
	_toast.text = text
	var tween: Tween = create_tween()
	tween.tween_property(_toast, "modulate:a", 1.0, 0.12)
	tween.tween_interval(2.6)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


#endregion

#region Tastiera


func _unhandled_input(event: InputEvent) -> void:
	# Se le impostazioni sono aperte stanno loro sopra a tutto e Esc chiude
	# prima loro: qui non facciamo niente, o chiuderemmo due cose insieme.
	if Settings.is_menu_open():
		return

	if not event.is_action_pressed(&"ui_cancel"):
		return

	if _confirm_layer.visible:
		_on_confirm_no()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()


func _focus_first() -> void:
	if not _buttons.is_empty():
		_buttons[0].call_deferred("grab_focus")


func _focus_confirm_button(text: String) -> void:
	for node: Node in _confirm_layer.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if button != null and button.text == text:
			button.call_deferred("grab_focus")
			return


#endregion
