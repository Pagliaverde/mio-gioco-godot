## Un passaggio verso un'altra mappa: una porta, un varco tra le quinte.
##
## Ci si cammina dentro e si cambia stanza. Se [member requires_boss] non e'
## vuoto, il passaggio resta chiuso finche' quel boss non e' battuto: ti
## respinge indietro e dice [member locked_text].
class_name Warp extends Area2D


## La mappa di destinazione (id di [WorldData.map_ids]).
@export var target_map: StringName = &""

## Il punto d'arrivo nella mappa di destinazione ([WorldSpawn]).
@export var target_spawn: StringName = &"ingresso"

## Il boss da battere prima di poter passare (vuoto = sempre aperto).
@export var requires_boss: StringName = &""

## Cosa si legge se il passaggio e' chiuso.
@export_multiline var locked_text: String = "Non e' ancora il momento di passare di qui."

## Grandezza dell'area, in pixel.
@export var size: Vector2 = Vector2(32, 32)

## Una freccia luminosa che indica il passaggio.
@export var show_marker: bool = true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	if show_marker:
		_add_marker()


func is_open() -> bool:
	return requires_boss == &"" or GameState.is_boss_defeated(requires_boss)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and Overworld.instance != null:
		Overworld.instance.on_warp(self, body)


## Un bagliore sul pavimento: qui si passa.
func _add_marker() -> void:
	var glow: Polygon2D = Polygon2D.new()
	var half: Vector2 = size * 0.5
	glow.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	glow.color = Color(1.0, 0.85, 0.5, 0.18) if is_open() else Color(0.8, 0.2, 0.25, 0.18)
	glow.z_index = -1
	add_child(glow)
	var tween: Tween = glow.create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
