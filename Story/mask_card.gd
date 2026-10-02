## Una maschera disegnata come una carta: la carta vecchia di [MenuCardArt] e,
## nel riquadro, la faccia della maschera dipinta in pixel art.
##
## [b]Come si usa:[/b] imposta [member mask] prima di aggiungerla all'albero
## (o chiama [method show_mask]). Si disegna da sola.
##
## Ogni maschera ha una [i]faccia[/i] ([member MaskData.face]): vuota, che
## ride, che piange, a meta', un occhio solo, divisa in due, con il cuore,
## con le sbarre, o tante una sopra l'altra. La faccia e' il suo sprite, e
## viene dipinta pixel per pixel da [method paint_face].
class_name MaskCard extends Control


## Emesso quando la carta viene cliccata.
signal pressed(card: MaskCard)


## La maschera da mostrare.
var mask: MaskData = null

## Dimensione della carta.
var card_size: Vector2 = Vector2(240, 336)

## Se true la carta ha il contorno acceso.
var selected: bool = false:
	set(value):
		selected = value
		_apply_glow()

## Se false la carta e' spenta (es. maschera non disponibile).
var enabled: bool = true

## Dimensione del titolo sul cartiglio. Si riduce da sola finche' il titolo
## non sta su una riga.
var title_font_size: int = 24

var _built: bool = false
var _glow: TextureRect
var _face_rect: TextureRect
var _title: Label
var _hovered: bool = false


func _ready() -> void:
	_build()


## Cambia la maschera mostrata e ridisegna.
func show_mask(value: MaskData) -> void:
	mask = value
	if _built:
		for child: Node in get_children():
			child.queue_free()
		_built = false
		_build()


func _build() -> void:
	if _built:
		return
	_built = true

	size = card_size
	custom_minimum_size = card_size
	pivot_offset = card_size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var accent: Color = mask.accent if mask != null else Color(0.5, 0.5, 0.55)
	var title_text: String = mask.display_name if mask != null else "A volto scoperto"
	var seed: int = absi(title_text.hash())
	var style: Dictionary = Settings.card_style()
	var art: Dictionary = MenuCardArt.build(card_size, accent, seed, enabled, style)
	var px: float = float(MenuCardArt.PX)

	var shadow: TextureRect = _texture_rect(art["shadow"], Rect2(Vector2(px, px * 2.0), card_size))
	shadow.modulate = Color(0, 0, 0, 0.45)
	add_child(shadow)

	_glow = _texture_rect(art["glow"], Rect2(-Vector2.ONE * px * 2.0, card_size + Vector2.ONE * px * 4.0))
	_glow.modulate = Color(accent.lightened(0.3), 0.0)
	add_child(_glow)

	add_child(_texture_rect(art["face"], Rect2(Vector2.ZERO, card_size)))

	# La faccia della maschera, dentro il riquadro.
	var window: Rect2i = art["window"]
	var face_texture: ImageTexture = paint_face(window.size.x - 2, window.size.y - 2,
		mask.face if mask != null else "none", accent)
	_face_rect = _texture_rect(face_texture, Rect2(
		(Vector2(window.position) + Vector2.ONE) * px,
		(Vector2(window.size) - Vector2.ONE * 2.0) * px
	))
	add_child(_face_rect)

	# Il titolo sul cartiglio.
	var plaque: Rect2i = art["plaque"]
	_title = Label.new()
	_title.text = title_text
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.position = Vector2(plaque.position) * px + Vector2(px * 6.0, px)
	_title.size = Vector2(plaque.size) * px - Vector2(px * 12.0, px * 2.0)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_color_override("font_color", style.get("ink", MenuCardArt.INK))
	_title.add_theme_constant_override("line_spacing", -6)
	var font: Font = Settings.ui_font()
	if font != null:
		_title.add_theme_font_override("font", font)
	_title.add_theme_font_size_override("font_size", _fit_title_size(_title, title_text, Settings.font_size(title_font_size)))
	add_child(_title)


## La dimensione piu' grande (fino a [param wanted]) con cui il titolo sta su
## una riga nel cartiglio. Sotto 12 lascia andare a capo.
func _fit_title_size(label: Label, text: String, wanted: int) -> int:
	var font: Font = label.get_theme_font("font")
	var font_size: int = wanted
	while font_size > 12 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
		font_size -= 1
	return font_size

	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	gui_input.connect(_on_gui_input)
	_apply_glow()


func _on_hover(inside: bool) -> void:
	_hovered = inside
	_apply_glow()


func _texture_rect(texture: Texture2D, rect: Rect2) -> TextureRect:
	var tr: TextureRect = TextureRect.new()
	tr.texture = texture
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.position = rect.position
	tr.size = rect.size
	return tr


func _apply_glow() -> void:
	if _glow == null:
		return
	var mix: float = 1.0 if selected else (0.4 if _hovered and enabled else 0.0)
	_glow.modulate.a = mix


func _on_gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		accept_event()
		if enabled:
			pressed.emit(self)


#region La faccia


## Dipinge la faccia di una maschera in un'immagine [param w] x [param h]
## (in pixel della carta). [param style] e' [member MaskData.face].
static func paint_face(w: int, h: int, style: String, accent: Color) -> ImageTexture:
	var img: Image = Image.create_empty(maxi(w, 8), maxi(h, 8), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var ink: Color = Color("1a1216")
	var light: Color = accent.lightened(0.35)
	var dark: Color = accent.darkened(0.35)
	var paper: Color = accent.lerp(Color(0.95, 0.92, 0.85), 0.55)

	var cx: float = float(w) * 0.5
	var cy: float = float(h) * 0.5
	var rx: float = float(w) * 0.34
	var ry: float = float(h) * 0.40

	match style:
		"none":
			# Nessuna maschera: solo un'ombra dove starebbe il volto.
			_ellipse(img, cx, cy, rx, ry, Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.5))
			return ImageTexture.create_from_image(img)
		"many":
			# Tre maschere una sopra l'altra, sfalsate.
			_ellipse(img, cx + rx * 0.45, cy + ry * 0.25, rx * 0.85, ry * 0.85, dark.darkened(0.3), ink)
			_ellipse(img, cx - rx * 0.45, cy + ry * 0.12, rx * 0.85, ry * 0.85, dark, ink)
			_mask_shape(img, cx, cy - ry * 0.1, rx * 0.9, ry * 0.9, paper, light, dark, ink)
			_eyes(img, cx, cy - ry * 0.1, rx * 0.9, ry * 0.9, ink, "flat")
			_mouth(img, cx, cy - ry * 0.1, rx * 0.9, ry * 0.9, ink, "flat")
			return ImageTexture.create_from_image(img)
		"half":
			# Una mezza maschera, tagliata in diagonale: copre un occhio solo.
			_mask_shape(img, cx, cy, rx, ry, paper, light, dark, ink, true)
			_eyes(img, cx, cy, rx, ry, ink, "sly")
			return ImageTexture.create_from_image(img)
		"mirror":
			_mask_shape(img, cx, cy, rx, ry, paper, light, dark, ink)
			# La meta' destra e' il negativo della sinistra.
			for y: int in h:
				for x: int in range(int(cx), w):
					var c: Color = img.get_pixel(x, y)
					if c.a > 0.0:
						img.set_pixel(x, y, Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a).lerp(c, 0.25))
			for y: int in range(int(cy - ry), int(cy + ry) + 1):
				if y >= 0 and y < h:
					img.set_pixel(int(cx), y, ink)
			_eyes(img, cx, cy, rx, ry, ink, "flat")
			_mouth(img, cx, cy, rx, ry, ink, "flat")
			return ImageTexture.create_from_image(img)

	# Le maschere "intere".
	_mask_shape(img, cx, cy, rx, ry, paper, light, dark, ink)
	match style:
		"empty":
			pass  # Nessun tratto: e' la maschera di chi non ha mai osato.
		"smile":
			_eyes(img, cx, cy, rx, ry, ink, "happy")
			_mouth(img, cx, cy, rx, ry, ink, "smile")
		"frown":
			_eyes(img, cx, cy, rx, ry, ink, "sad")
			_mouth(img, cx, cy, rx, ry, ink, "frown")
			# Una lacrima.
			_ellipse(img, cx - rx * 0.42, cy + ry * 0.15, 1.2, 2.2, light, light)
		"eye":
			# Un occhio solo, grande, al centro: vede la prossima carta.
			_ellipse(img, cx, cy - ry * 0.05, rx * 0.55, ry * 0.30, Color(0.97, 0.96, 0.92), ink)
			_ellipse(img, cx, cy - ry * 0.05, rx * 0.22, ry * 0.22, accent.darkened(0.2), ink)
			_ellipse(img, cx, cy - ry * 0.05, rx * 0.09, ry * 0.09, ink, ink)
			img.set_pixel(int(cx - rx * 0.08), int(cy - ry * 0.14), Color.WHITE)
			_mouth(img, cx, cy, rx, ry, ink, "flat")
		"heart":
			_eyes(img, cx, cy, rx, ry, ink, "closed")
			_mouth(img, cx, cy, rx, ry, ink, "smile")
			_heart(img, int(cx), int(cy - ry * 0.62), 3, Color("c93a5a"), ink)
		"bars":
			_eyes(img, cx, cy, rx, ry, ink, "flat")
			_mouth(img, cx, cy, rx, ry, ink, "flat")
			# Le sbarre della gabbia, davanti alla faccia.
			for i: int in range(-2, 3):
				var bx: int = int(cx + float(i) * rx * 0.42)
				for y: int in range(int(cy - ry - 2), int(cy + ry + 3)):
					if y >= 0 and y < h and bx >= 0 and bx < w:
						img.set_pixel(bx, y, ink if y % 2 == 0 else dark.darkened(0.4))
		_:
			_eyes(img, cx, cy, rx, ry, ink, "flat")
			_mouth(img, cx, cy, rx, ry, ink, "flat")

	return ImageTexture.create_from_image(img)


## L'ovale della maschera, con l'ombra a destra, la luce a sinistra e il bordo.
static func _mask_shape(
	img: Image, cx: float, cy: float, rx: float, ry: float,
	paper: Color, light: Color, dark: Color, ink: Color, half: bool = false
) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y: int in h:
		for x: int in w:
			var dx: float = (float(x) - cx) / rx
			var dy: float = (float(y) - cy) / ry
			var d: float = dx * dx + dy * dy
			if d > 1.0:
				continue
			# La meta' maschera: tagliata in diagonale, copre la parte destra.
			if half and float(x) - cx < (float(y) - cy) * 0.35 - 1.0:
				continue
			var c: Color = paper
			if dx < -0.35 and dy < 0.0:
				c = light
			elif dx > 0.3 or dy > 0.55:
				c = dark
			# Grana a puntini.
			if (x + y) % 3 == 0 and (x * 7 + y * 3) % 5 == 0:
				c = c.darkened(0.08)
			if d > 0.86:
				c = ink
			elif half and float(x) - cx < (float(y) - cy) * 0.35 + 0.5:
				c = ink
			img.set_pixel(x, y, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, fill: Color, outline: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y: int in range(maxi(int(cy - ry) - 1, 0), mini(int(cy + ry) + 2, h)):
		for x: int in range(maxi(int(cx - rx) - 1, 0), mini(int(cx + rx) + 2, w)):
			var dx: float = (float(x) - cx) / maxf(rx, 0.5)
			var dy: float = (float(y) - cy) / maxf(ry, 0.5)
			var d: float = dx * dx + dy * dy
			if d <= 1.0:
				img.set_pixel(x, y, outline if d > 0.7 else fill)


## Gli occhi: due buchi, con l'espressione decisa da [param mood].
static func _eyes(img: Image, cx: float, cy: float, rx: float, ry: float, ink: Color, mood: String) -> void:
	for side: float in [-1.0, 1.0]:
		var ex: float = cx + side * rx * 0.42
		var ey: float = cy - ry * 0.18
		match mood:
			"happy":
				# Archi verso l'alto: occhi che ridono.
				for i: int in range(-3, 4):
					var y: int = int(ey + float(i * i) * 0.35 - 1.0)
					_dot(img, int(ex + float(i)), y, ink)
			"sad":
				# Inclinati verso il basso, all'esterno.
				for i: int in range(-3, 4):
					var y: int = int(ey + side * float(i) * 0.45)
					_dot(img, int(ex + float(i)), y, ink)
					_dot(img, int(ex + float(i)), y + 1, ink)
			"closed":
				for i: int in range(-3, 4):
					_dot(img, int(ex + float(i)), int(ey), ink)
			"sly":
				# Solo l'occhio coperto dalla mezza maschera: a destra.
				if side > 0.0:
					_ellipse(img, ex, ey, rx * 0.2, ry * 0.11, Color(0, 0, 0, 1), ink)
			_:
				_ellipse(img, ex, ey, rx * 0.2, ry * 0.14, Color(0, 0, 0, 1), ink)


## La bocca: un arco, verso l'alto o verso il basso.
static func _mouth(img: Image, cx: float, cy: float, rx: float, ry: float, ink: Color, mood: String) -> void:
	var my: float = cy + ry * 0.45
	var half_width: int = int(rx * 0.45)
	for i: int in range(-half_width, half_width + 1):
		var t: float = float(i) / float(maxi(half_width, 1))
		var bend: float = 0.0
		match mood:
			"smile":
				bend = -t * t * ry * 0.22 + ry * 0.12
			"frown":
				bend = t * t * ry * 0.22 - ry * 0.10
		_dot(img, int(cx + float(i)), int(my + bend), ink)
		if mood != "flat" and absi(i) < half_width - 1:
			_dot(img, int(cx + float(i)), int(my + bend) + 1, ink)


static func _heart(img: Image, x: int, y: int, r: int, fill: Color, outline: Color) -> void:
	_ellipse(img, float(x - r) + 0.5, float(y), float(r), float(r), fill, outline)
	_ellipse(img, float(x + r) - 0.5, float(y), float(r), float(r), fill, outline)
	for dy: int in range(0, r * 2 + 1):
		var half: int = r * 2 - dy
		for dx: int in range(-half, half + 1):
			_dot(img, x + dx, y + dy, outline if absi(dx) == half or dy == r * 2 else fill)


static func _dot(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)


#endregion
