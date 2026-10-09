## Un punto della mappa dove succede qualcosa di scritto: guardi la platea,
## arrivi davanti alla porta dipinta, l'ultima fila.
##
## Quando il giocatore ci entra, [WorldDirector] riceve [member event] e decide
## cosa raccontare. Con [member once] succede una volta sola per partita.
class_name StoryTrigger extends Area2D


## Cosa succede (vedi [method WorldDirector.on_story_event]).
@export var event: StringName = &"platea"

## Se true succede una sola volta per partita (resta nel salvataggio).
@export var once: bool = false

## Grandezza dell'area, in pixel.
@export var size: Vector2 = Vector2(64, 32)

## Le frasi per l'evento [code]testo[/code] (un pensiero, una scritta sul muro).
@export_multiline var lines: PackedStringArray = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)


## La chiave con cui ci si ricorda che e' gia' successo.
func flag_key() -> String:
	return "evento/%s/%s" % [GameState.map_id, event]


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player") or Overworld.instance == null:
		return
	if once and GameState.flag(flag_key()):
		return
	Overworld.instance.director.on_story_event(self)
