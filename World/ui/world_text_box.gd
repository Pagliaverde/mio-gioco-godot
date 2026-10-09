## Il riquadro dei testi del mondo, in basso come nei giochi di ruolo: il nome
## di chi parla, il testo che compare lettera per lettera, una freccia che
## lampeggia quando si puo' andare avanti, e i pulsanti quando c'e' da scegliere.
##
## [codeblock]
## var index: int = await text_box.page("Vuoi aprirlo?", ["Si'", "No"])
## [/codeblock]
## [code]Invio[/code], [code]Spazio[/code], [code]E[/code] o un click: il primo
## completa il testo, il secondo va avanti. Sopra al riquadro puo' comparire
## un'immagine ([method show_picture]): una maschera, un cartello.
class_name WorldTextBox extends CanvasLayer


## Interno: il giocatore ha scelto.
signal _chosen(index: int)

## Se true sceglie sempre il primo pulsante (controlli senza finestra).
var auto_pilot: bool = false

var _root: Control
var _panel: PanelContainer
var _speaker: Label
var _text: RichTextLabel
var _arrow: Label
var _buttons: VBoxContainer
var _picture: CenterContainer
var _reveal: Tween = null
var _open: bool = false
var _single: bool = true


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_picture = CenterContainer.new()
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.offset_bottom = -330
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_picture)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 140
	_panel.offset_right = -140
	_panel.offset_top = -300
	_panel.offset_bottom = -36
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.05, 0.1, 0.94)
	style.border_color = Color(0.79, 0.64, 0.29)
	style.set_border_width_all(4)
	style.set_corner_radius_all(2)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 22
	style.content_margin_bottom = 20
	style.anti_aliasing = false
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", style)
	_panel.gui_input.connect(_on_panel_input)
	_root.add_child(_panel)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_panel.add_child(row)

	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)

	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", Settings.font_size(26))
	_speaker.add_theme_color_override("font_color", Color(0.98, 0.82, 0.45))
	column.add_child(_speaker)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	for kind: String in ["normal", "bold", "italics"]:
		_text.add_theme_font_size_override(kind + "_font_size", Settings.font_size(28))
	_text.add_theme_color_override("default_color", Color(0.96, 0.93, 0.88))
	column.add_child(_text)

	_arrow = Label.new()
	_arrow.text = "▼"
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_arrow.add_theme_color_override("font_color", Color(0.98, 0.82, 0.45))
	column.add_child(_arrow)
	var blink: Tween = _arrow.create_tween().set_loops()
	blink.tween_property(_arrow, "modulate:a", 0.2, 0.45)
	blink.tween_property(_arrow, "modulate:a", 1.0, 0.45)

	_buttons = VBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 10)
	row.add_child(_buttons)


func is_open() -> bool:
	return _open


## Mostra una pagina e aspetta. Ritorna l'indice del pulsante scelto (0 se
## c'era solo "Continua").
func page(text: String, buttons: Array = [], speaker: String = "") -> int:
	if auto_pilot:
		print("[mondo] %s%s" % [(speaker + ": ") if speaker != "" else "", text.left(70).replace("\n", " ")])
	_open = true
	_root.visible = true
	_speaker.text = speaker
	_speaker.visible = speaker != ""
	_show_text(text)

	for child: Node in _buttons.get_children():
		child.queue_free()
	_single = buttons.size() <= 1
	_buttons.visible = not _single
	if not _single:
		for i: int in buttons.size():
			var button: Button = Button.new()
			button.text = str(buttons[i])
			button.custom_minimum_size = Vector2(260, 58)
			button.pressed.connect(_choose.bind(i))
			_buttons.add_child(button)
		(_buttons.get_child(0) as Button).call_deferred("grab_focus")

	if auto_pilot:
		call_deferred("_choose", 0)
	var index: int = await _chosen
	return index


## Chiude il riquadro (e toglie l'immagine).
func close() -> void:
	_open = false
	_root.visible = false
	clear_picture()


## Un'immagine sopra il riquadro (una maschera, un cartello). Sostituisce
## quella che c'era.
func show_picture(node: Control) -> void:
	clear_picture()
	_picture.add_child(node)
	node.modulate.a = 0.0
	node.scale = Vector2(0.6, 0.6)
	node.pivot_offset = node.custom_minimum_size * 0.5
	var tween: Tween = node.create_tween().set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, 0.25 * Settings.motion_scale())
	tween.tween_property(node, "scale", Vector2.ONE, 0.35 * Settings.motion_scale()).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func clear_picture() -> void:
	for child: Node in _picture.get_children():
		child.queue_free()


func _show_text(text: String) -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
	_text.text = text
	_text.visible_ratio = 0.0
	_arrow.visible = false
	var seconds: float = float(_text.get_total_character_count()) * 0.022 / Settings.text_speed()
	if Settings.reduce_motion() or auto_pilot:
		seconds = 0.0
	_reveal = create_tween()
	_reveal.tween_property(_text, "visible_ratio", 1.0, seconds)
	_reveal.finished.connect(func() -> void: _arrow.visible = _single)


func _revealing() -> bool:
	return _reveal != null and _reveal.is_running()


func _complete_reveal() -> void:
	_reveal.kill()
	_text.visible_ratio = 1.0
	_arrow.visible = _single


func _choose(index: int) -> void:
	if not _open:
		return
	if _revealing() and not auto_pilot:
		_complete_reveal()
		return
	_chosen.emit(index)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	var advance: bool = event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact")
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _revealing():
		_complete_reveal()
	elif _single:
		_choose(0)


func _on_panel_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		if _revealing():
			_complete_reveal()
		elif _single:
			_choose(0)
