## Costruisce le scene delle mappe ([code]World/maps/*.tscn[/code]) e il TileSet
## del teatro ([code]World/art/theatre_tileset.tres[/code]) a partire dai
## disegni a lettere di [MapLayouts].
##
## [b]Come si usa[/b] (e' una scena: servono gli autoload):
## [codeblock]
## godot --headless --path . res://World/tools/build_maps.tscn
## [/codeblock]
##
## [b]Attenzione:[/b] riscrive le mappe da zero. Se le hai ritoccate
## nell'editor (mattonelle dipinte a mano, oggetti spostati col mouse), quelle
## modifiche si perdono. Dopo la prima volta, le mappe sono scene normali: si
## modificano nell'editor e questo script non serve piu'. Serve per ripartire
## dal disegno, o per aggiungere una mappa nuova (rigenera solo quella con
## [code]-- nome_mappa[/code]).
extends Node


const TILE := 32
const TILES_TEXTURE := "res://World/art/theatre_tiles.png"
const TILESET_PATH := "res://World/art/theatre_tileset.tres"
const SLIME_SCENE := "res://Scene/Player/SlimeNpc.tscn"

## Le lettere del pavimento e la loro mattonella (colonna, riga).
const FLOORS := {
	".": Vector2i(0, 0), "=": Vector2i(3, 0), "_": Vector2i(4, 0), "g": Vector2i(5, 0),
	"m": Vector2i(6, 0), "~": Vector2i(7, 0), "b": Vector2i(3, 2), "c": Vector2i(4, 2),
	"d": Vector2i(7, 2), "o": Vector2i(2, 2),
}

## Le lettere dei muri. Per [code]#[/code], [code]G[/code] e [code]R[/code] la
## mattonella cambia se sotto c'e' pavimento (la faccia del muro) o altro muro
## (la cima).
const WALLS := {
	"#": Vector2i(1, 1), "G": Vector2i(0, 2), "R": Vector2i(5, 2),
	"C": Vector2i(2, 1), "M": Vector2i(3, 1), "K": Vector2i(4, 1), "B": Vector2i(5, 1),
	" ": Vector2i(6, 1), "h": Vector2i(7, 1), "E": Vector2i(1, 2),
}
const WALL_TOP := Vector2i(0, 1)
const SOURCE := 0

var _tileset: TileSet
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _counters: Dictionary = {}


func _ready() -> void:
	var only: PackedStringArray = OS.get_cmdline_user_args()
	_tileset = _build_tileset()
	var built: int = 0
	for layout: Dictionary in MapLayouts.all():
		if not only.is_empty() and not only.has(str(layout["id"])):
			continue
		_build_map(layout)
		built += 1
	print("[build_maps] %d mappe costruite." % built)
	get_tree().quit(0)


#region TileSet


## Il TileSet: una sola sorgente (le mattonelle dipinte), un livello di fisica
## sul livello "mondo", e un quadrato pieno di collisione sulle mattonelle solide.
func _build_tileset() -> TileSet:
	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = load(TILES_TEXTURE)
	source.texture_region_size = Vector2i(TILE, TILE)
	tileset.add_source(source, SOURCE)

	var solid: Array[Vector2i] = [WALL_TOP]
	for key: String in WALLS:
		solid.append(WALLS[key])
	var half: float = TILE * 0.5
	var square: PackedVector2Array = [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]
	for y: int in 3:
		for x: int in 8:
			var coords: Vector2i = Vector2i(x, y)
			source.create_tile(coords)
			if solid.has(coords):
				var data: TileData = source.get_tile_data(coords, 0)
				data.add_collision_polygon(0)
				data.set_collision_polygon_points(0, 0, square)

	var error: Error = ResourceSaver.save(tileset, TILESET_PATH)
	if error != OK:
		push_error("build_maps: non riesco a salvare il TileSet (%d)" % error)
	return load(TILESET_PATH)


#endregion

#region Mappe


func _build_map(layout: Dictionary) -> void:
	_rng.seed = hash(str(layout["id"]))
	_counters = {}
	var map_id: StringName = StringName(str(layout["id"]))
	var rows: Array = layout["rows"]
	var default_floor: String = layout["floor"]
	var legend: Dictionary = layout["legend"]
	var on: Dictionary = layout.get("on", {})

	var root: GameMap = GameMap.new()
	root.name = str(map_id).capitalize().replace(" ", "")
	root.map_id = map_id
	root.ambient = layout.get("ambient", Color(0.8, 0.78, 0.85))
	root.dust = layout.get("dust", true)

	var floor_layer: TileMapLayer = TileMapLayer.new()
	floor_layer.name = "Pavimento"
	floor_layer.tile_set = _tileset
	floor_layer.z_index = -10
	_add(root, floor_layer, root)

	var wall_layer: TileMapLayer = TileMapLayer.new()
	wall_layer.name = "Muri"
	wall_layer.tile_set = _tileset
	wall_layer.z_index = -9
	_add(root, wall_layer, root)

	var entities: Node2D = Node2D.new()
	entities.name = "Entita"
	entities.y_sort_enabled = true
	_add(root, entities, root)

	var height: int = rows.size()
	for y: int in height:
		var row: String = rows[y]
		for x: int in row.length():
			var ch: String = row[x]
			var cell: Vector2i = Vector2i(x, y)
			if WALLS.has(ch):
				wall_layer.set_cell(cell, SOURCE, _wall_tile(rows, x, y))
				continue
			var floor_char: String = ch if FLOORS.has(ch) else str(on.get(ch, default_floor))
			floor_layer.set_cell(cell, SOURCE, _floor_tile(floor_char))
			if not FLOORS.has(ch):
				if not legend.has(ch):
					push_warning("build_maps: lettera '%s' sconosciuta in %s (%d, %d)" % [ch, map_id, x, y])
					continue
				for entity: Dictionary in legend[ch]:
					_add_entity(root, entities, entity, cell)

	for entity: Dictionary in layout.get("decor", []):
		var at: Vector2 = entity["at"]
		_add_entity(root, entities, entity, Vector2i(at))

	_add_encounter_zones(root, entities, rows)

	var packed: PackedScene = PackedScene.new()
	var error: Error = packed.pack(root)
	if error == OK:
		error = ResourceSaver.save(packed, WorldData.map_path(map_id))
	print("[build_maps] %s: %s" % [map_id, "OK" if error == OK else "ERRORE %d" % error])
	root.free()


func _wall_tile(rows: Array, x: int, y: int) -> Vector2i:
	var ch: String = rows[y][x]
	if ch in ["#", "G", "R"]:
		var below: String = rows[y + 1][x] if y + 1 < rows.size() and x < rows[y + 1].length() else "#"
		if WALLS.has(below):
			return WALL_TOP
	return WALLS[ch]


func _floor_tile(ch: String) -> Vector2i:
	if ch == ".":
		# Le assi viola hanno tre varianti, a caso ma sempre le stesse.
		var roll: float = _rng.randf()
		return Vector2i(0, 0) if roll < 0.55 else (Vector2i(1, 0) if roll < 0.85 else Vector2i(2, 0))
	return FLOORS.get(ch, Vector2i(0, 0))


## Le quinte: ogni gruppo di "~" vicini diventa una [EncounterZone].
func _add_encounter_zones(root: Node, entities: Node2D, rows: Array) -> void:
	var seen: Dictionary = {}
	for y: int in rows.size():
		for x: int in String(rows[y]).length():
			if rows[y][x] != "~" or seen.has(Vector2i(x, y)):
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[Vector2i(x, y)] = true
			var low: Vector2i = Vector2i(x, y)
			var high: Vector2i = Vector2i(x, y)
			while not stack.is_empty():
				var cell: Vector2i = stack.pop_back()
				low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
				high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
				for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = cell + step
					if seen.has(next) or next.y < 0 or next.y >= rows.size() or next.x < 0 or next.x >= String(rows[next.y]).length():
						continue
					if rows[next.y][next.x] == "~":
						seen[next] = true
						stack.append(next)
			var zone: EncounterZone = EncounterZone.new()
			zone.name = _name("Quinte")
			zone.size = Vector2((high - low + Vector2i.ONE) * TILE)
			zone.position = Vector2(low * TILE) + zone.size * 0.5
			_add(entities, zone, root)


func _add_entity(root: Node, parent: Node2D, entity: Dictionary, cell: Vector2i) -> void:
	var feet: Vector2 = Vector2(cell.x * TILE + TILE * 0.5, cell.y * TILE + TILE)
	var center: Vector2 = Vector2(cell.x * TILE + TILE * 0.5, cell.y * TILE + TILE * 0.5)
	var node: Node2D = null
	match str(entity["t"]):
		"spawn":
			var spawn: WorldSpawn = WorldSpawn.new()
			spawn.spawn_id = StringName(entity["id"])
			spawn.facing = entity.get("face", Vector2.DOWN)
			spawn.name = _name("Arrivo_" + str(entity["id"]).capitalize().replace(" ", ""))
			spawn.position = feet - Vector2(0, 6)
			node = spawn
		"warp":
			var warp: Warp = Warp.new()
			warp.target_map = StringName(entity["to"])
			warp.target_spawn = StringName(entity["spawn"])
			warp.requires_boss = StringName(entity.get("boss", ""))
			if entity.has("locked"):
				warp.locked_text = entity["locked"]
			warp.size = entity.get("size", Vector2(TILE, TILE))
			warp.name = _name("Porta_" + str(entity["to"]).capitalize().replace(" ", ""))
			warp.position = center
			node = warp
		"prop":
			var prop: WorldProp = WorldProp.new()
			prop.kind = entity["kind"]
			if entity.has("tint"):
				prop.tint = entity["tint"]
			prop.name = _name(str(entity["kind"]).capitalize().replace(" ", ""))
			prop.position = feet
			node = prop
		"inspect":
			var point: InspectPoint = InspectPoint.new()
			point.lines = PackedStringArray(entity.get("lines", []))
			point.prompt = entity.get("prompt", "Guarda")
			point.heals = entity.get("heals", false)
			point.radius = entity.get("radius", 26.0)
			point.name = _name("DaGuardare")
			point.position = feet - Vector2(0, 8)
			node = point
		"chest":
			var chest: StageChest = StageChest.new()
			chest.kind = entity.get("kind", "cassa")
			chest.money = int(entity.get("money", 0))
			chest.item_id = StringName(entity.get("item", ""))
			chest.card_id = StringName(entity.get("card", ""))
			chest.name = _name("BauleDiScena" if chest.kind == "scena" else "CassaAttrezzi")
			chest.position = feet
			node = chest
		"boss":
			var boss: WorldBoss = WorldBoss.new()
			boss.boss_id = StringName(entity["id"])
			boss.facing = entity.get("face", Vector2.DOWN)
			boss.sight_tiles = int(entity.get("sight", 4))
			boss.defeated_offset = entity.get("off", Vector2(48, 0))
			boss.tint = entity.get("tint", Color.WHITE)
			boss.name = _name("Boss_" + str(entity["id"]).capitalize().replace(" ", ""))
			boss.position = feet
			node = boss
		"npc":
			var npc: WorldNpc = WorldNpc.new()
			npc.display_name = entity.get("name", "")
			npc.look = entity.get("look", "npc")
			npc.tint = entity.get("tint", Color.WHITE)
			npc.facing = entity.get("face", Vector2.DOWN)
			npc.lines = PackedStringArray(entity.get("lines", []))
			npc.heals = entity.get("heals", false)
			npc.wanders = entity.get("wander", false)
			npc.prompt = entity.get("prompt", "Parla")
			npc.name = _name(str(entity.get("name", "Abitante")).capitalize().replace(" ", "").replace("'", ""))
			npc.position = feet
			node = npc
		"shop":
			var shop: ShopStall = ShopStall.new()
			shop.shop_id = StringName(entity["id"])
			shop.stall_kind = entity.get("stall", "baracca")
			shop.keeper_look = entity.get("keeper", "")
			shop.keeper_tint = entity.get("keeper_tint", Color.WHITE)
			shop.name = _name("Negozio_" + str(entity["id"]).capitalize().replace(" ", ""))
			shop.position = feet
			node = shop
		"trigger":
			var trigger: StoryTrigger = StoryTrigger.new()
			trigger.event = StringName(entity["event"])
			trigger.size = entity.get("size", Vector2(64, 32))
			trigger.once = entity.get("once", false)
			trigger.lines = PackedStringArray(entity.get("lines", []))
			trigger.name = _name("Evento_" + str(entity["event"]).capitalize().replace(" ", ""))
			trigger.position = center
			node = trigger
		"audience":
			var audience: WorldAudience = WorldAudience.new()
			audience.rows = int(entity.get("rows", 3))
			audience.seats_per_row = int(entity.get("seats", 8))
			audience.facing = entity.get("face", Vector2.UP)
			audience.aisle_every = int(entity.get("aisle", 4))
			audience.spacing = entity.get("spacing", Vector2(40, 44))
			audience.has_wanderer = entity.get("wanderer", true)
			audience.name = _name("Platea")
			audience.position = feet
			node = audience
		"slime":
			var slime: Node2D = (load(SLIME_SCENE) as PackedScene).instantiate()
			slime.name = _name("Slime")
			slime.position = feet - Vector2(0, 10)
			slime.scale = Vector2(1.6, 1.6)
			parent.add_child(slime)
			slime.owner = root
			return
	if node != null:
		_add(parent, node, root)


func _add(parent: Node, node: Node, root: Node) -> void:
	parent.add_child(node)
	if node != root:
		node.owner = root


## Un nome unico, con un numero: i bauli si ricordano per nome.
func _name(base: String) -> String:
	var count: int = int(_counters.get(base, 0)) + 1
	_counters[base] = count
	return base if count == 1 else "%s%d" % [base, count]


#endregion
