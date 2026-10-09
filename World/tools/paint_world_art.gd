## Dipinge in codice la grafica del mondo esplorabile: le mattonelle del teatro
## e gli oggetti di scena che negli asset non c'erano.
##
## Come le illustrazioni delle carte ([code]Cards/ui/card_art_painter.gd[/code]),
## e' pixel art fatta di rettangoli e rumore con un seme fisso: ogni volta che
## lo rilanci escono gli stessi pixel.
##
## [b]Come si usa:[/b]
## [codeblock]
## godot --headless --path . --script res://World/tools/paint_world_art.gd
## godot --headless --path . --import
## [/codeblock]
## Scrive [code]World/art/theatre_tiles.png[/code] (mattonelle 32x32, 8 colonne)
## e [code]World/art/theatre_props.png[/code] (oggetti, vedi [WorldProp]).
## Se ridipingi a mano uno dei due PNG, non rilanciare questo script.
extends SceneTree


const TILE := 32
const TILES_PATH := "res://World/art/theatre_tiles.png"
const PROPS_PATH := "res://World/art/theatre_props.png"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Dove si puo' dipingere adesso: una mattonella non sborda mai nella vicina.
var _clip: Rect2i = Rect2i(0, 0, 4096, 4096)


func _init() -> void:
	_rng.seed = 1717
	var tiles: Image = Image.create_empty(TILE * 8, TILE * 3, false, Image.FORMAT_RGBA8)
	tiles.fill(Color(0, 0, 0, 0))
	_paint_tiles(tiles)
	_save(tiles, TILES_PATH)

	var props: Image = Image.create_empty(512, 192, false, Image.FORMAT_RGBA8)
	props.fill(Color(0, 0, 0, 0))
	_paint_props(props)
	_save(props, PROPS_PATH)
	quit(0)


func _save(img: Image, path: String) -> void:
	var error: Error = img.save_png(ProjectSettings.globalize_path(path))
	print("[paint_world_art] %s %s" % [path, "OK" if error == OK else "ERRORE %d" % error])


#region Pennelli


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			_px(img, xx, yy, c)


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and _clip.has_point(Vector2i(x, y)):
		img.set_pixel(x, y, c)


## Un rettangolo con un po' di grana: ogni pixel varia di poco.
func _grain(img: Image, x: int, y: int, w: int, h: int, c: Color, amount: float) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			var v: float = _rng.randf_range(-amount, amount)
			_px(img, xx, yy, Color(clampf(c.r + v, 0, 1), clampf(c.g + v, 0, 1), clampf(c.b + v, 0, 1), c.a))


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy: int in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx: int in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx: float = (float(xx) + 0.5 - cx) / rx
			var dy: float = (float(yy) + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(img, xx, yy, c)


#endregion

#region Mattonelle


func _paint_tiles(img: Image) -> void:
	# Riga 0: pavimenti (attraversabili).
	_planks(img, 0, 0, Color("4a3358"), 0)
	_planks(img, 1, 0, Color("4f3760"), 1)
	_planks(img, 2, 0, Color("43304f"), 2, true)
	_carpet(img, 3, 0, Color("7a1f33"), Color("c9a24a"))
	_planks(img, 4, 0, Color("8a6236"), 0)
	_linoleum(img, 5, 0)
	_marble(img, 6, 0)
	_clutter(img, 7, 0)

	# Riga 1: muri e cose solide.
	_wall_top(img, 0, 1)
	_backdrop(img, 1, 1)
	_curtain(img, 2, 1)
	_mirror_wall(img, 3, 1)
	_sky(img, 4, 1)
	_cage(img, 5, 1)
	_void(img, 6, 1)
	_seats(img, 7, 1)

	# Riga 2: varianti.
	_corridor_wall(img, 0, 2)
	_stage_edge(img, 1, 2)
	_doorway(img, 2, 2)
	_carpet(img, 3, 2, Color("23315e"), Color("9fb8ff"))
	_cobbles(img, 4, 2)
	_brick(img, 5, 2)
	_paint_puddle(img, 6, 2)
	_planks(img, 7, 2, Color("2b2233"), 3)


func _o(col: int, row: int) -> Vector2i:
	_clip = Rect2i(col * TILE, row * TILE, TILE, TILE)
	return Vector2i(col * TILE, row * TILE)


## Assi di legno viola: il pavimento del teatro.
func _planks(img: Image, col: int, row: int, base: Color, variant: int, worn: bool = false) -> void:
	var o: Vector2i = _o(col, row)
	_grain(img, o.x, o.y, TILE, TILE, base, 0.025)
	for i: int in 4:
		var y: int = o.y + i * 8
		_rect(img, o.x, y + 7, TILE, 1, base.darkened(0.45))
		_rect(img, o.x, y, TILE, 1, base.lightened(0.12))
		# I giunti tra un'asse e l'altra, sfalsati.
		var joint: int = o.x + ((i * 11 + variant * 7) % TILE)
		_rect(img, joint, y, 1, 7, base.darkened(0.4))
		# Le venature.
		for k: int in 3:
			var vx: int = o.x + _rng.randi_range(0, TILE - 6)
			_rect(img, vx, y + _rng.randi_range(2, 5), _rng.randi_range(3, 6), 1, base.darkened(0.15))
	# I chiodi.
	for i: int in 4:
		_px(img, o.x + 2, o.y + i * 8 + 3, base.lightened(0.35))
		_px(img, o.x + TILE - 3, o.y + i * 8 + 3, base.lightened(0.35))
	if worn:
		for k: int in 18:
			_px(img, o.x + _rng.randi_range(0, TILE - 1), o.y + _rng.randi_range(0, TILE - 1), base.lightened(0.25))


## Velluto con il bordo dorato: il corridoio buono.
func _carpet(img: Image, col: int, row: int, base: Color, trim: Color) -> void:
	var o: Vector2i = _o(col, row)
	_grain(img, o.x, o.y, TILE, TILE, base, 0.03)
	_rect(img, o.x + 3, o.y, 2, TILE, trim)
	_rect(img, o.x + TILE - 5, o.y, 2, TILE, trim)
	for y: int in range(0, TILE, 8):
		_px(img, o.x + 15, o.y + y + 3, trim.darkened(0.2))
		_px(img, o.x + 16, o.y + y + 4, trim.darkened(0.2))
		_px(img, o.x + 15, o.y + y + 5, trim.darkened(0.2))
		_px(img, o.x + 14, o.y + y + 4, trim.darkened(0.2))


## Linoleum verde malato, a scacchi: i corridoi del personale.
func _linoleum(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	var a: Color = Color("4c6b4a")
	var b: Color = Color("3a5239")
	for y: int in 2:
		for x: int in 2:
			_grain(img, o.x + x * 16, o.y + y * 16, 16, 16, a if (x + y) % 2 == 0 else b, 0.02)
	_rect(img, o.x, o.y + 15, TILE, 1, Color("2a3a29"))
	_rect(img, o.x + 15, o.y, 1, TILE, Color("2a3a29"))


## Marmo freddo, a losanghe: la galleria degli specchi.
func _marble(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_grain(img, o.x, o.y, TILE, TILE, Color("3a3f63"), 0.03)
	for i: int in TILE:
		_px(img, o.x + i, o.y + i, Color("5a6290"))
		_px(img, o.x + TILE - 1 - i, o.y + i, Color("5a6290"))
	for k: int in 6:
		var x: int = _rng.randi_range(2, TILE - 8)
		var y: int = _rng.randi_range(2, TILE - 3)
		_rect(img, o.x + x, o.y + y, _rng.randi_range(3, 7), 1, Color("4a5078"))


## Le quinte: assi coperte di ritagli, costumi, vernice. Qui si incontra qualcuno.
func _clutter(img: Image, col: int, row: int) -> void:
	_planks(img, col, row, Color("3d2b48"), 3)
	var o: Vector2i = _o(col, row)
	var colors: Array[Color] = [Color("c9a24a"), Color("a8324a"), Color("6f4fa0"), Color("d8d0c0"), Color("2f8f83")]
	for k: int in 7:
		var c: Color = colors[_rng.randi() % colors.size()]
		var x: int = _rng.randi_range(1, TILE - 6)
		var y: int = _rng.randi_range(1, TILE - 4)
		_rect(img, o.x + x, o.y + y, _rng.randi_range(2, 5), _rng.randi_range(1, 3), c)
	for k: int in 10:
		_px(img, o.x + _rng.randi_range(0, TILE - 1), o.y + _rng.randi_range(0, TILE - 1), Color("e0d8f0"))


func _wall_top(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_grain(img, o.x, o.y, TILE, TILE, Color("1d1424"), 0.02)
	_rect(img, o.x, o.y + TILE - 2, TILE, 2, Color("33243f"))


## Il fondale dipinto: una tela tesa, con il bordo del telaio.
func _backdrop(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	for y: int in TILE:
		var t: float = float(y) / TILE
		_grain(img, o.x, o.y + y, TILE, 1, Color("5b3f78").lerp(Color("2d1f3d"), t), 0.02)
	# Le pennellate.
	for k: int in 5:
		var x: int = _rng.randi_range(0, TILE - 10)
		_rect(img, o.x + x, o.y + _rng.randi_range(3, 20), _rng.randi_range(5, 10), 1, Color("7a5a99"))
	_rect(img, o.x, o.y, TILE, 2, Color("8a6236"))
	_rect(img, o.x, o.y + TILE - 3, TILE, 3, Color("1a1220"))


## Il sipario rosso, con le pieghe.
func _curtain(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	for x: int in TILE:
		var fold: float = 0.5 + 0.5 * sin(float(x) / TILE * TAU * 2.0)
		var c: Color = Color("5e0f1e").lerp(Color("b8283f"), fold)
		_grain(img, o.x + x, o.y, 1, TILE, c, 0.015)
	_rect(img, o.x, o.y + TILE - 2, TILE, 2, Color("c9a24a"))


func _mirror_wall(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_rect(img, o.x, o.y, TILE, TILE, Color("c9a24a"))
	_rect(img, o.x + 1, o.y + 1, TILE - 2, TILE - 2, Color("7a5a2a"))
	for y: int in range(3, TILE - 3):
		var t: float = float(y) / TILE
		_rect(img, o.x + 3, o.y + y, TILE - 6, 1, Color("9fb8ff").lerp(Color("3a4778"), t))
	for i: int in 8:
		_px(img, o.x + 7 + i, o.y + 6 + i, Color(1, 1, 1, 0.8))
		_px(img, o.x + 12 + i, o.y + 6 + i, Color(1, 1, 1, 0.5))


## Il cielo di tela, con le pennellate e le cuciture.
func _sky(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	for y: int in TILE:
		var t: float = float(y) / TILE
		_grain(img, o.x, o.y + y, TILE, 1, Color("8c79c9").lerp(Color("c99ac9"), t), 0.02)
	for k: int in 3:
		_ellipse(img, o.x + _rng.randi_range(6, 26), o.y + _rng.randi_range(6, 26), _rng.randi_range(4, 7), 2.5, Color("e8dcf0"))
	_rect(img, o.x + 20, o.y, 1, TILE, Color("6f5fa8"))


func _cage(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_planks(img, col, row, Color("2b3a2a"), 1)
	for x: int in range(2, TILE, 7):
		_rect(img, o.x + x, o.y, 3, TILE, Color("1b1e1d"))
		_rect(img, o.x + x, o.y, 1, TILE, Color("7a8a85"))
	_rect(img, o.x, o.y + 4, TILE, 3, Color("1b1e1d"))
	_rect(img, o.x, o.y + 4, TILE, 1, Color("7a8a85"))


func _void(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_rect(img, o.x, o.y, TILE, TILE, Color("0b0910"))
	for k: int in 4:
		_px(img, o.x + _rng.randi_range(0, TILE - 1), o.y + _rng.randi_range(0, TILE - 1), Color("221a2c"))


## Una fila di poltrone di velluto, viste da dietro.
func _seats(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_planks(img, col, row, Color("2b1a3e"), 2)
	for s: int in 2:
		var x: int = o.x + s * 16
		_rect(img, x + 1, o.y + 8, 14, 18, Color("4a1022"))
		_rect(img, x + 2, o.y + 9, 12, 14, Color("8a1f3a"))
		_rect(img, x + 2, o.y + 9, 12, 2, Color("b8384a"))
		_rect(img, x + 1, o.y + 26, 2, 4, Color("1a0c12"))
		_rect(img, x + 13, o.y + 26, 2, 4, Color("1a0c12"))


func _corridor_wall(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_grain(img, o.x, o.y, TILE, 20, Color("6f8a5a"), 0.02)
	for x: int in range(0, TILE, 8):
		_rect(img, o.x + x, o.y, 1, 20, Color("4c6340"))
	_rect(img, o.x, o.y + 10, TILE, 1, Color("4c6340"))
	_grain(img, o.x, o.y + 20, TILE, 12, Color("2f3d29"), 0.02)
	_rect(img, o.x, o.y + 20, TILE, 1, Color("a0b88a"))


## Il bordo del palco, con le luci della ribalta.
func _stage_edge(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_grain(img, o.x, o.y, TILE, TILE, Color("3a2416"), 0.02)
	_rect(img, o.x, o.y, TILE, 4, Color("c9a24a"))
	for x: int in range(4, TILE, 10):
		_ellipse(img, o.x + x + 2, o.y + 9, 3, 2, Color("ffe9a0"))
	for y: int in range(14, TILE, 6):
		_rect(img, o.x, o.y + y, TILE, 1, Color("2a170c"))


func _doorway(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_rect(img, o.x, o.y, TILE, TILE, Color("150f1b"))
	for y: int in TILE:
		_rect(img, o.x + 4, o.y + y, TILE - 8, 1, Color("2a1f33").lerp(Color("4a3358"), float(y) / TILE))
	_rect(img, o.x + 2, o.y, 2, TILE, Color("8a6236"))
	_rect(img, o.x + TILE - 4, o.y, 2, TILE, Color("8a6236"))


## Il lastricato della piazza: e' dipinto sulle assi.
func _cobbles(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_grain(img, o.x, o.y, TILE, TILE, Color("3e3352"), 0.02)
	for y: int in 4:
		for x: int in 3:
			var cx: float = o.x + x * 11 + (5 if y % 2 == 0 else 0) + 3
			var cy: float = o.y + y * 8 + 4
			_ellipse(img, cx, cy, 4.5, 3.2, Color("6a5a85"))
			_ellipse(img, cx - 0.5, cy - 0.8, 3.2, 1.8, Color("7d6c99"))


func _brick(img: Image, col: int, row: int) -> void:
	var o: Vector2i = _o(col, row)
	_rect(img, o.x, o.y, TILE, TILE, Color("2a1d22"))
	for y: int in 4:
		for x: int in 3:
			var bx: int = o.x + x * 12 - (6 if y % 2 == 1 else 0)
			_grain(img, bx + 1, o.y + y * 8 + 1, 10, 6, Color("6e3b3b"), 0.03)


func _paint_puddle(img: Image, col: int, row: int) -> void:
	_planks(img, col, row, Color("3d2b48"), 2)
	var o: Vector2i = _o(col, row)
	_ellipse(img, o.x + 16, o.y + 17, 11, 7, Color("6f4fa0"))
	_ellipse(img, o.x + 13, o.y + 15, 6, 3, Color("9a7ad0"))
	_ellipse(img, o.x + 25, o.y + 9, 2, 2, Color("6f4fa0"))


#endregion

#region Oggetti di scena (vedi WorldProp)


func _paint_props(img: Image) -> void:
	_clip = Rect2i(0, 0, img.get_width(), img.get_height())
	_prop_mirror(img, 0, 0)
	_prop_spotlight(img, 32, 0)
	_prop_flat(img, 64, 0)
	_prop_stand(img, 96, 0)
	_prop_poster(img, 128, 0)
	_prop_crate(img, 128, 32)
	_prop_exit_door(img, 160, 0)
	_prop_trunk(img, 224, 0)
	_prop_facade(img, 256, 0, 128, 128, Color("d8c8e8"), Color("6f3a7a"), 3, true)
	_prop_facade(img, 384, 0, 128, 128, Color("e8c8a8"), Color("2f5a6f"), 2, false)
	_prop_facade(img, 160, 64, 96, 112, Color("c8d8c0"), Color("7a2a3a"), 2, true)
	_prop_puppet_stall(img, 0, 64)
	_prop_lamp(img, 128, 64)
	_prop_stage_chest(img, 256, 128, false)
	_prop_stage_chest(img, 304, 128, true)


## Uno specchio da camerino, alto, con la cornice dorata e le lampadine.
func _prop_mirror(img: Image, x: int, y: int) -> void:
	_rect(img, x + 3, y + 6, 26, 52, Color("7a5a2a"))
	_rect(img, x + 4, y + 7, 24, 50, Color("c9a24a"))
	for yy: int in range(10, 54):
		_rect(img, x + 7, y + yy, 18, 1, Color("b8c8ff").lerp(Color("3a4778"), float(yy - 10) / 44.0))
	for i: int in 10:
		_px(img, x + 9 + i, y + 14 + i, Color(1, 1, 1, 0.85))
	# La crepa.
	var cx: int = x + 18
	for yy: int in range(18, 46):
		cx += _rng.randi_range(-1, 1)
		_px(img, cx, y + yy, Color("1a1216"))
	for yy: int in range(9, 56, 7):
		_ellipse(img, x + 5, y + yy, 1.5, 1.5, Color("fff2b0"))
		_ellipse(img, x + 27, y + yy, 1.5, 1.5, Color("fff2b0"))
	_rect(img, x + 8, y + 58, 4, 6, Color("4a3020"))
	_rect(img, x + 20, y + 58, 4, 6, Color("4a3020"))


## Un riflettore da palco su un treppiede.
func _prop_spotlight(img: Image, x: int, y: int) -> void:
	for i: int in 22:
		_px(img, x + 16 - i / 2, y + 42 + i, Color("2a2a30"))
		_px(img, x + 16 + i / 2, y + 42 + i, Color("2a2a30"))
	_rect(img, x + 15, y + 30, 2, 34, Color("3a3a44"))
	_rect(img, x + 7, y + 14, 18, 18, Color("1e1e24"))
	_rect(img, x + 8, y + 15, 16, 16, Color("34343e"))
	_ellipse(img, x + 16, y + 23, 6, 6, Color("fff2b0"))
	_ellipse(img, x + 15, y + 22, 3, 3, Color("ffffff"))
	_rect(img, x + 5, y + 12, 22, 2, Color("1e1e24"))


## Una quinta: un pannello dipinto su un cavalletto, con il vuoto dietro.
func _prop_flat(img: Image, x: int, y: int) -> void:
	_rect(img, x + 2, y + 4, 28, 54, Color("8a6236"))
	for yy: int in range(5, 57):
		_grain(img, x + 3, y + yy, 26, 1, Color("5b3f78").lerp(Color("9a7ad0"), float(yy) / 60.0), 0.02)
	# Un albero di cartapesta dipinto.
	_rect(img, x + 15, y + 34, 3, 20, Color("4a3020"))
	_ellipse(img, x + 16, y + 26, 10, 12, Color("2f6b4a"))
	_ellipse(img, x + 13, y + 22, 5, 5, Color("3f8a5f"))
	# Il cavalletto.
	for i: int in 14:
		_px(img, x + 26 + i / 3, y + 48 + i, Color("6a4a26"))
	_rect(img, x + 4, y + 58, 24, 3, Color("3a2416"))


## Il leggio del suggeritore, con la sua lampadina.
func _prop_stand(img: Image, x: int, y: int) -> void:
	_rect(img, x + 15, y + 30, 2, 30, Color("2a2a30"))
	_rect(img, x + 9, y + 58, 14, 3, Color("2a2a30"))
	_rect(img, x + 6, y + 22, 20, 12, Color("2a2a30"))
	_rect(img, x + 8, y + 23, 16, 9, Color("e8e0c8"))
	for yy: int in range(25, 31, 2):
		_rect(img, x + 10, y + yy, _rng.randi_range(8, 12), 1, Color("6a6050"))
	_rect(img, x + 20, y + 16, 2, 7, Color("2a2a30"))
	_ellipse(img, x + 19, y + 15, 3, 2, Color("9fd0ff"))


## Una locandina strappata.
func _prop_poster(img: Image, x: int, y: int) -> void:
	_rect(img, x + 4, y + 2, 24, 28, Color("d8c8a0"))
	_rect(img, x + 6, y + 4, 20, 6, Color("a8324a"))
	_ellipse(img, x + 16, y + 18, 5, 6, Color("efe6d0"))
	_px(img, x + 14, y + 17, Color("1a1216"))
	_px(img, x + 18, y + 17, Color("1a1216"))
	_rect(img, x + 14, y + 21, 5, 1, Color("1a1216"))
	for i: int in 6:
		_px(img, x + 24 + i % 3, y + 24 + i, Color(0, 0, 0, 0))


## Una cassa di attrezzeria.
func _prop_crate(img: Image, x: int, y: int) -> void:
	_rect(img, x + 3, y + 8, 26, 22, Color("5a3a1e"))
	_grain(img, x + 4, y + 9, 24, 20, Color("8a6236"), 0.03)
	_rect(img, x + 4, y + 18, 24, 2, Color("5a3a1e"))
	for i: int in 20:
		_px(img, x + 5 + i, y + 10 + i * 18 / 20, Color("5a3a1e"))
	_rect(img, x + 6, y + 12, 8, 3, Color("d8c8a0"))


## La porta EXIT dipinta sul fondale: la scritta rossa che si vede da tutto il
## teatro. E' tela.
func _prop_exit_door(img: Image, x: int, y: int) -> void:
	_rect(img, x + 14, y + 16, 36, 48, Color("3a2416"))
	_grain(img, x + 16, y + 18, 32, 46, Color("6a4a2e"), 0.03)
	_rect(img, x + 31, y + 18, 2, 46, Color("3a2416"))
	_ellipse(img, x + 28, y + 42, 1.5, 1.5, Color("c9a24a"))
	_ellipse(img, x + 36, y + 42, 1.5, 1.5, Color("c9a24a"))
	# L'insegna.
	_rect(img, x + 16, y + 3, 32, 11, Color("1a0c0c"))
	var red: Color = Color("ff3a3a")
	# E
	_rect(img, x + 19, y + 5, 1, 7, red)
	_rect(img, x + 19, y + 5, 4, 1, red)
	_rect(img, x + 19, y + 8, 3, 1, red)
	_rect(img, x + 19, y + 11, 4, 1, red)
	# X
	for i: int in 7:
		_px(img, x + 25 + i * 4 / 6, y + 5 + i, red)
		_px(img, x + 29 - i * 4 / 6, y + 5 + i, red)
	# I
	_rect(img, x + 33, y + 5, 1, 7, red)
	# T
	_rect(img, x + 36, y + 5, 7, 1, red)
	_rect(img, x + 39, y + 5, 1, 7, red)
	# Le pennellate: si vede che e' dipinta.
	for k: int in 6:
		_rect(img, x + _rng.randi_range(14, 44), y + _rng.randi_range(20, 60), _rng.randi_range(3, 6), 1, Color("8a6a4e"))


## Un baule da viaggio con le cinghie (riserva per i bauli minori).
func _prop_trunk(img: Image, x: int, y: int) -> void:
	_rect(img, x + 3, y + 40, 26, 20, Color("3a2416"))
	_grain(img, x + 4, y + 41, 24, 18, Color("7a2a3a"), 0.03)
	_rect(img, x + 4, y + 46, 24, 2, Color("3a2416"))
	_rect(img, x + 9, y + 41, 2, 18, Color("c9a24a"))
	_rect(img, x + 21, y + 41, 2, 18, Color("c9a24a"))
	_rect(img, x + 14, y + 47, 4, 3, Color("ffe9a0"))


## Una facciata dipinta, vista di fronte: e' una tela tesa su un telaio, con
## il cavalletto dietro. Finestre accese, una porta che non si apre.
func _prop_facade(img: Image, x: int, y: int, w: int, h: int, wall: Color, roof: Color, columns: int, pediment: bool) -> void:
	_clip = Rect2i(x, y, w, h)
	var top: int = y + 26
	var bottom: int = y + h - 6
	# Il cavalletto: due puntoni che si vedono ai lati, dietro la tela.
	for i: int in 22:
		_rect(img, x + 2 + i / 4, bottom + 4 - i, 3, 1, Color("4a3020"))
		_rect(img, x + w - 5 - i / 4, bottom + 4 - i, 3, 1, Color("4a3020"))
	# Il muro, con la grana della tela e le pennellate.
	_grain(img, x + 8, top, w - 16, bottom - top, wall, 0.025)
	for k: int in 14:
		_rect(img, x + _rng.randi_range(10, w - 22), _rng.randi_range(top + 2, bottom - 4), _rng.randi_range(4, 10), 1, wall.darkened(0.08))
	_rect(img, x + 8, top, 2, bottom - top, wall.darkened(0.3))
	_rect(img, x + w - 10, top, 2, bottom - top, wall.darkened(0.3))
	# Lo zoccolo.
	_rect(img, x + 8, bottom - 8, w - 16, 8, wall.darkened(0.35))
	# Il tetto: un frontone a triangolo, o una cornice dritta con i merli.
	if pediment:
		for row: int in 22:
			var half: int = int(float(row) / 22.0 * (w * 0.5 - 4))
			_rect(img, x + w / 2 - half, top - 22 + row, half * 2, 1, roof if row % 4 != 0 else roof.lightened(0.12))
		_ellipse(img, x + w / 2, top - 9, 5, 5, wall.lightened(0.2))
		_ellipse(img, x + w / 2, top - 9, 3, 3, Color("ffe9a0"))
	else:
		_rect(img, x + 6, top - 8, w - 12, 8, roof)
		for mx: int in range(x + 8, x + w - 10, 10):
			_rect(img, mx, top - 14, 6, 6, roof)
	_rect(img, x + 6, top - 2, w - 12, 3, roof.darkened(0.3))
	# Le finestre: cornice, luce calda dentro, persiane.
	var step: int = (w - 32) / columns
	for row: int in 2:
		for col: int in columns:
			if row == 1 and col == columns / 2:
				continue
			var wx: int = x + 16 + col * step + (step - 14) / 2
			var wy: int = top + 10 + row * 28
			_rect(img, wx - 1, wy - 1, 16, 20, wall.darkened(0.45))
			_rect(img, wx, wy, 14, 18, Color("ffd27a"))
			_rect(img, wx, wy, 14, 6, Color("ffeab0"))
			_rect(img, wx + 6, wy, 2, 18, wall.darkened(0.45))
			_rect(img, wx, wy + 8, 14, 1, wall.darkened(0.45))
			_rect(img, wx - 5, wy, 4, 18, roof.darkened(0.1))
			_rect(img, wx + 15, wy, 4, 18, roof.darkened(0.1))
			_rect(img, wx - 2, wy + 19, 18, 2, wall.darkened(0.2))
	# La porta, al centro, ad arco.
	var dw: int = 20
	var dx: int = x + w / 2 - dw / 2
	_rect(img, dx - 2, bottom - 36, dw + 4, 30, wall.darkened(0.5))
	_ellipse(img, dx + dw / 2, bottom - 36, dw / 2 + 2, 6, wall.darkened(0.5))
	_rect(img, dx, bottom - 34, dw, 28, Color("5a3422"))
	_ellipse(img, dx + dw / 2, bottom - 34, dw / 2, 5, Color("5a3422"))
	_rect(img, dx + dw / 2, bottom - 38, 1, 32, Color("3a2416"))
	_px(img, dx + dw / 2 - 3, bottom - 20, Color("c9a24a"))
	_px(img, dx + dw / 2 + 3, bottom - 20, Color("c9a24a"))
	# La cucitura della tela: si vede che e' finta.
	for yy: int in range(top, bottom - 8, 3):
		_px(img, x + w / 3, yy, wall.darkened(0.18))
	_clip = Rect2i(0, 0, img.get_width(), img.get_height())


## La baracca del Burattinaio, vista di fronte: un teatrino con il sipario
## aperto e un burattino dentro.
func _prop_puppet_stall(img: Image, x: int, y: int) -> void:
	_clip = Rect2i(x, y, 128, 96)
	_rect(img, x + 10, y + 70, 6, 24, Color("4a3020"))
	_rect(img, x + 112, y + 70, 6, 24, Color("4a3020"))
	_grain(img, x + 6, y + 20, 116, 54, Color("8a5a36"), 0.03)
	for yy: int in range(y + 24, y + 74, 6):
		_rect(img, x + 6, yy, 116, 1, Color("6a4026"))
	# Il boccascena, con il sipario rosso aperto.
	_rect(img, x + 22, y + 22, 84, 40, Color("1a0f22"))
	_rect(img, x + 22, y + 22, 84, 3, Color("c9a24a"))
	for k: int in 3:
		_rect(img, x + 22 + k * 4, y + 25, 4, 37, Color("a8283f").darkened(0.15 * k))
		_rect(img, x + 102 - k * 4, y + 25, 4, 37, Color("a8283f").darkened(0.15 * k))
	# Il burattino, appeso ai suoi fili.
	_rect(img, x + 64, y + 25, 1, 8, Color("d8d0c0"))
	_rect(img, x + 54, y + 25, 1, 21, Color("d8d0c0"))
	_rect(img, x + 74, y + 25, 1, 21, Color("d8d0c0"))
	_ellipse(img, x + 64, y + 38, 6, 6, Color("e8c89a"))
	_px(img, x + 62, y + 37, Color("1a1216"))
	_px(img, x + 66, y + 37, Color("1a1216"))
	_rect(img, x + 61, y + 41, 6, 1, Color("a8283f"))
	_rect(img, x + 58, y + 44, 12, 14, Color("2f5a6f"))
	_rect(img, x + 52, y + 46, 6, 2, Color("e8c89a"))
	_rect(img, x + 70, y + 46, 6, 2, Color("e8c89a"))
	# Il tetto a tendina, a strisce.
	for i: int in 14:
		var c: Color = Color("a8283f") if i % 2 == 0 else Color("efe6d0")
		_rect(img, x + 4 + i * 9, y + 6, 9, 12, c)
		_ellipse(img, x + 8 + i * 9, y + 18, 4, 3, c)
	_rect(img, x + 2, y + 4, 124, 3, Color("4a3020"))
	# Il bancone davanti.
	_rect(img, x + 4, y + 62, 120, 10, Color("6a4026"))
	_rect(img, x + 4, y + 62, 120, 2, Color("c9a24a"))
	_clip = Rect2i(0, 0, img.get_width(), img.get_height())


## Un lampione da palcoscenico: ghisa scura e una lanterna calda.
func _prop_lamp(img: Image, x: int, y: int) -> void:
	_clip = Rect2i(x, y, 32, 112)
	_rect(img, x + 9, y + 104, 14, 6, Color("1e1a24"))
	_rect(img, x + 11, y + 100, 10, 4, Color("2a2430"))
	_rect(img, x + 14, y + 26, 4, 76, Color("2a2430"))
	_rect(img, x + 15, y + 26, 1, 76, Color("4a4256"))
	_rect(img, x + 12, y + 60, 8, 3, Color("2a2430"))
	_rect(img, x + 8, y + 22, 16, 4, Color("1e1a24"))
	_rect(img, x + 9, y + 8, 14, 14, Color("1e1a24"))
	_rect(img, x + 10, y + 9, 12, 12, Color("ffd27a"))
	_rect(img, x + 10, y + 9, 12, 4, Color("fff2c0"))
	_rect(img, x + 15, y + 9, 2, 12, Color("1e1a24"))
	_rect(img, x + 7, y + 4, 18, 4, Color("1e1a24"))
	_rect(img, x + 13, y + 1, 6, 3, Color("1e1a24"))
	_clip = Rect2i(0, 0, img.get_width(), img.get_height())


## Il Baule di Scena, visto di fronte: legno rosso, borchie e cinghie d'oro,
## una maschera dipinta sul coperchio. [param open] lo disegna aperto, con la
## luce che esce da dentro.
func _prop_stage_chest(img: Image, x: int, y: int, open: bool) -> void:
	_clip = Rect2i(x, y, 48, 48)
	var wood: Color = Color("7a1f33")
	var gold: Color = Color("e0b44a")
	# Il corpo.
	_rect(img, x + 4, y + 22, 40, 22, Color("3a1018"))
	_grain(img, x + 5, y + 23, 38, 20, wood, 0.03)
	_rect(img, x + 5, y + 40, 38, 3, wood.darkened(0.3))
	if open:
		# Il coperchio alzato, e la luce dentro.
		_rect(img, x + 4, y + 4, 40, 14, Color("3a1018"))
		_grain(img, x + 5, y + 5, 38, 12, wood.darkened(0.15), 0.03)
		_rect(img, x + 6, y + 18, 36, 5, Color("ffe9a0"))
		_rect(img, x + 10, y + 18, 28, 2, Color("fff8d8"))
	else:
		# Il coperchio a botte.
		_rect(img, x + 4, y + 12, 40, 11, Color("3a1018"))
		_grain(img, x + 5, y + 13, 38, 9, wood.lightened(0.08), 0.03)
		_rect(img, x + 6, y + 10, 36, 3, Color("3a1018"))
		_rect(img, x + 7, y + 11, 34, 2, wood.lightened(0.15))
		# La maschera dipinta sul coperchio.
		_ellipse(img, x + 24, y + 17, 5, 4, Color("efe6d0"))
		_px(img, x + 22, y + 16, Color("1a1216"))
		_px(img, x + 26, y + 16, Color("1a1216"))
	# Le cinghie e la serratura.
	for sx: int in [x + 11, x + 35]:
		_rect(img, sx, y + (4 if open else 11), 3, 33 if open else 32, gold)
		_rect(img, sx, y + (4 if open else 11), 1, 33 if open else 32, gold.lightened(0.3))
	_rect(img, x + 21, y + 24, 6, 6, gold)
	_rect(img, x + 23, y + 26, 2, 3, Color("3a1018"))
	# Le borchie agli angoli.
	for cx: int in [x + 5, x + 42]:
		_rect(img, cx, y + 41, 2, 2, gold)
		_rect(img, cx, y + 23, 2, 2, gold)
	_clip = Rect2i(0, 0, img.get_width(), img.get_height())


#endregion
