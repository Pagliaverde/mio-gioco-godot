## Disegna in pixel art la faccia di una carta del menu.
##
## [b]Niente immagini da importare:[/b] la carta viene dipinta pixel per pixel
## in un'[Image] piccola (un pixel della carta = [constant PX] pixel sullo
## schermo) e poi ingrandita senza filtro, cosi' resta pixel art vera.
##
## [b]Cosa ci disegna sopra:[/b] carta vecchia con la grana, bordi bruciati
## dal tempo, angoli scheggiati, a volte un'orecchia piegata, crepe con il
## riflesso di luce, macchie e fibre. Tutto e' deciso da un [code]seed[/code]:
## la stessa voce ha sempre le stesse crepe, voci diverse sono diverse.
class_name MenuCardArt extends RefCounted


## Quanti pixel dello schermo vale un pixel della carta.
const PX: int = 4

const INK := Color("2b1d14")
const PAPER_LIGHT := Color("efe2c0")
const PAPER := Color("dccb9d")
const PAPER_DARK := Color("c2a977")
const PAPER_BURN := Color("9a7a4c")
const EDGE := Color("5e4329")
const CRACK := Color("4a3220")
const CRACK_LIGHT := Color("fff6dd")
const FRAME := Color("7a5a36")

# I colori con cui si dipinge la carta in corso. Li prepara [method _set_palette]
# a partire dallo stile scelto nelle impostazioni (carta, inchiostro).
static var _ink: Color = INK
static var _paper: Color = PAPER
static var _paper_light: Color = PAPER_LIGHT
static var _paper_dark: Color = PAPER_DARK
static var _paper_burn: Color = PAPER_BURN
static var _edge: Color = EDGE
static var _crack: Color = CRACK
static var _crack_light: Color = CRACK_LIGHT
static var _frame: Color = FRAME
static var _wear: float = 0.6

## Matrice di Bayer 4x4: decide dove mettere i puntini del dithering.
const BAYER4: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


#region Emblemi

## I simboli che stanno dentro il riquadro della carta.
##
## [b]Sono matrici di pixel scritte a mano,[/b] una riga per riga di pixel
## della carta. Si leggono come un disegno: cambia un carattere e cambi un
## pixel. Ogni matrice e' 16 x 16.
##
## I caratteri:
## [codeblock]
##   .   niente: si vede il riquadro della carta
##   #   inchiostro: il contorno, e le parti scure
##   -   carta chiara: il riempimento
##   +   luce: il bianco, per i punti in rilievo
## [/codeblock]
##
## [b]Perche' disegnati cosi' e non come immagini.[/b] Perche' cosi' nascono
## sulla stessa griglia di pixel della carta, quindi non si puo' sbagliare
## l'allineamento, e soprattutto [b]invecchiano con la carta[/b]: macchie,
## puntini e crepe ci passano sopra come su tutto il resto. Un'immagine
## incollata sopra resterebbe nuova e pulita in mezzo a una carta vecchia.
const EMBLEMS: Dictionary = {

	# Una maschera che sorride: e' il segno del gioco.
	&"mask": [
		"................",
		"....########....",
		"..##--------##..",
		".#------------#.",
		".#--##----##--#.",
		".#--##----##--#.",
		".#------------#.",
		".#------------#.",
		".#------------#.",
		".#---##--##---#.",
		".#----####----#.",
		".#------------#.",
		".#------------#.",
		"..##--------##..",
		"....########....",
		"................",
	],

	# Un mazzo di carte appoggiate, con un seme su quella in cima.
	&"deck": [
		"................",
		"................",
		"..############..",
		"..#----##----#..",
		"..#---#++#---#..",
		"..#----##----#..",
		"..############..",
		"...#----------#.",
		"...#----------#.",
		"...############.",
		"....#----------#",
		"....#----------#",
		"....############",
		"................",
		"................",
		"................",
	],

	# Una tenda a righe sopra il bancone.
	&"shop": [
		"................",
		"..##.##.##.##...",
		"..##.##.##.##...",
		"..############..",
		"..#----------#..",
		"..#----------#..",
		"..#----------#..",
		"..#---####---#..",
		"..#----------#..",
		"..#----------#..",
		"..#----------#..",
		"..############..",
		"................",
		"................",
		"................",
		"................",
	],

	# Un ingranaggio con quattro denti.
	&"gear": [
		"......#--#......",
		"......#--#......",
		"......#--#......",
		"..############..",
		"..#----------#..",
		"..#----------#..",
		"###---####---###",
		"..#---#..#---#..",
		"..#---#..#---#..",
		"###---####---###",
		"..#----------#..",
		"..#----------#..",
		"..############..",
		"......#--#......",
		"......#--#......",
		"......#--#......",
	],

	# Una spada in verticale: il combattimento.
	&"sword": [
		"................",
		"......####......",
		"......#--#......",
		"....########....",
		"....########....",
		"......#--#......",
		"......#--#......",
		"......#--#......",
		"......#--#......",
		"......#--#......",
		"......#--#......",
		".......##.......",
		".......##.......",
		"........#.......",
		"................",
		"................",
	],

	# Una porta con la freccia che esce: si chiude qui.
	&"exit": [
		"................",
		"..#####.........",
		"..#---#.........",
		"..#---#.........",
		"..#---#...##....",
		"..#---#....##...",
		"..#---#.....####",
		"..#---#.....####",
		"..#---#....##...",
		"..#---#...##....",
		"..#---#.........",
		"..#---#.........",
		"..#####.........",
		"................",
		"................",
		"................",
	],

	# Un triangolo: riprendi.
	&"play": [
		"................",
		"................",
		"..######........",
		"..#----##.......",
		"..#------##.....",
		"..#--------##...",
		"..#----------##.",
		"..#-----------##",
		"..#-----------##",
		"..#----------##.",
		"..#--------##...",
		"..#------##.....",
		"..#----##.......",
		"..######........",
		"................",
		"................",
	],

	# Una croce: si ricomincia.
	&"plus": [
		"................",
		"......####......",
		"......#--#......",
		"......#--#......",
		"......#--#......",
		"..############..",
		"..#----------#..",
		"..#----------#..",
		"..#----------#..",
		"..############..",
		"......#--#......",
		"......#--#......",
		"......#--#......",
		"......#--#......",
		"................",
		"................",
	],
}

## Quanti pixel e' largo e alto un emblema.
const EMBLEM_SIZE: int = 16

## Quanta parte del riquadro occupa l'emblema, da 0 a 1.
##
## Lascia un margine: un simbolo che tocca i bordi del riquadro sembra
## disegnato male, non "grande".
const EMBLEM_FILL: float = 0.74

#endregion


## Disegna una carta.
##
## Restituisce un [Dictionary] con:
## [br]- [code]face[/code]: la carta ([ImageTexture])
## [br]- [code]glow[/code]: il contorno di selezione, bianco, 2 pixel piu' largo per lato
## [br]- [code]shadow[/code]: la sagoma nera della carta, per l'ombra
## [br]- [code]window[/code]: il riquadro dell'illustrazione, in pixel della carta
## [br]- [code]plaque[/code]: il cartiglio del titolo, in pixel della carta
##
## [param style] (facoltativo, di solito [code]Settings.card_style()[/code]):
## [code]paper[/code] e [code]ink[/code] sono i colori della carta e
## dell'inchiostro, [code]wear[/code] l'usura da 0 (nuova) a 1 (a pezzi).
##
## [param emblem] (facoltativo): il nome di un simbolo di [constant EMBLEMS]
## da disegnare dentro il riquadro. Vuoto = nessun simbolo.
static func build(card_size: Vector2, accent: Color, seed: int, enabled: bool, style: Dictionary = {}, emblem: StringName = &"") -> Dictionary:
	_set_palette(style)
	var w: int = maxi(int(card_size.x) / PX, 40)
	var h: int = maxi(int(card_size.y) / PX, 56)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.09

	var mask: PackedByteArray = _build_mask(w, h, rng)
	var flap: Dictionary = _cut_dog_ear(mask, w, h, rng)
	var dist: PackedInt32Array = _edge_distance(mask, w, h)

	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	_paint_paper(img, mask, dist, w, h, noise)

	var window: Rect2i = Rect2i(9, 9, w - 18, h - 9 - 33)
	var plaque: Rect2i = Rect2i(7, h - 30, w - 14, 19)

	_paint_frame(img, dist, w, h, accent)
	_paint_window(img, window, accent)
	# L'emblema va [b]dopo il riquadro e prima della vecchiaia[/b]: cosi' le
	# macchie, i puntini e le crepe gli passano sopra, e il simbolo sembra
	# consumato come tutto il resto invece di essere appiccicato sopra.
	var emblem_drawn: bool = _paint_emblem(img, window, emblem)
	_paint_plaque(img, plaque, accent)
	_paint_stains(img, mask, w, h, rng)
	_paint_specks(img, mask, dist, w, h, rng)
	_paint_cracks(img, mask, dist, w, h, rng, plaque)
	_paint_flap(img, flap)

	if not enabled:
		_desaturate(img, mask, w, h)

	return {
		"face": ImageTexture.create_from_image(img),
		"glow": ImageTexture.create_from_image(_build_glow(mask, w, h)),
		"shadow": ImageTexture.create_from_image(_build_shadow(mask, w, h)),
		"window": window,
		"plaque": plaque,
		"emblem_drawn": emblem_drawn,
	}


#region Sagoma


## La forma della carta: 1 = carta, 0 = vuoto.
##
## Angoli smussati a scaletta, piu' qualche scheggia lungo i bordi: una carta
## che e' passata per tante mani non ha i bordi dritti.
static func _build_mask(w: int, h: int, rng: RandomNumberGenerator) -> PackedByteArray:
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(w * h)
	mask.fill(1)

	# Angoli arrotondati a scaletta.
	for y: int in h:
		for x: int in w:
			var dx: int = mini(x, w - 1 - x)
			var dy: int = mini(y, h - 1 - y)
			if dx + dy < 3:
				mask[y * w + x] = 0

	# Schegge: piccole tacche lungo i bordi.
	var chips: int = rng.randi_range(roundi(_wear * 5.0), roundi(_wear * 12.0))
	for _i: int in chips:
		var side: int = rng.randi_range(0, 3)
		var length: int = rng.randi_range(1, 4)
		var depth: int = 2 if rng.randf() < 0.25 else 1
		var along: int = rng.randi_range(5, (w if side < 2 else h) - 6 - length)
		for k: int in length:
			# Le tacche sono piu' profonde al centro, come un morso.
			var d: int = depth if (k > 0 and k < length - 1) else 1
			for j: int in d:
				var p: Vector2i
				match side:
					0:
						p = Vector2i(along + k, j)
					1:
						p = Vector2i(along + k, h - 1 - j)
					2:
						p = Vector2i(j, along + k)
					_:
						p = Vector2i(w - 1 - j, along + k)
				mask[p.y * w + p.x] = 0

	return mask


## A volte un angolo e' piegato: lo tagliamo dalla sagoma e ricordiamo dove
## disegnare il lembo ripiegato sopra la carta.
static func _cut_dog_ear(mask: PackedByteArray, w: int, h: int, rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() > _wear * 0.9:
		return {}

	var s: int = rng.randi_range(6, 9)
	var corner: int = rng.randi_range(0, 3)
	var pixels: Array[Vector2i] = []
	var edge: Array[Vector2i] = []

	for dy: int in range(s + 1):
		for dx: int in range(s + 1):
			var x: int = dx if corner % 2 == 0 else w - 1 - dx
			var y: int = dy if corner < 2 else h - 1 - dy
			if dx + dy < s:
				mask[y * w + x] = 0
			elif dx + dy <= s * 2 - 1 and dx <= s and dy <= s:
				# Il lembo ripiegato e' lo specchio del triangolo tagliato.
				if dx + dy == s or dx == s or dy == s:
					edge.append(Vector2i(x, y))
				else:
					pixels.append(Vector2i(x, y))

	return {"pixels": pixels, "edge": edge}


## Quanto dista ogni pixel dal bordo della carta (1 = sul bordo).
static func _edge_distance(mask: PackedByteArray, w: int, h: int) -> PackedInt32Array:
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(w * h)
	dist.fill(999)

	var queue: Array[Vector2i] = []
	for y: int in h:
		for x: int in w:
			if mask[y * w + x] == 0:
				dist[y * w + x] = 0
				queue.append(Vector2i(x, y))
			elif x == 0 or y == 0 or x == w - 1 or y == h - 1:
				dist[y * w + x] = 1
				queue.append(Vector2i(x, y))

	var head: int = 0
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		var next: int = dist[p.y * w + p.x] + 1
		for d: Vector2i in dirs:
			var q: Vector2i = p + d
			if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
				continue
			if dist[q.y * w + q.x] > next:
				dist[q.y * w + q.x] = next
				queue.append(q)
	return dist


#endregion

#region Pittura


## La carta: grana a macchie con il dithering, e i bordi scuriti dal tempo.
static func _paint_paper(
	img: Image, mask: PackedByteArray, dist: PackedInt32Array,
	w: int, h: int, noise: FastNoiseLite
) -> void:
	for y: int in h:
		for x: int in w:
			if mask[y * w + x] == 0:
				continue
			var b: float = _bayer(x, y)
			var n: float = noise.get_noise_2d(float(x), float(y) * 1.4)
			var t: float = 0.5 + 0.5 * n + (b - 0.5) * 0.35

			var c: Color = _paper
			if t > 0.66:
				c = _paper_light
			elif t < 0.34:
				c = _paper_dark

			# Bordo consumato: lo spessore della bruciatura varia lungo il bordo.
			var d: int = dist[y * w + x]
			var wear: int = 1 if noise.get_noise_2d(float(x) * 2.0 + 50.0, float(y) * 2.0) > 0.25 else 0
			if _wear < 0.2:
				wear = -1
			if d <= 1:
				c = _edge
			elif d <= 2 + wear:
				c = _paper_burn
			elif d == 3 + wear and b < 0.5:
				c = _paper_burn
			elif d == 4 + wear and b < 0.3:
				c = _paper_dark

			img.set_pixel(x, y, c)


## La cornice interna a inchiostro, con una riga del colore della voce e i
## rombi negli angoli.
static func _paint_frame(img: Image, dist: PackedInt32Array, w: int, h: int, accent: Color) -> void:
	var accent_line: Color = accent.darkened(0.30)
	_rect_outline(img, dist, w, Rect2i(5, 5, w - 10, h - 10), _frame)
	_rect_outline(img, dist, w, Rect2i(6, 6, w - 12, h - 12), accent_line)

	for corner: Vector2i in [Vector2i(5, 5), Vector2i(w - 6, 5), Vector2i(5, h - 6), Vector2i(w - 6, h - 6)]:
		for d: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			_put(img, dist, w, corner + d, _ink)
		_put(img, dist, w, corner, accent.lightened(0.25))


## Il riquadro dell'illustrazione: incassato nella carta, con un cielo del
## colore della voce, sfumato a puntini, e qualche raggio di luce.
static func _paint_window(img: Image, r: Rect2i, accent: Color) -> void:
	var top: Color = accent.darkened(0.10)
	var mid: Color = accent.darkened(0.35)
	var low: Color = accent.darkened(0.58)

	for y: int in range(r.position.y, r.end.y):
		for x: int in range(r.position.x, r.end.x):
			var t: float = float(y - r.position.y) / float(maxi(r.size.y - 1, 1))
			var b: float = _bayer(x, y)
			var c: Color = top
			if t + (b - 0.5) * 0.25 > 0.66:
				c = low
			elif t + (b - 0.5) * 0.25 > 0.33:
				c = mid

			# Raggi di luce in diagonale, appena accennati.
			if posmod(x - y, 11) < 2 and b < 0.5:
				c = c.lightened(0.12)
			img.set_pixel(x, y, c)

	# Incasso: bordo d'inchiostro, ombra dentro in alto a sinistra,
	# luce fuori in basso a destra.
	for x: int in range(r.position.x - 1, r.end.x + 1):
		img.set_pixel(x, r.position.y - 1, _ink)
		img.set_pixel(x, r.end.y, _ink)
		if x > r.position.x - 1:
			img.set_pixel(x, r.end.y + 1, _paper_light)
		if x >= r.position.x:
			img.set_pixel(x, r.position.y, low.darkened(0.45))
	for y: int in range(r.position.y - 1, r.end.y + 1):
		img.set_pixel(r.position.x - 1, y, _ink)
		img.set_pixel(r.end.x, y, _ink)
		if y > r.position.y - 1:
			img.set_pixel(r.end.x + 1, y, _paper_light)
		if y >= r.position.y:
			img.set_pixel(r.position.x, y, low.darkened(0.45))


## L'emblema della voce, dentro il riquadro dell'illustrazione.
##
## Ritorna true se ha disegnato qualcosa: la carta usa quel valore per sapere
## se nascondere la lettera di ripiego.
##
## [b]Come e' fatto.[/b] La matrice e' 16 x 16 pixel [i]della carta[/i]. Qui si
## calcola di quanto ingrandirla per riempire il riquadro lasciando un margine
## ([constant EMBLEM_FILL]), si centra, e si dipinge pixel per pixel stando
## dentro il riquadro.
##
## [b]Perche' c'e' l'ombra.[/b] Prima di disegnare il simbolo ne disegna la
## sagoma spostata in basso a destra. Su un fondo scuro un'ombra netta di un
## pixel basta a staccare il simbolo dal riquadro: e' lo stesso trucco della
## cornice della carta.
static func _paint_emblem(img: Image, r: Rect2i, emblem: StringName) -> bool:
	if emblem == &"":
		return false

	if not EMBLEMS.has(emblem):
		push_warning("MenuCardArt: emblema sconosciuto '%s'. Uso la lettera." % emblem)
		return false

	var rows: Array = EMBLEMS[emblem]
	if rows.size() != EMBLEM_SIZE:
		push_warning("MenuCardArt: l'emblema '%s' ha %d righe invece di %d." % [
			emblem, rows.size(), EMBLEM_SIZE
		])
		return false

	# Quanto ingrandire: il piu' grande che entra nel riquadro col margine.
	var scale: int = maxi(1, int(minf(
		float(r.size.x) * EMBLEM_FILL / float(EMBLEM_SIZE),
		float(r.size.y) * EMBLEM_FILL / float(EMBLEM_SIZE)
	)))
	var drawn: Vector2i = Vector2i(EMBLEM_SIZE * scale, EMBLEM_SIZE * scale)

	# Centrato nel riquadro. Arrotondato al pixel: un mezzo pixel sfocherebbe
	# tutto e si perderebbe la pixel art.
	var origin: Vector2i = Vector2i(
		r.position.x + (r.size.x - drawn.x) / 2,
		r.position.y + (r.size.y - drawn.y) / 2
	)

	# Prima l'ombra, poi il simbolo sopra.
	for pass_index: int in 2:
		var offset: int = scale if pass_index == 0 else 0

		for row: int in EMBLEM_SIZE:
			var line: String = rows[row]
			for col: int in EMBLEM_SIZE:
				var glyph: String = line[col]
				if glyph == ".":
					continue

				var colour: Color = _ink
				if pass_index == 1:
					match glyph:
						"-":
							colour = _paper_light
						"+":
							colour = Color(1.0, 0.99, 0.93)

				# Un pixel della matrice diventa un quadrato di `scale` pixel.
				for dy: int in scale:
					for dx: int in scale:
						var px: int = origin.x + col * scale + dx + offset
						var py: int = origin.y + row * scale + dy + offset
						# Non usciamo dal riquadro: l'emblema non deve
						# sbordare sulla cornice della carta.
						if px < r.position.x or py < r.position.y or px >= r.end.x or py >= r.end.y:
							continue
						img.set_pixel(px, py, colour)

	return true


## Il cartiglio del titolo: un nastro con le code a V.
static func _paint_plaque(img: Image, r: Rect2i, accent: Color) -> void:
	var mid_y: int = r.position.y + r.size.y / 2
	var inside: Callable = func(x: int, y: int) -> bool:
		if y < r.position.y or y >= r.end.y:
			return false
		var notch: int = maxi(0, 4 - absi(y - mid_y))
		return x >= r.position.x + notch and x < r.end.x - notch

	for y: int in range(r.position.y, r.end.y):
		for x: int in range(r.position.x, r.end.x):
			if not inside.call(x, y):
				continue
			var border: bool = (
				not inside.call(x - 1, y) or not inside.call(x + 1, y)
				or not inside.call(x, y - 1) or not inside.call(x, y + 1)
			)
			var c: Color = _paper_light if _bayer(x, y) > 0.2 else _paper
			if border:
				c = _ink
			elif not inside.call(x, y - 2):
				c = Color(1.0, 0.98, 0.90)
			elif not inside.call(x, y + 2):
				c = _paper_dark
			img.set_pixel(x, y, c)

	# Due borchie del colore della voce alle estremita'.
	for x: int in [r.position.x + 6, r.end.x - 7]:
		img.set_pixel(x, mid_y, accent.darkened(0.2))
		img.set_pixel(x, mid_y - 1, accent.lightened(0.35))


## Macchie ad anello, come il fondo di una tazza appoggiata sulla carta.
static func _paint_stains(img: Image, mask: PackedByteArray, w: int, h: int, rng: RandomNumberGenerator) -> void:
	for _i: int in rng.randi_range(roundi(_wear), roundi(_wear * 3.0)):
		var center: Vector2 = Vector2(rng.randf_range(8.0, w - 8.0), rng.randf_range(8.0, h - 8.0))
		var radius: float = rng.randf_range(3.5, 7.5)
		for y: int in range(int(center.y - radius) - 2, int(center.y + radius) + 3):
			for x: int in range(int(center.x - radius) - 2, int(center.x + radius) + 3):
				if x < 0 or y < 0 or x >= w or y >= h or mask[y * w + x] == 0:
					continue
				var d: float = Vector2(x, y).distance_to(center)
				var b: float = _bayer(x, y)
				if absf(d - radius) < 0.8 and b < 0.7:
					img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.14))
				elif d < radius and b < 0.18:
					img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.07))


## Fibre e puntini: la carta non e' mai uniforme.
static func _paint_specks(
	img: Image, mask: PackedByteArray, dist: PackedInt32Array,
	w: int, h: int, rng: RandomNumberGenerator
) -> void:
	var count: int = int(float(w * h) * 0.004 + float(w * h) * 0.016 * _wear)
	for _i: int in count:
		var x: int = rng.randi_range(0, w - 1)
		var y: int = rng.randi_range(0, h - 1)
		if mask[y * w + x] == 0 or dist[y * w + x] < 3:
			continue
		var c: Color = img.get_pixel(x, y)
		img.set_pixel(x, y, c.darkened(0.22) if rng.randf() < 0.7 else c.lightened(0.18))


## Le crepe: partono dal bordo e camminano verso l'interno, a zig-zag,
## qualche volta si dividono in due. Ogni pixel di crepa ha sotto a destra un
## pixel di luce: e' quello che le fa sembrare incise e non disegnate.
##
## Si fermano sul bordo del cartiglio: il titolo deve restare leggibile.
static func _paint_cracks(
	img: Image, mask: PackedByteArray, dist: PackedInt32Array,
	w: int, h: int, rng: RandomNumberGenerator, keep_clear: Rect2i
) -> void:
	var starts: Array[Vector2i] = []
	for y: int in h:
		for x: int in w:
			if dist[y * w + x] == 2:
				starts.append(Vector2i(x, y))
	if starts.is_empty():
		return

	var crack_pixels: Dictionary = {}
	for _i: int in rng.randi_range(roundi(_wear * 3.0), roundi(_wear * 7.0)):
		var start: Vector2i = starts[rng.randi_range(0, starts.size() - 1)]
		# Verso l'interno: dal punto di partenza verso il centro, piu' un po' di caso.
		var to_center: Vector2 = (Vector2(w, h) * 0.5 - Vector2(start)).normalized()
		var angle: float = to_center.angle() + rng.randf_range(-0.7, 0.7)
		_walk_crack(crack_pixels, mask, dist, w, h, rng, keep_clear, Vector2(start), angle, rng.randi_range(10, 26), 0)

	# Prima la luce, poi la crepa: cosi' la luce non copre mai la crepa.
	for p: Vector2i in crack_pixels:
		var lit: Vector2i = p + Vector2i(1, 1)
		if lit.x < w and lit.y < h and mask[lit.y * w + lit.x] == 1 and not crack_pixels.has(lit):
			img.set_pixel(lit.x, lit.y, _crack_light.lerp(img.get_pixel(lit.x, lit.y), 0.35))
	for p: Vector2i in crack_pixels:
		var deep: bool = crack_pixels[p]
		img.set_pixel(p.x, p.y, _crack if deep else _crack.lerp(img.get_pixel(p.x, p.y), 0.35))


static func _walk_crack(
	out: Dictionary, mask: PackedByteArray, dist: PackedInt32Array,
	w: int, h: int, rng: RandomNumberGenerator, keep_clear: Rect2i,
	pos: Vector2, angle: float, length: int, generation: int
) -> void:
	for step: int in length:
		angle += rng.randf_range(-0.55, 0.55)
		pos += Vector2.from_angle(angle)
		var p: Vector2i = Vector2i(roundi(pos.x), roundi(pos.y))
		if p.x < 1 or p.y < 1 or p.x >= w - 1 or p.y >= h - 1:
			return
		if mask[p.y * w + p.x] == 0 or dist[p.y * w + p.x] < 2:
			return
		if keep_clear.grow(-1).has_point(p):
			return

		# Vicino al bordo la crepa e' piu' aperta: due pixel invece di uno.
		var deep: bool = step < length / 3 and generation == 0
		out[p] = true
		if deep:
			var side: Vector2 = Vector2.from_angle(angle + PI * 0.5)
			out[p + Vector2i(roundi(side.x), roundi(side.y))] = true
		elif step > length * 2 / 3 and rng.randf() < 0.35:
			# In punta la crepa sfuma: qualche pixel saltato, piu' chiaro.
			out[p] = false

		if generation < 2 and step > 2 and rng.randf() < 0.12:
			var turn: float = 0.9 if rng.randf() < 0.5 else -0.9
			_walk_crack(out, mask, dist, w, h, rng, keep_clear, pos, angle + turn, length / 2, generation + 1)


## Il lembo dell'orecchia piegata, appoggiato sopra la carta.
static func _paint_flap(img: Image, flap: Dictionary) -> void:
	if flap.is_empty():
		return
	for p: Vector2i in flap["pixels"]:
		# Il retro della carta e' piu' scuro e un po' rosato.
		img.set_pixel(p.x, p.y, _paper_dark.lerp(_paper_burn, 0.25) if _bayer(p.x, p.y) < 0.5 else _paper_dark)
	for p: Vector2i in flap["edge"]:
		img.set_pixel(p.x, p.y, _edge)


## Le carte spente perdono il colore.
static func _desaturate(img: Image, mask: PackedByteArray, w: int, h: int) -> void:
	for y: int in h:
		for x: int in w:
			if mask[y * w + x] == 0:
				continue
			var c: Color = img.get_pixel(x, y)
			var l: float = c.get_luminance()
			img.set_pixel(x, y, c.lerp(Color(l, l, l), 0.8).darkened(0.12))


#endregion

#region Contorno e ombra


## Il contorno di selezione: due anelli di pixel attorno alla sagoma.
static func _build_glow(mask: PackedByteArray, w: int, h: int) -> Image:
	var img: Image = Image.create_empty(w + 4, h + 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y: int in h + 4:
		for x: int in w + 4:
			if _mask_at(mask, w, h, x - 2, y - 2):
				continue
			var near: int = 3
			for oy: int in range(-2, 3):
				for ox: int in range(-2, 3):
					if _mask_at(mask, w, h, x - 2 + ox, y - 2 + oy):
						near = mini(near, maxi(absi(ox), absi(oy)))
			if near == 1:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
			elif near == 2 and _bayer(x, y) < 0.5:
				img.set_pixel(x, y, Color(1, 1, 1, 0.6))
	return img


static func _build_shadow(mask: PackedByteArray, w: int, h: int) -> Image:
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y: int in h:
		for x: int in w:
			if mask[y * w + x] == 1:
				img.set_pixel(x, y, Color(0, 0, 0, 1))
	return img


#endregion

#region Utility


## Prepara i colori della carta: tutti i toni nascono da due colori soli,
## carta e inchiostro. Cosi' un tema nuovo non deve sceglierne nove.
static func _set_palette(style: Dictionary) -> void:
	var paper: Color = style.get("paper", PAPER)
	var ink: Color = style.get("ink", INK)
	_wear = clampf(float(style.get("wear", 0.6)), 0.0, 1.0)
	_ink = ink
	_paper = paper
	_paper_light = paper.lerp(Color.WHITE, 0.4)
	_paper_dark = paper.lerp(ink, 0.12)
	_paper_burn = paper.lerp(ink, 0.35 + _wear * 0.1)
	_edge = paper.lerp(ink, 0.72)
	_crack = paper.lerp(ink, 0.82)
	_crack_light = paper.lerp(Color.WHITE, 0.75)
	_frame = paper.lerp(ink, 0.55)


static func _bayer(x: int, y: int) -> float:
	return (float(BAYER4[posmod(y, 4) * 4 + posmod(x, 4)]) + 0.5) / 16.0


static func _mask_at(mask: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	return mask[y * w + x] == 1


## Mette un pixel solo se e' ben dentro la carta (non sul bordo consumato).
static func _put(img: Image, dist: PackedInt32Array, w: int, p: Vector2i, c: Color) -> void:
	if p.x < 0 or p.y < 0 or p.x >= w or p.y >= img.get_height():
		return
	if dist[p.y * w + p.x] < 3:
		return
	img.set_pixel(p.x, p.y, c)


static func _rect_outline(img: Image, dist: PackedInt32Array, w: int, r: Rect2i, c: Color) -> void:
	for x: int in range(r.position.x, r.end.x):
		_put(img, dist, w, Vector2i(x, r.position.y), c)
		_put(img, dist, w, Vector2i(x, r.end.y - 1), c)
	for y: int in range(r.position.y, r.end.y):
		_put(img, dist, w, Vector2i(r.position.x, y), c)
		_put(img, dist, w, Vector2i(r.end.x - 1, y), c)


#endregion
