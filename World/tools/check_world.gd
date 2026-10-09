## Gioca tutto il mondo da solo, senza finestra, e controlla che regga.
##
## [b]Come si usa[/b] (e' una scena: servono gli autoload):
## [codeblock]
## godot --headless --path . res://World/tools/check_world.tscn
## [/codeblock]
## Usa [member Overworld.auto_pilot]: i testi scelgono il primo pulsante e le
## scene le recita un'IA (con sei livelli di gavetta in piu', come
## [code]check_story[/code]). Controlla, nell'ordine:
## - che ogni mappa abbia un ingresso e che ogni porta porti a un punto
##   d'arrivo che esiste;
## - che i muri fermino il giocatore;
## - bauli, letto, negozio, un incontro nelle quinte;
## - i cinque boss: battuti restano battuti, lasciano la maschera, aprono la porta;
## - salvataggio e ripresa (mappa, posizione, maschere, biglietti);
## - le stanze laterali e il finale.
## Esce con codice 1 se qualcosa non torna.
extends Node


var _world: Overworld
var _errors: PackedStringArray = []
var _ending: StringName = &""


func _ready() -> void:
	Overworld.auto_pilot = true
	SaveGame.erase()
	_check_maps()
	await _play()
	_finish()


func _expect(condition: bool, what: String) -> void:
	if condition:
		print("[check_world] ok: %s" % what)
	else:
		print("[check_world] ERRORE: %s" % what)
		_errors.append(what)


func _finish() -> void:
	if _errors.is_empty():
		print("[check_world] OK: mondo completato, finale '%s'." % _ending)
		get_tree().quit(0)
	else:
		print("[check_world] %d errori." % _errors.size())
		get_tree().quit(1)


#region Le mappe, da ferme


func _check_maps() -> void:
	var spawns: Dictionary = {}
	var warps: Array[Array] = []
	for map_id: StringName in WorldData.map_ids():
		if not WorldData.has_map(map_id):
			_expect(false, "la mappa %s esiste" % map_id)
			continue
		var map: GameMap = (load(WorldData.map_path(map_id)) as PackedScene).instantiate()
		var names: Array[StringName] = []
		for node: Node in map.find_children("*", "WorldSpawn", true, false):
			names.append((node as WorldSpawn).spawn_id)
		spawns[map_id] = names
		for node: Node in map.find_children("*", "Warp", true, false):
			var warp: Warp = node as Warp
			warps.append([map_id, warp.target_map, warp.target_spawn])
		_expect(map.map_id == map_id, "%s: map_id giusto" % map_id)
		_expect(names.has(&"ingresso"), "%s: ha un ingresso" % map_id)
		map.free()
	for warp: Array in warps:
		var targets: Array = spawns.get(warp[1], [])
		_expect(targets.has(warp[2]), "porta %s -> %s/%s" % warp)


#endregion

#region La partita


func _play() -> void:
	GameState.new_game()
	GameState.level += 6
	GameState.map_id = WorldData.START_MAP
	GameState.spawn = WorldData.START_SPAWN
	_world = (load("res://World/overworld.tscn") as PackedScene).instantiate()
	add_child(_world)
	_world.director.run_finished.connect(func(id: StringName) -> void: _ending = id)
	await _idle()
	_expect(GameState.map_id == &"camerino", "si comincia nel camerino")

	# --- I muri fermano ---
	var player: Player = _world.player
	_expect(player.test_move(player.global_transform, Vector2(0, -2000)), "il muro del camerino ferma il giocatore")
	_expect(player.test_move(player.global_transform, Vector2(-2000, 0)), "il muro di sinistra ferma il giocatore")

	# --- Il Baule di Scena e il letto ---
	await _open_chests()
	_expect(GameState.masks.size() == 1, "il baule del camerino da' una maschera (%d)" % GameState.masks.size())
	GameState.set_hp(100)
	var bed: InspectPoint = _first(InspectPoint, func(n: Node) -> bool: return (n as InspectPoint).heals)
	await _world.director.inspect(bed, player)
	_expect(GameState.hp == GameState.max_hp, "il letto ridà la vita")

	# --- La piazza: negozio, incontro, boss ---
	await _go(&"piazza")
	GameState.add_money(500)
	var before: int = GameState.build_deck().card_count()
	var shop: ShopStall = _first(ShopStall)
	await _world.director.open_shop(shop, player)
	_buy_first_card(shop.shop_id)
	_expect(GameState.build_deck().card_count() == before + 1, "una battuta comprata entra nel repertorio")
	_expect(GameState.money < 500, "comprare costa biglietti")
	_check_copy_limit()

	var hp_before: int = GameState.hp
	var money_before: int = GameState.money
	await _world.director.start_encounter(&"macchia")
	await _idle()
	_expect(GameState.hp <= hp_before, "la vita resta dopo la scena (%d -> %d)" % [hp_before, GameState.hp])
	_expect(GameState.money != money_before, "l'incontro cambia i biglietti")
	_expect(GameState.map_id == &"piazza", "dopo l'incontro si e' ancora in piazza")

	await _look_at_audience()
	await _open_chests()
	await _beat_boss(&"comparsa")

	# --- Salvataggio e ripresa ---
	_world.store_player_position()
	var saved_position: Vector2 = GameState.position
	var report: Dictionary = SaveGame.save_now(get_tree())
	_expect(report.get("ok", false) and int(report.get("nodes", 0)) >= 1, "il salvataggio si scrive")
	var data: Dictionary = SaveGame.read()
	var progress: Dictionary = {}
	for key: String in data.get("nodes", {}):
		if key.ends_with("Progresso"):
			progress = data["nodes"][key]
	_expect(str(progress.get("map", "")) == "piazza", "il salvataggio ricorda la mappa")
	_expect(progress.get("position", Vector2.ZERO) == saved_position, "il salvataggio ricorda la posizione")
	_expect(Array(progress.get("bosses", [])).has("comparsa"), "il salvataggio ricorda i boss battuti")
	var masks_before: int = GameState.masks.size()
	GameState.apply_save_data(progress)
	_expect(GameState.masks.size() == masks_before and GameState.is_boss_defeated(&"comparsa"), "la ripresa rimette maschere e boss")

	# --- Le stanze laterali ---
	await _visit_side_room(&"ridotto", &"piazza")

	# --- Le altre zone ---
	for step: Array in [
		[&"galleria", &"sostituto", &"magazzino"],
		[&"palco", &"prima_attrice", &"graticcia"],
		[&"corridoi", &"carceriere", &"sartoria"],
		[&"auditorium", &"ultimo", &""],
	]:
		await _go(step[0])
		await _look_at_audience()
		await _open_chests()
		if step[2] != &"":
			await _visit_side_room(step[2], step[0])
		await _beat_boss(step[1])

	_expect(GameState.masks.size() >= 9, "alla fine hai tutte le maschere (%d)" % GameState.masks.size())

	# --- Il finale ---
	await _go(&"fondo")
	var door: StoryTrigger = _first(StoryTrigger, func(n: Node) -> bool: return (n as StoryTrigger).event == &"porta_dipinta")
	await _world.director.on_story_event(door)
	var row: StoryTrigger = _first(StoryTrigger, func(n: Node) -> bool: return (n as StoryTrigger).event == &"ultima_fila")
	await _world.director.on_story_event(row)
	var turned: bool = true
	for node: Node in get_tree().get_nodes_in_group(&"world_audience"):
		turned = turned and (node as WorldAudience).turned
	_expect(turned, "i manichini si sono girati tutti")
	_expect(_ending != &"", "la partita arriva a un finale")
	_expect(not SaveGame.has_save(), "dopo il finale il salvataggio e' cancellato")


## Aspetta che il mondo sia fermo (niente testi, niente cambi di stanza).
func _idle() -> void:
	for i: int in 3:
		await get_tree().process_frame
	var safety: int = 100000
	while _world.is_busy() and safety > 0:
		safety -= 1
		await get_tree().process_frame


## Va in una mappa passando dalla sua porta, come farebbe il giocatore.
func _go(map_id: StringName) -> void:
	await _idle()
	var warp: Warp = _first(Warp, func(n: Node) -> bool: return (n as Warp).target_map == map_id)
	_expect(warp != null, "da %s c'e' una porta per %s" % [GameState.map_id, map_id])
	if warp == null:
		await _world.change_map(map_id, &"ingresso")
	else:
		_expect(warp.is_open(), "la porta per %s e' aperta" % map_id)
		await _world.on_warp(warp, _world.player)
	await _idle()
	_expect(GameState.map_id == map_id, "si arriva in %s" % map_id)


func _visit_side_room(room: StringName, back: StringName) -> void:
	await _go(room)
	await _open_chests()
	await _go(back)


func _open_chests() -> void:
	await _idle()
	for node: Node in _world.map.find_children("*", "StageChest", true, false):
		var chest: StageChest = node as StageChest
		if chest.is_open():
			continue
		await _world.director.open_chest(chest, _world.player)
		await _idle()
		_expect(chest.is_open(), "%s/%s si apre" % [GameState.map_id, chest.name])


func _look_at_audience() -> void:
	await _idle()
	var trigger: StoryTrigger = _first(StoryTrigger, func(n: Node) -> bool: return (n as StoryTrigger).event == &"platea")
	if trigger == null:
		return
	var visits: int = GameState.audience_visits
	await _world.director.on_story_event(trigger)
	_expect(GameState.audience_visits == visits + 1, "%s: si guarda la platea" % GameState.map_id)


func _beat_boss(boss_id: StringName) -> void:
	await _idle()
	var boss: WorldBoss = _first(WorldBoss, func(n: Node) -> bool: return (n as WorldBoss).boss_id == boss_id)
	_expect(boss != null, "%s e' nel mondo" % boss_id)
	if boss == null:
		return
	var level: int = GameState.level
	var tries: int = 0
	while not boss.is_defeated() and tries < 5:
		tries += 1
		await _world.director.face_boss(boss, _world.player, false)
		await _idle()
	var data: StoryData.StoryBoss = StoryData.find_boss(boss_id)
	_expect(boss.is_defeated(), "%s e' battuto" % boss_id)
	_expect(GameState.has_mask(data.reward_mask_id), "%s lascia la sua maschera" % boss_id)
	_expect(GameState.level == level + 1, "%s: si sale di gavetta" % boss_id)
	var locked: Array[Node] = _world.map.find_children("*", "Warp", true, false).filter(
		func(n: Node) -> bool: return (n as Warp).requires_boss == boss_id)
	for node: Node in locked:
		_expect((node as Warp).is_open(), "battuto %s, la porta si apre" % boss_id)


## Le battute rare hanno un limite di copie per mazzo: il negozio lo rispetta.
func _check_copy_limit() -> void:
	for shop_id: StringName in WorldData.shops():
		for entry: Array in WorldData.shop(shop_id)["stock"]:
			if entry[0] != "card" or GameState.card_limit(entry[1]) <= 0:
				continue
			var extra: Dictionary = GameState.deck_extra.duplicate()
			var guard: int = 0
			while GameState.can_add_card(entry[1]) and guard < 20:
				GameState.add_card(entry[1])
				guard += 1
			_expect(GameState.card_copies(entry[1]) == GameState.card_limit(entry[1]), "%s: al massimo %d copie" % [entry[1], GameState.card_limit(entry[1])])
			GameState.deck_extra = extra
			return


func _buy_first_card(shop_id: StringName) -> void:
	for entry: Array in WorldData.shop(shop_id).get("stock", []):
		if entry[0] == "card":
			var card: CardData = CardLibrary.find_by_id(entry[1])
			if GameState.spend(WorldData.card_price(card)):
				GameState.add_card(card.id)
			return


func _first(type: Variant, filter: Callable = Callable()) -> Node:
	for node: Node in _world.map.find_children("*", "", true, false):
		if not is_instance_of(node, type):
			continue
		if filter.is_valid() and not filter.call(node):
			continue
		return node
	return null


#endregion
