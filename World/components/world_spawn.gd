## Un punto d'arrivo in una mappa: dove compari entrando da una porta, dal
## menu, o dopo che il teatro ha ripetuto la sera.
class_name WorldSpawn extends Marker2D


## Il nome del punto (le porte delle altre mappe lo usano come destinazione).
@export var spawn_id: StringName = &"ingresso"

## Da che parte guardi quando compari.
@export var facing: Vector2 = Vector2.DOWN


func _ready() -> void:
	add_to_group(&"world_spawn")
