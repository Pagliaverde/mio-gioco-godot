## Un baule. Due tipi:
## - [b]Baule di Scena[/b] ([member kind] = [code]"scena"[/code]): dentro c'e'
##   una maschera base a caso, tra quelle che non hai (come nella storia);
## - [b]cassa di attrezzeria[/b] ([code]"cassa"[/code]): biglietti, un oggetto
##   o una battuta.
##
## Aperto, resta aperto: il salvataggio se lo ricorda per nome e mappa.
class_name StageChest extends StaticBody2D


@export_enum("scena", "cassa") var kind: String = "cassa"

## Biglietti dentro la cassa.
@export var money: int = 0

## Un oggetto dentro la cassa (id di [WorldData.items]).
@export var item_id: StringName = &""

## Una battuta dentro la cassa (id di carta).
@export var card_id: StringName = &""

const GOLD := "res://World/art/theatre_props.png"
const SMALL := "res://Asset/Sprite/Object/Chest.png"

var _sprite: Sprite2D
var _glow: PointLight2D = null
var interaction: Interactable


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_sprite = Sprite2D.new()
	add_child(_sprite)
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(30, 14) if kind == "scena" else Vector2(26, 12)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -7)
	add_child(collision)
	interaction = Interactable.create(self, 26.0, Vector2(0, -10))
	interaction.prompt = "Apri"
	interaction.interacted.connect(_on_interacted)
	if kind == "scena":
		_glow = WorldLights.make_light(Color(1.0, 0.85, 0.4), 0.9, 1.8)
		_glow.position = Vector2(0, -20)
		add_child(_glow)
	refresh()


## La chiave nel salvataggio.
func key() -> String:
	return "%s/%s" % [GameState.map_id, name]


func is_open() -> bool:
	return GameState.is_chest_opened(key())


func refresh() -> void:
	var opened: bool = is_open()
	if kind == "scena":
		_sprite.texture = load(GOLD)
		_sprite.region_enabled = true
		_sprite.region_rect = Rect2(304, 128, 48, 48) if opened else Rect2(256, 128, 48, 48)
		_sprite.position = Vector2(0, -20)
	else:
		_sprite.texture = load(SMALL)
		_sprite.region_enabled = true
		_sprite.region_rect = Rect2(96, 0, 48, 48) if opened else Rect2(0, 0, 48, 48)
		_sprite.position = Vector2(0, -16)
	if _glow != null:
		_glow.visible = not opened
	interaction.prompt = "Apri"


func _on_interacted(player: Node) -> void:
	if Overworld.instance != null:
		Overworld.instance.director.open_chest(self, player)
