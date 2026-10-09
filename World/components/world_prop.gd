@tool
## Un oggetto di scena con il suo ingombro: lampioni, facciate, letti, statue.
##
## Scegli il [member kind] dall'Ispettore e l'oggetto si costruisce da solo:
## lo sprite (preso dagli asset che ci sono gia'), la [b]collisione ai piedi[/b]
## (cosi' si passa [i]dietro[/i] a un lampione ma non [i]attraverso[/i]) e,
## per alcuni, una luce.
##
## [b]L'origine e' alla base dell'oggetto:[/b] con l'ordinamento per Y attivo
## nella mappa, il personaggio sta davanti quando e' piu' in basso e dietro
## quando e' piu' in alto, senza pensarci.
##
## Per aggiungere un oggetto nuovo basta una riga in [method library].
class_name WorldProp extends StaticBody2D


## Che oggetto e'. Vedi [method library].
@export_enum(
	"facciata", "facciata_b", "facciata_c", "baracca", "lampione", "paletto", "cancello",
	"letto", "letto_rosa", "cassettone", "sedia", "pianta", "tappeto", "quadro",
	"statua", "stendardo", "vaso", "pannello", "pannello_rosso", "macerie",
	"specchio", "riflettore", "quinta", "leggio", "cassa", "porta_dipinta", "locandina", "baule_viaggio", "lampione_spento", "porta_vera",
) var kind: String = "lampione":
	set(value):
		kind = value
		if is_inside_tree():
			_build()

## Colore che moltiplica lo sprite (le zone usano la stessa grafica con
## palette diverse).
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		if _sprite != null:
			_sprite.modulate = tint

## Specchia lo sprite in orizzontale.
@export var flip: bool = false:
	set(value):
		flip = value
		if _sprite != null:
			_sprite.flip_h = flip


var _sprite: Sprite2D = null


const HOUSE := "res://Asset/TileMap/MyTileMap/Details/HouseAndCity.png"
const FURNITURE := "res://Asset/Sprite/Object/Basic Furniture.png"
const TEMPLE := "res://Asset/TileMap/TempleDestroied/Objects_interior.png"
const TILES := "res://World/art/theatre_props.png"


## Il catalogo: texture, regione, scala, ingombro ai piedi (larghezza, altezza;
## zero = attraversabile) e luce opzionale ([code][colore, energia, raggio][/code]).
static func library() -> Dictionary:
	return {
		"facciata": [TILES, Rect2(256, 0, 128, 128), 1.0, Vector2(116, 18)],
		"facciata_b": [TILES, Rect2(384, 0, 128, 128), 1.0, Vector2(116, 18)],
		"facciata_c": [TILES, Rect2(160, 64, 96, 112), 1.0, Vector2(84, 18)],
		"baracca": [TILES, Rect2(0, 64, 128, 96), 1.0, Vector2(120, 24)],
		"lampione": [TILES, Rect2(128, 64, 32, 112), 1.0, Vector2(12, 8), [Color(1.0, 0.82, 0.45), 1.1, 3.2]],
		"paletto": [HOUSE, Rect2(192, 129, 20, 58), 1.0, Vector2(14, 10)],
		"cancello": [HOUSE, Rect2(64, 193, 64, 58), 1.0, Vector2(60, 12)],
		"letto": [FURNITURE, Rect2(1, 26, 14, 22), 2.0, Vector2(28, 36)],
		"letto_rosa": [FURNITURE, Rect2(33, 26, 14, 22), 2.0, Vector2(28, 36)],
		"cassettone": [FURNITURE, Rect2(49, 32, 14, 16), 2.0, Vector2(28, 14)],
		"sedia": [FURNITURE, Rect2(67, 33, 10, 13), 2.0, Vector2(18, 10)],
		"pianta": [FURNITURE, Rect2(51, 16, 10, 11), 2.0, Vector2(16, 8)],
		"tappeto": [FURNITURE, Rect2(0, 82, 48, 13), 2.0, Vector2.ZERO],
		"quadro": [FURNITURE, Rect2(1, 6, 15, 7), 2.0, Vector2.ZERO],
		"statua": [TEMPLE, Rect2(9, 8, 111, 82), 1.0, Vector2(40, 20)],
		"stendardo": [TEMPLE, Rect2(6, 108, 21, 43), 1.0, Vector2.ZERO],
		"vaso": [TEMPLE, Rect2(262, 1, 25, 29), 1.0, Vector2(20, 10)],
		"pannello": [TEMPLE, Rect2(146, 109, 29, 46), 1.0, Vector2(28, 12)],
		"pannello_rosso": [TEMPLE, Rect2(186, 109, 45, 46), 1.0, Vector2(44, 12)],
		"macerie": [TEMPLE, Rect2(26, 167, 35, 35), 1.0, Vector2(30, 14)],
		"specchio": [TILES, Rect2(0, 0, 32, 64), 1.0, Vector2(30, 10)],
		"riflettore": [TILES, Rect2(32, 0, 32, 64), 1.0, Vector2(18, 10), [Color(1.0, 0.95, 0.75), 1.4, 4.5]],
		"quinta": [TILES, Rect2(64, 0, 32, 64), 1.0, Vector2(30, 10)],
		"leggio": [TILES, Rect2(96, 0, 32, 64), 1.0, Vector2(16, 8), [Color(0.6, 0.8, 1.0), 0.7, 1.6]],
		"cassa": [TILES, Rect2(128, 32, 32, 32), 1.0, Vector2(30, 14)],
		"porta_dipinta": [TILES, Rect2(160, 0, 64, 64), 1.0, Vector2.ZERO, [Color(1.0, 0.25, 0.2), 0.9, 2.0]],
		"locandina": [TILES, Rect2(128, 0, 32, 32), 1.0, Vector2.ZERO],
		"baule_viaggio": [TILES, Rect2(224, 32, 32, 32), 1.0, Vector2(28, 14)],
		"lampione_spento": [TILES, Rect2(128, 64, 32, 112), 1.0, Vector2(12, 8)],
		"porta_vera": [TILES, Rect2(174, 16, 36, 48), 1.0, Vector2.ZERO],
	}


func _ready() -> void:
	_build()


func _build() -> void:
	for child: Node in get_children():
		if child.has_meta(&"generated"):
			remove_child(child)
			child.queue_free()
	_sprite = null

	var entry: Array = library().get(kind, [])
	if entry.is_empty():
		return
	var texture: Texture2D = load(entry[0]) if ResourceLoader.exists(entry[0]) else null
	var region: Rect2 = entry[1]
	var scale_factor: float = entry[2]
	var footprint: Vector2 = entry[3]

	_sprite = Sprite2D.new()
	_sprite.set_meta(&"generated", true)
	_sprite.texture = texture
	_sprite.region_enabled = true
	_sprite.region_rect = region
	_sprite.scale = Vector2(scale_factor, scale_factor)
	_sprite.centered = true
	# La base dello sprite sull'origine del nodo.
	_sprite.position = Vector2(0, -region.size.y * scale_factor * 0.5)
	_sprite.modulate = tint
	_sprite.flip_h = flip
	add_child(_sprite)

	collision_layer = 1
	collision_mask = 0
	if footprint != Vector2.ZERO:
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = footprint
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.set_meta(&"generated", true)
		collision.shape = shape
		collision.position = Vector2(0, -footprint.y * 0.5)
		add_child(collision)
	else:
		# Un tappeto o un quadro: si vede, ma non ingombra e sta sotto a tutti.
		z_index = -1

	if entry.size() > 4:
		var light_data: Array = entry[4]
		var light: PointLight2D = WorldLights.make_light(light_data[0], light_data[1], light_data[2])
		light.set_meta(&"generated", true)
		light.position = Vector2(0, -region.size.y * scale_factor * 0.85)
		add_child(light)
