## Costruisce il [Theme] di tutto il gioco a partire dai colori scelti.
##
## [b]Perche' un Theme:[/b] [Settings] lo assegna alla finestra principale, e da
## li' lo ereditano tutti i [Control] del gioco: pulsanti, slider, caselle,
## schede, pannelli, menu a tendina, campi di testo. Una schermata nuova del
## gioco e' gia' nello stile giusto senza fare niente; se cambia il tema,
## cambia anche lei.
##
## Lo stile e' pixel: niente angoli tondi, bordi spessi 4 pixel, un "labbro"
## sotto ai pulsanti che si schiaccia quando li premi.
##
## [b]Varianti in piu'[/b] (proprieta' [b]Theme Type Variation[/b] di un Control):
## [br]- [code]TitleLabel[/code]: titolo grande;
## [br]- [code]SectionLabel[/code]: intestazione di una sezione, del colore accento;
## [br]- [code]DimLabel[/code]: testo secondario, piu' tenue;
## [br]- [code]CardPanel[/code]: pannello color carta con bordo a inchiostro.
class_name UiThemeBuilder extends RefCounted


const PIXEL_FONT := "res://GrapeSoda.ttf"

## Lo spessore dei bordi, in pixel.
const BORDER := 4


## [param look] arriva da [Settings]: colori, font, dimensione del testo e
## contrasto alto.
static func build(look: Dictionary) -> Theme:
	var theme: Theme = Theme.new()

	var paper: Color = look["paper"]
	var ink: Color = look["ink"]
	var accent: Color = look["accent"]
	var panel: Color = look["panel"]
	var text: Color = look["text"]
	var high_contrast: bool = look["high_contrast"]
	var border: int = BORDER + (2 if high_contrast else 0)

	if look["font"] != null:
		theme.default_font = look["font"]
	theme.default_font_size = look["font_size"]

	var dim_text: Color = text.darkened(0.0 if high_contrast else 0.28)
	var lit: Color = accent.darkened(0.1)

	# --- Testi ---
	theme.set_color("font_color", "Label", text)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))

	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font_size("font_size", "TitleLabel", int(look["font_size"] * 1.9))
	theme.set_color("font_color", "TitleLabel", text)
	theme.set_color("font_shadow_color", "TitleLabel", Color(0, 0, 0, 0.6))
	theme.set_constant("shadow_offset_x", "TitleLabel", 4)
	theme.set_constant("shadow_offset_y", "TitleLabel", 4)

	theme.set_type_variation("SectionLabel", "Label")
	theme.set_font_size("font_size", "SectionLabel", int(look["font_size"] * 1.2))
	theme.set_color("font_color", "SectionLabel", accent)

	theme.set_type_variation("DimLabel", "Label")
	theme.set_color("font_color", "DimLabel", dim_text)

	# --- Pulsanti (e tutto cio' che ne eredita: OptionButton, ColorPickerButton...) ---
	for type: String in ["Button", "OptionButton", "ColorPickerButton", "MenuButton"]:
		theme.set_stylebox("normal", type, _button_style(paper, ink, border, 8))
		theme.set_stylebox("hover", type, _button_style(paper.lightened(0.18), lit, border, 8))
		theme.set_stylebox("pressed", type, _button_style(paper.darkened(0.12), lit, border, 4))
		theme.set_stylebox("hover_pressed", type, _button_style(paper.darkened(0.12), lit, border, 4))
		theme.set_stylebox("disabled", type, _button_style(paper.lerp(Color(0.5, 0.5, 0.5), 0.6), ink.lerp(Color(0.4, 0.4, 0.4), 0.6), border, 8))
		theme.set_stylebox("focus", type, _focus_style(lit, border))
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			theme.set_color(state, type, ink)
		theme.set_color("font_disabled_color", type, ink.lerp(Color(0.5, 0.5, 0.5), 0.6))
		theme.set_color("icon_normal_color", type, ink)
		theme.set_color("icon_hover_color", type, ink)
		theme.set_color("icon_pressed_color", type, ink)
		theme.set_color("icon_focus_color", type, ink)

	# --- Pannelli ---
	theme.set_stylebox("panel", "Panel", _panel_style(panel, ink.lerp(accent, 0.35), border))
	theme.set_stylebox("panel", "PanelContainer", _panel_style(panel, ink.lerp(accent, 0.35), border))
	theme.set_type_variation("CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", _panel_style(paper, ink, border))

	# --- Schede ---
	theme.set_stylebox("panel", "TabContainer", _panel_style(panel, lit, border))
	theme.set_stylebox("tab_selected", "TabContainer", _tab_style(paper, lit, border))
	theme.set_stylebox("tab_unselected", "TabContainer", _tab_style(panel.lightened(0.08), ink.lerp(panel, 0.3), border))
	theme.set_stylebox("tab_hovered", "TabContainer", _tab_style(panel.lightened(0.18), lit, border))
	theme.set_stylebox("tab_focus", "TabContainer", _focus_style(lit, border))
	theme.set_color("font_selected_color", "TabContainer", ink)
	theme.set_color("font_unselected_color", "TabContainer", dim_text)
	theme.set_color("font_hovered_color", "TabContainer", text)
	theme.set_constant("side_margin", "TabContainer", 0)

	# --- Slider ---
	var track: StyleBoxFlat = _flat(panel.darkened(0.4), ink, 2)
	track.content_margin_top = 4.0
	track.content_margin_bottom = 4.0
	theme.set_stylebox("slider", "HSlider", track)
	var filled: StyleBoxFlat = _flat(accent.darkened(0.15), ink, 2)
	filled.content_margin_top = 4.0
	filled.content_margin_bottom = 4.0
	theme.set_stylebox("grabber_area", "HSlider", filled)
	theme.set_stylebox("grabber_area_highlight", "HSlider", filled)
	theme.set_icon("grabber", "HSlider", _grabber_icon(paper, ink))
	theme.set_icon("grabber_highlight", "HSlider", _grabber_icon(paper.lightened(0.2), lit))
	theme.set_icon("grabber_disabled", "HSlider", _grabber_icon(Color(0.5, 0.5, 0.5), ink))

	# --- Caselle e interruttori ---
	for type: String in ["CheckBox", "CheckButton"]:
		theme.set_stylebox("normal", type, _empty())
		theme.set_stylebox("hover", type, _empty())
		theme.set_stylebox("pressed", type, _empty())
		theme.set_stylebox("hover_pressed", type, _empty())
		theme.set_stylebox("focus", type, _focus_style(lit, 2))
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			theme.set_color(state, type, text)
	theme.set_icon("checked", "CheckBox", _check_icon(paper, ink, accent, true))
	theme.set_icon("unchecked", "CheckBox", _check_icon(paper, ink, accent, false))
	theme.set_icon("checked", "CheckButton", _switch_icon(paper, ink, accent, true))
	theme.set_icon("unchecked", "CheckButton", _switch_icon(paper, ink, panel, false))

	# --- Campi di testo ---
	var field: StyleBoxFlat = _flat(panel.darkened(0.35), ink.lerp(text, 0.25), 2)
	_pad(field, 12, 8)
	var field_focus: StyleBoxFlat = _flat(panel.darkened(0.35), lit, border)
	_pad(field_focus, 12, 8)
	theme.set_stylebox("normal", "LineEdit", field)
	theme.set_stylebox("focus", "LineEdit", field_focus)
	theme.set_stylebox("read_only", "LineEdit", field)
	theme.set_color("font_color", "LineEdit", text)
	theme.set_color("caret_color", "LineEdit", accent)
	theme.set_color("selection_color", "LineEdit", Color(accent, 0.4))
	theme.set_color("font_placeholder_color", "LineEdit", Color(text, 0.45))

	# --- Menu a tendina ---
	var popup: StyleBoxFlat = _flat(panel, lit, border)
	_pad(popup, 6, 6)
	theme.set_stylebox("panel", "PopupMenu", popup)
	var hover: StyleBoxFlat = _flat(paper, paper, 0)
	theme.set_stylebox("hover", "PopupMenu", hover)
	theme.set_color("font_color", "PopupMenu", text)
	theme.set_color("font_hover_color", "PopupMenu", ink)
	theme.set_color("font_accelerator_color", "PopupMenu", dim_text)
	theme.set_constant("v_separation", "PopupMenu", 10)
	theme.set_stylebox("panel", "PopupPanel", popup)

	# --- Barre di scorrimento ---
	var bar: StyleBoxFlat = _flat(panel.darkened(0.3), panel.darkened(0.3), 0)
	bar.content_margin_left = 6.0
	bar.content_margin_right = 6.0
	theme.set_stylebox("scroll", "VScrollBar", bar)
	theme.set_stylebox("grabber", "VScrollBar", _flat(paper.darkened(0.15), ink, 2))
	theme.set_stylebox("grabber_highlight", "VScrollBar", _flat(paper, lit, 2))
	theme.set_stylebox("grabber_pressed", "VScrollBar", _flat(accent, ink, 2))
	theme.set_stylebox("scroll", "HScrollBar", bar)
	theme.set_stylebox("grabber", "HScrollBar", _flat(paper.darkened(0.15), ink, 2))
	theme.set_stylebox("grabber_highlight", "HScrollBar", _flat(paper, lit, 2))
	theme.set_stylebox("grabber_pressed", "HScrollBar", _flat(accent, ink, 2))

	# --- Separatori e suggerimenti ---
	var line: StyleBoxLine = StyleBoxLine.new()
	line.color = Color(text, 0.18)
	line.thickness = 2
	theme.set_stylebox("separator", "HSeparator", line)
	theme.set_constant("separation", "HSeparator", 18)
	theme.set_stylebox("panel", "TooltipPanel", _panel_style(paper, ink, 2))
	theme.set_color("font_color", "TooltipLabel", ink)

	return theme


#region Stili


static func _flat(background: Color, border_color: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border_color
	style.set_border_width_all(width)
	style.anti_aliasing = false
	return style


static func _pad(style: StyleBox, horizontal: int, vertical: int) -> void:
	style.content_margin_left = horizontal
	style.content_margin_right = horizontal
	style.content_margin_top = vertical
	style.content_margin_bottom = vertical


static func _empty() -> StyleBoxEmpty:
	var style: StyleBoxEmpty = StyleBoxEmpty.new()
	_pad(style, 4, 4)
	return style


## Il pulsante: bordo sottile ai lati, spesso sotto ([param lip]). Premuto, il
## labbro si assottiglia e il testo scende: sembra che il pulsante affondi.
static func _button_style(background: Color, border_color: Color, width: int, lip: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _flat(background, border_color, width)
	style.border_width_top = width + (8 - lip)
	style.border_width_bottom = lip
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 1
	style.shadow_offset = Vector2(4.0, 4.0)
	return style


static func _focus_style(color: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color
	style.set_border_width_all(width)
	style.set_expand_margin_all(6.0)
	style.anti_aliasing = false
	return style


static func _panel_style(background: Color, border_color: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _flat(background, border_color, width)
	_pad(style, 24, 20)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 1
	style.shadow_offset = Vector2(8.0, 8.0)
	return style


static func _tab_style(background: Color, border_color: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _flat(background, border_color, width)
	style.border_width_bottom = 0
	_pad(style, 20, 8)
	return style


#endregion

#region Icone pixel


## La maniglia dello slider: un rettangolino di carta con il bordo.
static func _grabber_icon(fill: Color, border_color: Color) -> ImageTexture:
	var img: Image = Image.create_empty(16, 28, false, Image.FORMAT_RGBA8)
	img.fill(border_color)
	img.fill_rect(Rect2i(4, 4, 8, 20), fill)
	img.fill_rect(Rect2i(4, 20, 8, 4), fill.darkened(0.2))
	return ImageTexture.create_from_image(img)


## La casella: quadrato di carta, con dentro un quadrato del colore accento
## quando e' spuntata.
static func _check_icon(fill: Color, border_color: Color, mark: Color, checked: bool) -> ImageTexture:
	var img: Image = Image.create_empty(28, 28, false, Image.FORMAT_RGBA8)
	img.fill(border_color)
	img.fill_rect(Rect2i(4, 4, 20, 20), fill)
	if checked:
		img.fill_rect(Rect2i(8, 8, 12, 12), mark.darkened(0.1))
		img.fill_rect(Rect2i(8, 8, 12, 4), mark.lightened(0.2))
	return ImageTexture.create_from_image(img)


## L'interruttore: una pista con un cursore che sta a destra (acceso) o a
## sinistra (spento).
static func _switch_icon(knob: Color, border_color: Color, track: Color, on: bool) -> ImageTexture:
	var img: Image = Image.create_empty(56, 28, false, Image.FORMAT_RGBA8)
	img.fill(border_color)
	img.fill_rect(Rect2i(4, 4, 48, 20), track.darkened(0.15) if on else track.darkened(0.45))
	var x: int = 28 if on else 4
	img.fill_rect(Rect2i(x, 4, 24, 20), border_color)
	img.fill_rect(Rect2i(x + 4, 8, 16, 12), knob)
	return ImageTexture.create_from_image(img)


#endregion
