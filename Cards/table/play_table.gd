## Tavolo di gioco interattivo: gioca una partita vera contro un'IA.
##
## [b]Nessuna grafica complicata:[/b] solo testo, uno stato e due pulsanti.
## Serve a [i]sentire[/i] il gioco con le mani prima di disegnare una sola carta.
##
## [b]Come si usa:[/b]
## 1. Apri [code]res://Cards/table/play_table.tscn[/code]
## 2. Premi [b]F6[/b]
## 3. Premi [code]PESCA[/code] finche' vuoi rischiare, poi [code]STOP[/code]
##
## [b]Tasti rapidi:[/b] [code]Spazio[/code] = pesca, [code]S[/code] = stop,
## [code]N[/code] = nuova partita.
##
## Le regole sono esattamente quelle del motore: peschi una carta alla volta,
## sei obbligato a giocarla se puoi permettertela, e se non puoi perdi il turno.
##
## [b]Suggerimento:[/b] guarda la riga "Rischio di bust": e' la probabilita'
## esatta di perdere il turno pescando ancora. E' l'informazione che serve per
## decidere, e ti fa capire subito se il bilanciamento funziona.
extends Control


## Il bilanciamento da usare. Lascia vuoto per quello di default.
@export var balance: BattleBalance

## Il tuo mazzo. Vuoto = mazzo Equilibrato.
@export var player_deck: DeckData

## Il mazzo dell'avversario. Vuoto = mazzo Veterano.
@export var opponent_deck: DeckData

## Il seme della partita. 0 = casuale. Metti un numero fisso per rigiocare
## esattamente la stessa partita.
@export var battle_seed: int = 0

## Quante righe di log tenere in memoria.
@export_range(50, 2000, 50) var max_log_lines: int = 300

## Tolleranza al rischio dell'IA avversaria (0-1).
##
## Il simulatore ha misurato che un'IA piu' audace gioca meglio: con 0,25
## vince il 48%, con 0,40 il 58%. Alzando questo valore l'avversario diventa
## piu' concreto e gioca piu' carte per turno.
@export_range(0.0, 1.0, 0.05) var ai_risk_tolerance: float = 0.40

## Se true il log spiega perche' l'avversario ha deciso di fermarsi.
## Utile per capire il gioco, oltre che per il debug.
@export var explain_opponent: bool = true

# --- Riferimenti UI (costruiti in codice, vedi _build_ui) ---
var _status: RichTextLabel
var _log_label: RichTextLabel
var _log_scroll: ScrollContainer
var _draw_button: Button
var _stop_button: Button
var _new_button: Button
var _hint_label: Label

# --- Stato della partita ---
var state: BattleState
var ai: SimAI

var _log_lines: PackedStringArray = []


func _ready() -> void:
	_build_ui()
	_start_new_game()


#region Costruzione interfaccia


## Costruisce tutta la UI in codice.
##
## [b]Perche' in codice e non in una scena?[/b] Perche' cosi' non si puo'
## rompere per un errore di formattazione del file .tscn, e i valori
## modificabili restano tutti in un posto solo (le @export qui sopra).
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background: ColorRect = ColorRect.new()
	background.color = Color(0.07, 0.08, 0.11)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	# --- Barra di stato ---
	_status = RichTextLabel.new()
	_status.bbcode_enabled = true
	_status.fit_content = true
	_status.scroll_active = false
	_status.custom_minimum_size = Vector2(0, 130)
	_status.add_theme_font_size_override("normal_font_size", 22)
	_status.add_theme_font_size_override("bold_font_size", 22)
	column.add_child(_status)

	# --- Riga del suggerimento (rischio di bust) ---
	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.add_theme_color_override("font_color", Color(0.98, 0.83, 0.42))
	column.add_child(_hint_label)

	# --- Log della partita ---
	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_log_scroll)

	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.fit_content = true
	_log_label.scroll_active = false
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.add_theme_font_size_override("normal_font_size", 17)
	_log_label.add_theme_font_size_override("bold_font_size", 17)
	_log_scroll.add_child(_log_label)

	# --- Pulsanti ---
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)

	_draw_button = _make_button("PESCA  (Spazio)", Color(0.30, 0.62, 0.45))
	_draw_button.pressed.connect(_on_draw_pressed)
	buttons.add_child(_draw_button)

	_stop_button = _make_button("STOP  (S)", Color(0.65, 0.42, 0.28))
	_stop_button.pressed.connect(_on_stop_pressed)
	buttons.add_child(_stop_button)

	_new_button = _make_button("Nuova partita  (N)", Color(0.35, 0.38, 0.48))
	_new_button.pressed.connect(_on_new_pressed)
	buttons.add_child(_new_button)


## Crea un pulsante dall'aspetto coerente.
##
## [code]focus_mode = NONE[/code] e' voluto: cosi' i pulsanti non catturano
## Spazio e Invio, che posso gestire io come scorciatoie di gioco.
func _make_button(text: String, color: Color) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(220, 56)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))

	button.add_theme_stylebox_override("normal", _make_style(color))
	button.add_theme_stylebox_override("hover", _make_style(color.lightened(0.18)))
	button.add_theme_stylebox_override("pressed", _make_style(color.darkened(0.2)))
	button.add_theme_stylebox_override("disabled", _make_style(color.darkened(0.55)))
	button.add_theme_stylebox_override("focus", _make_style(color))

	return button


## Crea lo stile di un pulsante con gli angoli arrotondati.
func _make_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


#endregion

#region Ciclo di gioco


## Comincia una nuova partita.
func _start_new_game() -> void:
	if balance == null:
		balance = BattleBalance.create_default()

	var my_deck: DeckData = player_deck if player_deck != null else CardLibrary.build_starter_deck()
	var foe_deck: DeckData = opponent_deck if opponent_deck != null else CardLibrary.build_veteran_deck()

	ai = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	ai.risk_tolerance = ai_risk_tolerance
	ai.lethal_risk_tolerance = 0.70

	state = BattleState.new()
	state.setup(
		balance,
		my_deck,
		foe_deck,
		CardLibrary.build_synergies(),
		battle_seed,
		"Tu",
		"Avversario"
	)
	state.message.connect(_on_message)

	_log_lines.clear()
	_add_line("╔" + "═".repeat(70))
	_add_line("║  IL TUO MAZZO      : %s" % my_deck.display_name)
	_add_line("║    %d carte, costo medio %.2f, costo massimo %d" % [
		my_deck.card_count(), my_deck.average_cost(), my_deck.highest_cost(),
	])
	_add_line("║  MAZZO AVVERSARIO  : %s" % foe_deck.display_name)
	_add_line("╚" + "═".repeat(70))
	_add_line("")
	_add_line("Premi PESCA per pescare una carta. STOP per chiudere il turno.")
	_add_line("")

	state.start()
	_refresh()


## Il giocatore pesca una carta.
func _on_draw_pressed() -> void:
	if not _can_play():
		return

	var result: CardTypes.TurnResult = state.draw_and_play()

	# Se la carta e' stata giocata, resta il mio turno e posso continuare.
	# In tutti gli altri casi (bust, mana finito, mazzo vuoto) il turno e' finito.
	if result != CardTypes.TurnResult.PLAYING:
		_after_my_turn()
	else:
		_refresh()


## Il giocatore decide di fermarsi.
func _on_stop_pressed() -> void:
	if not _can_play():
		return

	state.stop_turn()
	_after_my_turn()


## Comincia una partita nuova, scartando quella in corso.
func _on_new_pressed() -> void:
	# Seme nuovo ad ogni partita, altrimenti rigiocheresti sempre la stessa.
	battle_seed = randi()
	_start_new_game()


## Elabora la fine del mio turno: fa giocare l'avversario e aggiorna tutto.
func _after_my_turn() -> void:
	if state.is_finished():
		_finish_game()
		return

	_run_opponent_turn()
	_refresh()

	if state.is_finished():
		_finish_game()


## Fa giocare all'IA l'intero turno dell'avversario.
##
## Il turno viene eseguito tutto insieme: e' leggibile nel log e non costringe
## ad aspettare. Il ciclo termina quando l'avversario si ferma, esaurisce il
## mana o fa bust.
func _run_opponent_turn() -> void:
	# Rete di sicurezza identica a quella del simulatore: impedisce un loop
	# infinito se il motore finisse in uno stato inatteso.
	var safety: int = 500

	while safety > 0:
		safety -= 1

		if state.is_finished():
			return
		if state.phase != CardTypes.Phase.AWAITING_ACTION:
			return
		if state.active != state.player_b:
			return

		if ai.should_continue(state):
			var result: CardTypes.TurnResult = state.draw_and_play()
			# Se non ha potuto continuare, il turno e' finito.
			if result != CardTypes.TurnResult.PLAYING:
				return
		else:
			# Spiega la decisione: senza questo un'IA prudente sembra rotta.
			if explain_opponent:
				_add_line("  Avversario: %s." % ai.explain_decision(state))
			state.stop_turn()
			return


## True se il giocatore puo' agire adesso.
func _can_play() -> bool:
	if state == null or state.is_finished():
		return false
	if state.phase != CardTypes.Phase.AWAITING_ACTION:
		return false
	return state.active == state.player_a


## Chiude la partita mostrando l'esito in modo evidente.
func _finish_game() -> void:
	if state.is_draw:
		_add_line("")
		_add_line("╔" + "═".repeat(70))
		_add_line("║  PAREGGIO")
		_add_line("╚" + "═".repeat(70))
	else:
		var won: bool = state.winner == state.player_a
		_add_line("")
		_add_line("╔" + "═".repeat(70))
		_add_line("║  %s" % ("HAI VINTO!" if won else "HAI PERSO"))
		_add_line("║  Turni: %d" % state.turn_number)
		_add_line("╚" + "═".repeat(70))

	_refresh()


#endregion

#region Interfaccia


## Aggiorna la barra di stato e i pulsanti.
func _refresh() -> void:
	if state == null:
		return

	var me: BattlePlayer = state.player_a
	var foe: BattlePlayer = state.player_b

	# --- Intestazione ---
	var header: String
	if state.is_finished():
		if state.is_draw:
			header = "[b]PAREGGIO[/b]"
		else:
			header = "[b]%s[/b]" % ("HAI VINTO" if state.winner == me else "HAI PERSO")
	else:
		header = "[b]TURNO %d[/b]   %s" % [
			state.turn_number,
			"tocca a te" if state.active == me else "sta giocando l'avversario",
		]

	var lines: PackedStringArray = []
	lines.append(header)
	lines.append("")
	lines.append("%s  %s" % ["►" if state.active == me else " ", me.describe_state()])
	lines.append("%s  %s" % ["►" if state.active == foe else " ", foe.describe_state()])
	lines.append("")
	lines.append("Mazzo: %d carte rimaste   |   In campo: %d carte" % [
		me.draw_pile.size(), me.played.size(),
	])

	if not me.played.is_empty():
		var card_names: PackedStringArray = []
		for instance: CardInstance in me.played:
			card_names.append("%s (%d)" % [instance.get_display_name(), instance.get_cost()])
		lines.append("Carte schierate: %s" % " + ".join(card_names))

	_status.text = "\n".join(lines)

	# --- Suggerimento sul rischio ---
	_update_hint()

	# --- Pulsanti ---
	var can_play: bool = _can_play()
	_draw_button.disabled = not can_play
	_stop_button.disabled = not can_play


## Mostra la probabilita' di bust, che e' l'informazione chiave per decidere.
func _update_hint() -> void:
	if state == null or state.is_finished() or not _can_play():
		_hint_label.text = ""
		return

	var risk: float = ai.bust_probability(state)
	var text: String = "Rischio se peschi: %d%%" % int(round(risk * 100.0))

	if is_equal_approx(risk, 0.0):
		text += "   (nessuna carta ti puo' far sbagliare)"
	elif risk >= 1.0:
		text += "   (BUST GARANTITO: fermati!)"
	elif risk > 0.5:
		text += "   (molto pericoloso)"
	elif risk > ai.risk_tolerance:
		text += "   (piu' del tuo limite di %d%%)" % int(round(ai.risk_tolerance * 100.0))

	_hint_label.text = text


## Aggiunge una riga al log e scorre in fondo.
func _add_line(text: String) -> void:
	_log_lines.append(text)

	if _log_lines.size() > max_log_lines:
		_log_lines = _log_lines.slice(_log_lines.size() - max_log_lines)

	_log_label.text = _render_log()
	_scroll_to_bottom.call_deferred()


## Compone il testo del log, colorando le righe importanti.
func _render_log() -> String:
	var parts: PackedStringArray = []
	for line: String in _log_lines:
		parts.append(_colorize(line))
	return "\n".join(parts)


## Colora una riga in base a cosa contiene.
##
## Le parentesi quadre vengono "scappate" ([code][lb][/code]) perche' altrimenti
## un nome di carta con parentesi romperebbe il BBCode del RichTextLabel.
func _colorize(line: String) -> String:
	var escaped: String = line.replace("[", "[lb]")

	if line.contains("BUST"):
		return "[color=#ff6b6b]%s[/color]" % escaped
	if line.contains("SINERGIA"):
		return "[color=#ffd166]%s[/color]" % escaped
	if line.contains("CRITICO"):
		return "[color=#ff9f43]%s[/color]" % escaped
	if line.begins_with("║"):
		return "[color=#9ab7d3]%s[/color]" % escaped
	if line.begins_with("---"):
		return "[color=#6ec6ff]%s[/color]" % escaped
	if line.begins_with("==="):
		return "[b][color=#9ae66e]%s[/color][/b]" % escaped
	if line.begins_with("  >>") or line.begins_with("  Tu pesca"):
		return "[color=#b0b8c8]%s[/color]" % escaped

	return escaped


## Porta il log in fondo.
func _scroll_to_bottom() -> void:
	var bar: VScrollBar = _log_scroll.get_v_scroll_bar()
	_log_scroll.scroll_vertical = int(bar.max_value)


## Riceve ogni riga generata dal motore di battaglia.
func _on_message(text: String) -> void:
	_add_line(text)


## Scorciatoie da tastiera.
##
## I pulsanti hanno [code]focus_mode = NONE[/code], quindi non catturano questi
## tasti e posso gestirli tutti qui.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			_on_draw_pressed()
			get_viewport().set_input_as_handled()
		KEY_S:
			_on_stop_pressed()
			get_viewport().set_input_as_handled()
		KEY_N:
			_on_new_pressed()
			get_viewport().set_input_as_handled()


#endregion
