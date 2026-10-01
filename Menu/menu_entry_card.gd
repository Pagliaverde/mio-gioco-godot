## Una voce di menu che ha la forma di una carta del gioco.
##
## [b]Questa e' la carta del menu vero e proprio:[/b] c'e' un esemplare per ogni
## voce (Storia, Impostazioni, Esci...) e insieme formano il mazzo che tieni in
## mano. La carta decorativa che scorre sullo sfondo, se lo attivi, e' un'altra
## cosa e sta in [code]menu_card.gd[/code] ([MenuCard]).
##
## [b]Com'e' disegnata:[/b] in pixel art, da [MenuCardArt]: carta vecchia con
## crepe, macchie e bordi consumati. Ogni voce ha le sue crepe, sempre le stesse.
##
## [b]Cosa sa fare:[/b] disegnarsi, ricevere click e trascinamenti, e accendersi
## quando e' in cima al mazzo. [b]Non sa niente di posizioni:[/b] dove metterla
## e come animarla lo decide [MainMenu].
class_name MenuEntryCard extends Control


## Emesso quando il giocatore clicca questa carta (senza trascinarla).
signal card_pressed(card: MenuEntryCard)

## Emesso mentre il giocatore trascina la carta. [param offset] e' lo
## spostamento dal punto in cui l'ha presa.
signal card_dragged(card: MenuEntryCard, offset: Vector2)

## Emesso quando il giocatore lascia una carta che stava trascinando.
signal card_released(card: MenuEntryCard, offset: Vector2)


## Il font pixel del progetto. Se manca si usa quello di default.
const FONT_PATH := "res://GrapeSoda.ttf"

## Dopo quanti pixel un click diventa un trascinamento.
const DRAG_START := 6.0


## Un colore diverso per ogni voce, quando la voce non ne specifica uno.
##
## Viene dalla tavolozza del tema ([code]Settings.palette()[/code]): il
## giocatore la cambia nelle impostazioni, scheda Tema.
static func palette_color(position_in_list: int) -> Color:
	return Settings.palette_color(position_in_list)


# --- Dati della carta, impostati da MainMenu prima di aggiungerla all'albero ---

## Dimensione della carta, in pixel (prima della scala data dal mazzo).
var card_size: Vector2 = Vector2(300, 420)

## Il testo grande sulla carta (es. "Storia").
var title_text: String = "Voce"

## L'immagine sulla carta. Vuota: la carta mostra la lettera iniziale.
var art: Texture2D = null

## Il colore della voce: cielo dell'illustrazione, filetto e contorno.
var accent: Color = Color("c9772f")

## Se false la carta appare spenta e non si puo' scegliere.
var enabled: bool = true

## Colori della carta e usura, per [MenuCardArt]. Vuoto = quelli del tema.
var style: Dictionary = {}

## La posizione di questa voce nell'elenco. La usa [MainMenu] per i calcoli.
var index: int = 0

## Dimensione del titolo sulla carta.
var title_font_size: int = 32

# --- Stato visivo, guidato da MainMenu ---

## Quanto e' "accesa": 0 = spenta, 1 = in cima al mazzo. [MainMenu] la anima.
var accent_mix: float = 0.0

var _focused: bool = false
var _hovered: bool = false
var _built: bool = false

var _pressing: bool = false
var _dragging: bool = false
var _press_position: Vector2 = Vector2.ZERO

var _body: Control        # tutto il contenuto: si fa oscillare questo per il "no"
var _shadow: TextureRect
var _glow: TextureRect
var _face: TextureRect
var _art_clip: Control
var _art_rect: TextureRect
var _placeholder: Label
var _title_label: Label
var _tween: Tween


func _ready() -> void:
	_build()
	_apply_content()
	_apply_style()


#region Costruzione


## Costruisce l'aspetto della carta. Gira una volta sola.
func _build() -> void:
	if _built:
		return
	_built = true

	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	# Pixel art: niente sfocatura quando la carta viene ingrandita o ruotata.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	size = card_size
	custom_minimum_size = card_size
	pivot_offset = card_size * 0.5

	var px: float = float(MenuCardArt.PX)
	if style.is_empty():
		style = Settings.card_style()
	var ink: Color = style.get("ink", MenuCardArt.INK)
	var art_data: Dictionary = MenuCardArt.build(card_size, accent, _seed(), enabled, style)

	# Un unico figlio che contiene tutto. Serve per poter far oscillare la
	# carta ("non e' ancora pronto") senza toccare posizione, scala e
	# rotazione, che sono occupate dall'animazione del mazzo.
	_body = Control.new()
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	# --- Ombra: la sagoma della carta, nera, spostata in basso ---
	_shadow = _make_texture_rect(art_data["shadow"], Rect2(Vector2.ZERO, card_size))
	_body.add_child(_shadow)

	# --- Contorno di selezione: due anelli di pixel attorno alla carta ---
	_glow = _make_texture_rect(art_data["glow"], Rect2(-Vector2.ONE * px * 2.0, card_size + Vector2.ONE * px * 4.0))
	_body.add_child(_glow)

	# --- La carta ---
	_face = _make_texture_rect(art_data["face"], Rect2(Vector2.ZERO, card_size))
	_body.add_child(_face)

	# --- Illustrazione, ritagliata dentro il riquadro della carta ---
	var window: Rect2i = art_data["window"]
	_art_clip = Control.new()
	_art_clip.clip_contents = true
	_art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_clip.position = Vector2(window.position) * px + Vector2.ONE * px
	_art_clip.size = Vector2(window.size) * px - Vector2.ONE * px
	_body.add_child(_art_clip)

	_art_rect = TextureRect.new()
	_art_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_clip.add_child(_art_rect)

	# Se non c'e' immagine, al posto suo una grande lettera: si capisce subito
	# che li' andra' un disegno.
	_placeholder = _make_label(120)
	_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_placeholder.add_theme_color_override("font_outline_color", ink)
	_placeholder.add_theme_constant_override("outline_size", 14)
	_placeholder.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	_placeholder.add_theme_constant_override("shadow_offset_x", int(px))
	_placeholder.add_theme_constant_override("shadow_offset_y", int(px))
	_art_clip.add_child(_placeholder)

	# --- Titolo, sul cartiglio ---
	var plaque: Rect2i = art_data["plaque"]
	_title_label = _make_label(title_font_size)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Margine: il testo non deve finire sulle code a V del nastro.
	_title_label.position = Vector2(plaque.position) * px + Vector2(px * 6.0, px)
	_title_label.size = Vector2(plaque.size) * px - Vector2(px * 12.0, px * 2.0)
	_title_label.add_theme_color_override("font_color", ink)
	_title_label.add_theme_constant_override("line_spacing", -6)
	_body.add_child(_title_label)

	# --- Mouse ---
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func _make_texture_rect(texture: Texture2D, rect: Rect2) -> TextureRect:
	var tr: TextureRect = TextureRect.new()
	tr.texture = texture
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.position = rect.position
	tr.size = rect.size
	return tr


func _make_label(font_size: int) -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	# Il font della carta segue quello scelto nel tema.
	var font: Font = Settings.ui_font()
	if font != null:
		label.add_theme_font_override("font", font)
	return label


## Il seme delle crepe: dipende dalla voce, quindi ogni carta e' diversa ma
## resta sempre uguale a se stessa.
func _seed() -> int:
	return absi(title_text.hash()) + index * 7919


## Scrive testi e immagine nei nodi, e decide cosa mostrare.
func _apply_content() -> void:
	if not _built:
		return

	_title_label.text = title_text
	_fit_title()

	if art != null:
		_art_rect.texture = art
		_art_rect.visible = true
		_placeholder.visible = false
	else:
		_art_rect.visible = false
		_placeholder.visible = true
		_placeholder.text = _first_letter()


## Rimpicciolisce il titolo finche' non sta su una riga dentro il cartiglio.
##
## Sotto una certa misura smette e lascia andare a capo: meglio due righe
## leggibili che una riga minuscola.
func _fit_title() -> void:
	var font: Font = _title_label.get_theme_font("font")
	var font_size: int = title_font_size
	var width: float = _title_label.size.x
	while font_size > 18 and font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		font_size -= 1
	_title_label.add_theme_font_size_override("font_size", font_size)


## La prima lettera del titolo, in maiuscolo. Se il titolo e' vuoto, "?".
func _first_letter() -> String:
	var clean: String = title_text.strip_edges()
	if clean.is_empty():
		return "?"
	return clean.substr(0, 1).to_upper()


#endregion

#region Aspetto


## Accende o spegne l'evidenziazione della carta.
##
## La chiama [MainMenu] con [method Tween.tween_method], quindi deve accettare
## un solo numero: 0 = spenta, 1 = accesa.
func apply_accent(mix: float) -> void:
	accent_mix = clampf(mix, 0.0, 1.0)
	_apply_style()


## Dice alla carta se e' quella in cima al mazzo.
func set_focused(value: bool) -> void:
	_focused = value
	_apply_style()


## Ricalcola contorno e ombra in base allo stato attuale.
func _apply_style() -> void:
	if not _built:
		return

	var mix: float = accent_mix
	if _hovered and enabled:
		mix = maxf(mix, 0.35)

	var px: float = float(MenuCardArt.PX)
	var glow_color: Color = (accent if enabled else Color(0.6, 0.6, 0.6)).lightened(0.25)
	_glow.modulate = Color(glow_color, mix)

	# L'ombra si allunga quando la carta e' in cima: sembra che si alzi.
	_shadow.modulate = Color(0, 0, 0, lerpf(0.35, 0.55, mix))
	_shadow.position = Vector2(px, px * 2.0).lerp(Vector2(px * 2.0, px * 4.0), mix).snapped(Vector2.ONE * px)

	var letter: Color = accent.lightened(0.55) if enabled else Color(0.75, 0.75, 0.75)
	_placeholder.add_theme_color_override("font_color", letter)

	mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_FORBIDDEN
	)


#endregion

#region Animazione


## Fa oscillare la carta per dire "questa non e' ancora pronta".
##
## Muove solo [member _body]: posizione, scala e rotazione della carta restano
## libere per il mazzo, quindi le due animazioni non si pestano i piedi.
func shake() -> void:
	if not _built:
		return

	var base: Vector2 = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.tween_property(_body, "position", base + Vector2(14.0, 0.0), 0.05)
	tween.tween_property(_body, "position", base + Vector2(-14.0, 0.0), 0.10)
	tween.tween_property(_body, "position", base + Vector2(8.0, 0.0), 0.07)
	tween.tween_property(_body, "position", base, 0.05)


## Un breve tremolio: la carta "risponde" quando apre i suoi pulsanti.
##
## Ruota solo [member _body], attorno al centro, come [method shake].
func tremble() -> void:
	if not _built:
		return

	_body.pivot_offset = card_size * 0.5
	var tween: Tween = create_tween()
	for degrees: float in [2.5, -2.0, 1.5, -1.0, 0.0]:
		tween.tween_property(_body, "rotation", deg_to_rad(degrees), 0.04)


## Ferma l'animazione del mazzo in corso su questa carta.
func kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


## Registra l'animazione del mazzo, cosi' [method kill_tween] la trova.
func set_tween(tween: Tween) -> void:
	_tween = tween


#endregion

#region Mouse


func _on_mouse_entered() -> void:
	if not enabled:
		return
	_hovered = true
	_apply_style()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_style()


## Click e trascinamento.
##
## Un click senza movimento e' un "scegli"; se invece sposti il mouse di
## qualche pixel con il tasto premuto diventa un trascinamento, e la carta ti
## segue. Il mazzo decide poi, al rilascio, se mandarla in fondo.
func _on_gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_pressing = true
			_dragging = false
			_press_position = button.global_position
		elif _pressing:
			_pressing = false
			var offset: Vector2 = button.global_position - _press_position
			if _dragging:
				_dragging = false
				card_released.emit(self, offset)
			else:
				card_pressed.emit(self)
		accept_event()
		return

	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _pressing:
		var offset: Vector2 = motion.global_position - _press_position
		if not _dragging and offset.length() > DRAG_START:
			_dragging = true
		if _dragging:
			card_dragged.emit(self, offset)
		accept_event()


#endregion
