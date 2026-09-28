## Lo sfondo animato del menu: carte che scorrono da destra a sinistra.
##
## [b]Come funziona:[/b] crea N carte decorative, le distribuisce su fasce
## orizzontali e le muove verso sinistra. Quando una esce dallo schermo viene
## rimessa a destra, quindi il flusso non finisce mai.
##
## [b]La profondita':[/b] ogni carta ha una "distanza" casuale che determina
## tre cose insieme — dimensione, velocita' e trasparenza. Le carte lontane
## sono piccole, lente e sbiadite; quelle vicine sono grandi e veloci.
## E' il trucco che da' l'impressione di profondita' invece che di un semplice
## scorrimento piatto.
##
## [b]Per mettere le immagini:[/b] vedi [code]Menu/README.md[/code]. In breve:
## assegna una texture al campo [b]Art[/b] delle tue [CardData], oppure imposta
## [member card_back] con un'immagine unica per tutte le carte.
class_name MenuCardBackdrop extends Control


## La cartella dove il gioco tiene le carte salvate come file.
##
## E' la stessa che riempie [code]Cards/tools/generate_cards.gd[/code].
const SAVED_CARDS_DIR := "res://Cards/data/cards"


@export_group("Carte")

## Quante carte tenere in scena contemporaneamente.
## Alzalo per un effetto piu' fitto, abbassalo per uno piu' pulito.
@export_range(1, 60, 1) var card_count: int = 22

## Da dove prendere le carte del gioco.
##
## Lascia vuoto per usare tutte le carte disponibili. Assegna qui i tuoi
## [code].tres[/code] se vuoi che lo sfondo mostri solo alcune carte.
@export var card_pool: Array[CardData] = []

## Se true, lo sfondo usa le carte salvate su disco in [code]Cards/data/cards/[/code].
##
## Sono le stesse carte del gioco, ma salvate come file: puoi aprirle
## dall'inspector e assegnare il campo [b]Art[/b] per far comparire le
## illustrazioni anche qui. Se la cartella non esiste (o e' vuota) si usano
## le carte definite in codice da [CardLibrary].
##
## [b]In una build esportata[/b] la cartella non e' leggibile: li' si usano
## sempre le carte in codice. Per quello esiste [member card_back].
@export var prefer_saved_cards: bool = true

## Immagine unica applicata a tutte le carte che non hanno una propria [b]Art[/b].
##
## [b]E' il modo piu' veloce per vedere subito un risultato:[/b] trascina qui
## un'immagine e comparirà su tutte le carte dello sfondo.
@export var card_back: Texture2D

## Se true usa anche le carte senza immagine, mostrandole col nome in grande.
## Se false mostra solo le carte che hanno un'immagine.
@export var include_cards_without_art: bool = true

@export_group("Movimento")

## Velocita' di base in pixel al secondo della carta piu' vicina.
@export_range(0.0, 400.0, 5.0) var base_speed: float = 95.0

## Variazione casuale della velocita', per non avere tutte le carte allineate.
@export_range(0.0, 200.0, 5.0) var speed_variation: float = 45.0

## Quanto le carte oscillano su e giu', in pixel.
@export_range(0.0, 40.0, 1.0) var bob_amplitude: float = 9.0

## Velocita' dell'oscillazione verticale.
@export_range(0.0, 4.0, 0.05) var bob_speed: float = 0.7

@export_group("Aspetto")

## Dimensione della carta piu' vicina, in pixel.
@export var card_size: Vector2 = Vector2(190, 265)

## Scala della carta piu' lontana. 0.5 = meta' della piu' vicina.
@export_range(0.2, 1.0, 0.05) var min_depth: float = 0.55

## Opacita' della carta piu' lontana.
@export_range(0.05, 1.0, 0.05) var far_opacity: float = 0.45

## Rotazione massima, in gradi. Le carte vengono ruotate a caso fino a questo.
@export_range(0.0, 45.0, 1.0) var max_rotation: float = 10.0

## In quante fasce orizzontali distribuire le carte.
## Serve a evitare che si ammassino tutte nella stessa zona.
@export_range(1, 8, 1) var band_count: int = 3

## Tinta applicata a tutte le carte. Utile per farle "sparire" dietro ai menu.
@export var tint: Color = Color(1, 1, 1, 1)

@export_group("Avanzate")

## Seme del generatore casuale. Lo stesso seme produce lo stesso sfondo.
## Metti 0 per averne uno diverso ogni volta.
@export var layout_seed: int = 0

## Quanto a lungo il tempo impiegato dalla prima carta per attraversare
## lo schermo (in secondi). Solo per la stima di quantita' di carte visibili.
@export var debug_speed_log: bool = false


# --- Stato ---

var _cards: Array[MenuCard] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _elapsed: float = 0.0
var _ready_to_build: bool = false


func _ready() -> void:
	# Lo sfondo non deve mai intercettare click o focus.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

	if layout_seed != 0:
		_rng.seed = layout_seed
	else:
		_rng.randomize()

	# La dimensione non e' ancora valida a _ready: aspettiamo il primo
	# ridimensionamento, che arriva quando il layout e' stato calcolato.
	resized.connect(_on_resized)
	call_deferred("_try_build")


func _on_resized() -> void:
	_try_build()


## Costruisce le carte la prima volta che abbiamo una dimensione utile.
func _try_build() -> void:
	if _ready_to_build:
		return
	if size.x < 10.0 or size.y < 10.0:
		return
	_ready_to_build = true
	_build_cards()


## Crea tutte le carte e le piazza.
func _build_cards() -> void:
	var source_cards: Array[CardData] = _collect_source_cards()
	if source_cards.is_empty():
		# Nessuna carta disponibile: creiamo cartegeneriche cosi' lo sfondo
		# funziona comunque, senza dipendere dal resto del progetto.
		source_cards = _make_fallback_cards()

	# Mescoliamo con il nostro seme, cosi' lo sfondo e' riproducibile.
	_shuffle(source_cards)

	# Distribuiamo le carte a rotazione fra le fasce, cosi' nessuna resta vuota.
	var band: int = 0

	for i: int in range(card_count):
		var card: MenuCard = MenuCard.new()

		# Le carte che non stanno nel pool ricominciano da capo (in modo ciclico),
		# cosi' lo sfondo e' sempre pieno anche con poche carte disponibili.
		var data: CardData = source_cards[i % source_cards.size()]

		add_child(card)
		card.setup_from_data(data)
		card.card_size = card_size
		card.size = card_size
		card.custom_minimum_size = card_size
		card.pivot_offset = card_size * 0.5
		card.set_art(data.art if data.art != null else card_back)

		# Profondita' casuale: decide scala, velocita' e trasparenza insieme.
		var depth: float = _rng.randf_range(min_depth, 1.0)
		card.scale = Vector2(depth, depth)
		card.drift_speed = (base_speed + _rng.randf_range(0.0, speed_variation)) * depth
		card.bob_amplitude = bob_amplitude * depth
		card.bob_phase = _rng.randf_range(0.0, TAU)
		card.card_opacity = lerpf(far_opacity, 1.0, depth) * tint.a
		card.modulate = tint * Color(1, 1, 1, lerpf(far_opacity, 1.0, depth))
		card.rotation = deg_to_rad(_rng.randf_range(-max_rotation, max_rotation))

		# Le carte piu' vicine stanno davanti.
		card.z_index = int(depth * 100.0)

		_place_card(card, band, true)
		band = (band + 1) % maxi(band_count, 1)

		_cards.append(card)


## Raccoglie le carte da usare come soggetto dello sfondo.
func _collect_source_cards() -> Array[CardData]:
	var result: Array[CardData] = []

	var pool: Array[CardData] = []
	if not card_pool.is_empty():
		# 1. Il pool scelto a mano nell'inspector ha la priorita' su tutto.
		for raw: Variant in card_pool:
			var data: CardData = raw as CardData
			if data != null:
				pool.append(data)
	else:
		# 2. Le carte salvate su disco, che puoi modificare dall'inspector.
		if prefer_saved_cards:
			pool = _load_saved_cards()
		# 3. Altrimenti le carte definite in codice.
		if pool.is_empty():
			pool = CardLibrary.build_all()

	for data: CardData in pool:
		if data == null:
			continue
		# Se abbiamo un'immagine unica, tutte le carte vanno bene.
		# Altrimenti, se richiesto, saltiamo quelle senza illustrazione.
		if data.art == null and card_back == null and not include_cards_without_art:
			continue
		result.append(data)

	return result


## Carica le carte salvate come file [code].tres[/code] nella cartella del gioco.
##
## L'ordine e' alfabetico di proposito: [method DirAccess.get_files] non
## garantisce un ordine stabile, e un ordine casuale farebbe cambiare lo sfondo
## ad ogni avvio anche con lo stesso [member layout_seed].
func _load_saved_cards() -> Array[CardData]:
	var result: Array[CardData] = []

	if not DirAccess.dir_exists_absolute(SAVED_CARDS_DIR):
		return result

	var dir: DirAccess = DirAccess.open(SAVED_CARDS_DIR)
	if dir == null:
		return result

	var file_names: PackedStringArray = dir.get_files()
	file_names.sort()

	for file_name: String in file_names:
		# Le risorse importate possono comparire con suffisso .remap.
		if not file_name.ends_with(".tres"):
			continue

		var resource: Resource = load(SAVED_CARDS_DIR + "/" + file_name)
		var card: CardData = resource as CardData
		if card != null:
			result.append(card)

	if debug_speed_log and not result.is_empty():
		print("[MenuCardBackdrop] Caricate %d carte da %s" % [
			result.size(), SAVED_CARDS_DIR,
		])

	return result


## Carte di riserva, usate solo se il progetto non ne fornisce.
##
## Servono a garantire che lo sfondo funzioni anche da solo, senza dipendere
## dagli altri file. Sono le sei "personalita'" del gioco.
func _make_fallback_cards() -> Array[CardData]:
	var made: Array[CardData] = []
	var elements: Array = [
		CardTypes.Element.FIRE,
		CardTypes.Element.ICE,
		CardTypes.Element.POISON,
		CardTypes.Element.LIGHTNING,
		CardTypes.Element.NATURE,
		CardTypes.Element.DARK,
	]
	for raw_element: Variant in elements:
		var element: CardTypes.Element = raw_element
		var card: CardData = CardData.new()
		card.display_name = CardTypes.element_name(element)
		card.cost = 5
		card.element = element
		made.append(card)
	return made


## Piazza una carta in una fascia verticale.
##
## [param initial_spread] true solo al primo riempimento: in quel caso
## distribuiamo le carte su tutto lo schermo, cosi' lo sfondo e' subito pieno
## invece di restare vuoto per decine di secondi.
func _place_card(card: MenuCard, band: int, initial_spread: bool) -> void:
	var view_width: float = size.x
	var view_height: float = size.y

	var bands: int = maxi(band_count, 1)
	var band_height: float = view_height / float(bands)
	var visual_height: float = card_size.y * card.scale.y
	var visual_width: float = card_size.x * card.scale.x

	# --- Posizione verticale dentro la fascia, senza uscire dai bordi ---
	var top: float = float(band) * band_height
	var max_offset: float = maxf(band_height - visual_height, 0.0)
	var y: float = top + _rng.randf_range(0.0, max_offset)

	card.base_y = y
	card.position.y = y

	# --- Posizione orizzontale ---
	if initial_spread:
		# Primo riempimento: sparpagliate su tutta la larghezza dello schermo.
		card.position.x = _rng.randf_range(-visual_width, view_width)
	else:
		# Rientro da destra. Lo sfasamento e' piccolo di proposito: se fosse
		# ampio, una carta lenta impiegherebbe minuti a rientrare in scena
		# e lo sfondo si svuoterebbe.
		card.position.x = view_width + _rng.randf_range(0.0, view_width * 0.35)

	if debug_speed_log:
		print("[MenuCardBackdrop] '%s' banda %d, x %.0f, velocita' %.0f" % [
			card.display_name, band, card.position.x, card.drift_speed,
		])


func _process(delta: float) -> void:
	if not _ready_to_build:
		_try_build()
	if _cards.is_empty():
		return

	_elapsed += delta

	var view_width: float = size.x
	var exit_margin: float = card_size.x * 2.0

	for card: MenuCard in _cards:
		if not is_instance_valid(card):
			continue

		# --- Scorrimento verso sinistra ---
		card.position.x -= card.drift_speed * delta

		# --- Oscillazione verticale ---
		if card.bob_amplitude > 0.0:
			card.position.y = card.base_y + sin(_elapsed * bob_speed + card.bob_phase) * card.bob_amplitude

		# --- Rientro da destra ---
		# Usiamo la larghezza scalata: una carta grande esce "piu' tardi".
		var visual_width: float = card_size.x * card.scale.x
		if card.position.x + visual_width < -exit_margin:
			_place_card(card, _rng.randi_range(0, maxi(band_count, 1) - 1), false)


## Mescola un array con il nostro generatore (per avere un layout riproducibile).
func _shuffle(array: Array) -> void:
	for i: int in range(array.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp


## Ricostruisce completamente lo sfondo. Chiamalo se cambi i parametri a runtime.
func rebuild() -> void:
	for card: MenuCard in _cards:
		if is_instance_valid(card):
			card.queue_free()
	_cards.clear()
	_ready_to_build = false

	if layout_seed != 0:
		_rng.seed = layout_seed
	else:
		_rng.randomize()

	_try_build()
