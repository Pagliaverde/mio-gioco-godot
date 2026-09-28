## Disegna una [CardData] come una carta vera: cornice, costo, arte, testo.
##
## [b]E' un nodo riutilizzabile:[/b] funziona nel gioco (per mostrare le carte
## al giocatore) e nell'editor (per l'anteprima del tool delle carte). E'
## [code]@tool[/code], quindi si aggiorna anche mentre modifichi la carta.
##
## Costruisce da sola i propri figli, cosi' non serve una scena complicata:
## basta aggiungerla e assegnare [member card].
##
## [codeblock]
##   var view := CardView.new()
##   add_child(view)
##   view.card = CardDatabase.load_default().find(&"fire_inferno")
## [/codeblock]
##
## La cornice usa il colore della rarita' definito in [RarityProfile], quindi
## cambiare la tabella delle rarita' cambia l'aspetto di tutte le carte.
@tool
class_name CardView extends PanelContainer


## Colori di ripiego se la tabella delle rarita' non e' disponibile.
const FALLBACK_RARITY_COLORS: Dictionary = {
	CardTypes.Rarity.BASE: Color(0.72, 0.72, 0.75),
	CardTypes.Rarity.RARE: Color(0.30, 0.55, 0.95),
	CardTypes.Rarity.EPIC: Color(0.65, 0.35, 0.90),
	CardTypes.Rarity.LEGENDARY: Color(0.95, 0.75, 0.20),
	CardTypes.Rarity.UNIQUE: Color(1.0, 0.42, 0.18),
}

## La carta da mostrare. Assegnala per aggiornare l'anteprima.
@export var card: CardData:
	set(value):
		card = value
		if _built:
			_refresh()


## Tabella delle rarita' da usare per i colori. Se null si usa quella di default.
@export var rarity_table: RarityTable:
	set(value):
		rarity_table = value
		_resolve_table()
		if _built:
			_refresh()

@export_group("Aspetto")

## Larghezza della carta in pixel.
@export_range(140, 500, 2) var card_width: int = 240

## Altezza della carta in pixel.
@export_range(180, 700, 2) var card_height: int = 340

## Altezza dell'illustrazione in pixel.
@export_range(40, 400, 2) var art_height: int = 130


var _built: bool = false
var _table: RarityTable

# --- Nodi costruiti in codice ---
var _panel_style: StyleBoxFlat
var _badge_style: StyleBoxFlat
var _name_label: Label
var _cost_label: Label
var _element_swatch: ColorRect
var _element_label: Label
var _art_box: Control
var _art_placeholder: ColorRect
var _art_image: TextureRect
var _art_hint: Label
var _rarity_label: Label
var _description_label: Label
var _tags_label: Label


func _ready() -> void:
	_ensure_built()
	_refresh()


## Ricostruisce l'anteprima. Chiamala dopo aver cambiato la carta a mano.
func refresh() -> void:
	_ensure_built()
	_refresh()


## Imposta la carta e aggiorna. Scorciatoia piu' esplicita del setter.
func show_card(value: CardData) -> void:
	card = value


func _resolve_table() -> void:
	_table = rarity_table
	if _table == null:
		_table = RarityTable.load_default()


## Il colore della cornice per una rarita'.
func _rarity_color(rarity: CardTypes.Rarity) -> Color:
	if _table != null:
		var profile: RarityProfile = _table.get_profile(rarity)
		if profile != null:
			return profile.border_color
	return FALLBACK_RARITY_COLORS.get(rarity, Color(0.6, 0.6, 0.6))


#region Costruzione


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	custom_minimum_size = Vector2(card_width, card_height)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# --- Cornice ---
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.09, 0.09, 0.12, 1.0)
	_panel_style.set_border_width_all(3)
	_panel_style.set_corner_radius_all(10)
	add_theme_stylebox_override("panel", _panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	# --- Riga superiore: nome + costo ---
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	column.add_child(top_row)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_font_size_override("font_size", 17)
	_name_label.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	top_row.add_child(_name_label)

	var badge: PanelContainer = PanelContainer.new()
	badge.custom_minimum_size = Vector2(38, 38)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_badge_style = StyleBoxFlat.new()
	_badge_style.bg_color = Color(0.16, 0.20, 0.34, 1.0)
	_badge_style.set_corner_radius_all(19)
	_badge_style.set_border_width_all(2)
	_badge_style.border_color = Color(0.45, 0.65, 1.0)
	badge.add_theme_stylebox_override("panel", _badge_style)
	top_row.add_child(badge)

	_cost_label = Label.new()
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.add_theme_font_size_override("font_size", 18)
	_cost_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	badge.add_child(_cost_label)

	# --- Riga elemento + rarita' ---
	var info_row: HBoxContainer = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 6)
	column.add_child(info_row)

	_element_swatch = ColorRect.new()
	_element_swatch.custom_minimum_size = Vector2(12, 12)
	_element_swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_row.add_child(_element_swatch)

	_element_label = Label.new()
	_element_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_element_label.add_theme_font_size_override("font_size", 13)
	info_row.add_child(_element_label)

	_rarity_label = Label.new()
	_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rarity_label.add_theme_font_size_override("font_size", 13)
	info_row.add_child(_rarity_label)

	# --- Illustrazione ---
	_art_box = Control.new()
	_art_box.custom_minimum_size = Vector2(0, art_height)
	_art_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_art_box)

	_art_placeholder = ColorRect.new()
	_art_placeholder.color = Color(0.14, 0.14, 0.18, 1.0)
	_art_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_box.add_child(_art_placeholder)

	_art_image = TextureRect.new()
	_art_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_box.add_child(_art_image)

	_art_hint = Label.new()
	_art_hint.text = "Nessuna immagine"
	_art_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_art_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_art_hint.add_theme_font_size_override("font_size", 12)
	_art_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.58))
	_art_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_box.add_child(_art_hint)

	# --- Descrizione ---
	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_description_label.add_theme_font_size_override("font_size", 13)
	_description_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	column.add_child(_description_label)

	# --- Tag ---
	_tags_label = Label.new()
	_tags_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tags_label.add_theme_font_size_override("font_size", 11)
	_tags_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	column.add_child(_tags_label)

	_resolve_table()


#endregion

#region Aggiornamento


func _refresh() -> void:
	if not _built:
		return

	custom_minimum_size = Vector2(card_width, card_height)
	_art_box.custom_minimum_size = Vector2(0, art_height)

	if card == null:
		_apply_empty_state()
		return

	var accent: Color = _rarity_color(card.rarity)

	_panel_style.border_color = accent
	_badge_style.bg_color = accent.darkened(0.72)
	_badge_style.border_color = accent

	_cost_label.text = "%d" % card.cost
	_cost_label.add_theme_color_override("font_color", accent.lightened(0.35))

	_name_label.text = card.display_name

	var element_color: Color = CardTypes.element_color(card.element)
	_element_swatch.color = element_color
	_element_label.text = CardTypes.element_name(card.element)
	_element_label.add_theme_color_override("font_color", element_color.lightened(0.15))

	_rarity_label.text = CardTypes.rarity_name(card.rarity)
	_rarity_label.add_theme_color_override("font_color", accent)

	var description: String = card.get_description()
	_description_label.text = description if not description.is_empty() else "(nessun effetto)"
	_description_label.add_theme_color_override("font_color",
		Color(0.85, 0.85, 0.9) if not description.is_empty() else Color(0.5, 0.5, 0.55))

	_tags_label.text = " ".join(card.tags) if not card.tags.is_empty() else ""

	if card.art != null:
		_art_image.texture = card.art
		_art_image.visible = true
		_art_hint.visible = false
		_art_placeholder.color = Color(0.14, 0.14, 0.18, 1.0)
	else:
		_art_image.texture = null
		_art_image.visible = false
		_art_hint.visible = true
		_art_placeholder.color = element_color.darkened(0.78)


func _apply_empty_state() -> void:
	_panel_style.border_color = Color(0.35, 0.35, 0.4)
	_badge_style.bg_color = Color(0.18, 0.18, 0.22)
	_badge_style.border_color = Color(0.4, 0.4, 0.45)
	_cost_label.text = "?"
	_cost_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_name_label.text = "Nessuna carta"
	_element_swatch.color = Color(0.3, 0.3, 0.35)
	_element_label.text = ""
	_rarity_label.text = ""
	_description_label.text = "Seleziona una carta per vederla qui."
	_tags_label.text = ""
	_art_image.texture = null
	_art_image.visible = false
	_art_hint.visible = true
	_art_placeholder.color = Color(0.13, 0.13, 0.17)


#endregion
