## Una carta decorativa che scorre sullo sfondo del menu.
##
## [b]Non e' una carta giocabile.[/b] E' solo un elemento visivo: mostra un
## bordo colorato secondo l'elemento, il nome, il costo e (se ce l'ha)
## un'immagine.
##
## [b]Per mettere le immagini:[/b] assegna una texture a [member art] su una
## [CardData] (campo [b]Art[/b]), oppure imposta [member MenuCardBackdrop.card_back]
## con una texture unica per tutte le carte. Vedi [code]Menu/README.md[/code].
##
## La UI viene costruita in codice per due motivi:
## 1. non si puo' rompere per un errore di formattazione in un file .tscn
## 2. tutti i valori regolabili stanno nell'inspector di [MenuCardBackdrop]
class_name MenuCard extends Control


## Dimensione della carta in pixel (prima della scala applicata dal backdrop).
var card_size: Vector2 = Vector2(190, 265)

## L'immagine mostrata sulla carta. Vuota = carta "lisciata" col colore elemento.
var art: Texture2D = null

## L'elemento, che decide il colore del bordo.
var element: CardTypes.Element = CardTypes.Element.NONE

## Il nome mostrato in basso.
var display_name: String = ""

## Il costo mostrato in alto.
var cost: int = 0

## Quanto e' "opaca" la carta. Il backdrop la abbassa per le carte lontane.
var card_opacity: float = 1.0

# --- Parametri di scorrimento (li applica il backdrop) ---

## Pixels al secondo verso sinistra. Le carte lontane si muovono piu' piano.
var drift_speed: float = 60.0

## Ampiezza dell'oscillazione verticale, in pixel.
var bob_amplitude: float = 0.0

## Sfasamento dell'oscillazione, cosi' le carte non ondeggiano all'unisono.
var bob_phase: float = 0.0

## La Y attorno a cui la carta oscilla. La imposta [MenuCardBackdrop]
## quando piazza la carta, cosi' l'oscillazione non si accumula nel tempo.
var base_y: float = 0.0

var _built: bool = false

# Riferimenti ai figli, per aggiornarli dopo la costruzione.
var _frame: Panel
var _art_rect: TextureRect
var _name_label: Label
var _cost_label: Label
var _placeholder: Label


func _ready() -> void:
	_build_ui()
	_apply_visuals()


## Costruisce l'aspetto della carta. Chiamato una volta sola.
func _build_ui() -> void:
	if _built:
		return
	_built = true

	# La carta non deve intercettare i click: sotto ci sono i pulsanti del menu.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

	size = card_size
	custom_minimum_size = card_size
	pivot_offset = card_size * 0.5

	# --- Cornice ---
	_frame = Panel.new()
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	# --- Margine interno ---
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	# --- Costo ---
	_cost_label = _make_label(26, HORIZONTAL_ALIGNMENT_LEFT)
	_cost_label.add_theme_color_override("font_color", Color(0.16, 0.18, 0.24))
	column.add_child(_cost_label)

	# --- Immagine (oppure il segnaposto col nome) ---
	_art_rect = TextureRect.new()
	_art_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_art_rect)

	_placeholder = _make_label(20, HORIZONTAL_ALIGNMENT_CENTER)
	_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_placeholder.add_theme_color_override("font_color", Color(0.20, 0.22, 0.28))
	_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_placeholder)

	# --- Nome ---
	_name_label = _make_label(19, HORIZONTAL_ALIGNMENT_CENTER)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_color_override("font_color", Color(0.14, 0.15, 0.20))
	column.add_child(_name_label)


## Crea una Label con lo stile coerente.
func _make_label(font_size: int, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Riempie la carta a partire da una [CardData] del gioco.
##
## Cosi' le carte del menu sono le [b]vere[/b] carte del gioco: se cambi il nome
## di "Inferno", cambia anche sullo sfondo del menu.
func setup_from_data(data: CardData) -> void:
	if data == null:
		return
	art = data.art
	element = data.element
	display_name = data.display_name
	cost = data.cost
	_apply_visuals()


## Imposta solo l'aspetto, senza una [CardData].
func setup_plain(card_name: String, card_cost: int, card_element: CardTypes.Element) -> void:
	display_name = card_name
	cost = card_cost
	element = card_element
	_apply_visuals()


## Imposta l'immagine (usata quando il backdrop ha una texture unica).
func set_art(texture: Texture2D) -> void:
	art = texture
	_apply_visuals()


## Applica colori, testi e immagine ai nodi.
func _apply_visuals() -> void:
	if not _built:
		return

	var accent: Color = CardTypes.element_color(element)

	# --- Cornice: carta chiara con bordo del colore dell'elemento ---
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.96, 0.93)
	style.border_color = accent
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 5
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	_frame.add_theme_stylebox_override("panel", style)

	# --- Testi ---
	_cost_label.text = str(cost)
	_name_label.text = display_name

	# --- Immagine o segnaposto ---
	if art != null:
		_art_rect.texture = art
		_art_rect.visible = true
		_placeholder.visible = false
	else:
		# Nessuna immagine: mostriamo un segnaposto riconoscibile cosi' si
		# capisce subito dove andra' l'illustrazione.
		_art_rect.visible = false
		_placeholder.visible = true
		_placeholder.text = display_name.to_upper()
		_placeholder.add_theme_color_override("font_color", accent.darkened(0.25))

	modulate.a = card_opacity


func _to_string() -> String:
	return "<MenuCard '%s' (%d)>" % [display_name, cost]
