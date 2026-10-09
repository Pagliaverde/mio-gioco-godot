## Il mondo esplorabile: la scena in cui si gioca tutto [b]Fuori Copione[/b].
##
## Tiene il giocatore, la mappa in cui si trova, la HUD e i livelli dove
## compaiono testi, negozi e battaglie. [b]Non si ricarica mai durante la
## partita:[/b] cambiare stanza cambia solo la mappa figlia, e una battaglia
## compare sopra al mondo e poi sparisce. Cosi', finita una scena, sei
## esattamente dov'eri.
##
## [codeblock]
## Overworld
## ├── Mappe            la mappa corrente ([GameMap]); il giocatore sta
## │                    dentro la sua "Entita"
## ├── Regista          [WorldDirector]: storia, boss, bauli, negozi
## ├── Progresso        partecipa al salvataggio per conto di [code]GameState[/code]
## ├── HUD              [WorldHud]
## ├── Testi            [WorldTextBox]
## ├── Menu             negozio e inventario
## └── Battaglia        dove compare [StoryBattle]
## [/codeblock]
##
## Tutto e' costruito in codice: [code]World/overworld.tscn[/code] contiene
## solo questo script.
class_name Overworld extends Node2D


## Il mondo aperto in questo momento (ce n'e' uno solo). Le componenti delle
## mappe ([WorldBoss], [StageChest]...) passano di qui per chiedere qualcosa.
static var instance: Overworld = null

## Se true il gioco si gioca da solo (serve ai controlli senza finestra):
## i testi scelgono il primo pulsante e le scene le recita un'IA.
static var auto_pilot: bool = false

## Emesso dopo che una mappa e' entrata e il giocatore e' al suo posto.
signal map_loaded(map_id: StringName)

const PLAYER_SCENE := preload("res://Scene/Player/Player.tscn")
const MENU_SCENE := "res://Menu/main_menu.tscn"


## Il nodo che partecipa al salvataggio per conto di [code]GameState[/code].
class ProgressNode extends Node:
	func get_save_data() -> Variant:
		var world: Overworld = get_parent() as Overworld
		if world != null:
			world.store_player_position()
		return GameState.get_save_data()

	func apply_save_data(data: Variant) -> void:
		GameState.apply_save_data(data)


var player: Player
var map: GameMap = null
var director: WorldDirector
var hud: WorldHud
var text_box: WorldTextBox
var menu_layer: CanvasLayer
var battle_layer: CanvasLayer

var _map_holder: Node2D
var _changing_map: bool = false
var _old_clear_color: Color

## Il colore fuori dalle mappe: il buio della sala.
const BACKSTAGE_COLOR := Color("0b0910")


func _ready() -> void:
	instance = self
	Transition.instant = auto_pilot
	_old_clear_color = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(BACKSTAGE_COLOR)

	_map_holder = Node2D.new()
	_map_holder.name = "Mappe"
	add_child(_map_holder)

	player = PLAYER_SCENE.instantiate()
	player.saves_itself = false
	player.attack_enabled = false

	hud = WorldHud.new()
	hud.name = "HUD"
	add_child(hud)

	text_box = WorldTextBox.new()
	text_box.name = "Testi"
	text_box.auto_pilot = auto_pilot
	add_child(text_box)

	menu_layer = CanvasLayer.new()
	menu_layer.name = "Menu"
	menu_layer.layer = 25
	add_child(menu_layer)

	battle_layer = CanvasLayer.new()
	battle_layer.name = "Battaglia"
	battle_layer.layer = 30
	add_child(battle_layer)

	director = WorldDirector.new()
	director.name = "Regista"
	add_child(director)

	# Il progresso: se arriviamo da "Riprendi" i dati ci vengono consegnati
	# adesso. Se no, e non c'e' una partita in corso (es. F6 dall'editor),
	# ne comincia una nuova.
	var progress: ProgressNode = ProgressNode.new()
	progress.name = "Progresso"
	add_child(progress)
	progress.add_to_group(SaveGame.GROUP)
	if not SaveGame.apply_to(progress) and not GameState.started:
		GameState.new_game()

	if GameState.spawn != &"":
		load_map(GameState.map_id, GameState.spawn)
	else:
		load_map(GameState.map_id, &"", GameState.position)
	player.face(GameState.facing)

	if not auto_pilot:
		Transition.fade_in(0.6)


func _exit_tree() -> void:
	if instance == self:
		instance = null
	Transition.instant = false
	RenderingServer.set_default_clear_color(_old_clear_color)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"inventory") and not is_busy():
		get_viewport().set_input_as_handled()
		director.open_inventory()


## True mentre succede qualcosa che non deve essere interrotto (un testo, una
## battaglia, un cambio di stanza): niente incontri, niente sguardi dei boss.
func is_busy() -> bool:
	return _changing_map or director.is_busy()


#region Mappe


## Carica una mappa e ci mette il giocatore. Usa [param spawn_id] se esiste,
## altrimenti [param at], altrimenti il primo punto d'arrivo.
func load_map(map_id: StringName, spawn_id: StringName = &"", at: Variant = null) -> void:
	if not WorldData.has_map(map_id):
		push_warning("Overworld: la mappa '%s' non esiste, torno al camerino." % map_id)
		map_id = WorldData.START_MAP
		spawn_id = WorldData.START_SPAWN

	if player.get_parent() != null:
		player.get_parent().remove_child(player)
	if map != null:
		_map_holder.remove_child(map)
		map.queue_free()

	GameState.map_id = map_id
	map = (load(WorldData.map_path(map_id)) as PackedScene).instantiate()
	_map_holder.add_child(map)
	map.entities().add_child(player)

	var spawn: WorldSpawn = map.find_spawn(spawn_id) if spawn_id != &"" else null
	if spawn != null:
		player.global_position = spawn.global_position
		player.face(spawn.facing)
	elif typeof(at) == TYPE_VECTOR2:
		player.global_position = at
	else:
		spawn = map.first_spawn()
		if spawn != null:
			player.global_position = spawn.global_position
			player.face(spawn.facing)
	GameState.spawn = &""
	store_player_position()

	_fit_camera()
	var zone: StoryData.StoryZone = WorldData.zone_for(map_id)
	hud.show_zone(zone.title if zone != null else str(map_id), zone.subtitle if zone != null else "")
	map_loaded.emit(map_id)
	director.on_map_entered(map)


## Cambia stanza con una dissolvenza, e salva se le impostazioni lo chiedono.
func change_map(map_id: StringName, spawn_id: StringName) -> void:
	if _changing_map:
		return
	_changing_map = true
	player.lock()
	await Transition.fade_out(0.25)
	load_map(map_id, spawn_id)
	await get_tree().process_frame
	await Transition.fade_in(0.3)
	_changing_map = false
	player.unlock()
	autosave()


## Una porta: se e' aperta si passa, se no si torna indietro di un passo.
func on_warp(warp: Warp, _body: Node2D) -> void:
	if is_busy():
		return
	if warp.is_open():
		change_map(warp.target_map, warp.target_spawn)
		return
	var back: Vector2 = -player.last_direction.normalized() * 20.0
	player.global_position += back
	await director.say(warp.locked_text)


## I limiti della telecamera: non si vede mai fuori dalla mappa.
func _fit_camera() -> void:
	var camera: Camera2D = player.get_node_or_null(^"Camera2D") as Camera2D
	if camera == null:
		return
	var rect: Rect2 = map.bounds()
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)
	camera.reset_smoothing()


#endregion

#region Salvataggio


## Scrive in [code]GameState[/code] dove sta il giocatore adesso.
func store_player_position() -> void:
	if player != null and player.is_inside_tree():
		GameState.position = player.global_position
		GameState.facing = player.last_direction


## Salva se nelle impostazioni c'e' il salvataggio automatico.
func autosave() -> void:
	if auto_pilot or not bool(Settings.get_value("game", "auto_save", true)):
		return
	SaveGame.save_now(get_tree())


## Salva comunque (boss battuti, bauli, negozi: cose che non si vogliono perdere).
func save_now() -> void:
	if not auto_pilot:
		SaveGame.save_now(get_tree())


## Torna al menu principale.
func go_to_menu() -> void:
	if auto_pilot:
		return
	await Transition.fade_out(0.4)
	get_tree().change_scene_to_file(MENU_SCENE)
	Transition.fade_in(0.4)


#endregion
