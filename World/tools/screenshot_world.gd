## Fotografa le mappe del mondo e qualche momento di gioco, in
## [code]user://screenshots/world/[/code]. Serve una finestra (anche virtuale):
## [codeblock]
## xvfb-run -a godot --path . --rendering-driver opengl3 res://World/tools/screenshot_world.tscn
## [/codeblock]
## Per ogni mappa: una foto intera dall'alto ([code]<mappa>_mappa.png[/code])
## e una inquadratura di gioco sul punto d'arrivo ([code]<mappa>_gioco.png[/code]).
extends Node


const DIR := "user://screenshots/world"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	Transition.instant = true
	await _shoot_maps()
	await _shoot_play()
	await _shoot_moments()
	print("[screenshot_world] foto in %s" % ProjectSettings.globalize_path(DIR))
	get_tree().quit(0)


func _shoot_maps() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	for map_id: StringName in WorldData.map_ids():
		var map: GameMap = (load(WorldData.map_path(map_id)) as PackedScene).instantiate()
		add_child(map)
		var camera: Camera2D = Camera2D.new()
		var rect: Rect2 = map.bounds()
		camera.position = rect.get_center()
		var zoom: float = minf(size.x / rect.size.x, size.y / rect.size.y)
		camera.zoom = Vector2(zoom, zoom)
		map.add_child(camera)
		camera.make_current()
		await get_tree().create_timer(0.3).timeout
		_save("%s_mappa" % map_id)
		map.queue_free()
		await _frames(1)


func _shoot_play() -> void:
	Overworld.auto_pilot = false
	GameState.new_game()
	for map_id: StringName in [&"camerino", &"piazza", &"palco", &"auditorium"]:
		GameState.map_id = map_id
		GameState.spawn = &"ingresso"
		GameState.set_flag("zona/%s" % map_id)
		var world: Overworld = (load("res://World/overworld.tscn") as PackedScene).instantiate()
		add_child(world)
		await get_tree().create_timer(1.2).timeout
		_save("%s_gioco" % map_id)
		world.queue_free()
		await _frames(2)


## I momenti: un testo, il negozio, la scelta della maschera, una battaglia.
func _shoot_moments() -> void:
	GameState.new_game()
	GameState.gain_mask(&"tragedia")
	GameState.gain_mask(&"commedia")
	GameState.add_money(300)
	GameState.map_id = &"piazza"
	GameState.spawn = &"ingresso"
	GameState.set_flag("zona/piazza")
	var world: Overworld = (load("res://World/overworld.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().create_timer(0.8).timeout
	world.text_box.page("Sei quello senza faccia, eh? Benvenuto in piazza. E' tutta dipinta: non appoggiarti ai palazzi.", [], "Il Macchinista")
	await get_tree().create_timer(1.5).timeout
	_save("momento_testo")
	world.text_box.close()

	var menu: ShopMenu = ShopMenu.new()
	menu.shop_id = &"burattinaio"
	world.menu_layer.add_child(menu)
	await get_tree().create_timer(0.6).timeout
	_save("momento_negozio")
	menu.queue_free()

	var picker: MaskPicker = MaskPicker.new()
	world.battle_layer.add_child(picker)
	picker.pick(GameState.owned_masks(), "La Comparsa", GameState.worn_mask_data())
	await get_tree().create_timer(0.6).timeout
	_save("momento_maschera")
	picker.queue_free()

	world.text_box.auto_pilot = true
	world.director.start_encounter(&"manichino_prova")
	await get_tree().create_timer(5.0).timeout
	_save("momento_battaglia")
	world.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func _save(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [DIR, file_name])
