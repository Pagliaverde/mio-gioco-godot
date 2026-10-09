## Un'area con cui si interagisce premendo [code]E[/code]: un baule, un bancone,
## un boss, una porta dipinta.
##
## [b]E' separata dalla collisione:[/b] l'oggetto ha il suo corpo solido (che
## ferma il giocatore) e questa area, un po' piu' larga, che dice "sei abbastanza
## vicino per parlarci". Il giocatore ([Player]) cerca le aree del gruppo
## [code]interactable[/code] sul livello di fisica 2 e chiama [method interact].
##
## Quando il giocatore e' vicino compare un fumetto con il tasto.
##
## [codeblock]
## var area: Interactable = Interactable.create(self, 28.0)
## area.interacted.connect(_on_interacted)
## [/codeblock]
class_name Interactable extends Area2D


## Emesso quando il giocatore preme il tasto di interazione qui davanti.
signal interacted(player: Node)

## Quanto e' larga l'area, in pixel.
@export var radius: float = 26.0:
	set(value):
		radius = value
		if _shape != null:
			(_shape.shape as CircleShape2D).radius = radius

## Il testo del fumetto ("E", "Parla", "Apri"...).
@export var prompt: String = "E"

## Se false l'area non risponde (es. un baule gia' aperto, per chi lo vuole muto).
@export var enabled: bool = true:
	set(value):
		enabled = value
		monitorable = value
		if not value and _bubble != null:
			_bubble.visible = false

var _shape: CollisionShape2D = null
var _bubble: Node2D = null
var _player_near: bool = false


## Crea un'area e la aggiunge a [param parent], spostata di [param offset].
static func create(parent: Node2D, area_radius: float = 26.0, offset: Vector2 = Vector2.ZERO) -> Interactable:
	var area: Interactable = Interactable.new()
	area.name = "Interazione"
	area.radius = area_radius
	area.position = offset
	parent.add_child(area)
	return area


func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 2
	collision_mask = 4
	monitoring = true
	monitorable = enabled

	for child: Node in get_children():
		if child is CollisionShape2D:
			_shape = child
	if _shape == null:
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = radius
		_shape = CollisionShape2D.new()
		_shape.shape = circle
		add_child(_shape)

	_bubble = _make_bubble()
	add_child(_bubble)
	# Il fumetto galleggia piano su e giu'.
	var tween: Tween = _bubble.create_tween().set_loops()
	tween.tween_property(_bubble, "position:y", _bubble.position.y - 2.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_bubble, "position:y", _bubble.position.y, 0.5).set_trans(Tween.TRANS_SINE)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Chiamato dal giocatore.
func interact(player: Node = null) -> void:
	if enabled:
		interacted.emit(player)


## Mostra o nasconde il fumetto (per chi vuole nasconderlo durante un testo).
func set_bubble_visible(value: bool) -> void:
	if _bubble != null:
		_bubble.visible = value and _player_near and enabled


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_near = true
		set_bubble_visible(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_near = false
		set_bubble_visible(false)


## Il fumetto: un quadratino scuro con il tasto, che galleggia sopra l'oggetto.
func _make_bubble() -> Node2D:
	var bubble: Node2D = Node2D.new()
	bubble.name = "Fumetto"
	bubble.visible = false
	bubble.z_index = 50
	bubble.position = Vector2(0, -radius - 30.0)

	var panel: Panel = Panel.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.08, 0.8)
	style.border_color = Color(1, 0.92, 0.7, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size = Vector2(maxf(12.0, 6.0 * prompt.length() + 6.0), 12)
	panel.position = -panel.size * 0.5
	bubble.add_child(panel)

	var label: Label = Label.new()
	label.text = prompt
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = panel.size
	label.position = panel.position
	bubble.add_child(label)

	return bubble
