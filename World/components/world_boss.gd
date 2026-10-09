## Un boss nel mondo: sta in piedi dove lo incontri, con la maschera che non
## si e' piu' tolto.
##
## Ci si parla premendo [code]E[/code], oppure ti vede da lontano: se entri nel
## suo sguardo (una striscia di [member sight_tiles] mattonelle davanti a lui,
## senza muri in mezzo) compare un "!" e ti viene incontro, come un allenatore.
## Poi parte la scena (vedi [method WorldDirector.face_boss]).
##
## Battuto, resta battuto: si sposta di [member defeated_offset] (libera il
## passaggio) e ti dice solo una frase.
class_name WorldBoss extends WorldCharacter


## Quale boss e' (id di [StoryData]).
@export var boss_id: StringName = &"comparsa"

## Quante mattonelle vede davanti a se' (0 = non ti viene incontro).
@export var sight_tiles: int = 4

## Dove si sposta quando e' battuto, rispetto a dove sta.
@export var defeated_offset: Vector2 = Vector2(48, 0)

var _sight: Area2D = null
var _home: Vector2


func _ready() -> void:
	var data: StoryData.StoryBoss = StoryData.find_boss(boss_id)
	if data != null and face_style == "":
		var worn: MaskData = MaskLibrary.find_by_id(data.worn_mask_id)
		if worn != null:
			face_style = worn.face
			face_accent = worn.accent
		elif data.worn_mask_id == &"":
			face_style = "none"
	prompt = "Parla"
	super._ready()
	add_to_group(&"world_boss")
	_home = position
	talked.connect(_on_talked)
	_build_sight()
	refresh()


## Si rimette dove deve stare, a seconda che sia battuto o no.
func refresh() -> void:
	var defeated: bool = GameState.is_boss_defeated(boss_id)
	position = _home + (defeated_offset if defeated else Vector2.ZERO)
	if _sight != null:
		_sight.monitoring = not defeated and sight_tiles > 0
	if defeated:
		face(Vector2.DOWN)
		sprite.modulate = tint.darkened(0.25)


func is_defeated() -> bool:
	return GameState.is_boss_defeated(boss_id)


func _on_talked(player: Node) -> void:
	if Overworld.instance != null:
		Overworld.instance.director.face_boss(self, player, false)


func _build_sight() -> void:
	if sight_tiles <= 0:
		return
	_sight = Area2D.new()
	_sight.collision_layer = 0
	_sight.collision_mask = 4
	var shape: RectangleShape2D = RectangleShape2D.new()
	var length: float = sight_tiles * 32.0
	var dir: Vector2 = facing.normalized()
	shape.size = Vector2(absf(dir.x) * length + 24.0, absf(dir.y) * length + 24.0)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = dir * (length * 0.5 + 16.0)
	_sight.add_child(collision)
	add_child(_sight)
	_sight.body_entered.connect(_on_seen)


func _on_seen(body: Node2D) -> void:
	if not body.is_in_group(&"player") or is_defeated() or Overworld.instance == null:
		return
	if Overworld.instance.is_busy() or not _clear_line_to(body):
		return
	Overworld.instance.director.face_boss(self, body, true)


## Niente muri tra lui e te.
func _clear_line_to(body: Node2D) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -4), body.global_position + Vector2(0, -4), 1)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
