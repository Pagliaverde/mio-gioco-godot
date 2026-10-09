## I disegni del negozio: la moneta, il festone della bancarella, il cartellino.
##
## [b]Perche' in codice e non in PNG:[/b] e' quello che fa gia' il resto del
## gioco ([MenuCardArt] disegna le carte del menu, [CardArtPainter] le
## illustrazioni). Cosi' l'icona [i]segue i colori del tema[/i]: se il giocatore
## cambia tavolozza nelle impostazioni, cambia anche la moneta. Un PNG no.
##
## [b]I disegni sono matrici di caratteri,[/b] come gli emblemi del menu: si
## leggono a colpo d'occhio e si correggono in un secondo. Il punto e' il
## carattere, il colore lo decide [method _palette].
class_name ShopArt extends RefCounted


## La moneta, 12x12.
##
## [code]o[/code] contorno (inchiostro), [code]#[/code] oro scuro,
## [code]g[/code] oro, [code]l[/code] oro chiaro (la luce arriva da in alto a
## sinistra, come tutto il resto del gioco), [code].[/code] trasparente.
const COIN: PackedStringArray = [
	"....oooo....",
	"..oo####oo..",
	".o##gggg##o.",
	"o##ggllgg##o",
	"o#ggllllgg#o",
	"o#ggllllgg#o",
	"o#ggllllgg#o",
	"o#ggllllgg#o",
	"o##ggllgg##o",
	".o##gggg##o.",
	"..oo####oo..",
	"....oooo....",
]

## I nomi dei colori, per il punto di sostituzione.
const COIN_CHARS: Dictionary = {
	"o": "ink",
	"#": "dark",
	"g": "gold",
	"l": "light",
}


## La moneta, scalata di [param scale] pixel per punto.
##
## [param gold] e' il colore del metallo (di solito l'accento del tema) e
## [param ink] il contorno. Le due sfumature si ricavano da [param gold]: non
## serve un colore in piu' da tenere aggiornato.
static func coin(scale: int, gold: Color, ink: Color) -> ImageTexture:
	var colors: Dictionary = {
		"ink": ink,
		"dark": gold.darkened(0.32),
		"gold": gold,
		"light": gold.lightened(0.42),
	}
	return _from_matrix(COIN, COIN_CHARS, colors, scale)


## Il festone della bancarella: una striscia di triangoli alternati.
##
## E' quello che trasforma un pannello in una [i]bancarella[/i]. Va messo sotto
## all'intestazione, largo quanto il pannello, e non copre nulla.
##
## [param tiles] quanti triangoli, [param tile_width] la loro larghezza in
## pixel, [param height] l'altezza totale della striscia.
static func valance(tiles: int, tile_width: int, height: int, color_a: Color, color_b: Color, ink: Color) -> ImageTexture:
	var width: int = maxi(tiles, 1) * maxi(tile_width, 2)
	var h: int = maxi(height, 3)
	var img: Image = Image.create(width, h, false, Image.FORMAT_RGBA8)

	# La fascia piena in cima, alta un quarto: e' il bastone a cui e' appeso.
	var bar: int = maxi(h / 4, 1)
	for x: int in width:
		for y: int in h:
			img.set_pixel(x, y, ink)
	for x: int in width:
		for y: int in bar:
			img.set_pixel(x, y, color_a if (x / maxi(tile_width, 2)) % 2 == 0 else color_b)

	# I triangoli, appesi sotto alla fascia, che si assottigliano verso il basso.
	var drop: int = h - bar
	for t: int in maxi(tiles, 1):
		var base_x: int = t * maxi(tile_width, 2)
		var fill: Color = color_a if t % 2 == 0 else color_b
		for x: int in maxi(tile_width, 2):
			# Altezza del triangolo in questa colonna: 0 ai bordi, piena al centro.
			var half: float = float(maxi(tile_width, 2)) * 0.5
			var distance: float = abs(float(x) - half + 0.5)
			var column_h: int = int(round((half - distance) / half * float(drop)))
			for y: int in column_h:
				var px: int = base_x + x
				if px >= 0 and px < width:
					img.set_pixel(px, bar + y, fill)

	return ImageTexture.create_from_image(img)


## Disegna una matrice di caratteri, ingrandita di [param scale].
##
## Un carattere assente da [param chars] resta trasparente: cosi' un errore di
## battitura si vede subito invece di colorare a caso.
static func _from_matrix(matrix: PackedStringArray, chars: Dictionary, colors: Dictionary, scale: int) -> ImageTexture:
	var size: int = maxi(scale, 1)
	var rows: int = matrix.size()
	var cols: int = 0
	for row: String in matrix:
		cols = maxi(cols, row.length())

	var img: Image = Image.create(cols * size, rows * size, false, Image.FORMAT_RGBA8)

	for y: int in rows:
		var row: String = matrix[y]
		for x: int in row.length():
			var key: String = row[x]
			if not chars.has(key):
				continue
			var color_name: String = chars[key]
			if not colors.has(color_name):
				continue
			var color: Color = colors[color_name]
			for dy: int in size:
				for dx: int in size:
					img.set_pixel(x * size + dx, y * size + dy, color)

	return ImageTexture.create_from_image(img)
