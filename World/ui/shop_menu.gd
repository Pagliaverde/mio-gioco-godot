## Il negozio: la merce a sinistra, l'anteprima a destra, i biglietti in alto.
##
## Vende quello che c'e' nel modello dati del gioco:
## - [b]battute[/b] ([CardData]): entrano nel repertorio ([method GameState.add_card]);
## - [b]maschere dei Bauli[/b] che non hai ancora ([MaskData]);
## - [b]oggetti[/b] ([method WorldData.items]): te', camomilla, fiori.
##
## Si chiude con [code]Esc[/code] o "Esci". Emette [signal closed].
class_name ShopMenu extends Control


signal closed()

var shop_id: StringName = &""

var _data: Dictionary = {}
var _list: VBoxContainer
var _preview: CenterContainer
var _detail: RichTextLabel
var _money: Label
var _message: Label
var _rows: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_data = WorldData.shop(shop_id)

	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0, 0, 0, 0.6)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 120
	panel.offset_right = -120
	panel.offset_top = 70
	panel.offset_bottom = -70
	add_child(panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	column.add_child(header)
	var title: Label = Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = str(_data.get("title", "Negozio"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_money = Label.new()
	_money.add_theme_font_size_override("font_size", Settings.font_size(32))
	_money.add_theme_color_override("font_color", Color(0.98, 0.8, 0.35))
	header.add_child(_money)

	var greeting: Label = Label.new()
	greeting.theme_type_variation = &"DimLabel"
	greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	greeting.text = str(_data.get("greeting", ""))
	column.add_child(greeting)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 30)
	column.add_child(body)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.3
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	body.add_child(right)
	_preview = CenterContainer.new()
	_preview.custom_minimum_size = Vector2(0, 360)
	right.add_child(_preview)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for kind: String in ["normal", "bold", "italics"]:
		_detail.add_theme_font_size_override(kind + "_font_size", Settings.font_size(22))
	right.add_child(_detail)

	var footer: HBoxContainer = HBoxContainer.new()
	column.add_child(footer)
	_message = Label.new()
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.add_theme_color_override("font_color", Color(0.98, 0.85, 0.5))
	footer.add_child(_message)
	var leave: Button = Button.new()
	leave.text = "Esci"
	leave.custom_minimum_size = Vector2(200, 56)
	leave.pressed.connect(_close)
	footer.add_child(leave)

	_build_rows()
	_refresh()


func _build_rows() -> void:
	for entry: Array in _data.get("stock", []):
		var kind: String = entry[0]
		var id: StringName = entry[1]
		var row: Dictionary = {"kind": kind, "id": id}
		match kind:
			"card":
				var card: CardData = CardLibrary.find_by_id(id)
				if card == null:
					continue
				row["name"] = card.display_name
				row["price"] = WorldData.card_price(card)
				row["sub"] = "Battuta · %s · costo %d" % [CardTypes.rarity_name(card.rarity), card.cost]
			"mask":
				var mask: MaskData = MaskLibrary.find_by_id(id)
				if mask == null:
					continue
				row["name"] = mask.display_name
				row["price"] = WorldData.MASK_PRICE
				row["sub"] = "Maschera · %s" % CardTypes.mask_gambit_name(mask.gambit)
			"item":
				var item: Dictionary = WorldData.item(id)
				if item.is_empty():
					continue
				row["name"] = item["name"]
				row["price"] = int(item["price"])
				row["sub"] = "Oggetto"
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 56)
		button.pressed.connect(_buy.bind(row))
		button.focus_entered.connect(_show.bind(row))
		button.mouse_entered.connect(_show.bind(row))
		_list.add_child(button)
		row["button"] = button
		_rows.append(row)
	if not _rows.is_empty():
		(_rows[0]["button"] as Button).call_deferred("grab_focus")
		_show(_rows[0])


func _refresh() -> void:
	_money.text = "%d %s" % [GameState.money, WorldData.MONEY_NAME]
	for row: Dictionary in _rows:
		var button: Button = row["button"]
		var owned: String = ""
		if row["kind"] == "mask" and GameState.has_mask(row["id"]):
			owned = "  (ce l'hai)"
		elif row["kind"] == "item" and GameState.item_count(row["id"]) > 0:
			owned = "  (ne hai %d)" % GameState.item_count(row["id"])
		elif row["kind"] == "card" and int(GameState.deck_extra.get(row["id"], 0)) > 0:
			owned = "  (+%d nel repertorio)" % int(GameState.deck_extra[row["id"]])
		button.text = "%s  —  %d%s" % [row["name"], row["price"], owned]
		button.disabled = row["kind"] == "mask" and GameState.has_mask(row["id"])
		button.modulate = Color(1, 1, 1) if GameState.money >= int(row["price"]) else Color(0.7, 0.65, 0.65)


func _show(row: Dictionary) -> void:
	for child: Node in _preview.get_children():
		child.queue_free()
	var lines: PackedStringArray = ["[b]%s[/b]   [color=#f5c86a]%d %s[/color]" % [row["name"], row["price"], WorldData.MONEY_NAME], "[i]%s[/i]" % row["sub"], ""]
	match row["kind"]:
		"card":
			var view: CardView = CardView.new()
			view.card_width = 230
			view.card_height = 320
			view.art_height = 120
			_preview.add_child(view)
			view.card = CardLibrary.find_by_id(row["id"])
			lines.append("Entra nel tuo repertorio: la pescherai nelle prossime scene. Dall'inventario (I) puoi metterla da parte.")
		"mask":
			var mask: MaskData = MaskLibrary.find_by_id(row["id"])
			var card: MaskCard = MaskCard.new()
			card.mask = mask
			card.card_size = Vector2(230, 322)
			_preview.add_child(card)
			lines.append(StoryWords.describe_mask(mask, "Una maschera dei Bauli di Scena. Comprarla vuol dire non aspettare il baule."))
		"item":
			lines.append(str(WorldData.item(row["id"]).get("text", "")))
	_detail.text = "\n".join(lines)


func _buy(row: Dictionary) -> void:
	var price: int = int(row["price"])
	if row["kind"] == "mask" and GameState.has_mask(row["id"]):
		_message.text = "Ce l'hai gia'."
		return
	if row["kind"] == "card" and not GameState.can_add_card(row["id"]):
		_message.text = "Il repertorio ne regge al massimo %d copie: e' una battuta rara." % GameState.card_limit(row["id"])
		return
	if not GameState.spend(price):
		_message.text = "Non ti bastano i biglietti."
		return
	match row["kind"]:
		"card":
			GameState.add_card(row["id"])
		"mask":
			GameState.gain_mask(row["id"])
		"item":
			GameState.add_item(row["id"])
	_message.text = "Comprato: %s." % row["name"]
	_refresh()


func _close() -> void:
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"inventory"):
		get_viewport().set_input_as_handled()
		_close()
