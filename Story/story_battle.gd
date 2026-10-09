## Una scena della storia: il tavolo di battaglia contro un boss.
##
## E' lo stesso motore di [code]Cards/table[/code] ([BattleState] + [SimAI]),
## con tre cose in piu': le [b]maschere[/b] (tue e sue), i tratti del boss
## (gabbia, vita, danno) e le [b]parole del teatro[/b] (Pubblico, Favore,
## Fuori copione) al posto di mana, scudo e bust.
##
## [b]Come si usa:[/b] chiama [method prepare] prima di aggiungerlo all'albero,
## poi [method begin]. Quando la scena finisce emette [signal finished].
##
## [b]Tasti:[/b] [code]Spazio[/code] = pesca, [code]S[/code] = stop.
class_name StoryBattle extends Control


## Emesso quando la battaglia e' conclusa e il giocatore ha premuto "Continua".
signal finished(won: bool)


## Secondi tra una mossa e l'altra del boss.
@export_range(0.0, 2.0, 0.05) var opponent_step_delay: float = 0.5

## Secondi prima che il boss cominci il suo turno.
@export_range(0.0, 3.0, 0.05) var opponent_think_delay: float = 0.7

## Righe massime di log tenute a schermo.
@export_range(20, 500, 10) var max_log_lines: int = 160

## Vita con cui cominci la scena. Negativo = piena.
##
## Serve al mondo esplorabile: la vita resta tra una scena e l'altra, come in
## un gioco di ruolo. Il motore non cambia: la vita viene ritoccata dopo
## [method BattleState.start], come fanno i tratti dei boss.
var player_start_health: int = -1

## Favore (scudo) con cui cominci la scena: lo danno gli oggetti del negozio.
var player_start_shield: int = 0

## Il nome con cui compari nel tavolo.
var player_display_name: String = "Tu"

## Un palco da mostrare al centro, accanto al log (il mondo esplorabile ci
## mette i due personaggi sotto i riflettori). Va impostato prima di
## aggiungere il nodo all'albero; null = niente palco, come nella storia.
var stage: Control = null


# --- Configurazione (da prepare) ---
var _player_deck: DeckData
var _enemy_deck: DeckData
var _player_mask: MaskData
var _enemy_mask: MaskData
var _boss: StoryData.StoryBoss
var _player_level: int = 1
var _balance: BattleBalance
var _battle_seed: int = 0

# --- Motore ---
var state: BattleState
var ai: SimAI
var _busy: bool = false
var _ended: bool = false
var _log_lines: PackedStringArray = []

# --- UI ---
var _background: ColorRect
var _enemy_name: Label
var _enemy_mask_label: Label
var _enemy_health: ProgressBar
var _enemy_health_text: Label
var _enemy_stats: Label
var _enemy_statuses: HBoxContainer
var _enemy_played: HFlowContainer
var _enemy_panel: PanelContainer

var _player_name: Label
var _player_mask_label: Label
var _player_health: ProgressBar
var _player_health_text: Label
var _player_stats: Label
var _player_statuses: HBoxContainer
var _player_played: HFlowContainer
var _player_panel: PanelContainer

var _turn_label: Label
var _risk_label: Label
var _hint_label: Label
var _peek_box: VBoxContainer
var _peek_view: CardView
var _draw_button: Button
var _stop_button: Button
var _log_label: RichTextLabel
var _log_scroll: ScrollContainer

var _result_layer: Control
var _result_title: Label
var _result_text: Label
var _result_button: Button


## Prepara la scena. Chiamala prima di aggiungere il nodo all'albero.
func prepare(
	player_deck: DeckData,
	enemy_deck: DeckData,
	player_mask: MaskData,
	enemy_mask: MaskData,
	boss: StoryData.StoryBoss,
	player_level: int,
	balance: BattleBalance = null,
	battle_seed: int = 0
) -> void:
	_player_deck = player_deck
	_enemy_deck = enemy_deck
	_player_mask = player_mask
	_enemy_mask = enemy_mask
	_boss = boss
	_player_level = maxi(player_level, 1)
	_balance = balance if balance != null else BattleBalance.create_default()
	_battle_seed = battle_seed


func _ready() -> void:
	_build_ui()


## Fa partire la battaglia.
func begin() -> void:
	ai = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	ai.risk_tolerance = _boss.risk_tolerance if _boss != null else 0.4
	ai.lethal_risk_tolerance = 0.70

	var enemy_name: String = _boss.display_name if _boss != null else "Avversario"
	var enemy_level: int = _boss.level if _boss != null else 1

	state = BattleState.new()
	state.setup(_balance, _player_deck, _enemy_deck, CardLibrary.build_synergies(),
		_battle_seed, player_display_name, enemy_name, _player_level, enemy_level)
	state.set_masks(_player_mask, _enemy_mask)

	if _boss != null:
		state.player_b.cage_strength = _boss.cage
		state.player_b.damage_scale = _boss.damage_scale
		state.player_b.max_health = int(round(float(_balance.starting_health) * _boss.health_scale))

	state.message.connect(_on_message)
	state.card_played.connect(_on_card_played)
	state.busted.connect(_on_busted)
	state.forgiven.connect(_on_forgiven)
	state.turn_started.connect(_on_turn_started)
	state.turn_resolved.connect(_on_turn_resolved)

	_busy = false
	_ended = false
	_log_lines.clear()
	_clear_cards(_player_played)
	_clear_cards(_enemy_played)
	_result_layer.visible = false

	state.start()
	if player_start_health > 0:
		state.player_a.health = clampi(player_start_health, 1, state.player_a.max_health)
	if player_start_shield > 0:
		state.player_a.add_shield(player_start_shield)
	_refresh()


## La vita che ti resta (alla fine della scena e' quella da riportare nel mondo).
func player_health() -> int:
	return state.player_a.health if state != null else 0


## Fa giocare il turno del giocatore a un'IA (serve ai test senza finestra).
func autoplay_my_turn(player_ai: SimAI) -> void:
	var safety: int = 500
	while safety > 0 and _can_play():
		safety -= 1
		if player_ai.should_continue(state):
			state.draw_and_play()
		else:
			state.stop_turn()
	_after_my_turn()


#region Interfaccia


func _build_ui() -> void:
	# Siamo gia' nell'albero: servono anche gli offset, non solo gli anchor,
	# altrimenti il nodo resta della dimensione che aveva (zero).
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var text: Color = Settings.color("text")
	var accent: Color = Settings.color("accent")

	_background = ColorRect.new()
	_background.color = Color("17111f")
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	# --- Riga in alto: turno ---
	_turn_label = Label.new()
	_turn_label.theme_type_variation = &"SectionLabel"
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_turn_label)

	# --- Il boss ---
	var enemy: Dictionary = _build_fighter_panel(Color("3a1d26"))
	_enemy_panel = enemy["panel"]
	_enemy_name = enemy["name"]
	_enemy_mask_label = enemy["mask"]
	_enemy_health = enemy["health"]
	_enemy_health_text = enemy["health_text"]
	_enemy_stats = enemy["stats"]
	_enemy_statuses = enemy["statuses"]
	_enemy_played = enemy["played"]
	column.add_child(_enemy_panel)

	# --- Il centro: log a sinistra, decisioni a destra ---
	var middle: HBoxContainer = HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 18)
	column.add_child(middle)

	if stage != null:
		stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stage.size_flags_stretch_ratio = 1.5
		middle.add_child(stage)

	var log_panel: PanelContainer = PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_panel.size_flags_stretch_ratio = 1.6 if stage == null else 1.0
	middle.add_child(log_panel)

	_log_scroll = ScrollContainer.new()
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_panel.add_child(_log_scroll)

	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.fit_content = true
	_log_label.scroll_active = false
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.add_theme_font_size_override("normal_font_size", Settings.font_size(19))
	_log_label.add_theme_font_size_override("bold_font_size", Settings.font_size(19))
	_log_scroll.add_child(_log_label)

	var side: VBoxContainer = VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 10)
	middle.add_child(side)

	_risk_label = Label.new()
	_risk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_risk_label.add_theme_font_size_override("font_size", Settings.font_size(24))
	side.add_child(_risk_label)

	_hint_label = Label.new()
	_hint_label.theme_type_variation = &"DimLabel"
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.text = "Spazio: pesca una battuta.  S: fermati, il pubblico non speso diventa Favore."
	side.add_child(_hint_label)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	side.add_child(buttons)

	_draw_button = Button.new()
	_draw_button.text = "PESCA"
	_draw_button.focus_mode = Control.FOCUS_NONE
	_draw_button.custom_minimum_size = Vector2(200, 64)
	_draw_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_draw_button.pressed.connect(_on_draw_pressed)
	buttons.add_child(_draw_button)

	_stop_button = Button.new()
	_stop_button.text = "STOP"
	_stop_button.focus_mode = Control.FOCUS_NONE
	_stop_button.custom_minimum_size = Vector2(200, 64)
	_stop_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stop_button.pressed.connect(_on_stop_pressed)
	buttons.add_child(_stop_button)

	# Il Presagio: la prossima carta, quando la maschera la mostra.
	_peek_box = VBoxContainer.new()
	_peek_box.add_theme_constant_override("separation", 6)
	_peek_box.visible = false
	side.add_child(_peek_box)

	var peek_title: Label = Label.new()
	peek_title.theme_type_variation = &"SectionLabel"
	peek_title.text = "Presagio: la prossima battuta"
	_peek_box.add_child(peek_title)

	_peek_view = CardView.new()
	_peek_view.card_width = 170
	_peek_view.card_height = 230
	_peek_view.art_height = 84
	_peek_box.add_child(_peek_view)

	# --- Tu ---
	var player: Dictionary = _build_fighter_panel(Color("1c2a3a"))
	_player_panel = player["panel"]
	_player_name = player["name"]
	_player_mask_label = player["mask"]
	_player_health = player["health"]
	_player_health_text = player["health_text"]
	_player_stats = player["stats"]
	_player_statuses = player["statuses"]
	_player_played = player["played"]
	column.add_child(_player_panel)

	# --- Esito ---
	_result_layer = Control.new()
	_result_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_layer.visible = false
	add_child(_result_layer)

	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0, 0, 0, 0.72)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_layer.add_child(veil)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_layer.add_child(center)

	var result_panel: PanelContainer = PanelContainer.new()
	result_panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(result_panel)

	var result_column: VBoxContainer = VBoxContainer.new()
	result_column.add_theme_constant_override("separation", 18)
	result_panel.add_child(result_column)

	_result_title = Label.new()
	_result_title.theme_type_variation = &"TitleLabel"
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_column.add_child(_result_title)

	_result_text = Label.new()
	_result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_column.add_child(_result_text)

	_result_button = Button.new()
	_result_button.text = "Continua"
	_result_button.custom_minimum_size = Vector2(240, 60)
	_result_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_result_button.pressed.connect(_on_result_pressed)
	result_column.add_child(_result_button)

	_turn_label.add_theme_color_override("font_color", accent)
	_risk_label.add_theme_color_override("font_color", text)


## Il pannello di un combattente: nome, maschera, vita, pubblico e favore,
## status, e le carte che ha schierato.
func _build_fighter_panel(tint: Color) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = tint
	style.border_color = tint.lightened(0.35)
	style.set_border_width_all(UiThemeBuilder.BORDER)
	style.anti_aliasing = false
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(0, 250)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)

	var info: VBoxContainer = VBoxContainer.new()
	info.custom_minimum_size = Vector2(360, 0)
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)

	var name_label: Label = Label.new()
	name_label.theme_type_variation = &"SectionLabel"
	info.add_child(name_label)

	var mask_label: Label = Label.new()
	mask_label.theme_type_variation = &"DimLabel"
	mask_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(mask_label)

	var health: ProgressBar = ProgressBar.new()
	health.min_value = 0
	health.show_percentage = false
	health.custom_minimum_size = Vector2(0, 26)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color("b8384a")
	fill.anti_aliasing = false
	health.add_theme_stylebox_override("fill", fill)
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.5)
	track.anti_aliasing = false
	health.add_theme_stylebox_override("background", track)
	info.add_child(health)

	var health_text: Label = Label.new()
	info.add_child(health_text)

	var stats: Label = Label.new()
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(stats)

	var statuses: HBoxContainer = HBoxContainer.new()
	statuses.add_theme_constant_override("separation", 12)
	info.add_child(statuses)

	var played: HFlowContainer = HFlowContainer.new()
	played.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	played.add_theme_constant_override("h_separation", 8)
	played.add_theme_constant_override("v_separation", 8)
	row.add_child(played)

	return {
		"panel": panel, "name": name_label, "mask": mask_label, "health": health,
		"health_text": health_text, "stats": stats, "statuses": statuses, "played": played,
	}


#endregion

#region Azioni


func _can_play() -> bool:
	if state == null or state.is_finished() or _busy or _ended:
		return false
	if state.phase != CardTypes.Phase.AWAITING_ACTION:
		return false
	return state.active == state.player_a


func _on_draw_pressed() -> void:
	if not _can_play():
		return
	var result: CardTypes.TurnResult = state.draw_and_play()
	if result == CardTypes.TurnResult.PLAYING:
		_refresh()
	else:
		_after_my_turn()


func _on_stop_pressed() -> void:
	if not _can_play():
		return
	state.stop_turn()
	_after_my_turn()


func _after_my_turn() -> void:
	if state.is_finished():
		_finish()
		return
	_run_opponent_turn()


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if _result_layer.visible:
		if key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_on_result_pressed()
			get_viewport().set_input_as_handled()
		return
	match key_event.keycode:
		KEY_SPACE:
			_on_draw_pressed()
			get_viewport().set_input_as_handled()
		KEY_S:
			_on_stop_pressed()
			get_viewport().set_input_as_handled()


## Il turno del boss, con le pause: cosi' si vede, invece di subirlo.
func _run_opponent_turn() -> void:
	_busy = true
	_refresh()

	if opponent_think_delay > 0.0 and is_inside_tree():
		await get_tree().create_timer(opponent_think_delay).timeout

	var safety: int = 500
	while safety > 0:
		safety -= 1
		if state.is_finished() or state.phase != CardTypes.Phase.AWAITING_ACTION or state.active != state.player_b:
			break

		if not ai.should_continue(state):
			_add_line("  %s: %s." % [state.player_b.display_name, StoryWords.translate(ai.explain_decision(state))])
			state.stop_turn()
			break

		state.draw_and_play()
		_refresh()

		if state.is_finished() or state.phase != CardTypes.Phase.AWAITING_ACTION or state.active != state.player_b:
			break
		if opponent_step_delay > 0.0 and is_inside_tree():
			await get_tree().create_timer(opponent_step_delay).timeout

	_busy = false
	_refresh()
	if state.is_finished():
		_finish()


func _finish() -> void:
	if _ended:
		return
	_ended = true
	_refresh()

	var won: bool = state.winner == state.player_a
	if state.is_draw:
		_result_title.text = "SIPARIO"
		_result_text.text = "Nessuno dei due e' rimasto in piedi. Il teatro ripete la scena."
	elif won:
		_result_title.text = "LA SCENA E' TUA"
		_result_text.text = "Il pubblico non reagisce. Non ha mai reagito."
	else:
		_result_title.text = "FUORI COPIONE"
		_result_text.text = "La scena crolla. Ma il teatro non finisce: si ricomincia, sera dopo sera."
	_result_layer.visible = true
	_result_button.grab_focus()


func _on_result_pressed() -> void:
	if not _ended:
		return
	finished.emit(state.winner == state.player_a)


#endregion

#region Segnali del motore


func _on_message(text: String) -> void:
	_add_line(StoryWords.translate(text))


func _on_card_played(instance: CardInstance) -> void:
	var target: Container = _player_played if state.active == state.player_a else _enemy_played
	_add_card(target, instance, Color.WHITE)


func _on_busted(instance: CardInstance) -> void:
	var target: Container = _player_played if state.active == state.player_a else _enemy_played
	_add_card(target, instance, Color(1.0, 0.45, 0.42))


func _on_forgiven(instance: CardInstance) -> void:
	var target: Container = _player_played if state.active == state.player_a else _enemy_played
	var view: CardView = _add_card(target, instance, Color(0.75, 0.9, 1.0, 0.6))
	# La carta perdonata resta un attimo e poi sparisce: non e' stata giocata.
	if is_inside_tree():
		var tween: Tween = view.create_tween()
		tween.tween_property(view, "modulate:a", 0.0, 1.2)
		tween.tween_callback(view.queue_free)


func _on_turn_started(_report: Dictionary) -> void:
	_clear_cards(_player_played if state.active == state.player_a else _enemy_played)


func _on_turn_resolved(_report: Dictionary) -> void:
	_push_log()


#endregion

#region Aggiornamento


func _refresh() -> void:
	if state == null:
		return

	if state.is_finished():
		_turn_label.text = "Sipario"
	else:
		_turn_label.text = "Scena %d  ·  %s" % [
			state.turn_number,
			"tocca a te" if state.active == state.player_a else "recita %s" % state.player_b.display_name,
		]

	_refresh_fighter(state.player_a, _player_panel, _player_name, _player_mask_label, _player_health,
		_player_health_text, _player_stats, _player_statuses, false)
	_refresh_fighter(state.player_b, _enemy_panel, _enemy_name, _enemy_mask_label, _enemy_health,
		_enemy_health_text, _enemy_stats, _enemy_statuses, true)

	_refresh_risk()
	_refresh_peek()

	var can_play: bool = _can_play()
	_draw_button.disabled = not can_play
	_stop_button.disabled = not can_play
	_push_log()


func _refresh_fighter(
	player: BattlePlayer, panel: Control, name_label: Label, mask_label: Label,
	health: ProgressBar, health_text: Label, stats: Label, statuses: HBoxContainer, is_enemy: bool
) -> void:
	panel.modulate = Color(1, 1, 1) if state.active == player else Color(0.78, 0.78, 0.84)
	name_label.text = player.display_name

	if player.mask != null:
		mask_label.text = "Indossa %s: %s" % [player.mask.display_name, CardTypes.mask_gambit_name(player.mask.gambit)]
	else:
		mask_label.text = "A volto scoperto"

	health.max_value = maxi(player.max_health, 1)
	health.value = player.health
	health_text.text = "Vita %d / %d" % [player.health, player.max_health]

	# L'Inganno: il rivale non vede il tuo pubblico. Qui vale al contrario:
	# se il boss lo indossa, sei tu a non vederlo.
	var hide_mana: bool = is_enemy and player.has_gambit(CardTypes.MaskGambit.DECEIT)
	var mana_text: String = "?" if hide_mana else str(player.mana)
	var parts: PackedStringArray = ["Pubblico %s" % mana_text, "Favore %d" % player.shield]
	if player.forgiveness_left > 0:
		parts.append("Perdono pronto")
	if player.guard_active:
		parts.append("Guardia pronta")
	if player.cage_strength > 0:
		parts.append("Gabbia -%d" % player.cage_strength)
	stats.text = "   ".join(parts)

	for child: Node in statuses.get_children():
		child.queue_free()
	for raw_status: Variant in player.statuses:
		var status: CardTypes.StatusType = raw_status
		var stack: StatusStack = player.statuses[status]
		var chip: Label = Label.new()
		chip.text = "%s %d" % [StoryWords.status_name(status), stack.stacks]
		chip.add_theme_color_override("font_color", _status_color(status))
		statuses.add_child(chip)


func _status_color(status: CardTypes.StatusType) -> Color:
	match status:
		CardTypes.StatusType.BURN:
			return Color(0.95, 0.55, 0.25)
		CardTypes.StatusType.POISON:
			return Color(0.6, 0.85, 0.35)
		CardTypes.StatusType.CHILL:
			return Color(0.5, 0.78, 0.98)
		CardTypes.StatusType.EMPOWER:
			return Color(0.98, 0.85, 0.4)
		CardTypes.StatusType.REGEN:
			return Color(0.5, 0.9, 0.6)
	return Color(0.85, 0.85, 0.9)


func _refresh_risk() -> void:
	if not _can_play():
		_risk_label.text = ""
		return
	var risk: float = ai.bust_probability(state)
	var text: String = "Rischio di andare fuori copione: %d%%" % int(round(risk * 100.0))
	var color: Color = Color(0.92, 0.88, 0.55)
	if is_equal_approx(risk, 0.0):
		text += "\nNessuna battuta ti puo' tradire."
		color = Color(0.55, 0.9, 0.6)
	elif risk >= 1.0:
		text += "\nQualunque battuta ti tradisce: fermati."
		color = Color(0.98, 0.4, 0.35)
	elif risk > 0.5:
		color = Color(0.98, 0.65, 0.35)
	if state.player_a.forgiveness_left > 0:
		text += "\n(il pubblico perdonera' il prossimo passo falso)"
	_risk_label.text = text
	_risk_label.add_theme_color_override("font_color", color)


func _refresh_peek() -> void:
	var next: CardInstance = state.peek_next_card() if _can_play() else null
	if next == null:
		_peek_box.visible = false
		return
	_peek_box.visible = true
	_peek_view.card = next.data


func _push_log() -> void:
	_log_label.text = "\n".join(_log_lines)
	if is_inside_tree():
		await get_tree().process_frame
		if is_instance_valid(_log_scroll):
			_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


func _add_line(text: String) -> void:
	_log_lines.append(_colorize(text))
	if _log_lines.size() > max_log_lines:
		_log_lines.remove_at(0)


func _colorize(line: String) -> String:
	var escaped: String = line.replace("[", "[lb]")
	if line.contains("FUORI COPIONE"):
		return "[color=#ff6b6b]%s[/color]" % escaped
	if line.contains("SINERGIA") or line.contains("✦"):
		return "[color=#ffd166]%s[/color]" % escaped
	if line.contains("SCENA RUBATA") or line.contains("ruba la scena"):
		return "[color=#ff9f43]%s[/color]" % escaped
	if line.begins_with("---"):
		return "[color=#9fb8ff]%s[/color]" % escaped
	if line.begins_with("==="):
		return "[b][color=#9ae66e]%s[/color][/b]" % escaped
	return escaped


func _add_card(target: Container, instance: CardInstance, tint: Color) -> CardView:
	var view: CardView = CardView.new()
	view.card_width = 150
	view.card_height = 205
	view.art_height = 78
	target.add_child(view)
	view.card = instance.data
	view.modulate = tint
	return view


func _clear_cards(container: Container) -> void:
	for child: Node in container.get_children():
		child.queue_free()


#endregion
