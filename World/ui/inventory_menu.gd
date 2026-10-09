## L'inventario ([code]I[/code]): gli oggetti da usare, le maschere (quale
## indossare contro le comparse) e il repertorio, con le battute comprate che
## si possono mettere da parte.
class_name InventoryMenu extends Control


signal closed()

var _tabs: TabContainer
var _items: VBoxContainer
var _masks: VBoxContainer
var _deck: VBoxContainer
var _status: Label
var _message: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0, 0, 0, 0.6)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 220
	panel.offset_right = -220
	panel.offset_top = 80
	panel.offset_bottom = -80
	add_child(panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var title: Label = Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = "Il baule del camerino"
	column.add_child(title)

	_status = Label.new()
	_status.theme_type_variation = &"DimLabel"
	column.add_child(_status)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tabs)
	_items = _tab("Oggetti")
	_masks = _tab("Maschere")
	_deck = _tab("Repertorio")

	var footer: HBoxContainer = HBoxContainer.new()
	column.add_child(footer)
	_message = Label.new()
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override("font_color", Color(0.98, 0.85, 0.5))
	footer.add_child(_message)
	var close_button: Button = Button.new()
	close_button.text = "Chiudi"
	close_button.custom_minimum_size = Vector2(200, 56)
	close_button.pressed.connect(func() -> void: closed.emit())
	footer.add_child(close_button)

	_refresh()
	close_button.call_deferred("grab_focus")


func _tab(tab_name: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	return box


func _refresh() -> void:
	_status.text = "%s   ·   Vita %d / %d   ·   %d %s" % [
		StoryWords.level_name(GameState.level), GameState.hp, GameState.max_hp, GameState.money, WorldData.MONEY_NAME,
	]
	for box: VBoxContainer in [_items, _masks, _deck]:
		for child: Node in box.get_children():
			child.queue_free()

	# --- Oggetti ---
	if GameState.items.is_empty():
		_note(_items, "Niente. I negozi vendono te', camomilla e fiori; le casse di attrezzeria a volte li nascondono.")
	for item_id: Variant in GameState.items:
		var data: Dictionary = WorldData.item(item_id)
		_row(_items, "%s  ×%d" % [data.get("name", item_id), GameState.item_count(item_id)], str(data.get("text", "")), "Usa", _use.bind(item_id))

	# --- Maschere ---
	var worn: StringName = GameState.worn_mask
	_row(_masks, "A volto scoperto" + ("  (indossata)" if worn == &"" else ""), "Nessuna regola, nessuna affinita'.", "Indossa", _wear.bind(&""), worn == &"")
	for mask: MaskData in GameState.owned_masks():
		var text: String = "%s: %s. %s" % [CardTypes.mask_gambit_name(mask.gambit), mask.affinity_text(), mask.drawback]
		_row(_masks, mask.display_name + ("  (indossata)" if worn == mask.id else ""), text, "Indossa", _wear.bind(mask.id), worn == mask.id)
	_note(_masks, "Con le comparse reciti con la maschera indossata. Con i boss la scegli ogni volta.")

	# --- Repertorio ---
	var deck: DeckData = GameState.build_deck()
	_note(_deck, "%d battute nel repertorio. Le battute comprate si possono mettere da parte e riprendere." % deck.card_count())
	for card_id: Variant in GameState.deck_extra:
		var card: CardData = CardLibrary.find_by_id(card_id)
		if card != null:
			_row(_deck, "%s  ×%d (comprata)" % [card.display_name, int(GameState.deck_extra[card_id])], card.get_description(), "Metti da parte", _shelve.bind(card_id, true))
	for card_id: Variant in GameState.deck_shelf:
		var card: CardData = CardLibrary.find_by_id(card_id)
		if card != null:
			_row(_deck, "%s  ×%d (da parte)" % [card.display_name, int(GameState.deck_shelf[card_id])], card.get_description(), "Riprendi", _shelve.bind(card_id, false))
	for entry: DeckEntry in CardLibrary.build_starter_deck().entries:
		if entry.card != null:
			_note(_deck, "%s  ×%d · costo %d" % [entry.card.display_name, entry.count, entry.card.cost])


func _row(box: VBoxContainer, title: String, text: String, action: String, callback: Callable, disabled: bool = false) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var labels: VBoxContainer = VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(labels)
	var name_label: Label = Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", Settings.font_size(24))
	labels.add_child(name_label)
	var text_label: Label = Label.new()
	text_label.theme_type_variation = &"DimLabel"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.text = text
	labels.add_child(text_label)
	var button: Button = Button.new()
	button.text = action
	button.disabled = disabled
	button.custom_minimum_size = Vector2(180, 48)
	button.pressed.connect(callback)
	row.add_child(button)


func _note(box: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.theme_type_variation = &"DimLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	box.add_child(label)


func _use(item_id: StringName) -> void:
	var result: String = GameState.use_item(item_id)
	_message.text = result if result != "" else "Non ne hai."
	_refresh()


func _wear(mask_id: StringName) -> void:
	GameState.wear(mask_id)
	_refresh()


func _shelve(card_id: StringName, to_shelf: bool) -> void:
	GameState.shelve_card(card_id, to_shelf)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"inventory"):
		get_viewport().set_input_as_handled()
		closed.emit()
