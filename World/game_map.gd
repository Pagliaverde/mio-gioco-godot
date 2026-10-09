## Una mappa del mondo: una stanza del teatro in cui si cammina.
##
## [b]Com'e' fatta una mappa[/b] (vedi [code]World/maps/*.tscn[/code]):
## [codeblock]
## Mappa (GameMap)
## ├── Pavimento   TileMapLayer, solo grafica
## ├── Muri        TileMapLayer, con collisione (livello "mondo")
## └── Entita      Node2D con ordinamento per Y: oggetti di scena, bauli,
##                 boss, negozi, porte, punti d'arrivo... e il giocatore,
##                 che [Overworld] ci mette dentro entrando.
## [/codeblock]
## La palette della zona e' un [CanvasModulate] ([member ambient]): tutte le
## zone usano le stesse mattonelle con colori diversi, come chiede il documento
## di design. Le luci (lampioni, riflettori) ci bucano dentro.
class_name GameMap extends Node2D


## Quale mappa e' (id di [WorldData.map_ids]).
@export var map_id: StringName = &""

## Il colore della luce della zona: piu' scuro = piu' buio in sala.
@export var ambient: Color = Color(0.8, 0.78, 0.85)

## Lucciole di polvere nell'aria.
@export var dust: bool = true

const TILE := 32


func _ready() -> void:
	var modulate_node: CanvasModulate = CanvasModulate.new()
	modulate_node.color = ambient
	add_child(modulate_node)
	if dust:
		_add_dust()


## Il nodo dove stanno i personaggi (ordinato per Y).
func entities() -> Node2D:
	var node: Node2D = get_node_or_null(^"Entita") as Node2D
	return node if node != null else self


## Un punto d'arrivo dal suo nome, o null.
func find_spawn(spawn_id: StringName) -> WorldSpawn:
	for node: Node in find_children("*", "WorldSpawn", true, false):
		var spawn: WorldSpawn = node as WorldSpawn
		if spawn.spawn_id == spawn_id:
			return spawn
	return null


## Il primo punto d'arrivo della mappa (per quando il nome non torna).
func first_spawn() -> WorldSpawn:
	var found: Array[Node] = find_children("*", "WorldSpawn", true, false)
	return found[0] as WorldSpawn if not found.is_empty() else null


## Il rettangolo della mappa in pixel, dalle mattonelle usate.
func bounds() -> Rect2:
	var rect: Rect2i = Rect2i()
	var first: bool = true
	for node: Node in get_children():
		var layer: TileMapLayer = node as TileMapLayer
		if layer == null:
			continue
		var used: Rect2i = layer.get_used_rect()
		if used.size == Vector2i.ZERO:
			continue
		rect = used if first else rect.merge(used)
		first = false
	return Rect2(Vector2(rect.position * TILE), Vector2(rect.size * TILE))


func _add_dust() -> void:
	var area: Rect2 = bounds()
	if area.size == Vector2.ZERO:
		return
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Polvere"
	particles.position = area.get_center()
	particles.amount = clampi(int(area.get_area() / 9000.0), 12, 80)
	particles.lifetime = 8.0
	particles.preprocess = 8.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = area.size * 0.5
	particles.direction = Vector2(0.3, 1)
	particles.spread = 30.0
	particles.gravity = Vector2(0, 2)
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 9.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 1.5
	particles.color = Color(1.0, 0.95, 0.85, 0.35)
	particles.z_index = 30
	add_child(particles)
