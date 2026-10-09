## Il regista del mondo esplorabile: tutto quello che [i]succede[/i] mentre
## cammini. Le presentazioni delle zone, i boss, i Bauli di Scena, i negozi,
## gli incontri nelle quinte, la platea e il finale.
##
## E' il fratello di [StoryDirector]: stessi testi ([StoryData]), stesse
## battaglie ([StoryBattle]), stesse maschere. Solo che invece di una sequenza
## di pagine c'e' un teatro in cui camminare, e le cose succedono quando ci
## arrivi davanti.
##
## [b]Come funziona:[/b] le componenti delle mappe ([WorldBoss], [StageChest],
## [ShopStall], [EncounterZone], [StoryTrigger]...) chiamano i metodi pubblici
## di questo nodo. Ogni metodo e' una piccola scena che si [code]await[/code]:
## mentre dura, il giocatore e' fermo ([method Player.lock]) e il mondo non
## fa partire altro ([method is_busy]).
class_name WorldDirector extends Node


## Emesso quando la partita finisce (dopo un finale). Serve ai controlli.
signal run_finished(ending_id: StringName)

## Emesso dopo ogni battaglia, con l'esito. Serve ai controlli.
signal battle_finished(enemy_id: StringName, won: bool)

var world: Overworld

var _busy: int = 0
var _looked_at_audience: bool = false


func _ready() -> void:
	world = get_parent() as Overworld


## True mentre una scena del regista e' in corso.
func is_busy() -> bool:
	return _busy > 0


func _begin() -> void:
	_busy += 1
	world.player.lock()


func _end() -> void:
	_busy = maxi(_busy - 1, 0)
	world.player.unlock()
	if _busy == 0:
		world.text_box.close()


## Una pagina di testo nel riquadro. Ritorna l'indice del pulsante scelto.
func say(text: String, buttons: Array = [], speaker: String = "") -> int:
	_begin()
	var index: int = await world.text_box.page(text, buttons, speaker)
	_end()
	return index


## Piu' pagine di fila, senza chiudere il riquadro tra una e l'altra.
func say_all(pages: PackedStringArray, speaker: String = "") -> void:
	_begin()
	for text: String in pages:
		await world.text_box.page(text, [], speaker)
	_end()


#region Zone


## Una mappa e' appena entrata: la prima volta si racconta la zona.
func on_map_entered(map: GameMap) -> void:
	_looked_at_audience = false
	var key: String = "zona/%s" % map.map_id
	if GameState.flag(key):
		return
	GameState.set_flag(key)
	# Aspettiamo un fotogramma: la mappa deve finire di entrare.
	await get_tree().process_frame
	var zone: StoryData.StoryZone = WorldData.zone_for(map.map_id)
	if zone == null:
		return
	if map.map_id == WorldData.START_MAP:
		await _prologue(zone)
	else:
		await say_all(zone.intro)


## Il camerino: la stanza, il numero sul muro, le regole.
func _prologue(zone: StoryData.StoryZone) -> void:
	_begin()
	for text: String in zone.intro:
		await world.text_box.page(text.replace("%d", str(GameState.runs)))
	var pick: int = await world.text_box.page("Prima di uscire, vuoi ripassare come si recita?", ["Spiegami le regole", "Le conosco"])
	if pick == 0:
		for text: String in StoryData.tutorial_pages():
			await world.text_box.page(text)
	await world.text_box.page("Ti alzi. Il camerino e' piccolo: il letto, lo specchio rotto, un baule. La porta, in basso, e' socchiusa.\n\n[i]WASD per muoverti, E per guardare e interagire, I per l'inventario.[/i]")
	_end()


## Qualcosa da guardare da vicino ([InspectPoint]).
func inspect(point: InspectPoint, _player: Node) -> void:
	if is_busy():
		return
	_begin()
	for text: String in point.lines:
		await world.text_box.page(text.replace("%d", str(GameState.runs)))
	if point.heals:
		GameState.heal(-1)
		await world.text_box.page("Chiudi gli occhi un momento. Quando li riapri, la stanza e' la stessa e tu sei di nuovo in forze.\n\n[i]Vita piena.[/i]")
	_end()


## Un abitante del teatro ([WorldNpc]).
func talk_to(npc: WorldNpc, player: Node) -> void:
	if is_busy():
		return
	_begin()
	if npc.dialogue != null:
		DialogueManager.show_dialogue_balloon(npc.dialogue, npc.dialogue_title, [npc, player])
		await DialogueManager.dialogue_ended
	else:
		for text: String in npc.lines:
			await world.text_box.page(text, [], npc.display_name)
	if npc.heals:
		GameState.heal(-1)
		await world.text_box.page("Ti senti di nuovo in forze.\n\n[i]Vita piena.[/i]", [], npc.display_name)
	_end()


## Un punto scritto della mappa ([StoryTrigger]).
func on_story_event(trigger: StoryTrigger) -> void:
	if is_busy():
		return
	match trigger.event:
		&"platea":
			if _looked_at_audience:
				return
			_looked_at_audience = true
			GameState.audience_visits += 1
			var lines: PackedStringArray = StoryData.audience_lines()
			await say(lines[mini(GameState.audience_visits - 1, lines.size() - 1)])
		&"testo":
			await say_all(trigger.lines)
		&"porta_dipinta":
			await _finale_door()
		&"ultima_fila":
			if GameState.flag("finale/porta"):
				await _finale_last_row()
			return
	if trigger.once:
		GameState.set_flag(trigger.flag_key())


#endregion

#region Bauli e negozi


## Un baule: una maschera dei Bauli di Scena, o il contenuto di una cassa.
func open_chest(chest: StageChest, _player: Node) -> void:
	if is_busy():
		return
	if chest.is_open():
		await say("E' vuoto. Qualcuno e' passato prima di te, o eri tu.")
		return
	_begin()
	if chest.kind == "scena":
		await _open_stage_chest(chest)
	else:
		await _open_crate(chest)
	world.save_now()
	_end()


func _open_stage_chest(chest: StageChest) -> void:
	var zone: StoryData.StoryZone = WorldData.zone_for(GameState.map_id)
	var text: String = zone.chest_text if zone != null and zone.chest_text != "" else "Un [b]Baule di Scena[/b]. Dentro, una maschera. Non la scegli tu: e' la prima che la mano trova."
	await world.text_box.page(text, ["Apri il baule"])
	GameState.open_chest(chest.key())
	chest.refresh()

	var available: Array[MaskData] = GameState.missing_chest_masks()
	if available.is_empty():
		GameState.add_money(80)
		await world.text_box.page("Il baule e' vuoto: le maschere dei bauli le hai gia' tutte. In fondo, sotto la fodera, qualche biglietto.\n\n[b]+80 %s[/b]" % WorldData.MONEY_NAME)
		return

	var mask: MaskData = available[randi() % available.size()]
	world.text_box.show_picture(_mask_card(mask, Vector2(220, 308)))
	await world.text_box.page(StoryWords.describe_mask(mask, "La mano trova [b]%s[/b]." % mask.display_name), ["Indossala"])
	GameState.gain_mask(mask.id)
	GameState.wear(mask.id)
	world.text_box.clear_picture()
	await world.text_box.page("Ti sta. Non e' tua, ma ti sta: e' il modo in cui esisti qui.\n\n[i]Con le comparse reciti con la maschera che indossi. Puoi cambiarla dall'inventario (I).[/i]")


func _open_crate(chest: StageChest) -> void:
	GameState.open_chest(chest.key())
	chest.refresh()
	var found: PackedStringArray = []
	if chest.money > 0:
		GameState.add_money(chest.money)
		found.append("[b]%d %s[/b]" % [chest.money, WorldData.MONEY_NAME])
	if chest.item_id != &"" and not WorldData.item(chest.item_id).is_empty():
		GameState.add_item(chest.item_id)
		found.append("[b]%s[/b]" % WorldData.item(chest.item_id)["name"])
	if chest.card_id != &"" and CardLibrary.find_by_id(chest.card_id) != null:
		var card_name: String = CardLibrary.find_by_id(chest.card_id).display_name
		if GameState.can_add_card(chest.card_id):
			GameState.add_card(chest.card_id)
			found.append("la battuta [b]%s[/b], che entra nel tuo repertorio" % card_name)
		else:
			GameState.deck_shelf[chest.card_id] = int(GameState.deck_shelf.get(chest.card_id, 0)) + 1
			found.append("la battuta [b]%s[/b] (messa da parte: nel repertorio non ci sta)" % card_name)
	if found.is_empty():
		await world.text_box.page("Una cassa di attrezzeria. Dentro, solo segatura.")
	else:
		await world.text_box.page("Una cassa di attrezzeria. Dentro trovi " + ", ".join(found) + ".")


## Un negozio ([ShopStall]).
func open_shop(shop: ShopStall, _player: Node) -> void:
	if is_busy():
		return
	_begin()
	var menu: ShopMenu = ShopMenu.new()
	menu.shop_id = shop.shop_id
	world.menu_layer.add_child(menu)
	world.hud.set_shown(false)
	if Overworld.auto_pilot:
		menu.call_deferred("emit_signal", "closed")
	await menu.closed
	menu.queue_free()
	world.hud.set_shown(true)
	var data: Dictionary = WorldData.shop(shop.shop_id)
	await world.text_box.page(str(data.get("farewell", "")), [], str(data.get("keeper", "")))
	world.save_now()
	_end()


## L'inventario (tasto I).
func open_inventory() -> void:
	if is_busy():
		return
	_begin()
	var menu: InventoryMenu = InventoryMenu.new()
	world.menu_layer.add_child(menu)
	if Overworld.auto_pilot:
		menu.call_deferred("emit_signal", "closed")
	await menu.closed
	menu.queue_free()
	_end()


#endregion

#region Boss


## Un boss: ti vede (o gli parli), la presentazione, la scelta della maschera,
## la scena. Se perdi, il teatro ripete la sera: riprovi subito o ti ritiri.
## Se vinci, prendi la sua maschera e sali di gavetta.
func face_boss(boss: WorldBoss, player: Node, spotted: bool) -> void:
	if is_busy():
		return
	var data: StoryData.StoryBoss = GameState.boss(boss.boss_id)
	if data == null:
		return
	_begin()
	var player_node: Node2D = player as Node2D

	if boss.is_defeated():
		boss.face_point(player_node.global_position)
		await world.text_box.page("\"%s\"" % data.quote, [], data.display_name)
		_end()
		return

	if spotted:
		await boss.emote("!")
		var dir: Vector2 = player_node.global_position - boss.global_position
		var stop: Vector2 = player_node.global_position - dir.normalized() * 34.0
		await boss.walk_to(stop)
	boss.face_point(player_node.global_position)
	world.player.face(player_node.global_position.direction_to(boss.global_position))

	var first: bool = not GameState.flag("boss/%s" % data.id)
	GameState.set_flag("boss/%s" % data.id)
	world.text_box.show_picture(_boss_placard(data))
	if first:
		for text: String in data.intro:
			await world.text_box.page(text, [], data.display_name)
	else:
		await world.text_box.page("\"%s\"\n\nLa scena e' ancora sua. Vuoi riprovarci?" % data.quote, [], data.display_name)
	world.text_box.clear_picture()

	while true:
		var won: bool = await battle(data, true, _look_of(boss))
		if won:
			break
		for text: String in data.defeat:
			await world.text_box.page(text, [], data.display_name)
		var pick: int = await world.text_box.page("Il sipario si chiude e si riapre. Stessa scena, stessa sera: nel teatro nulla si perde mai.", ["Riprova", "Ritirati"])
		if pick == 1:
			await _whiteout()
			_end()
			return
		GameState.heal(-1)

	for text: String in data.victory:
		await world.text_box.page(text, [], data.display_name)

	var reward: MaskData = MaskLibrary.find_by_id(data.reward_mask_id)
	if reward != null:
		world.text_box.show_picture(_mask_card(reward, Vector2(220, 308)))
		await world.text_box.page(StoryWords.describe_mask(reward, "Quando batti un boss ne prendi la maschera, e diventi lui.\n\n[b]%s[/b] e' tua." % reward.display_name), ["Prendila"])
		GameState.gain_mask(reward.id)
		world.text_box.clear_picture()

	var money: int = WorldData.boss_money(data.id)
	GameState.add_money(money)
	GameState.defeat_boss(data.id)
	await world.text_box.page("[b]%s.[/b] La compagnia ti riconosce un'anzianita' in piu': a ogni scena avrai piu' pubblico. La vita torna piena.\n\nNel camerino del boss trovi [b]%d %s[/b]." % [
		StoryWords.level_name(GameState.level), money, WorldData.MONEY_NAME,
	])
	var tween: Tween = boss.create_tween()
	tween.tween_property(boss, "position", boss.position + boss.defeated_offset, 0.6)
	await tween.finished
	boss.refresh()
	world.save_now()
	_end()


## Come appare un boss sul palco della battaglia.
func _look_of(character: WorldCharacter) -> Dictionary:
	return {
		"look": character.look, "tint": character.tint,
		"face_style": character.face_style, "face_accent": character.face_accent,
	}


#endregion

#region Le quinte (incontri minori)


## Come appaiono le comparse sul palco della battaglia.
static func extra_look(extra_id: StringName) -> Dictionary:
	match extra_id:
		&"macchia":
			return {"look": "mc", "tint": Color(0.62, 0.42, 0.95), "face_style": "none"}
		&"manichino_prova":
			return {"look": "manichino", "tint": Color(0.95, 0.9, 0.8)}
		&"riflesso":
			return {"look": "mc", "tint": Color(0.7, 0.85, 1.0), "face_style": "mirror", "face_accent": Color(0.7, 0.8, 1.0)}
		&"controfigura":
			return {"look": "mc", "tint": Color(0.3, 0.28, 0.34), "face_style": "empty", "face_accent": Color(0.3, 0.3, 0.35)}
		&"attrezzista":
			return {"look": "mc", "tint": Color(0.85, 0.7, 0.5), "face_style": "half", "face_accent": Color(0.6, 0.5, 0.35)}
	return {"look": "mc"}


## Un incontro nelle quinte: una scena breve con la maschera indossata.
func start_encounter(extra_id: StringName) -> void:
	if is_busy():
		return
	var enemy: StoryData.StoryBoss = WorldData.extra_as_boss(extra_id)
	if enemy == null:
		return
	var data: Dictionary = WorldData.extras()[extra_id]
	_begin()
	world.player.emote_alert()
	var won: bool = await battle(enemy, false, extra_look(extra_id), str(data["line"]))
	if won:
		var money: int = int(data["money"])
		GameState.add_money(money)
		var text: String = "%s esce di scena. [b]+%d %s[/b]." % [enemy.display_name, money, WorldData.MONEY_NAME]
		if randf() < 0.18:
			GameState.add_item(&"te_caldo")
			text += "\nHa lasciato cadere un [b]Te' caldo[/b]."
		await world.text_box.page(text)
	else:
		await _whiteout()
	_end()


## Hai perso e non riprovi: il teatro ripete la sera. Ti ritrovi all'ingresso
## della zona, con la vita piena e qualche biglietto in meno.
func _whiteout() -> void:
	var lost: int = int(float(GameState.money) * WorldData.WHITEOUT_LOSS)
	GameState.add_money(-lost)
	GameState.heal(-1)
	await world.text_box.page("Il sipario cala. Il teatro ripete la sera, come sempre: ti ritrovi all'ingresso della zona.\n\nNella confusione hai perso [b]%d %s[/b]." % [lost, WorldData.MONEY_NAME])
	world.text_box.close()
	await world.change_map(GameState.map_id, &"ingresso")


#endregion

#region Battaglia


## Una scena con le carte: transizione, maschera (solo con i boss), il tavolo
## di [StoryBattle] con il palco al centro, e ritorno al mondo.
## Ritorna true se hai vinto. La vita che ti resta torna nel mondo.
func battle(enemy: StoryData.StoryBoss, is_boss: bool, look: Dictionary, opening: String = "") -> bool:
	_begin()
	if opening != "":
		await world.text_box.page(opening, [], enemy.display_name)
	world.text_box.close()
	await Transition.battle_in(is_boss)
	world.hud.set_shown(false)

	var mask: MaskData = GameState.worn_mask_data()
	if is_boss:
		var picker: MaskPicker = MaskPicker.new()
		picker.auto_pilot = Overworld.auto_pilot
		world.battle_layer.add_child(picker)
		Transition.fade_in(0.25)
		mask = await picker.pick(GameState.owned_masks(), enemy.display_name, mask)
		await Transition.fade_out(0.2)
		picker.queue_free()

	var enemy_mask: MaskData = null
	if enemy.worn_mask_id == &"*tua*":
		enemy_mask = mask
	elif enemy.worn_mask_id != &"":
		enemy_mask = MaskLibrary.find_by_id(enemy.worn_mask_id)

	var deck: DeckData = GameState.build_deck()
	var scene: StoryBattle = StoryBattle.new()
	scene.prepare(deck, enemy.build_deck(deck), mask, enemy_mask, enemy, GameState.level, GameState.balance)
	scene.player_start_health = GameState.hp
	scene.player_start_shield = GameState.next_battle_shield
	GameState.next_battle_shield = 0
	var stage: BattleStage = BattleStage.new()
	stage.enemy_look = look
	scene.stage = stage
	if Overworld.auto_pilot:
		scene.opponent_step_delay = 0.0
		scene.opponent_think_delay = 0.0
	world.battle_layer.add_child(scene)
	scene.begin()
	stage.attach(scene.state)
	await Transition.fade_in(0.35)

	if Overworld.auto_pilot:
		_auto_play(scene)
	var won: bool = await scene.finished
	var health: int = scene.player_health()

	await Transition.fade_out(0.3)
	scene.queue_free()
	world.hud.set_shown(true)
	GameState.set_hp(health if won else 1)
	battle_finished.emit(enemy.id, won)
	await Transition.fade_in(0.35)
	_end()
	return won


## Con [member Overworld.auto_pilot] un'IA gioca al posto tuo.
func _auto_play(scene: StoryBattle) -> void:
	var player_ai: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	player_ai.risk_tolerance = 0.35
	var safety: int = 2000
	while safety > 0 and is_instance_valid(scene) and not scene._ended:
		safety -= 1
		scene.autoplay_my_turn(player_ai)
		await get_tree().process_frame
	if is_instance_valid(scene) and scene._ended:
		scene._on_result_pressed()


#endregion

#region Il finale


## Davanti alla porta EXIT: e' dipinta. L'uscita e' dietro il pubblico.
func _finale_door() -> void:
	if GameState.flag("finale/porta"):
		await say("La porta dipinta. Tela, e nient'altro. L'uscita e' dall'altra parte: in fondo alla platea.")
		return
	var pages: PackedStringArray = StoryData.finale_pages()
	_begin()
	await world.text_box.page(pages[0])
	await world.text_box.page(pages[1])
	await world.text_box.page(pages[2], ["Attraversa la platea"])
	GameState.set_flag("finale/porta")
	_end()


## L'ultima fila: i manichini si girano, la rivelazione, la scelta.
func _finale_last_row() -> void:
	var pages: PackedStringArray = StoryData.finale_pages()
	_begin()
	await world.text_box.page(pages[3])
	for node: Node in get_tree().get_nodes_in_group(&"world_audience"):
		(node as WorldAudience).turn_all(world.player.global_position)
	world.text_box.close()
	if not Overworld.auto_pilot:
		await get_tree().create_timer(1.4).timeout
	await world.text_box.page(pages[4])
	await world.text_box.page(pages[5])
	await world.text_box.page(pages[6], ["Decidi"])

	var endings: Array[Dictionary] = StoryData.endings()
	var labels: Array = []
	var summary: PackedStringArray = ["[b]Tre modi di finire. Nessuno e' quello giusto.[/b]", ""]
	for ending: Dictionary in endings:
		labels.append(ending["label"])
		summary.append("[b]%s[/b]: %s" % [ending["label"], ending["choice"]])
	var pick: int = await world.text_box.page("\n".join(summary), labels)
	var ending: Dictionary = endings[clampi(pick, 0, endings.size() - 1)]
	for text: String in ending["pages"]:
		await world.text_box.page(text)

	StorySave.remember_ending(ending["id"])
	# La storia e' finita: il salvataggio non ha piu' niente da riprendere.
	SaveGame.erase()
	GameState.started = false
	await world.text_box.page("[b]FUORI COPIONE[/b]\n\n[i]Non hai un volto. Hai un repertorio.[/i]", ["Sipario"])
	_end()
	run_finished.emit(ending["id"])
	world.go_to_menu()


#endregion

#region Immagini


func _mask_card(mask: MaskData, card_size: Vector2) -> Control:
	var card: MaskCard = MaskCard.new()
	card.mask = mask
	card.card_size = card_size
	card.custom_minimum_size = card_size
	return card


## Il cartello di un boss: chi e', cosa porta, come combatte.
func _boss_placard(boss: StoryData.StoryBoss) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	panel.custom_minimum_size = Vector2(760, 0)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var ink: Color = Settings.color("ink")
	var title: Label = Label.new()
	title.text = "%s. %s" % [boss.numeral, boss.display_name.to_upper()]
	title.add_theme_font_size_override("font_size", Settings.font_size(40))
	title.add_theme_color_override("font_color", ink)
	column.add_child(title)
	for row: Array in [["", "\"%s\"" % boss.quote], ["Porta", boss.wears], ["Come recita", boss.mechanic]]:
		var label: RichTextLabel = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.add_theme_color_override("default_color", ink)
		for kind: String in ["normal", "bold", "italics"]:
			label.add_theme_font_size_override(kind + "_font_size", Settings.font_size(22))
		label.text = "[i]%s[/i]" % row[1] if str(row[0]).is_empty() else "[b]%s:[/b] %s" % [row[0], row[1]]
		column.add_child(label)
	return panel


#endregion
