## Prima di una scena con un boss: quale maschera indossi?
##
## Come nella storia ([code]StoryDirector._pick_mask[/code]): una maschera per
## incontro, oppure "a volto scoperto". A sinistra le maschere che hai, a
## destra quella scelta, grande, con le sue regole.
##
## [code]← →[/code] cambiano, [code]Invio[/code] conferma, oppure click.
class_name MaskPicker extends Control


signal _picked(index: int)

## Se true sceglie da solo (controlli senza finestra): la maschera indossata.
var auto_pilot: bool = false

var _options: Array[MaskData] = []
var _selected: int = 0
var _cards: Array[MaskCard] = []
var _big_slot: CenterContainer
var _text: RichTextLabel
var _title: Label
var _flow: HFlowContainer
var _enemy_name: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = Color("120c1a")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 56)
	add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	margin.add_child(column)

	_title = Label.new()
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 40)
	column.add_child(row)

	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 20)
	row.add_child(left)

	_big_slot = CenterContainer.new()
	_big_slot.custom_minimum_size = Vector2(0, 340)
	left.add_child(_big_slot)

	_flow = HFlowContainer.new()
	_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_flow.add_theme_constant_override("h_separation", 10)
	_flow.add_theme_constant_override("v_separation", 10)
	left.add_child(_flow)

	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(panel)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	for kind: String in ["normal", "bold", "italics"]:
		_text.add_theme_font_size_override(kind + "_font_size", Settings.font_size(26))
	_text.add_theme_color_override("default_color", Settings.color("text"))
	panel.add_child(_text)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	column.add_child(buttons)
	for entry: Array in [["◀ Maschera prima", -1], ["Recita", 0], ["Maschera dopo ▶", 1]]:
		var button: Button = Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(260, 64)
		button.pressed.connect(_on_button.bind(int(entry[1])))
		buttons.add_child(button)
		if int(entry[1]) == 0:
			button.call_deferred("grab_focus")


## Mostra le maschere e aspetta la scelta. [param preferred] e' quella
## selezionata all'inizio (di solito quella indossata).
func pick(masks: Array[MaskData], enemy_name: String, preferred: MaskData = null) -> MaskData:
	_enemy_name = enemy_name
	_title.text = "La scena con %s. Che volto porti?" % enemy_name
	_options = [null]
	_options.append_array(masks)
	_selected = 0
	for i: int in _options.size():
		if preferred != null and _options[i] != null and _options[i].id == preferred.id:
			_selected = i
	if preferred == null and _options.size() > 1:
		_selected = _options.size() - 1

	for i: int in _options.size():
		var card: MaskCard = MaskCard.new()
		card.mask = _options[i]
		card.card_size = Vector2(120, 168)
		card.title_font_size = 14
		card.pressed.connect(func(_card: MaskCard) -> void: _select(i))
		_flow.add_child(card)
		_cards.append(card)
	_select(_selected)

	if auto_pilot:
		call_deferred("emit_signal", "_picked", _selected)
	var index: int = await _picked
	return _options[index]


func _select(index: int) -> void:
	_selected = posmod(index, _options.size())
	for i: int in _cards.size():
		_cards[i].selected = i == _selected
	for child: Node in _big_slot.get_children():
		child.queue_free()
	var big: MaskCard = MaskCard.new()
	big.mask = _options[_selected]
	big.card_size = Vector2(230, 322)
	_big_slot.add_child(big)
	var chosen: MaskData = _options[_selected]
	if chosen == null:
		_text.text = "[b]A volto scoperto.[/b]\n\nNessuna regola, nessuna affinita': valgono le regole normali e tutte le sinergie."
	else:
		_text.text = StoryWords.describe_mask(chosen, "Per la scena con %s indossi [b]%s[/b]." % [_enemy_name, chosen.display_name])


func _on_button(delta: int) -> void:
	if delta == 0:
		_picked.emit(_selected)
	else:
		_select(_selected + delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"left"):
		_select(_selected - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"right"):
		_select(_selected + 1)
		get_viewport().set_input_as_handled()
