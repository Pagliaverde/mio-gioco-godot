## Il regista della storia: dal camerino alla porta in fondo alla platea.
##
## E' [b]Fuori Copione[/b], la storia di [code]Docs/TRAMA_E_MASCHERE.md[/code]:
## ti svegli in una stanza senza volto, attraversi un teatro che e' tutto il
## mondo, batti cinque attori che hanno provato a uscire prima di te, e alla
## fine scegli come finire.
##
## [b]Com'e' fatto:[/b] una sequenza di [i]pagine[/i] ([method _page]) con dei
## pulsanti sotto. Il regista aspetta ([code]await[/code]) la scelta e va
## avanti. Le battaglie sono [StoryBattle]; i contenuti sono in [StoryData].
##
## [b]Salvataggio:[/b] il regista e' iscritto al gruppo [code]save_state[/code]
## di [SaveGame]: "Salva" nel menu di pausa e "Riprendi" nel menu principale
## funzionano come nel resto del gioco. Si riparte dall'inizio della zona
## salvata. Il numero sul muro e i finali visti stanno in [StorySave].
##
## [b]Tutto in codice:[/b] come il menu, niente nodi da sistemare a mano.
## [code]Story/story.tscn[/code] contiene solo questo script.
class_name StoryDirector extends Control


## Se true la storia si gioca da sola (serve ai controlli senza finestra):
## sceglie sempre il primo pulsante e fa giocare un'IA al posto tuo.
static var auto_pilot: bool = false

## Emesso quando la storia e' finita (dopo un finale) o quando il giocatore
## torna al menu. In [member auto_pilot] non cambia scena: emette e basta.
signal run_finished(ending_id: StringName)

## Interno: il giocatore ha premuto un pulsante.
signal _choice_made(index: int)

## Il menu a cui tornare.
const MENU_SCENE := "res://Menu/main_menu.tscn"


## Il nodo che partecipa al salvataggio per conto del regista.
class ProgressNode extends Node:
	func get_save_data() -> Variant:
		var director: StoryDirector = get_parent() as StoryDirector
		return director.get_save_data() if director != null else {}

	func apply_save_data(data: Variant) -> void:
		var director: StoryDirector = get_parent() as StoryDirector
		if director != null:
			director.apply_save_data(data)

## Il mazzo con cui si recita. E' sempre questo: la storia e' sulle maschere.
var _player_deck: DeckData
var _balance: BattleBalance

# --- Progresso ---
var _zones: Array[StoryData.StoryZone] = []
var _zone_index: int = 0
var _level: int = 1
var _owned: Array[StringName] = []
var _audience_visits: int = 0
var _runs: int = 1
var _ending_chosen: StringName = &""

# --- UI ---
var _background: ColorRect
var _zone_title: Label
var _zone_subtitle: Label
var _narration: RichTextLabel
var _narration_panel: PanelContainer
var _side: Control
var _choices: HBoxContainer
var _status_label: Label
var _menu_button: Button
var _battle_holder: Control
var _stage: HBoxContainer
var _reveal_tween: Tween = null
var _audience: TheatreView = null


func _ready() -> void:
	_balance = BattleBalance.create_default()
	_player_deck = CardLibrary.build_starter_deck()
	_zones = StoryData.zones()
	_apply_difficulty()
	_build_ui()

	# Il progresso sta in un nodo figlio iscritto al salvataggio: [SaveGame]
	# raccoglie i discendenti della scena, non la scena stessa. Se stiamo
	# arrivando da "Riprendi", i dati ci vengono consegnati adesso (vedi
	# apply_save_data). Altrimenti e' una partita nuova.
	var progress: ProgressNode = ProgressNode.new()
	progress.name = "Progresso"
	add_child(progress)
	progress.add_to_group(SaveGame.GROUP)
	if not SaveGame.apply_to(progress):
		_runs = StorySave.begin_new_run()

	if auto_pilot:
		_level += 6

	_refresh_status()
	call_deferred("_run")


## Cosa finisce nel salvataggio: la zona, la gavetta, le maschere, quante volte
## hai guardato la platea. Niente della scena in corso: si riparte dalla zona.
func get_save_data() -> Variant:
	var masks: Array = []
	for mask_id: StringName in _owned:
		masks.append(str(mask_id))
	return {
		"zone": _zone_index,
		"level": _level,
		"masks": masks,
		"audience_visits": _audience_visits,
		"runs": _runs,
	}


## Riprende da un salvataggio.
func apply_save_data(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var saved: Dictionary = data
	_zone_index = clampi(int(saved.get("zone", 0)), 0, _zones.size() - 1)
	_level = maxi(int(saved.get("level", 1)), 1)
	_owned = []
	for raw: Variant in saved.get("masks", []):
		var mask_id: StringName = StringName(str(raw))
		if MaskLibrary.find_by_id(mask_id) != null and not _owned.has(mask_id):
			_owned.append(mask_id)
	_audience_visits = maxi(int(saved.get("audience_visits", 0)), 0)
	_runs = maxi(int(saved.get("runs", StorySave.run_count())), 1)


## La difficolta' delle impostazioni sposta la gavetta dei boss di un passo.
func _apply_difficulty() -> void:
	var delta: int = 0
	match Settings.difficulty():
		"easy":
			delta = -1
		"hard":
			delta = 1
	for zone: StoryData.StoryZone in _zones:
		if zone.boss != null:
			zone.boss.level = maxi(zone.boss.level + delta, 1)


#region Interfaccia


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var text: Color = Settings.color("text")

	_background = ColorRect.new()
	_background.color = _zones[0].color
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	# --- Intestazione: la zona ---
	var header: HBoxContainer = HBoxContainer.new()
	column.add_child(header)

	var titles: VBoxContainer = VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)

	_zone_title = Label.new()
	_zone_title.theme_type_variation = &"TitleLabel"
	titles.add_child(_zone_title)

	_zone_subtitle = Label.new()
	_zone_subtitle.theme_type_variation = &"DimLabel"
	titles.add_child(_zone_subtitle)

	_menu_button = Button.new()
	_menu_button.text = "Torna al menu"
	_menu_button.focus_mode = Control.FOCUS_NONE
	_menu_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_menu_button.pressed.connect(_on_menu_pressed)
	header.add_child(_menu_button)

	# --- Il palco: testo a sinistra, immagine a destra ---
	_stage = HBoxContainer.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.alignment = BoxContainer.ALIGNMENT_CENTER
	_stage.add_theme_constant_override("separation", 40)
	column.add_child(_stage)

	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.1
	_stage.add_child(panel)
	_narration_panel = panel

	_narration = RichTextLabel.new()
	_narration.bbcode_enabled = true
	_narration.scroll_active = true
	_narration.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_narration.add_theme_font_size_override("normal_font_size", Settings.font_size(30))
	_narration.add_theme_font_size_override("bold_font_size", Settings.font_size(30))
	_narration.add_theme_font_size_override("italics_font_size", Settings.font_size(30))
	_narration.add_theme_color_override("default_color", text)
	panel.add_child(_narration)

	_side = Control.new()
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_side)

	# --- I pulsanti ---
	_choices = HBoxContainer.new()
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices.add_theme_constant_override("separation", 24)
	column.add_child(_choices)

	# --- La riga di stato ---
	_status_label = Label.new()
	_status_label.theme_type_variation = &"DimLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status_label)

	# --- Dove compare la battaglia ---
	_battle_holder = Control.new()
	_battle_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_battle_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battle_holder.visible = false
	add_child(_battle_holder)


func _refresh_status() -> void:
	var names: PackedStringArray = []
	for mask_id: StringName in _owned:
		var mask: MaskData = MaskLibrary.find_by_id(mask_id)
		if mask != null:
			names.append(mask.display_name)
	var masks_text: String = ", ".join(names) if not names.is_empty() else "nessuna"
	_status_label.text = "%s   ·   Repertorio: %s   ·   Maschere: %s" % [
		StoryWords.level_name(_level), _player_deck.display_name, masks_text,
	]


func _enter_zone(zone: StoryData.StoryZone) -> void:
	_zone_title.text = zone.title
	_zone_subtitle.text = zone.subtitle
	var tween: Tween = create_tween()
	tween.tween_property(_background, "color", zone.color, 0.8 * Settings.motion_scale())
	_clear_side()


## Mostra una pagina di testo con i pulsanti indicati e aspetta la scelta.
## Ritorna l'indice del pulsante premuto.
func _page(text: String, buttons: Array = ["Continua"]) -> int:
	if auto_pilot:
		print("[story] %s | %s" % [_zone_title.text, text.left(60).replace("\n", " ")])
	_show_text(text)
	return await _choose(buttons)


## Mette i pulsanti e aspetta che il giocatore ne prema uno.
func _choose(buttons: Array) -> int:
	for child: Node in _choices.get_children():
		child.queue_free()

	var first: Button = null
	for i: int in buttons.size():
		var button: Button = Button.new()
		button.text = str(buttons[i])
		button.custom_minimum_size = Vector2(260, 64)
		button.pressed.connect(_on_choice_pressed.bind(i))
		_choices.add_child(button)
		if first == null:
			first = button
	if first != null:
		first.call_deferred("grab_focus")

	if auto_pilot:
		call_deferred("_on_choice_pressed", 0)

	var index: int = await _choice_made
	return index


func _on_choice_pressed(index: int) -> void:
	# Se il testo sta ancora comparendo, il primo click lo completa.
	if _reveal_tween != null and _reveal_tween.is_running() and not auto_pilot:
		_reveal_tween.kill()
		_narration.visible_ratio = 1.0
		return
	_choice_made.emit(index)


func _show_text(text: String) -> void:
	if _reveal_tween != null and _reveal_tween.is_running():
		_reveal_tween.kill()
	_narration.text = text
	_narration.visible_ratio = 0.0
	var seconds: float = float(_narration.get_total_character_count()) * 0.018 / Settings.text_speed()
	if Settings.reduce_motion() or auto_pilot:
		seconds = 0.0
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(_narration, "visible_ratio", 1.0, seconds)


## "Torna al menu": salva e torna. (Esc apre il menu di pausa, che fa lo stesso.)
func _on_menu_pressed() -> void:
	_save()
	run_finished.emit(&"")
	if not auto_pilot:
		get_tree().change_scene_to_file(MENU_SCENE)


#endregion

#region La parte destra del palco


func _clear_side() -> void:
	for child: Node in _side.get_children():
		child.queue_free()
	_audience = null
	# Senza niente a destra, il testo prende il centro del palco.
	_side.visible = false
	_narration_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_narration_panel.custom_minimum_size = Vector2(1180, 0)


func _set_side(node: Control) -> void:
	_clear_side()
	_side.visible = true
	_narration_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_narration_panel.custom_minimum_size = Vector2(0, 0)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_side.add_child(node)


## Una carta maschera, grande, al centro della parte destra.
func _show_mask_card(mask: MaskData) -> MaskCard:
	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card: MaskCard = MaskCard.new()
	card.mask = mask
	card.card_size = Vector2(300, 420)
	center.add_child(card)
	_set_side(center)

	# La carta compare dal mazzo: piccola e girata, poi si posa.
	card.scale = Vector2(0.2, 0.2)
	card.rotation = deg_to_rad(-25.0)
	card.modulate.a = 0.0
	var tween: Tween = card.create_tween()
	tween.set_parallel(true)
	var m: float = Settings.motion_scale()
	tween.tween_property(card, "scale", Vector2.ONE, 0.5 * m).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", 0.0, 0.5 * m).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.25 * m)
	return card


## La platea, nella parte destra.
func _show_audience() -> TheatreView:
	var view: TheatreView = TheatreView.new()
	_set_side(view)
	view.set_visits(_audience_visits)
	_audience = view
	return view


## Il cartello di un boss: chi e', cosa porta, come combatte.
func _show_boss_placard(boss: StoryData.StoryBoss) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var ink: Color = Settings.color("ink")
	var title: Label = Label.new()
	title.text = "%s. %s" % [boss.numeral, boss.display_name.to_upper()]
	title.add_theme_font_size_override("font_size", Settings.font_size(40))
	title.add_theme_color_override("font_color", ink)
	column.add_child(title)

	var rows: Array[Array] = [
		["", "\"%s\"" % boss.quote],
		["Chi e'", boss.what],
		["Porta", boss.wears],
		["Come recita", boss.mechanic],
		["La lezione", boss.lesson],
	]
	for row: Array in rows:
		var label: RichTextLabel = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.add_theme_color_override("default_color", ink)
		label.add_theme_font_size_override("normal_font_size", Settings.font_size(22))
		label.add_theme_font_size_override("bold_font_size", Settings.font_size(22))
		label.add_theme_font_size_override("italics_font_size", Settings.font_size(22))
		if str(row[0]).is_empty():
			label.text = "[i]%s[/i]" % row[1]
		else:
			label.text = "[b]%s:[/b] %s" % [row[0], row[1]]
		column.add_child(label)

	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	wrapper.add_child(panel)
	_set_side(wrapper)


#endregion

#region La storia


## Il filo della storia, dall'inizio alla fine.
func _run() -> void:
	if _zone_index == 0:
		await _prologue(_zones[0])
		_zone_index = 1
		_save()

	for i: int in range(_zone_index, _zones.size()):
		_zone_index = i
		_save()
		var zone: StoryData.StoryZone = _zones[i]
		if zone.id == &"fondo":
			await _finale(zone)
			return
		await _play_zone(zone)


## Il camerino: la stanza, il numero sul muro, le regole, il primo baule.
func _prologue(zone: StoryData.StoryZone) -> void:
	_enter_zone(zone)
	for page: String in zone.intro:
		await _page(page.replace("%d", str(_runs)))

	var pick: int = await _page("Prima di uscire, vuoi ripassare come si recita?", ["Spiegami le regole", "Le conosco"])
	if pick == 0:
		for page: String in StoryData.tutorial_pages():
			await _page(page)

	await _open_chest(zone)
	await _page("La porta del camerino e' socchiusa. Dall'altra parte, una luce viola che non viene da nessun sole.", ["Esci dal camerino"])


## Una zona: l'ingresso, il baule, la platea, il boss.
func _play_zone(zone: StoryData.StoryZone) -> void:
	_enter_zone(zone)
	for page: String in zone.intro:
		await _page(page)

	if zone.has_chest:
		await _open_chest(zone)

	if zone.shows_audience:
		await _look_at_audience()

	if zone.boss != null:
		await _face_boss(zone.boss)


## Un Baule di Scena: una maschera base a caso, tra quelle che non hai.
func _open_chest(zone: StoryData.StoryZone) -> void:
	await _page(zone.chest_text, ["Apri il baule"])

	var available: Array[MaskData] = []
	for mask: MaskData in MaskLibrary.chest_masks():
		if not _owned.has(mask.id):
			available.append(mask)

	if available.is_empty():
		await _page("Il baule e' vuoto. Qualcuno e' passato prima di te, o eri tu.")
		return

	var mask: MaskData = available[randi() % available.size()]
	_show_mask_card(mask)
	await _page(_describe_mask(mask, "La mano trova [b]%s[/b]." % mask.display_name), ["Indossala"])
	_gain_mask(mask.id)
	await _page("Ti sta. Non e' tua, ma ti sta: e' il modo in cui esisti qui.")
	_clear_side()


## Guardi la platea. Un manichino e' in un posto diverso ogni volta.
func _look_at_audience() -> void:
	_audience_visits += 1
	_show_audience()
	var lines: PackedStringArray = StoryData.audience_lines()
	var line: String = lines[mini(_audience_visits - 1, lines.size() - 1)]
	await _page(line)
	_clear_side()


## Un boss: la presentazione, la scelta della maschera, la scena. Finche'
## non vinci, il teatro ripete la sera.
func _face_boss(boss: StoryData.StoryBoss) -> void:
	_show_boss_placard(boss)
	for page: String in boss.intro:
		await _page(page)

	while true:
		var mask: MaskData = await _pick_mask(boss)
		var won: bool = await _battle(boss, mask)
		if won:
			break
		_show_boss_placard(boss)
		for page: String in boss.defeat:
			await _page(page)
		await _page("Il sipario si chiude e si riapre. Stessa scena, stessa sera: nel teatro nulla si perde mai.", ["Riprova"])

	_clear_side()
	for page: String in boss.victory:
		await _page(page)

	var reward: MaskData = MaskLibrary.find_by_id(boss.reward_mask_id)
	if reward != null:
		_show_mask_card(reward)
		await _page(_describe_mask(reward, "Quando batti un boss ne prendi la maschera, e diventi lui.\n\n[b]%s[/b] e' tua." % reward.display_name), ["Prendila"])
		_gain_mask(reward.id)

	_level += 1
	_refresh_status()
	_save()
	await _page("[b]%s.[/b] La compagnia ti riconosce un'anzianita' in piu': a ogni scena avrai piu' pubblico." % StoryWords.level_name(_level))
	_clear_side()


## La maschera per questa scena: una tra quelle che hai, o nessuna.
func _pick_mask(boss: StoryData.StoryBoss) -> MaskData:
	var options: Array[MaskData] = [null]
	for mask_id: StringName in _owned:
		var mask: MaskData = MaskLibrary.find_by_id(mask_id)
		if mask != null:
			options.append(mask)

	# A destra: la maschera scelta, grande, e sotto tutte le altre, piccole.
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	_set_side(column)

	var big_slot: CenterContainer = CenterContainer.new()
	column.add_child(big_slot)

	var flow: HFlowContainer = HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	column.add_child(flow)

	var cards: Array[MaskCard] = []
	var selected: int = options.size() - 1 if options.size() > 1 else 0
	for i: int in options.size():
		var card: MaskCard = MaskCard.new()
		card.mask = options[i]
		card.card_size = Vector2(136, 190)
		card.title_font_size = 15
		card.pressed.connect(_on_mask_card_pressed.bind(i))
		flow.add_child(card)
		cards.append(card)

	# La scelta: cliccare una carta la seleziona, "Recita" conferma.
	var big_card: MaskCard = null
	while true:
		for i: int in cards.size():
			cards[i].selected = i == selected
		if big_card != null:
			big_card.queue_free()
		big_card = MaskCard.new()
		big_card.mask = options[selected]
		big_card.card_size = Vector2(230, 322)
		big_card.pressed.connect(_on_mask_card_pressed.bind(selected))
		big_slot.add_child(big_card)
		var chosen: MaskData = options[selected]
		var text: String
		if chosen == null:
			text = "[b]A volto scoperto.[/b]\n\nNessuna regola, nessuna affinita': valgono le regole normali e tutte le sinergie.\n\nScegli una maschera, o recita cosi'."
		else:
			text = _describe_mask(chosen, "Per la scena con %s indossi [b]%s[/b]." % [boss.display_name, chosen.display_name])
		_show_text(text)

		var pick: int = await _choose(["Recita", "Maschera dopo", "Maschera prima"])
		if pick == 0:
			break
		if pick == 1:
			selected = posmod(selected + 1, options.size())
		elif pick == 2:
			selected = posmod(selected - 1, options.size())
		elif pick >= 100:
			selected = pick - 100

	_clear_side()
	return options[selected]


func _on_mask_card_pressed(_card: MaskCard, index: int) -> void:
	# Un click sulla carta: la selezione cambia (indice spostato di 100, cosi'
	# non si confonde con i pulsanti).
	_choice_made.emit(100 + index)


## Una scena contro un boss. Ritorna true se hai vinto.
func _battle(boss: StoryData.StoryBoss, mask: MaskData) -> bool:
	var enemy_mask: MaskData = null
	if boss.worn_mask_id == &"*tua*":
		enemy_mask = mask
	elif boss.worn_mask_id != &"":
		enemy_mask = MaskLibrary.find_by_id(boss.worn_mask_id)

	var battle: StoryBattle = StoryBattle.new()
	battle.prepare(_player_deck, boss.build_deck(_player_deck), mask, enemy_mask, boss, _level, _balance)
	if auto_pilot:
		battle.opponent_step_delay = 0.0
		battle.opponent_think_delay = 0.0
	_battle_holder.add_child(battle)
	_battle_holder.visible = true
	_stage.visible = false
	_choices.visible = false
	battle.begin()

	if auto_pilot:
		_auto_play(battle)

	var won: bool = await battle.finished

	battle.queue_free()
	_battle_holder.visible = false
	_stage.visible = true
	_choices.visible = true
	return won


## In [member auto_pilot] un'IA gioca al posto tuo, un turno per frame.
func _auto_play(battle: StoryBattle) -> void:
	var player_ai: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	player_ai.risk_tolerance = 0.35
	var safety: int = 2000
	while safety > 0 and is_instance_valid(battle) and not battle._ended:
		safety -= 1
		battle.autoplay_my_turn(player_ai)
		await get_tree().process_frame
	if is_instance_valid(battle) and battle._ended:
		battle._on_result_pressed()


## L'ultimo atto: la porta dipinta, la platea, i manichini che si girano,
## la rivelazione, e la scelta.
func _finale(zone: StoryData.StoryZone) -> void:
	_enter_zone(zone)
	var pages: PackedStringArray = StoryData.finale_pages()

	await _page(pages[0])
	await _page(pages[1])
	var view: TheatreView = _show_audience()
	await _page(pages[2], ["Attraversa la platea"])
	await _page(pages[3])
	view.turn_all()
	await _page(pages[4])
	await _page(pages[5])
	await _page(pages[6], ["Decidi"])

	var endings: Array[Dictionary] = StoryData.endings()
	var labels: Array = []
	var summary: PackedStringArray = ["[b]Tre modi di finire. Nessuno e' quello giusto.[/b]", ""]
	for ending: Dictionary in endings:
		labels.append(ending["label"])
		summary.append("[b]%s[/b]: %s" % [ending["label"], ending["choice"]])
	var pick: int = await _page("\n".join(summary), labels)
	var ending: Dictionary = endings[clampi(pick, 0, endings.size() - 1)]
	_ending_chosen = ending["id"]

	_clear_side()
	for page: String in ending["pages"]:
		await _page(page)

	StorySave.remember_ending(_ending_chosen)
	# La storia e' finita: il salvataggio non ha piu' niente da riprendere.
	SaveGame.erase()
	await _page("[b]FUORI COPIONE[/b]\n\n[i]Non hai un volto. Hai un repertorio.[/i]", ["Sipario"])

	run_finished.emit(_ending_chosen)
	if not auto_pilot:
		get_tree().change_scene_to_file(MENU_SCENE)


#endregion

#region Utility


func _gain_mask(mask_id: StringName) -> void:
	if not _owned.has(mask_id):
		_owned.append(mask_id)
	_refresh_status()
	_save()


func _describe_mask(mask: MaskData, lead: String) -> String:
	var lines: PackedStringArray = [lead, ""]
	if not mask.quote.is_empty():
		lines.append("[i]\"%s\"[/i]" % mask.quote)
		lines.append("")
	lines.append("[b]Affinita':[/b] %s" % mask.affinity_text())
	lines.append("[b]Regola dell'azzardo:[/b] %s. %s" % [CardTypes.mask_gambit_name(mask.gambit), mask.description])
	lines.append("[b]Il prezzo:[/b] %s" % mask.drawback)
	return "\n".join(lines)


## Salva da solo, come farebbe "Salva" nel menu di pausa.
func _save() -> void:
	if is_inside_tree():
		SaveGame.save_now(get_tree())


#endregion
