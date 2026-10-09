## Le quinte: un tratto di pavimento pieno di ritagli, costumi e vernice dove,
## camminando, si incontra qualcuno. E' l'erba alta dei giochi di mostri.
##
## Chi si incontra lo decide [method WorldData.encounter_table] per la mappa;
## [member table] lo sostituisce se non e' vuoto.
class_name EncounterZone extends Area2D


## Probabilita' di un incontro a ogni passo (una mattonella).
@export_range(0.0, 1.0, 0.01) var chance: float = 0.09

## Chi si incontra qui (vuoto = la tabella della mappa).
@export var table: Array[StringName] = []

## Grandezza dell'area, in pixel.
@export var size: Vector2 = Vector2(96, 96)

## Passi minimi dopo un incontro prima del prossimo.
@export var cooldown_steps: int = 4

## Ultima posizione del giocatore vista, per contare i passi.
var _last: Vector2 = Vector2.INF
var _walked: float = 0.0
var _player: Node2D = null

## I passi da fare prima che sia di nuovo possibile un incontro (condiviso:
## uscire e rientrare non lo azzera).
static var steps_to_wait: int = 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group(&"player"):
			_player = body
			_last = body.global_position)
	body_exited.connect(func(body: Node2D) -> void:
		if body == _player:
			_player = null)
	_add_dust()


func _physics_process(_delta: float) -> void:
	if _player == null or Overworld.instance == null or Overworld.instance.is_busy():
		if _player != null:
			_last = _player.global_position
		return
	_walked += _player.global_position.distance_to(_last)
	_last = _player.global_position
	while _walked >= 32.0:
		_walked -= 32.0
		_step()


func _step() -> void:
	if steps_to_wait > 0:
		steps_to_wait -= 1
		return
	if randf() >= chance:
		return
	var options: Array[StringName] = table if not table.is_empty() else WorldData.encounter_table(GameState.map_id)
	if options.is_empty():
		return
	steps_to_wait = cooldown_steps
	_walked = 0.0
	Overworld.instance.director.start_encounter(options[randi() % options.size()])


## Polvere di scena che galleggia: si vede che qui c'e' qualcosa.
func _add_dust() -> void:
	var dust: CPUParticles2D = CPUParticles2D.new()
	dust.amount = maxi(int(size.x * size.y / 2048.0), 4)
	dust.lifetime = 3.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = size * 0.5
	dust.direction = Vector2(0, -1)
	dust.spread = 40.0
	dust.gravity = Vector2(0, -4)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 8.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.0
	dust.color = Color(0.85, 0.75, 1.0, 0.45)
	dust.z_index = 5
	add_child(dust)
