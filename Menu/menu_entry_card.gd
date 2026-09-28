## Una voce di menu che ha la forma di una carta del gioco.
##
## [b]Questa e' la carta del menu vero e proprio:[/b] c'e' un esemplare per ogni
## voce (Storia, Impostazioni, Esci...) e insieme formano il carosello.
## La carta decorativa che scorre sullo sfondo, se lo attivi, e' un'altra cosa
## e sta in [code]menu_card.gd[/code] ([MenuCard]).
##
## [b]Cosa sa fare:[/b] disegnarsi, ricevere i click, e accendersi quando viene
## selezionata. [b]Non sa niente di posizioni:[/b] dove metterla e come
## animarla lo decide [MainMenu]. Cosi' la carta resta semplice e il movimento
## sta tutto in un posto solo.
class_name MenuEntryCard extends Control


## Emesso quando il giocatore clicca questa carta.
signal card_pressed(card: MenuEntryCard)


## Il colore del testo sulle carte (le carte sono chiare).
const DARK_TEXT := Color(0.13, 0.14, 0.19)

## Il fondo della carta.
const CARD_BG := Color(0.97, 0.96, 0.93)

## Il bordo della carta quando non e' selezionata.
const CARD_BORDER := Color(0.70, 0.70, 0.75)

## Il fondo di una carta spenta.
const CARD_BG_DISABLED := Color(0.66, 0.66, 0.70)

## Il colore di bordo di una carta spenta.
const ACCENT_DISABLED := Color(0.55, 0.56, 0.62)


## Un colore diverso per ogni voce, quando la voce non ne specifica uno.
##
## Serve a far risaltare ogni carta: se fossero tutte uguali il carosello
## sarebbe piatto. Se vuoi il tuo colore, compila il campo [b]Accent[/b] della
## [MenuAction].
static func palette_color(position_in_list: int) -> Color:
	var palette: Array = [
		Color(0.98, 0.62, 0.25),  # ambra
		Color(0.35, 0.68, 0.95),  # azzurro
		Color(0.45, 0.78, 0.42),  # verde
		Color(0.72, 0.45, 0.90),  # viola
		Color(0.95, 0.45, 0.45),  # rosso
		Color(0.95, 0.80, 0.30),  # giallo
		Color(0.35, 0.80, 0.78),  # turchese
		Color(0.95, 0.55, 0.75),  # rosa
	]
	var picked: Color = palette[posmod(position_in_list, palette.size())]
	return picked


# --- Dati della carta, impostati da MainMenu prima di aggiungerla all'albero ---

## Dimensione della carta, in pixel (prima della scala data dal carosello).
var card_size: Vector2 = Vector2(300, 420)

## Il testo grande sulla carta (es. "Storia").
var title_text: String = "Voce"

## L'immagine sulla carta. Vuota: la carta mostra solo il titolo su un fondo
## tinto del colore della voce.
var art: Texture2D = null

## Il colore del bordo e dell'evidenziazione.
var accent: Color = Color(0.98, 0.62, 0.25)

## Se false la carta appare spenta e non si puo' scegliere.
var enabled: bool = true

## La posizione di questa voce nell'elenco. La usa [MainMenu] per i calcoli.
var index: int = 0

## Dimensione del titolo sulla carta.
var title_font_size: int = 32

# --- Stato visivo, guidato da MainMenu ---

## Quanto e' "accesa": 0 = spenta, 1 = selezionata. [MainMenu] la anima.
var accent_mix: float = 0.0

var _focused: bool = false
var _hovered: bool = false
var _built: bool = false

var _body: Control        # tutto il contenuto: si fa oscillare questo per il "no"
var _frame: Panel
var _style: StyleBoxFlat
var _art_area: Control
var _art_rect: TextureRect
var _art_tint: ColorRect
var _placeholder: Label
var _title_band: PanelContainer
var _band_style: StyleBoxFlat
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

	size = card_size
	custom_minimum_size = card_size
	pivot_offset = card_size * 0.5

	# Un unico figlio che contiene tutto. Serve per poter far oscillare la
	# carta ("non e' ancora pronto") senza toccare posizione, scala e
	# rotazione, che sono occupate dall'animazione del carosello.
	_body = Control.new()
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	# --- Cornice ---
	_frame = Panel.new()
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = StyleBoxFlat.new()
	_style.corner_radius_top_left = 18
	_style.corner_radius_top_right = 18
	_style.corner_radius_bottom_left = 18
	_style.corner_radius_bottom_right = 18
	_style.anti_aliasing = true
	_frame.add_theme_stylebox_override("panel", _style)
	_body.add_child(_frame)

	# --- Margine interno ---
	var inset: MarginContainer = MarginContainer.new()
	inset.set_anchors_preset(Control.PRESET_FULL_RECT)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_theme_constant_override("margin_left", 10)
	inset.add_theme_constant_override("margin_top", 10)
	inset.add_theme_constant_override("margin_right", 10)
	inset.add_theme_constant_override("margin_bottom", 10)
	_body.add_child(inset)

	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
	inset.add_child(column)

	# --- Area dell'illustrazione ---
	# [b]Un solo riquadro[/b] nel VBox, che contiene tre cose [b]sovrapposte[/b]:
	# l'immagine, un velo del colore della voce sopra di essa, e la lettera
	# segnaposto. Devono stare una sopra l'altra, non una sotto l'altra: se le
	# mettessimo tutte e tre come figlie del VBox finirebbero impilate in
	# colonna, e l'immagine sarebbe alta un terzo della carta.
	_art_area = Control.new()
	_art_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_art_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_art_area)

	_art_rect = TextureRect.new()
	_art_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_area.add_child(_art_rect)

	# Velo del colore della voce sopra l'immagine: rende le carte diverse tra
	# loro anche se l'illustrazione e' la stessa, e tiene la figura un po'
	# in secondo piano rispetto al testo.
	_art_tint = ColorRect.new()
	_art_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_area.add_child(_art_tint)

	# Se non c'e' immagine, al posto suo mostriamo una grande lettera sbiadita:
	# si capisce subito che li' andra' un disegno.
	_placeholder = Label.new()
	_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placeholder.add_theme_font_size_override("font_size", 120)
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_area.add_child(_placeholder)

	# --- Fascia del titolo ---
	# Sempre chiara: cosi' il titolo si legge sia su una foto chiara sia su
	# una scura. E' l'unica parte che non dipende dall'immagine.
	_title_band = PanelContainer.new()
	_title_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band_style = StyleBoxFlat.new()
	_band_style.corner_radius_top_left = 10
	_band_style.corner_radius_top_right = 10
	_band_style.corner_radius_bottom_left = 10
	_band_style.corner_radius_bottom_right = 10
	_band_style.content_margin_left = 12
	_band_style.content_margin_right = 12
	_band_style.content_margin_top = 12
	_band_style.content_margin_bottom = 12
	_title_band.add_theme_stylebox_override("panel", _band_style)
	column.add_child(_title_band)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.custom_minimum_size = Vector2(0, 62)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_band.add_child(_title_label)

	# --- Mouse ---
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


## Scrive testi e immagine nei nodi, e decide cosa mostrare.
func _apply_content() -> void:
	if not _built:
		return

	_title_label.text = title_text
	_title_label.add_theme_font_size_override("font_size", title_font_size)

	if art != null:
		_art_rect.texture = art
		_art_rect.visible = true
		_placeholder.visible = false
		_art_tint.visible = true
	else:
		# Nessuna immagine: fondo tinto + la lettera iniziale in grande.
		_art_rect.visible = false
		_placeholder.visible = true
		_art_tint.visible = true
		_placeholder.text = _first_letter()


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


## Dice alla carta se e' quella selezionata.
func set_focused(value: bool) -> void:
	_focused = value
	_apply_style()


## Ricalcola colori e spessori in base allo stato attuale.
##
## Tutto passa da qui: cosi' l'aspetto della carta dipende sempre solo da
## [member accent_mix], [member _focused] e [member _hovered], e non ci sono
## due pezzi di codice che litigano sugli stessi colori.
func _apply_style() -> void:
	if not _built:
		return

	var a: Color = accent if enabled else ACCENT_DISABLED
	var mix: float = accent_mix

	# Il passaggio del mouse da' un accenno di evidenziazione, ma non deve
	# mai rubare il posto alla selezione vera.
	if _hovered and not _focused and enabled:
		mix = maxf(mix, 0.35)

	# --- Cornice ---
	_style.bg_color = CARD_BG if enabled else CARD_BG_DISABLED
	_style.border_color = CARD_BORDER.lerp(a, mix)
	var width: int = int(round(lerpf(2.0, 7.0, mix)))
	_style.border_width_left = width
	_style.border_width_top = width
	_style.border_width_right = width
	_style.border_width_bottom = width

	# L'ombra: e' quella che fa "alzare" la carta selezionata dal piano.
	_style.shadow_color = Color(0.0, 0.0, 0.0, lerpf(0.30, 0.55, mix))
	_style.shadow_size = int(round(lerpf(12.0, 30.0, mix)))
	_style.shadow_offset = Vector2(0.0, lerpf(7.0, 14.0, mix))

	# --- Fascia del titolo ---
	# Parte quasi bianca e prende il colore della voce man mano che si accende.
	var band: Color = Color(1.0, 0.99, 0.96, 0.92).lerp(Color(a.r, a.g, a.b, 1.0), mix * 0.75)
	_band_style.bg_color = band
	_title_label.add_theme_color_override("font_color", DARK_TEXT)

	# --- Fondo dell'illustrazione ---
	_art_tint.color = Color(a.r, a.g, a.b, lerpf(0.30, 0.06, mix))
	_placeholder.add_theme_color_override("font_color", Color(a.r, a.g, a.b, lerpf(0.35, 0.55, mix)))

	mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_FORBIDDEN
	)


#endregion

#region Animazione


## Fa oscillare la carta per dire "questa non e' ancora pronta".
##
## Muove solo [member _body], la cornice interna: posizione, scala e rotazione
## della carta restano libere per il carosello, quindi le due animazioni non
## si pestano i piedi.
func shake() -> void:
	if not _built:
		return

	var base: Vector2 = _body.position
	var tween: Tween = create_tween()
	tween.tween_property(_body, "position", base + Vector2(14.0, 0.0), 0.05)
	tween.tween_property(_body, "position", base + Vector2(-14.0, 0.0), 0.10)
	tween.tween_property(_body, "position", base + Vector2(8.0, 0.0), 0.07)
	tween.tween_property(_body, "position", base, 0.05)


## Ferma l'animazione del carosello in corso su questa carta.
func kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


## Registra l'animazione del carosello, cosi' [method kill_tween] la trova.
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


func _on_gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null:
		return
	if click.button_index != MOUSE_BUTTON_LEFT or not click.pressed:
		return

	card_pressed.emit(self)
	accept_event()


#endregion
