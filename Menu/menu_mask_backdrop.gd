## Le maschere che fluttuano dietro al menu principale.
##
## [b]Cosa fa:[/b] prende il foglio delle maschere
## ([code]Menu/img/mask2BgRemoved.png[/code]: 60 maschere in griglia 10x6), lo
## [b]ritaglia da solo[/b] e mette ogni maschera a fluttuare lentamente sullo
## schermo. Non devi ritagliare niente a mano.
##
## [b]Se vuoi il risultato perfetto:[/b] metti le maschere gia' separate come
## singoli png in [member masks_folder]. E' l'unico caso in cui non c'e' proprio
## niente da calcolare. Col foglio di default il ritaglio e' comunque esatto.
##
## [b]Come le ritaglia:[/b] cerca le colonne e le righe di disegno separate da
## spazio vuoto e le incrocia. I riquadri cadono esattamente intorno a ogni
## maschera, con 2 pixel di margine per recuperare il bordo sfumato.
##
## [b]La profondita':[/b] ogni maschera ha una "distanza" casuale che decide
## insieme dimensione, velocita' e trasparenza. Le lontane sono piccole, lente e
## sbiadite; le vicine grandi e piu' nette. E' quello che da' l'impressione di
## profondita' invece di un semplice scorrimento piatto.
##
## [b]Movimento ridotto:[/b] se il giocatore ha scelto "Riduci il movimento"
## (Accessibilita'), le maschere restano ferme dove sono. E' un'impostazione sua,
## non una tua scelta: non aggirarla.
##
## [b]Dove si usa:[/b] lo crea [code]main_menu.gd[/code] dentro il menu. Vedi
## anche [code]Menu/README.md[/code].
class_name MenuMaskBackdrop extends Control


## Il foglio di default: 60 maschere in griglia 10x6, ben distanziate.
##
## [b]Deve avere lo sfondo trasparente[/b] (png). Il jpg con il fondo bianco non
## si puo' ne' ritagliare ne' disegnare sul sipario senza mostrare i rettangoli.
const DEFAULT_SHEET_PATH := "res://Menu/img/mask2BgRemoved.png"

## Sotto questa soglia di alpha un pixel e' considerato vuoto.
const ALPHA_THRESHOLD := 8

## Sopra questa soglia un pixel e' "pieno": e' il disegno, non l'alone.
##
## [b]Le bande si cercano su questo,[/b] non su [constant ALPHA_THRESHOLD]: con la
## soglia bassa gli aloni di maschere vicine si unirebbero e le bande
## risulterebbero attaccate.
const CONTENT_ALPHA := 128

## Quanti byte per pixel nel formato RGBA8, e a che offset sta l'alpha.
const BYTES_PER_PIXEL := 4
const ALPHA_OFFSET := 3

## Due pezzi separati da un buco piu' stretto di cosi' restano una banda sola.
##
## [b]Deve restare piccolo:[/b] sul foglio nuovo le righe sono separate da 3
## pixel, e con una tolleranza piu' alta due righe finiscono nella stessa banda
## (e' quello che succedeva con 3, che fondeva 60 maschere in 50).
const BAND_GAP_TOLERANCE := 1

## Di quanto allargare ogni banda per recuperare l'alone attorno alla maschera.
##
## [b]Serve:[/b] le bande si trovano sul disegno pieno, quindi senza questo il
## bordo sfumato verrebbe tagliato di netto. Il valore e' bloccato dal non
## invadere la maschera vicina, quindi alzarlo e' sempre sicuro.
const BAND_PADDING := 2

## Quanto spazio oltre il bordo continuano a muoversi le maschere prima di
## rientrare dall'altro lato. Devono sparire prima di uscire davvero, o si
## vedrebbero comparire di colpo.
const WRAP_MARGIN := 220.0


@export_group("Foglio")

## Una cartella con le maschere gia' separate, un file per maschera.
##
## [b]E' la via migliore, se ce l'hai.[/b] Le maschere del foglio si toccano
## (le fiamme, i fulmini), quindi ritagliandole qualche pixel di bordo viene
## sempre tagliato. Mettendo qui un png per maschera non si taglia niente.
##
## Se la cartella non esiste o e' vuota si usa il foglio qui sotto.
@export_dir var masks_folder: String = "res://Menu/masks"

## Il foglio delle maschere. Se lo lasci vuoto si usa [member sheet_path].
@export var sheet: Texture2D:
	set(value):
		sheet = value
		if is_inside_tree():
			_rebuild()

## Percorso del foglio, usato quando [member sheet] e' vuoto.
##
## [b]Deve avere lo sfondo trasparente[/b] (png o webp). Se ha lo sfondo pieno
## il fondo viene tagliato solo a griglia, quindi il risultato mostra i
## rettangoli di sfondo.
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var sheet_path: String = DEFAULT_SHEET_PATH

## Come e' diviso il foglio, in colonne e righe.
##
## Serve [b]solo[/b] come ripiego, se il foglio ha le maschere attaccate. Con il
## foglio di default (ben spaziato) il ritaglio per bande lo ignora: trova da
## solo le 10 colonne e le 6 righe.
@export_range(1, 16, 1) var grid_columns: int = 10
@export_range(1, 16, 1) var grid_rows: int = 6

@export_group("Maschere")

## Quante maschere tenere in scena contemporaneamente.
@export_range(1, 60, 1) var mask_count: int = 16

## Altezza minima e massima di una maschera, in pixel. La piu' grande e' quella
## "piu' vicina".
##
## [b]Tienile vicine alla dimensione del disegno[/b] (le maschere del foglio sono
## alte ~100-125px): ingrandirle troppo ingrandisce anche le imperfezioni del
## ritaglio, dove due maschere si toccano.
@export_range(40, 400, 2) var mask_height_min: int = 76
@export_range(40, 500, 2) var mask_height_max: int = 150

## Quanto sono visibili. Tienile discrete: sono sfondo, non protagoniste.
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.40

## Quanto varia la scena con la profondita'. 0 = tutte uguali (piatto),
## 1 = le lontane sono molto piu' piccole e lente delle vicine.
@export_range(0.0, 1.0, 0.05) var depth_spread: float = 0.75

## Se true ogni maschera del foglio viene usata a turno (nessuna resta fuori).
## Se false le maschere sono estratte a caso e qualcuna puo' non comparire.
@export var use_all_masks: bool = true

@export_group("Movimento")

## Velocita' di base in pixel al secondo della maschera a meta' profondita'.
## Tienila bassa: devono [i]fluttuare[/i], non attraversare lo schermo.
@export_range(0.0, 120.0, 1.0) var drift_speed: float = 13.0

## Gradi al secondo di rotazione continua. 0 = non ruotano mai.
@export_range(0.0, 60.0, 0.5) var rotation_speed: float = 2.5

## Di quanto oscillano, in gradi, mentre fluttuano. Da' l'idea che ciondolino.
@export_range(0.0, 40.0, 0.5) var sway_degrees: float = 5.0

## Quante oscillazioni al secondo (piu' basso = piu' lento).
@export_range(0.0, 2.0, 0.01) var sway_frequency: float = 0.13

## Di quanti pixel salgono e scendono, perpendicolarmente al loro movimento.
@export_range(0.0, 120.0, 1.0) var bob_amplitude: float = 18.0

## Quante salite/discese al secondo.
@export_range(0.0, 2.0, 0.01) var bob_frequency: float = 0.10

@export_group("Bordi")

## Quanti pixel prima del bordo la maschera comincia a sparire.
##
## E' quello che rende invisibile il "salto" quando rientra dal lato opposto:
## si consuma prima di uscire e si accende dopo essere rientrata.
## Mettilo a 0 per un taglio netto.
@export_range(0.0, 400.0, 10.0) var edge_fade: float = 170.0

## Seme del disegno. 0 = casuale a ogni avvio; un numero fisso lo rende
## sempre identico (utile per confrontare due versioni del menu).
@export var random_seed: int = 0


## Una maschera in scena: il nodo piu' i dati del suo movimento.
## Chiavi: node, texture, base (posizione), velocity, rotation, spin,
## depth, alpha, sway_phase, bob_phase.
var _masks: Array[Dictionary] = []

## I ritagli del foglio, conservati per poterli riusare al resize.
var _textures: Array[Texture2D] = []

## Il tempo passato, per le oscillazioni.
var _time: float = 0.0


func _ready() -> void:
	# Non deve mai intercettare un click: e' solo sfondo.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_rebuild()


#region Costruzione


## Carica il foglio, lo ritaglia e mette le maschere in scena.
func _rebuild() -> void:
	_clear()
	_textures = _load_textures()
	if _textures.is_empty():
		return
	_spawn_masks()


## Svuota le maschere in scena.
func _clear() -> void:
	for entry: Dictionary in _masks:
		var node: Node = entry.get("node")
		if is_instance_valid(node):
			node.queue_free()
	_masks.clear()

	for child: Node in get_children():
		child.queue_free()


## Carica e ritaglia le maschere. Prima la cartella (se c'e'), poi il foglio.
func _load_textures() -> Array[Texture2D]:
	var from_folder: Array[Texture2D] = _load_from_folder()
	if not from_folder.is_empty():
		return from_folder

	var source: Texture2D = sheet

	if source == null and not sheet_path.strip_edges().is_empty():
		if ResourceLoader.exists(sheet_path):
			source = load(sheet_path) as Texture2D
		else:
			push_warning("MenuMaskBackdrop: foglio non trovato: %s\nApri l'editor di Godot una volta: importa lui le immagini nuove." % sheet_path)

	if source == null:
		push_warning("MenuMaskBackdrop: nessuna maschera da mostrare (cartella vuota e foglio assente).")
		return []

	return slice_sheet(source, grid_columns, grid_rows)


## Carica le maschere gia' separate da [member masks_folder].
##
## Ritorna un elenco vuoto se la cartella non c'e' o non contiene immagini:
## in quel caso si passa al foglio. L'ordine e' per nome, cosi' due avvii di
## seguito mettono le stesse maschere nello stesso ordine.
func _load_from_folder() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	if masks_folder.strip_edges().is_empty():
		return textures

	var dir: DirAccess = DirAccess.open(masks_folder)
	if dir == null:
		return textures

	var names: PackedStringArray = PackedStringArray()
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_image_name(file_name):
			names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	names.sort()
	for name: String in names:
		var path: String = masks_folder.path_join(name)
		var resource: Resource = load(path)
		if resource is Texture2D:
			textures.append(resource as Texture2D)
		else:
			push_warning("MenuMaskBackdrop: %s non e' un'immagine." % path)

	return textures


## True se il nome del file ha un'estensione di immagine.
static func _is_image_name(file_name: String) -> bool:
	var extension: String = file_name.get_extension().to_lower()
	return extension in ["png", "webp", "jpg", "jpeg"]


## Ritaglia un foglio di maschere in singole texture.
##
## [b]Due metodi, in ordine di qualita':[/b]
##
## 1. [b]Per bande[/b] ([method _slice_by_bands]): trova le colonne e le righe di
##    disegno separate da spazio vuoto e le incrocia. I riquadri cadono
##    esattamente intorno a ogni maschera: [b]non si taglia niente[/b].
## 2. [b]Griglia + rifilo[/b]: divide in [param columns] x [param rows] e rifila
##    ogni cella. Serve quando le maschere si toccano, perche' allora il metodo 1
##    non le puo' separare.
##
## Si passa al secondo solo se il primo fallisce: e' lui a decidere, guardando
## se le colonne hanno tutte lo stesso numero di maschere. Sul foglio nuovo
## (ben spaziato) vince il primo e il taglio e' perfetto; sul foglio vecchio
## (maschere attaccate) vince il secondo e qualche bordo viene tagliato.
##
## Se il foglio non ha trasparenza nessuno dei due puo' rifilare, quindi si vede
## lo sfondo di ogni cella: in quel caso serve un foglio con il fondo tolto.
##
## E' [code]static[/code] di proposito: puo' servire anche fuori da questo nodo.
static func slice_sheet(source: Texture2D, columns: int = 6, rows: int = 3) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if source == null:
		return result

	var image: Image = source.get_image()
	if image == null:
		return result

	image.convert(Image.FORMAT_RGBA8)
	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return result

	var data: PackedByteArray = image.get_data()
	if not _has_transparency(data):
		push_warning("MenuMaskBackdrop: il foglio non ha trasparenza, quindi non posso rifilare le maschere e si vedra' lo sfondo di ogni cella.\nUsa un foglio con il fondo tolto (es. mask2BgRemoved.png).")

	# 1. Il metodo buono: ritaglio sulle bande di contenuto.
	var banded: Array[Texture2D] = _slice_by_bands(image, data, width, height)
	if not banded.is_empty():
		return banded

	# 2. Ripiego: griglia + rifilo.
	push_warning("MenuMaskBackdrop: le maschere del foglio si toccano, quindi uso la griglia %dx%d e qualche bordo verra' tagliato.\nPer un risultato perfetto salva le maschere separate (un file per maschera) e indicale in Masks Folder." % [columns, rows])

	var safe_columns: int = maxi(columns, 1)
	var safe_rows: int = maxi(rows, 1)

	for row: int in safe_rows:
		for column: int in safe_columns:
			var cell: Rect2i = _grid_cell(width, height, safe_columns, safe_rows, column, row)
			if cell.size.x < 1 or cell.size.y < 1:
				continue

			# Con la trasparenza, la cella viene ridotta al rettangolo che
			# contiene davvero la maschera: a schermo saranno tutte alte uguali.
			var region: Rect2i = _trim_to_content(data, width, cell) if _has_transparency(data) else cell
			result.append(ImageTexture.create_from_image(image.get_region(region)))

	return result


## Ritaglia incrociando le bande di contenuto, colonne per righe.
##
## [b]Ritorna un elenco vuoto se il foglio non e' regolare,[/b] e allora si passa
## alla griglia. Il controllo e' questo: [b]tutte le colonne devono contenere lo
## stesso numero di maschere[/b]. Se una ne ha di meno, li' due maschere si
## toccano (o una e' stata spezzata da una riga vuota interna), e in entrambi i
## casi i riquadri non sarebbero affidabili.
##
## E' il test che distingue i due fogli: quello ben spaziato passa, quello con le
## maschere attaccate no.
static func _slice_by_bands(image: Image, data: PackedByteArray, width: int, height: int) -> Array[Texture2D]:
	var slices: Array[Texture2D] = []

	var columns: Array[Vector2i] = _runs(_column_map(data, width, height), BAND_GAP_TOLERANCE)
	if columns.size() < 2:
		return slices

	var padded_columns: Array[Vector2i] = _pad_bands(columns, BAND_PADDING, width)
	var expected_rows: int = -1

	for index: int in padded_columns.size():
		var column: Vector2i = padded_columns[index]

		# Le righe si cercano nella colonna [b]senza padding[/b]: allargandola si
		# rischierebbe di pescare l'alone della maschera accanto, che a sua volta
		# puo' attaccarsi alle righe vicine.
		var rows: Array[Vector2i] = _runs(
			_row_map(data, width, columns[index].x, columns[index].y), BAND_GAP_TOLERANCE
		)
		if rows.size() < 2:
			return []

		if expected_rows < 0:
			expected_rows = rows.size()
		elif rows.size() != expected_rows:
			return []

		var padded_rows: Array[Vector2i] = _pad_bands(rows, BAND_PADDING, height)
		for row: Vector2i in padded_rows:
			var region: Rect2i = Rect2i(
				column.x, row.x, column.y - column.x + 1, row.y - row.x + 1
			)
			slices.append(ImageTexture.create_from_image(image.get_region(region)))

	return slices


## Per ogni colonna, dice se contiene almeno un pixel di disegno.
static func _column_map(data: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var map: PackedByteArray = PackedByteArray()
	map.resize(width)
	var stride: int = width * BYTES_PER_PIXEL
	for x: int in width:
		var offset: int = x * BYTES_PER_PIXEL + ALPHA_OFFSET
		for y: int in height:
			if data[offset + y * stride] > CONTENT_ALPHA:
				map[x] = 1
				break
	return map


## Per ogni riga fra [param x0] e [param x1], dice se contiene almeno un pixel di disegno.
static func _row_map(data: PackedByteArray, width: int, x0: int, x1: int) -> PackedByteArray:
	var height: int = data.size() / (width * BYTES_PER_PIXEL)
	var map: PackedByteArray = PackedByteArray()
	map.resize(height)
	var stride: int = width * BYTES_PER_PIXEL
	for y: int in height:
		var offset: int = y * stride + x0 * BYTES_PER_PIXEL + ALPHA_OFFSET
		for x: int in range(x0, x1 + 1):
			if data[offset + (x - x0) * BYTES_PER_PIXEL] > CONTENT_ALPHA:
				map[y] = 1
				break
	return map


## Le bande di "1" consecutive dentro una mappa di occupazione.
##
## Due bande separate da un buco piu' corto o uguale a [param min_gap] restano
## unite. Ritorna coppie (primo, ultimo) compresi.
static func _runs(occupied: PackedByteArray, min_gap: int) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start: int = -1
	var last: int = -1

	for i: int in occupied.size():
		if occupied[i] != 0:
			if start < 0:
				start = i
			last = i
		elif start >= 0 and i - last > min_gap:
			runs.append(Vector2i(start, last))
			start = -1
			last = -1

	if start >= 0:
		runs.append(Vector2i(start, last))

	return runs


## Allarga ogni banda di [param amount] pixel per lato.
##
## [b]Senza invadere la vicina:[/b] ogni banda si ferma al pixel prima di quella
## dopo. Cosi' alzare il padding non puo' mai far sovrapporre due maschere.
static func _pad_bands(bands: Array[Vector2i], amount: int, limit: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for index: int in bands.size():
		var low: int = maxi(bands[index].x - amount, 0)
		var high: int = mini(bands[index].y + amount, limit - 1)
		if index > 0:
			low = maxi(low, bands[index - 1].y + 1)
		if index < bands.size() - 1:
			high = mini(high, bands[index + 1].x - 1)
		result.append(Vector2i(low, high))
	return result


## Il rettangolo di una cella della griglia.
##
## I confini si arrotondano (invece di una divisione secca) perche' la larghezza
## raramente e' un multiplo esatto delle colonne: cosi' tutte le celle sono
## grandi uguali e non si perde una striscia di pixel sul bordo.
static func _grid_cell(width: int, height: int, columns: int, rows: int, column: int, row: int) -> Rect2i:
	var x0: int = int(round(float(column) * float(width) / float(columns)))
	var x1: int = int(round(float(column + 1) * float(width) / float(columns)))
	var y0: int = int(round(float(row) * float(height) / float(rows)))
	var y1: int = int(round(float(row + 1) * float(height) / float(rows)))

	x1 = mini(x1, width)
	y1 = mini(y1, height)

	return Rect2i(x0, y0, maxi(x1 - x0, 0), maxi(y1 - y0, 0))


## Riduce una cella al rettangolo che contiene davvero dei pixel disegnati.
##
## [b]Serve a due cose insieme:[/b] togliere il margine trasparente intorno a
## ogni maschera (cosi' a schermo sono tutte della stessa altezza, anche se nel
## foglio una e' piu' alta) e centrarle bene, invece di lasciarle dove capita
## dentro la cella.
##
## Se la cella e' vuota ritorna la cella intera: un ritaglio di dimensione zero
## darebbe una texture degenere, che e' peggio.
static func _trim_to_content(data: PackedByteArray, width: int, cell: Rect2i) -> Rect2i:
	var left: int = cell.position.x + cell.size.x
	var top: int = cell.position.y + cell.size.y
	var right: int = cell.position.x - 1
	var bottom: int = cell.position.y - 1

	var row_stride: int = width * BYTES_PER_PIXEL
	var start_x: int = cell.position.x
	var end_x: int = cell.position.x + cell.size.x

	for y: int in range(cell.position.y, cell.position.y + cell.size.y):
		var offset: int = y * row_stride + start_x * BYTES_PER_PIXEL + ALPHA_OFFSET
		for x: int in range(start_x, end_x):
			if data[offset] > ALPHA_THRESHOLD:
				if x < left:
					left = x
				if x > right:
					right = x
				if y < top:
					top = y
				if y > bottom:
					bottom = y
			offset += BYTES_PER_PIXEL

	if right < left or bottom < top:
		return cell

	return Rect2i(left, top, right - left + 1, bottom - top + 1)


## True se almeno un pixel e' semitrasparente.
##
## Basta questo per distinguere un foglio rifilabile (png con fondo tolto) da
## uno a fondo pieno (jpg).
static func _has_transparency(data: PackedByteArray) -> bool:
	# L'alpha e' un byte ogni 4 (RGBA), quindi partiamo dall'indice 3.
	var index: int = 3
	while index < data.size():
		if data[index] < 250:
			return true
		index += 4
	return false


#endregion

#region Le maschere in scena


## Distribuisce le maschere sullo schermo, tutte diverse.
func _spawn_masks() -> void:
	_clear()
	if _textures.is_empty():
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()

	var area: Vector2 = _area()

	# Distribuzione a griglia con un po' di disordine: cosi' le maschere sono
	# sparse in modo uniforme invece di ammassarsi in un angolo.
	var aspect: float = area.x / maxf(area.y, 1.0)
	var columns: int = maxi(1, int(ceil(sqrt(float(mask_count) * aspect))))
	var rows: int = maxi(1, int(ceil(float(mask_count) / float(columns))))
	var cell: Vector2 = Vector2(area.x / float(columns), area.y / float(rows))

	for i: int in mask_count:
		var texture: Texture2D = (
			_textures[i % _textures.size()] if use_all_masks
			else _textures[rng.randi_range(0, _textures.size() - 1)]
		)
		if texture == null:
			continue

		var depth: float = rng.randf()

		# Dimensione: le maschere "vicine" sono piu' grandi.
		var target_height: float = lerpf(
			float(mask_height_min), float(mask_height_max), depth
		)
		var texture_size: Vector2 = texture.get_size()
		var ratio: float = texture_size.x / maxf(texture_size.y, 1.0)
		var mask_size: Vector2 = Vector2(target_height * ratio, target_height)

		var node: TextureRect = TextureRect.new()
		node.texture = texture
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.stretch_mode = TextureRect.STRETCH_SCALE
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.size = mask_size
		node.pivot_offset = mask_size * 0.5
		# Un po' trasparente anche il disegno: sono sfondo, non protagonisti.
		node.modulate.a = 0.0
		add_child(node)

		# Posizione dentro la sua cella, con un margine per non toccarne i bordi.
		var cell_x: int = i % columns
		var cell_y: int = i / columns
		var jitter: float = 0.72
		var position: Vector2 = Vector2(
			(float(cell_x) + 0.5 + rng.randf_range(-jitter, jitter) * 0.5) * cell.x,
			(float(cell_y) + 0.5 + rng.randf_range(-jitter, jitter) * 0.5) * cell.y
		)

		# Velocita': le maschere vicine si muovono di piu' (e' la parallasse).
		var speed_scale: float = lerpf(
			1.0 - 0.5 * depth_spread, 1.0 + 0.6 * depth_spread, depth
		)
		var angle: float = rng.randf_range(0.0, TAU)
		var entry: Dictionary = {
			"node": node,
			"base": position,
			"velocity": Vector2(cos(angle), sin(angle)) * drift_speed * speed_scale,
			"rotation": rng.randf_range(-20.0, 20.0),
			"spin": rng.randf_range(-1.0, 1.0) * rotation_speed,
			"depth": depth,
			"alpha": opacity * lerpf(1.0 - 0.6 * depth_spread, 1.0, depth),
			"sway_phase": rng.randf_range(0.0, TAU),
			"bob_phase": rng.randf_range(0.0, TAU),
		}
		_masks.append(entry)

		# Le mettiamo subito a posto: se il giocatore ha chiesto "riduci il
		# movimento" non si muoveranno mai, ma devono comunque essere visibili.
		_apply(entry)


## Sposta le maschere e le fa ruotare. Chiamata ogni fotogramma.
func _process(delta: float) -> void:
	if _masks.is_empty():
		return

	# Con il pannello delle impostazioni aperto lo sfondo si ferma: e' sotto a
	# una velatura scura comunque, e cosi' non consuma niente mentre leggi.
	if Settings.is_menu_open():
		return

	# "Riduci il movimento" ferma le maschere: e' una scelta del giocatore.
	if Settings.reduce_motion():
		return

	var motion: float = Settings.motion_scale()
	if motion <= 0.0:
		return

	_time += delta * motion
	var area: Vector2 = _area()

	for entry: Dictionary in _masks:
		var position: Vector2 = entry["base"]
		position += (entry["velocity"] as Vector2) * delta * motion
		# Rientrano dall'altro lato: il cambio e' nascosto dalla sfumatura sui bordi.
		position.x = wrapf(position.x, -WRAP_MARGIN, area.x + WRAP_MARGIN)
		position.y = wrapf(position.y, -WRAP_MARGIN, area.y + WRAP_MARGIN)
		entry["base"] = position
		entry["rotation"] = float(entry["rotation"]) + float(entry["spin"]) * delta * motion

		_apply(entry)


## Porta i dati di una maschera sul suo nodo.
func _apply(entry: Dictionary) -> void:
	var node: TextureRect = entry["node"]
	if not is_instance_valid(node):
		return

	var depth: float = entry["depth"]
	var position: Vector2 = entry["base"]

	# Oscillazione perpendicolare al movimento: sembra che ciondolino.
	if bob_amplitude > 0.0 and drift_speed > 0.0:
		var velocity: Vector2 = entry["velocity"]
		var perpendicular: Vector2 = Vector2(-velocity.y, velocity.x).normalized()
		var bob: float = sin(_time * bob_frequency * TAU + float(entry["bob_phase"]))
		position += perpendicular * bob * bob_amplitude * depth

	var sway: float = 0.0
	if sway_degrees > 0.0:
		sway = sin(_time * sway_frequency * TAU + float(entry["sway_phase"])) * sway_degrees

	# Il nodo si posiziona dall'angolo: la posizione salvata e' il suo centro.
	node.position = position - node.size * 0.5
	node.rotation = deg_to_rad(float(entry["rotation"]) + sway)

	# Sfumatura sui bordi: si consuma prima di uscire, si accende dopo essere
	# rientrata. E' quello che rende invisibile il "salto" da un lato all'altro.
	var fade: float = 1.0
	if edge_fade > 0.0:
		var area: Vector2 = _area()
		var distance: float = minf(
			minf(position.x, area.x - position.x),
			minf(position.y, area.y - position.y)
		)
		fade = clampf(distance / edge_fade, 0.0, 1.0)

	node.modulate.a = float(entry["alpha"]) * fade


## L'area su cui distribuire le maschere.
##
## Usa la dimensione del nodo; se non e' ancora calcolata (al primo fotogramma
## puo' essere zero) ripiega sull'area della finestra. Cosi' le maschere non
## finiscono tutte ammassate nell'angolo in alto a sinistra.
func _area() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	var viewport: Vector2 = get_viewport_rect().size
	if viewport.x > 1.0 and viewport.y > 1.0:
		return viewport
	return Vector2(1920.0, 1080.0)


## La finestra ha cambiato dimensione: ridistribuiamo le maschere.
##
## Non ritagliamo di nuovo il foglio (sarebbe lavoro inutile): i ritagli sono
## gli stessi, cambia solo dove vanno.
func _on_resized() -> void:
	if _textures.is_empty():
		return
	_spawn_masks()


#endregion
