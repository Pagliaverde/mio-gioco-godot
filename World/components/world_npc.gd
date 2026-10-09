## Un abitante del teatro che dice qualcosa: un macchinista, un suggeritore.
##
## Due modi di farlo parlare:
## - [member lines]: frasi semplici, una dopo l'altra, nel riquadro del mondo;
## - [member dialogue] + [member dialogue_title]: un file [code].dialogue[/code]
##   di Dialogue Manager, per i dialoghi con scelte (come lo slime).
##
## Con [member heals] ti rimette in forze (il letto del camerino, il bar).
class_name WorldNpc extends WorldCharacter


## Il nome che compare sopra le battute.
@export var display_name: String = ""

## Le frasi, una per pagina.
@export_multiline var lines: PackedStringArray = []

## Un dialogo di Dialogue Manager (ha la precedenza su [member lines]).
@export var dialogue: Resource = null

## Il titolo da cui comincia il dialogo.
@export var dialogue_title: String = "start"

## Se true, dopo aver parlato la vita torna piena.
@export var heals: bool = false

## Se true gira piano in un raggio di poche mattonelle.
@export var wanders: bool = false

var _home: Vector2
var _start_facing: Vector2
var _wander_time: float = 0.0
var _busy: bool = false


func _ready() -> void:
	super._ready()
	_home = position
	_start_facing = facing
	talked.connect(_on_talked)
	_wander_time = randf_range(1.0, 3.0)


func _physics_process(delta: float) -> void:
	if not wanders or _busy:
		return
	_wander_time -= delta
	if _wander_time > 0.0:
		return
	_wander_time = randf_range(1.5, 4.0)
	var target: Vector2 = _home + Vector2(randf_range(-40, 40), randf_range(-24, 24))
	walk_to(get_parent().to_global(target) if get_parent() is Node2D else target, 40.0)


func _on_talked(player: Node) -> void:
	if _busy or Overworld.instance == null:
		return
	_busy = true
	face_point((player as Node2D).global_position)
	await Overworld.instance.director.talk_to(self, player)
	_busy = false
	face(_start_facing)
