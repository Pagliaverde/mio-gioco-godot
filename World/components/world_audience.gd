## La platea: file di manichini, immobili, che guardano tutti dalla stessa parte.
##
## Le tre regole del documento di design, e non si toccano:
## 1. [b]non si muovono mai[/b];
## 2. [b]non ti attaccano[/b] (hanno una collisione, ma niente area di
##    interazione: non si parla col pubblico);
## 3. [b]si girano tutti insieme, una volta sola[/b]: [method turn_all], nel finale.
##
## E poi c'e' [b]quello che si sposta[/b]: a ogni visita alla platea
## ([member GameState.audience_visits]) un posto e' vuoto e il suo manichino e'
## da un'altra parte. Nessuno te lo dice: lo vedi.
class_name WorldAudience extends Node2D


@export var rows: int = 4
@export var seats_per_row: int = 8

## Distanza tra un manichino e l'altro, in pixel.
@export var spacing: Vector2 = Vector2(40, 44)

## Da che parte guardano (verso il palco).
@export var facing: Vector2 = Vector2.UP

## Ogni quanti posti c'e' il corridoio (0 = nessuno).
@export var aisle_every: int = 4

## Se true c'e' il manichino che si sposta.
@export var has_wanderer: bool = true

var _mannequins: Array[WorldCharacter] = []
var turned: bool = false


func _ready() -> void:
	y_sort_enabled = true
	add_to_group(&"world_audience")
	_build()


func _build() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9137 + GameState.audience_visits * 7919
	var empty_seat: Vector2i = Vector2i(rng.randi_range(0, seats_per_row - 1), rng.randi_range(0, rows - 1))
	if not has_wanderer:
		empty_seat = Vector2i(-1, -1)

	for row: int in rows:
		for seat: int in seats_per_row:
			if Vector2i(seat, row) == empty_seat:
				continue
			_add_mannequin(_seat_position(seat, row), facing)

	if has_wanderer:
		# Il manichino che non sta al suo posto: in piedi in un corridoio, o
		# davanti alla prima fila, girato appena di lato.
		var spots: Array[Vector2] = []
		for row: int in rows:
			spots.append(_seat_position(-1, row) + Vector2(spacing.x * 0.5, 0))
			spots.append(_seat_position(seats_per_row, row) - Vector2(spacing.x * 0.5, 0))
		if aisle_every > 0:
			spots.append(_seat_position(aisle_every, rows - 1) - Vector2(spacing.x * 0.75, -spacing.y * 0.5))
		var spot: Vector2 = spots[rng.randi() % spots.size()]
		var wanderer: WorldCharacter = _add_mannequin(spot, facing.rotated(deg_to_rad(rng.randf_range(-40, 40))))
		wanderer.name = "QuelloCheSiSposta"


func _seat_position(seat: int, row: int) -> Vector2:
	var aisles: int = (seat / aisle_every) if aisle_every > 0 and seat >= 0 else 0
	return Vector2(seat * spacing.x + aisles * spacing.x * 0.75, row * spacing.y)


func _add_mannequin(at: Vector2, dir: Vector2) -> WorldCharacter:
	var mannequin: WorldCharacter = WorldCharacter.new()
	mannequin.look = "manichino"
	mannequin.facing = dir
	mannequin.position = at
	mannequin.prompt = ""
	add_child(mannequin)
	# Non si parla col pubblico.
	mannequin.interaction.enabled = false
	mannequin.interaction.monitoring = false
	_mannequins.append(mannequin)
	return mannequin


## Si girano tutti insieme, nello stesso fotogramma, verso [param point].
## Una volta sola.
func turn_all(point: Vector2) -> void:
	if turned:
		return
	turned = true
	for mannequin: WorldCharacter in _mannequins:
		mannequin.face_point(point)
