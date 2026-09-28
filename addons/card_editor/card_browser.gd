## Il dock "Carte" dell'editor: elenca, filtra, cerca, mostra e crea carte.
##
## [b]E' il modo comodo di lavorare sulle carte.[/b] Da qui puoi:
## [codeblock]
##   - cercare per id, nome o tag
##   - filtrare per elemento e rarita'
##   - vedere l'anteprima grafica della carta selezionata
##   - creare una carta nuova o duplicarne una esistente
##   - popolare i .tres dalla libreria in codice
##   - rigenerare l'indice e validare il bilanciamento
## [/codeblock]
##
## Ogni carta creata viene salvata in
## [code]res://Cards/data/cards/<elemento>/<id>.tres[/code], aggiunta
## all'indice e aperta nell'inspector.
##
## Si aggancia al dock tramite [code]plugin.gd[/code]: non va aperto a mano.
@tool
extends VBoxContainer


const CARD_VIEW_SCRIPT: Script = preload("res://Cards/ui/card_view.gd")

## Dove cercare le illustrazioni: un file per carta, chiamato come l'id.
##
## Convenzione: [code]res://Cards/art/<id>.png[/code]. Cosi' "fire_inferno"
## prende automaticamente "fire_inferno.png", senza trascinare nulla a mano.
const ART_DIR: String = "res://Cards/art"

## Estensioni accettate per le illustrazioni, in ordine di preferenza.
const ART_EXTENSIONS: PackedStringArray = ["png", "jpg", "jpeg", "webp", "svg"]

## Colori di ripiego per la lista, se la tabella delle rarita' non e' disponibile.
const FALLBACK_RARITY_COLORS: Dictionary = {
	CardTypes.Rarity.BASE: Color(0.72, 0.72, 0.75),
	CardTypes.Rarity.RARE: Color(0.45, 0.65, 1.0),
	CardTypes.Rarity.EPIC: Color(0.78, 0.55, 1.0),
	CardTypes.Rarity.LEGENDARY: Color(1.0, 0.85, 0.35),
	CardTypes.Rarity.UNIQUE: Color(1.0, 0.55, 0.30),
}

var _database: CardDatabase
var _table: RarityTable
var _updating: bool = false

# --- Interfaccia ---
var _search: LineEdit
var _element_filter: OptionButton
var _rarity_filter: OptionButton
var _sort_option: OptionButton
var _list: ItemList
var _preview: Control
var _info: Label
var _status: Label

# --- Finestra "nuova carta" ---
var _dialog: ConfirmationDialog
var _id_field: LineEdit
var _name_field: LineEdit
var _element_field: OptionButton
var _rarity_field: OptionButton
var _cost_field: SpinBox
var _dialog_source: CardData = null

## La carta attualmente mostrata in anteprima (per ricollegare il segnale "changed").
var _current_preview_card: CardData = null


func _ready() -> void:
	_database = CardDatabase.load_default()
	_table = RarityTable.load_default()

	_ensure_art_folder()
	_build_ui()
	_build_dialog()
	_refresh_list()


#region Costruzione interfaccia


func _build_ui() -> void:
	add_theme_constant_override("separation", 6)

	# --- Riga 1: ricerca e filtri ---
	var filters: HFlowContainer = HFlowContainer.new()
	filters.add_theme_constant_override("h_separation", 6)
	filters.add_theme_constant_override("v_separation", 4)
	add_child(filters)

	_search = LineEdit.new()
	_search.placeholder_text = "Cerca per id, nome o tag..."
	_search.custom_minimum_size = Vector2(160, 0)
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_text: String) -> void: _refresh_list())
	filters.add_child(_search)

	_element_filter = OptionButton.new()
	_fill_element_options(_element_filter, true)
	_element_filter.item_selected.connect(func(_i: int) -> void: _refresh_list())
	filters.add_child(_element_filter)

	_rarity_filter = OptionButton.new()
	_fill_rarity_options(_rarity_filter, true)
	_rarity_filter.item_selected.connect(func(_i: int) -> void: _refresh_list())
	filters.add_child(_rarity_filter)

	_sort_option = OptionButton.new()
	_sort_option.add_item("Ordina: costo", 0)
	_sort_option.add_item("Ordina: nome", 1)
	_sort_option.add_item("Ordina: rarita'", 2)
	_sort_option.item_selected.connect(func(_i: int) -> void: _refresh_list())
	filters.add_child(_sort_option)

	# --- Riga 2: azioni ---
	var actions: HFlowContainer = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 4)
	add_child(actions)

	_add_button(actions, "Assegna art", _on_assign_art)
	_add_button(actions, "Nuova carta", _on_new_card)
	_add_button(actions, "Duplica", _on_duplicate_card)
	_add_button(actions, "Popola .tres", _on_seed_from_library)
	_add_button(actions, "Ricarica da disco", _on_rebuild_index)
	_add_button(actions, "Valida", _on_validate)

	# --- Corpo: elenco + anteprima ---
	var split: HSplitContainer = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.split_offset = 190
	add_child(split)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Un minimo basso ma visibile: cosi' l'anteprima non puo' schiacciare
	# l'elenco fino a farlo sparire quando il dock e' piccolo.
	_list.custom_minimum_size = Vector2(0, 150)
	_list.allow_reselect = true
	_list.auto_height = false
	_list.item_selected.connect(_on_item_selected)
	_list.item_activated.connect(_on_item_activated)
	split.add_child(_list)

	var preview_box: VBoxContainer = VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 6)
	preview_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	split.add_child(preview_box)

	# Anteprima compatta: nel dock serve a riconoscere la carta a colpo d'occhio,
	# non a mostrarla a grandezza piena. Cosi' resta spazio per l'elenco.
	_preview = CARD_VIEW_SCRIPT.new()
	_preview.card_width = 190
	_preview.card_height = 250
	_preview.art_height = 92
	preview_box.add_child(_preview)

	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_font_size_override("font_size", 11)
	_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.78))
	preview_box.add_child(_info)

	# --- Stato ---
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", Color(0.62, 0.72, 0.62))
	add_child(_status)

	_update_status()


func _add_button(parent: Control, text: String, handler: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


func _fill_element_options(option: OptionButton, include_all: bool) -> void:
	option.clear()
	if include_all:
		option.add_item("Tutti gli elementi", -1)
	for raw_element: Variant in [
		CardTypes.Element.FIRE,
		CardTypes.Element.ICE,
		CardTypes.Element.POISON,
		CardTypes.Element.LIGHTNING,
		CardTypes.Element.NATURE,
		CardTypes.Element.DARK,
		CardTypes.Element.NONE,
	]:
		var element: CardTypes.Element = raw_element
		option.add_item(CardTypes.element_name(element), int(element))


func _fill_rarity_options(option: OptionButton, include_all: bool) -> void:
	option.clear()
	if include_all:
		option.add_item("Tutte le rarita'", -1)
	for raw_rarity: Variant in [
		CardTypes.Rarity.BASE,
		CardTypes.Rarity.RARE,
		CardTypes.Rarity.EPIC,
		CardTypes.Rarity.LEGENDARY,
		CardTypes.Rarity.UNIQUE,
	]:
		var rarity: CardTypes.Rarity = raw_rarity
		option.add_item(CardTypes.rarity_name(rarity), int(rarity))


#endregion

#region Finestra nuova carta


func _build_dialog() -> void:
	_dialog = ConfirmationDialog.new()
	_dialog.title = "Nuova carta"
	_dialog.ok_button_text = "Crea"
	_dialog.cancel_button_text = "Annulla"
	_dialog.min_size = Vector2i(440, 260)
	_dialog.confirmed.connect(_on_dialog_confirmed)
	add_child(_dialog)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	_dialog.add_child(grid)

	grid.add_child(_make_label("Id"))
	_id_field = LineEdit.new()
	_id_field.placeholder_text = "fire_inferno (minuscolo, underscore)"
	_id_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_id_field)

	grid.add_child(_make_label("Nome"))
	_name_field = LineEdit.new()
	_name_field.placeholder_text = "Inferno"
	_name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_name_field)

	grid.add_child(_make_label("Elemento"))
	_element_field = OptionButton.new()
	_fill_element_options(_element_field, false)
	grid.add_child(_element_field)

	grid.add_child(_make_label("Rarita'"))
	_rarity_field = OptionButton.new()
	_fill_rarity_options(_rarity_field, false)
	_rarity_field.item_selected.connect(func(_i: int) -> void: _apply_cost_for_rarity())
	grid.add_child(_rarity_field)

	grid.add_child(_make_label("Costo"))
	_cost_field = SpinBox.new()
	_cost_field.min_value = 1
	_cost_field.max_value = 60
	_cost_field.step = 1
	_cost_field.value = 10
	grid.add_child(_cost_field)


func _make_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	return label


## Quando cambia la rarita' nella finestra, propone il costo minimo della fascia.
func _apply_cost_for_rarity() -> void:
	if _table == null:
		return
	var rarity: CardTypes.Rarity = _rarity_field.get_selected_id()
	var profile: RarityProfile = _table.get_profile(rarity)
	if profile != null:
		_cost_field.value = profile.cost_min


## Apre la finestra. Con [param source] null crea una carta vuota,
## altrimenti prepara una copia della carta indicata.
func _open_dialog(source: CardData) -> void:
	_dialog_source = source

	if source == null:
		_dialog.title = "Nuova carta"
		_id_field.text = ""
		_name_field.text = ""
		_select_option_by_id(_element_field, int(CardTypes.Element.FIRE))
		_select_option_by_id(_rarity_field, int(CardTypes.Rarity.BASE))
		_apply_cost_for_rarity()
	else:
		_dialog.title = "Duplica '%s'" % source.display_name
		_id_field.text = "%s_copy" % source.id
		_name_field.text = "%s (copia)" % source.display_name
		_select_option_by_id(_element_field, int(source.element))
		_select_option_by_id(_rarity_field, int(source.rarity))
		_cost_field.value = source.cost

	_dialog.popup_centered(Vector2i(440, 260))
	_id_field.grab_focus()


func _select_option_by_id(option: OptionButton, id: int) -> void:
	for index: int in option.item_count:
		if option.get_item_id(index) == id:
			option.select(index)
			return


func _on_dialog_confirmed() -> void:
	var id_text: String = _id_field.text.strip_edges().to_lower().replace(" ", "_")
	if id_text.is_empty():
		_warn("L'id non puo' essere vuoto.")
		return
	if not _is_valid_id(id_text):
		_warn("Id '%s' non valido: usa minuscolo, numeri e underscore." % id_text)
		return
	if _database.has_id(StringName(id_text)):
		_warn("Esiste gia' una carta con id '%s'." % id_text)
		return

	var name_text: String = _name_field.text.strip_edges()
	if name_text.is_empty():
		name_text = id_text.capitalize()

	var card: CardData
	if _dialog_source != null:
		card = _duplicate_card(_dialog_source)
	else:
		card = CardData.new()

	card.id = StringName(id_text)
	card.display_name = name_text
	card.element = _element_field.get_selected_id()
	card.rarity = _rarity_field.get_selected_id()
	card.cost = int(_cost_field.value)

	# Se esiste gia' un'illustrazione con lo stesso nome dell'id, la aggancia subito.
	if card.art == null:
		card.art = _find_art_for(card)

	var path: String = CardDatabase.path_for_card(card)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())

	var error: Error = ResourceSaver.save(card, path)
	if error != OK:
		_warn("Impossibile salvare %s (codice %d)." % [path, error])
		return

	_database.add_card(card)
	_database.save_default()
	EditorInterface.get_resource_filesystem().scan()

	_refresh_list()
	_select_card(card)
	EditorInterface.edit_resource(card)

	_set_status("Creata '%s' in %s" % [card.display_name, path])


## Copia una carta, duplicando anche gli effetti (cosi' restano indipendenti).
func _duplicate_card(source: CardData) -> CardData:
	var copy: CardData = CardData.new()
	copy.display_name = source.display_name
	copy.description = source.description
	copy.cost = source.cost
	copy.element = source.element
	copy.rarity = source.rarity
	copy.tags = source.tags.duplicate()
	copy.art = source.art

	var effects: Array[CardEffect] = []
	for effect: CardEffect in source.effects:
		if effect != null:
			effects.append(effect.duplicate(true) as CardEffect)
	copy.effects = effects

	return copy


#endregion

#region Elenco e anteprima


func _refresh_list() -> void:
	if _list == null or _database == null:
		return

	_updating = true
	_list.clear()

	var cards: Array[CardData] = _filtered_cards()
	for card: CardData in cards:
		var index: int = _list.add_item("%3d  %s  (%s)" % [
			card.cost, card.display_name, CardTypes.rarity_name(card.rarity),
		])
		_list.set_item_metadata(index, card)
		_list.set_item_custom_fg_color(index, _rarity_color(card.rarity))
	_updating = false

	if cards.is_empty():
		_preview.card = null
		_info.text = ""
	else:
		_list.select(0)
		_show_card(cards[0])

	_update_status()


func _filtered_cards() -> Array[CardData]:
	var element_filter: int = _element_filter.get_selected_id()
	var rarity_filter: int = _rarity_filter.get_selected_id()
	var needle: String = _search.text.strip_edges().to_lower()

	var result: Array[CardData] = []
	for card: CardData in _database.cards:
		if card == null:
			continue
		if element_filter >= 0 and int(card.element) != element_filter:
			continue
		if rarity_filter >= 0 and int(card.rarity) != rarity_filter:
			continue
		if not needle.is_empty() and not _matches(card, needle):
			continue
		result.append(card)

	match _sort_option.get_selected_id():
		1:
			result.sort_custom(func(a: CardData, b: CardData) -> bool:
				return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
		2:
			result.sort_custom(func(a: CardData, b: CardData) -> bool:
				if a.rarity != b.rarity:
					return a.rarity > b.rarity
				return a.cost < b.cost)
		_:
			result.sort_custom(func(a: CardData, b: CardData) -> bool:
				if a.cost != b.cost:
					return a.cost < b.cost
				return a.display_name.naturalnocasecmp_to(b.display_name) < 0)

	return result


func _matches(card: CardData, needle: String) -> bool:
	if String(card.id).to_lower().contains(needle):
		return true
	if card.display_name.to_lower().contains(needle):
		return true
	for tag: String in card.tags:
		if tag.to_lower().contains(needle):
			return true
	return false


func _on_item_selected(index: int) -> void:
	if _updating:
		return
	var card: CardData = _list.get_item_metadata(index)
	_show_card(card)


func _on_item_activated(index: int) -> void:
	var card: CardData = _list.get_item_metadata(index)
	if card != null:
		EditorInterface.edit_resource(card)


func _show_card(card: CardData) -> void:
	# Ricollega il segnale "changed" alla carta in anteprima, cosi' l'anteprima
	# si aggiorna DA SOLA mentre modifichi gli effetti nell'inspector.
	if _current_preview_card != null and is_instance_valid(_current_preview_card):
		if _current_preview_card.changed.is_connected(_on_preview_card_changed):
			_current_preview_card.changed.disconnect(_on_preview_card_changed)

	_current_preview_card = card
	_preview.card = card

	if card != null and not card.changed.is_connected(_on_preview_card_changed):
		card.changed.connect(_on_preview_card_changed)

	_update_info(card)


## Chiamato quando la carta in anteprima viene modificata nell'inspector.
func _on_preview_card_changed() -> void:
	if _current_preview_card == null:
		return
	_preview.refresh()
	_update_info(_current_preview_card)
	_update_selected_row(_current_preview_card)


## Aggiorna il testo informativo sotto l'anteprima (potenza, efficienza, budget).
func _update_info(card: CardData) -> void:
	if card == null:
		_info.text = ""
		return

	var budget: float = 0.0
	if _table != null:
		budget = _table.power_budget(card.cost, card.rarity)

	var power: float = card.power_score()
	var ratio: String = "ok"
	if budget > 0.0:
		var delta: float = power / budget
		if delta > 1.25:
			ratio = "troppo forte per la rarita'"
		elif delta < 0.75:
			ratio = "debole per la rarita'"

	_info.text = "%s\nPotenza %.1f · Budget %.1f (%s)\nEfficienza %.2f · %s · %s" % [
		String(card.id),
		power,
		budget,
		ratio,
		card.efficiency(),
		CardTypes.element_name(card.element),
		CardTypes.rarity_name(card.rarity),
	]


## Riscrive la riga della carta nell'elenco, senza ricostruire tutto.
func _update_selected_row(card: CardData) -> void:
	if card == null:
		return
	for index: int in _list.item_count:
		if _list.get_item_metadata(index) != card:
			continue
		_list.set_item_text(index, "%3d  %s  (%s)" % [
			card.cost, card.display_name, CardTypes.rarity_name(card.rarity),
		])
		_list.set_item_custom_fg_color(index, _rarity_color(card.rarity))
		return


func _select_card(card: CardData) -> void:
	for index: int in _list.item_count:
		if _list.get_item_metadata(index) == card:
			_list.select(index)
			_show_card(card)
			return


#endregion

#region Azioni


func _on_new_card() -> void:
	_open_dialog(null)


func _on_duplicate_card() -> void:
	var selected: Array = _list.get_selected_items()
	if selected.is_empty():
		_warn("Seleziona prima una carta da duplicare.")
		return
	_open_dialog(_list.get_item_metadata(selected[0]))


## Materializza in .tres le carte definite in codice (solo la prima volta).
func _on_seed_from_library() -> void:
	var result: Dictionary = CardDatabase.seed_from_library()
	var written: int = int(result["written"])
	var skipped: int = int(result["skipped"])

	var found: int = _database.rebuild_from_folder()
	if found > 0:
		_database.save_default()
	EditorInterface.get_resource_filesystem().scan()
	_refresh_list()

	var message: String = "Popolate %d carte in .tres (indice: %d)." % [written, found]
	if skipped > 0:
		message += " %d carte esistevano gia' e NON sono state toccate." % skipped
		message += " Per sovrascriverle dal codice usa tools/generate_cards.gd."
	_set_status(message)


## Riscansiona la cartella e aggiorna l'indice.
##
## [b]Va premuto dopo aver eseguito generate_cards.gd[/b]: quello riscrive i
## .tres su disco, ma il dock continua a mostrare le copie in memoria finche'
## non ricarica. Questo pulsante rilegge tutto dal disco.
func _on_rebuild_index() -> void:
	var found: int = _database.rebuild_from_folder()
	if found == 0:
		_warn("Nessun .tres trovato: usa 'Popola .tres' per creare le carte dalla libreria.")
		return

	_database.save_default()

	# La carta in anteprima apparteneva alla vecchia versione delle risorse:
	# va staccata, o il dock resterebbe agganciato a un oggetto morto.
	_current_preview_card = null

	EditorInterface.get_resource_filesystem().scan()
	_refresh_list()
	_set_status("Indice ricaricato dal disco: %d carte. (I .tres sono la fonte di verita')" % found)


## Controlla tutte le carte contro il modello di potenza.
func _on_validate() -> void:
	var result: Dictionary = _database.validate(_table)
	print("")
	print(CardValidator.format_report(result, _table))
	print("")
	_update_status()
	_set_status("Validazione: %d carte, %d errori, %d avvisi. Vedi Output." % [
		result["checked"], result["errors"], result["warnings"],
	])


## Assegna le illustrazioni a tutte le carte, cercandole per nome nella cartella art.
##
## Basta mettere [code]res://Cards/art/fire_inferno.png[/code] e premere questo
## pulsante: nessun trascinamento a mano, una grafica per volta.
func _on_assign_art() -> void:
	var assigned: int = 0
	var missing: int = 0

	for card: CardData in _database.cards:
		if card == null:
			continue

		var texture: Texture2D = _find_art_for(card)
		if texture == null:
			missing += 1
			continue
		if card.art == texture:
			continue

		card.art = texture
		if not card.resource_path.is_empty():
			ResourceSaver.save(card, card.resource_path)
		assigned += 1

	_refresh_list()
	_set_status("Illustrazioni assegnate: %d. Carte senza immagine: %d. (File attesi in %s/<id>.png)" % [
		assigned, missing, ART_DIR,
	])


#endregion

#region Utility


## Crea la cartella delle illustrazioni, se non esiste.
func _ensure_art_folder() -> void:
	if not DirAccess.dir_exists_absolute(ART_DIR):
		DirAccess.make_dir_recursive_absolute(ART_DIR)


## Cerca l'illustrazione di una carta per nome file ([code]<id>.png[/code]).
## Ritorna null se non c'e' nessun file con quel nome.
func _find_art_for(card: CardData) -> Texture2D:
	if card == null or card.id == &"":
		return null

	for extension: String in ART_EXTENSIONS:
		var path: String = "%s/%s.%s" % [ART_DIR, card.id, extension]
		if ResourceLoader.exists(path):
			var resource: Resource = ResourceLoader.load(path)
			if resource is Texture2D:
				return resource as Texture2D

	return null


func _rarity_color(rarity: CardTypes.Rarity) -> Color:
	if _table != null:
		var profile: RarityProfile = _table.get_profile(rarity)
		if profile != null:
			return profile.border_color
	return FALLBACK_RARITY_COLORS.get(rarity, Color(0.7, 0.7, 0.7))


func _update_status() -> void:
	if _status == null or _database == null:
		return
	var counts: Dictionary = _database.count_by_rarity()
	_set_status("%d carte  ·  Base %d · Rara %d · Epica %d · Leggendaria %d · Unica %d" % [
		_database.size(),
		counts.get(CardTypes.Rarity.BASE, 0),
		counts.get(CardTypes.Rarity.RARE, 0),
		counts.get(CardTypes.Rarity.EPIC, 0),
		counts.get(CardTypes.Rarity.LEGENDARY, 0),
		counts.get(CardTypes.Rarity.UNIQUE, 0),
	])


func _set_status(text: String) -> void:
	if _status != null:
		_status.text = text


func _warn(text: String) -> void:
	push_warning(text)
	_set_status(text)


func _is_valid_id(text: String) -> bool:
	var regex: RegEx = RegEx.new()
	regex.compile("^[a-z0-9_]+$")
	return regex.search(text) != null


#endregion
