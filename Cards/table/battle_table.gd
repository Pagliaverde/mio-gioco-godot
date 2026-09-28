## Tavolo di battaglia grafico: gioca contro l'IA con le carte disegnate.
##
## [b]Come e' pensato:[/b] questo script NON costruisce l'interfaccia. La scena
## la disegni tu in Godot (e' la parte che vuoi curare), e questo script la
## pilota. Ogni nodo viene cercato per [b]nome unico[/b] ([code]%Nome[/code]):
## se non lo trova, quella funzione resta spenta e te lo segnala.
##
## Cosi' puoi costruire la scena [b]un pezzo alla volta[/b]: parti da due
## pulsanti e una barra della vita, e man mano che aggiungi nodi col nome
## giusto quelli iniziano a funzionare. Nessuna modifica allo script.
##
## [b]Impostazione dei nomi unici in Godot:[/b] seleziona il nodo nel pannello
## Scena, tasto destro -> [b]Accesso come nome univoco[/b] (Access as Unique
## Name). Compare un [code]%[/code] accanto al nome. Fatto.
##
## L'elenco completo dei nodi riconosciuti e' in
## [code]res://Cards/table/LEGGIMI.md[/code].
##
## [b]Tasti:[/b] [code]Spazio[/code] = pesca, [code]S[/code] = stop,
## [code]N[/code] = nuova partita.
extends Control


@export_group("Partita")

## Il bilanciamento da usare. Vuoto = quello di default.
@export var balance: BattleBalance

## Il tuo mazzo. Vuoto = Equilibrato.
@export var player_deck: DeckData

## Il mazzo dell'avversario. Vuoto = Veterano.
@export var opponent_deck: DeckData

## Seme della partita. 0 = casuale (nuovo a ogni partita).
@export var battle_seed: int = 0

## Nome mostrato per i due combattenti.
@export var player_name: String = "Tu"
@export var opponent_name: String = "Avversario"

@export_group("Avversario (IA)")

## Tolleranza al rischio dell'IA (0-1). Il simulatore ha misurato che un'IA
## piu' audace gioca meglio: con 0,40 e' piu' concreta che con 0,25.
@export_range(0.0, 1.0, 0.05) var ai_risk_tolerance: float = 0.40

## Se true il log spiega perche' l'avversario si ferma.
@export var explain_opponent: bool = true

@export_group("Ritmo")

## Secondi di pausa tra un'azione e l'altra dell'avversario.
## Metti 0 per giocare il turno istantaneamente (come il tavolo testuale).
@export_range(0.0, 2.0, 0.05) var opponent_step_delay: float = 0.45

## Secondi di pausa prima che l'avversario inizi il suo turno.
@export_range(0.0, 3.0, 0.05) var opponent_think_delay: float = 0.6

@export_group("Carte sul tavolo")

## Dimensione delle carte giocate mostrate sul tavolo.
@export var played_card_width: int = 150
@export var played_card_height: int = 205
@export var played_card_art_height: int = 78

@export_group("Presentazione")

## Righe massime di log tenute a schermo.
@export_range(20, 500, 10) var max_log_lines: int = 120


# --- Nodi dell'interfaccia (possono essere null: vedi _collect_ui) -----------
# Tutti opzionali. Se un nodo non esiste, la funzione collegata resta spenta.

var _turn_label: Label
var _new_game_button: Button

var _enemy_name: Label
var _enemy_health: ProgressBar
var _enemy_health_text: Label
var _enemy_mana_label: Label
var _enemy_shield_label: Label
var _enemy_statuses: Container
var _enemy_played: Container
var _enemy_root: Control

var _player_name: Label
var _player_health: ProgressBar
var _player_health_text: Label
var _player_mana_label: Label
var _player_shield_label: Label
var _player_statuses: Container
var _player_played: Container
var _player_root: Control

var _draw_button: Button
var _stop_button: Button
var _risk_label: Label
var _log_label: RichTextLabel
var _log_scroll: ScrollContainer
var _result_overlay: Control
var _result_label: Label

# --- Stato della partita -----------------------------------------------------

## Il motore della battaglia.
var state: BattleState

## L'IA che gioca l'avversario.
var ai: SimAI

## True mentre e' l'avversario a giocare: blocca i pulsanti del giocatore.
var _busy: bool = false

## Le righe di log accumulate (per ricostruire il testo).
var _log_lines: PackedStringArray = []

## Le CardView attualmente sul tavolo, per poterle ripulire.
var _enemy_card_views: Array[Control] = []
var _player_card_views: Array[Control] = []


func _ready() -> void:
	_collect_ui()
	_report_missing()
	_start_new_game()


#region Raccolta dei nodi


## Cerca i nodi dell'interfaccia per nome unico e collega i pulsanti.
##
## [b]Non fallisce se un nodo manca:[/b] lascia la variabile a null e quelle
## funzioni restano spente. Alla fine stampa la checklist di cosa manca, cosi'
## sai esattamente cosa aggiungere per attivare le varie parti.
func _collect_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Riga superiore
	_turn_label = _find_node("TurnLabel") as Label
	_new_game_button = _find_node("NewGameButton") as Button

	# Avversario
	_enemy_root = _find_node("EnemyPanel") as Control
	_enemy_name = _find_node("EnemyName") as Label
	_enemy_health = _find_node("EnemyHealth") as ProgressBar
	_enemy_health_text = _find_node("EnemyHealthText") as Label
	_enemy_mana_label = _find_node("EnemyMana") as Label
	_enemy_shield_label = _find_node("EnemyShield") as Label
	_enemy_statuses = _find_node("EnemyStatuses") as Container
	_enemy_played = _find_node("EnemyPlayed") as Container

	# Giocatore
	_player_root = _find_node("PlayerPanel") as Control
	_player_name = _find_node("PlayerName") as Label
	_player_health = _find_node("PlayerHealth") as ProgressBar
	_player_health_text = _find_node("PlayerHealthText") as Label
	_player_mana_label = _find_node("PlayerMana") as Label
	_player_shield_label = _find_node("PlayerShield") as Label
	_player_statuses = _find_node("PlayerStatuses") as Container
	_player_played = _find_node("PlayerPlayed") as Container

	# Azioni e informazioni
	_draw_button = _find_node("DrawButton") as Button
	_stop_button = _find_node("StopButton") as Button
	_risk_label = _find_node("RiskLabel") as Label
	_log_label = _find_node("LogLabel") as RichTextLabel
	_log_scroll = _find_node("LogScroll") as ScrollContainer

	# Esito
	_result_overlay = _find_node("ResultOverlay") as Control
	_result_label = _find_node("ResultLabel") as Label

	# --- Collegamento dei pulsanti ---
	if _draw_button != null:
		_draw_button.focus_mode = Control.FOCUS_NONE
		_draw_button.pressed.connect(_on_draw_pressed)
	if _stop_button != null:
		_stop_button.focus_mode = Control.FOCUS_NONE
		_stop_button.pressed.connect(_on_stop_pressed)
	if _new_game_button != null:
		_new_game_button.focus_mode = Control.FOCUS_NONE
		_new_game_button.pressed.connect(_on_new_game_pressed)

	if _result_overlay != null:
		_result_overlay.visible = false


## Ritorna il nodo, oppure null se non esiste (con nome unico [code]%Nome[/code]).
func _find_node(node_name: String) -> Node:
	return get_node_or_null("%%%s" % node_name)


## Stampa la checklist dei nodi mancanti, una volta sola all'avvio.
##
## [b]Serve a te, non al gioco:[/b] ti dice esattamente cosa aggiungere alla
## scena per attivare le parti che ancora non si vedono.
func _report_missing() -> void:
	var missing: PackedStringArray = []
	var checks: Dictionary = {
		"TurnLabel": _turn_label,
		"NewGameButton": _new_game_button,
		"EnemyPanel": _enemy_root,
		"EnemyName": _enemy_name,
		"EnemyHealth": _enemy_health,
		"EnemyPlayed": _enemy_played,
		"PlayerPanel": _player_root,
		"PlayerName": _player_name,
		"PlayerHealth": _player_health,
		"PlayerMana": _player_mana_label,
		"PlayerPlayed": _player_played,
		"DrawButton": _draw_button,
		"StopButton": _stop_button,
		"RiskLabel": _risk_label,
		"LogLabel": _log_label,
	}
	for key: String in checks:
		if checks[key] == null:
			missing.append(key)

	if missing.is_empty():
		print("[battle_table] Tutti i nodi presenti. Buona partita!")
	else:
		print("[battle_table] Nodi non trovati nella scena (%d): %s" % [
			missing.size(), ", ".join(missing),
		])
		print("[battle_table] Sono opzionali: il gioco funziona lo stesso. ")
		print("[battle_table] Aggiungili (con nome univoco) per attivare le varie parti. ")
		print("[battle_table] Elenco completo: res://Cards/table/LEGGIMI.md")


#endregion

#region Avvio partita


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
		player_name,
		opponent_name
	)
	state.message.connect(_on_message)
	state.card_played.connect(_on_card_played)
	state.busted.connect(_on_busted)
	state.turn_resolved.connect(_on_turn_resolved)
	state.turn_started.connect(_on_turn_started)

	_busy = false
	_log_lines.clear()
	_clear_played_cards()

	if _result_overlay != null:
		_result_overlay.visible = false

	_add_line("── %s  vs  %s ──" % [my_deck.display_name, foe_deck.display_name])
	_add_line("")

	state.start()
	_refresh()


## Elabora la fine del mio turno: fa giocare l'avversario e aggiorna tutto.
func _after_my_turn() -> void:
	if state.is_finished():
		_finish_game()
		return

	_run_opponent_turn()


## Chiude la partita mostrando l'esito.
func _finish_game() -> void:
	var won: bool = state.winner == state.player_a

	if _result_overlay != null and _result_label != null:
		if state.is_draw:
			_result_label.text = "PAREGGIO"
		elif won:
			_result_label.text = "HAI VINTO!"
		else:
			_result_label.text = "HAI PERSO"
		_result_overlay.visible = true

	_refresh()


#endregion

#region Azioni del giocatore


func _on_draw_pressed() -> void:
	if not _can_play():
		return

	var result: CardTypes.TurnResult = state.draw_and_play()

	# Se la carta e' stata giocata resta il mio turno; in ogni altro caso
	# (bust, mana finito, mazzo vuoto) il turno e' concluso.
	if result == CardTypes.TurnResult.PLAYING:
		_refresh()
	else:
		_after_my_turn()


func _on_stop_pressed() -> void:
	if not _can_play():
		return

	state.stop_turn()
	_after_my_turn()


func _on_new_game_pressed() -> void:
	if _busy:
		return
	# Seme nuovo, altrimenti rigiocheresti sempre la stessa partita.
	battle_seed = randi()
	_start_new_game()


## True se il giocatore puo' agire adesso.
func _can_play() -> bool:
	if state == null or state.is_finished() or _busy:
		return false
	if state.phase != CardTypes.Phase.AWAITING_ACTION:
		return false
	return state.active == state.player_a


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var key_event: InputEventKey = event
	match key_event.keycode:
		KEY_SPACE:
			_on_draw_pressed()
		KEY_S:
			_on_stop_pressed()
		KEY_N:
			_on_new_game_pressed()


#endregion

#region Turno dell'avversario


## Fa giocare all'IA l'intero turno, con una pausa tra le azioni.
##
## [b]E' asincrono di proposito:[/b] ogni azione viene mostrata sul tavolo
## prima della successiva, cosi' si vede la partita invece di subirla.
func _run_opponent_turn() -> void:
	_busy = true
	_refresh()

	if opponent_think_delay > 0.0:
		await get_tree().create_timer(opponent_think_delay).timeout

	# Rete di sicurezza, come nel simulatore: impedisce un loop infinito
	# se il motore finisse in uno stato inatteso.
	var safety: int = 500

	while safety > 0:
		safety -= 1

		if state.is_finished():
			break
		if state.phase != CardTypes.Phase.AWAITING_ACTION:
			break
		if state.active != state.player_b:
			break

		if not ai.should_continue(state):
			if explain_opponent:
				_add_line("  %s: %s." % [state.player_b.display_name, ai.explain_decision(state)])
				_push_log()
			state.stop_turn()
			break

		state.draw_and_play()
		_refresh()

		# Se dopo la pesca il turno non e' piu' il suo (bust o mana finito),
		# il ciclo si chiude da solo al prossimo giro.
		if state.is_finished():
			break
		if state.phase != CardTypes.Phase.AWAITING_ACTION:
			break
		if state.active != state.player_b:
			break

		if opponent_step_delay > 0.0:
			await get_tree().create_timer(opponent_step_delay).timeout

	_busy = false
	_refresh()

	if state.is_finished():
		_finish_game()


#endregion

#region Segnali del motore


## Ogni riga di log prodotta dal motore.
func _on_message(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > max_log_lines:
		_log_lines.remove_at(0)


## Una carta e' stata giocata: la mostro sul tavolo.
func _on_card_played(instance: CardInstance) -> void:
	var target: Container = _player_played if state.active == state.player_a else _enemy_played
	_add_card_view(target, instance, false)


## Pesca una carta troppo cara: evidenzio il fallimento.
func _on_busted(instance: CardInstance) -> void:
	var target: Container = _player_played if state.active == state.player_a else _enemy_played
	_add_card_view(target, instance, true)
	_push_log()


## Il turno e' stato risolto: aggiorno il log.
func _on_turn_resolved(_report: Dictionary) -> void:
	_push_log()


## Comincia un turno: svuoto le carte del giocatore [b]a cui tocca[/b].
##
## [b]Solo quelle di chi sta iniziando:[/b] cosi' le carte dell'altro restano
## sul tavolo per tutto lo scambio. Si vede cosa ha giocato lui mentre giochi tu,
## che e' proprio il confronto che rende leggibile la partita.
func _on_turn_started(_report: Dictionary) -> void:
	var container: Container = _player_played if state.active == state.player_a else _enemy_played
	var registry: Array[Control] = (
		_player_card_views if state.active == state.player_a else _enemy_card_views
	)
	_clear_container(container, registry)


#endregion

#region Aggiornamento dell'interfaccia


## Ridisegna tutto lo stato a schermo.
func _refresh() -> void:
	if state == null:
		return

	_refresh_turn_label()
	_refresh_player(state.player_a, _player_name, _player_health, _player_health_text,
		_player_mana_label, _player_shield_label, _player_statuses, _player_root)
	_refresh_player(state.player_b, _enemy_name, _enemy_health, _enemy_health_text,
		_enemy_mana_label, _enemy_shield_label, _enemy_statuses, _enemy_root)

	_refresh_risk_hint()
	_refresh_buttons()
	_push_log()


func _refresh_turn_label() -> void:
	if _turn_label == null:
		return

	if state.is_finished():
		if state.is_draw:
			_turn_label.text = "PAREGGIO"
		else:
			_turn_label.text = "HAI VINTO" if state.winner == state.player_a else "HAI PERSO"
		return

	var whose: String = "tocca a te" if state.active == state.player_a else "sta giocando l'avversario"
	_turn_label.text = "Turno %d  ·  %s" % [state.turn_number, whose]


## Aggiorna il pannello di un combattente.
func _refresh_player(
	player: BattlePlayer,
	name_label: Label,
	health_bar: ProgressBar,
	health_text: Label,
	mana_label: Label,
	shield_label: Label,
	statuses_box: Container,
	root: Control
) -> void:
	if player == null:
		return

	# Evidenzia chi sta giocando.
	if root != null:
		root.modulate = Color(1, 1, 1) if state.active == player else Color(0.72, 0.72, 0.78)

	if name_label != null:
		name_label.text = player.display_name

	if health_bar != null:
		health_bar.max_value = maxi(player.max_health, 1)
		health_bar.value = player.health

	if health_text != null:
		health_text.text = "%d / %d" % [player.health, player.max_health]

	if mana_label != null:
		mana_label.text = "Mana %d" % player.mana

	if shield_label != null:
		shield_label.text = "Scudo %d" % player.shield
		shield_label.visible = player.shield > 0

	if statuses_box != null:
		_refresh_statuses(player, statuses_box)


## Ricostruisce le etichette degli status attivi di un combattente.
func _refresh_statuses(player: BattlePlayer, box: Container) -> void:
	for child: Node in box.get_children():
		child.queue_free()

	for raw_status: Variant in player.statuses:
		var status: CardTypes.StatusType = raw_status
		var stack: StatusStack = player.statuses[status]

		var chip: Label = Label.new()
		chip.text = "%s %d" % [CardTypes.status_name(status), stack.stacks]
		chip.add_theme_font_size_override("font_size", 13)
		chip.add_theme_color_override("font_color", _status_color(status))
		box.add_child(chip)


## Il colore di uno status, per riconoscerlo a colpo d'occhio.
func _status_color(status: CardTypes.StatusType) -> Color:
	match status:
		CardTypes.StatusType.BURN:
			return Color(0.95, 0.45, 0.25)
		CardTypes.StatusType.POISON:
			return Color(0.55, 0.85, 0.30)
		CardTypes.StatusType.CHILL:
			return Color(0.45, 0.75, 0.98)
		CardTypes.StatusType.EMPOWER:
			return Color(0.98, 0.85, 0.35)
		CardTypes.StatusType.REGEN:
			return Color(0.45, 0.90, 0.55)
	return Color(0.8, 0.8, 0.85)


## Mostra la probabilita' di bust: e' l'informazione che serve per decidere.
func _refresh_risk_hint() -> void:
	if _risk_label == null:
		return

	if not _can_play():
		_risk_label.text = ""
		return

	var risk: float = ai.bust_probability(state)
	var text: String = "Rischio se peschi: %d%%" % int(round(risk * 100.0))

	if is_equal_approx(risk, 0.0):
		text += "  (nessuna carta ti puo' far sbagliare)"
		_risk_label.add_theme_color_override("font_color", Color(0.55, 0.90, 0.60))
	elif risk >= 1.0:
		text += "  (BUST GARANTITO: fermati!)"
		_risk_label.add_theme_color_override("font_color", Color(0.98, 0.40, 0.35))
	elif risk > 0.5:
		_risk_label.add_theme_color_override("font_color", Color(0.98, 0.65, 0.35))
	else:
		_risk_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.55))

	_risk_label.text = text


func _refresh_buttons() -> void:
	var can_play: bool = _can_play()
	if _draw_button != null:
		_draw_button.disabled = not can_play
	if _stop_button != null:
		_stop_button.disabled = not can_play


## Ricostruisce il testo del log e scorre in fondo.
func _push_log() -> void:
	if _log_label == null:
		return

	_log_label.text = "\n".join(_log_lines)

	if _log_scroll != null:
		await get_tree().process_frame
		if is_instance_valid(_log_scroll):
			_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


## Aggiunge una riga al log (in memoria, verra' mostrata da _push_log).
func _add_line(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > max_log_lines:
		_log_lines.remove_at(0)
	_push_log()


#endregion

#region Carte sul tavolo


## Aggiunge una [CardView] al contenitore indicato.
##
## [param busted] colora la carta di rosso: e' la carta che l'ha fatta fallire.
func _add_card_view(target: Container, instance: CardInstance, busted: bool) -> void:
	if target == null or instance == null or instance.data == null:
		return

	var view: Control = CardView.new()
	view.card_width = played_card_width
	view.card_height = played_card_height
	view.art_height = played_card_art_height
	target.add_child(view)
	view.card = instance.data

	if busted:
		view.modulate = Color(1.0, 0.45, 0.42)

	# Tiene traccia delle viste per poterle ripulire a fine turno.
	var registry: Array[Control] = _player_card_views if target == _player_played else _enemy_card_views
	registry.append(view)


## Svuota le carte mostrate sul tavolo.
func _clear_played_cards() -> void:
	_clear_container(_player_played, _player_card_views)
	_clear_container(_enemy_played, _enemy_card_views)


## Svuota un contenitore di carte e il suo registro.
func _clear_container(container: Container, registry: Array[Control]) -> void:
	if container != null:
		for child: Node in container.get_children():
			child.queue_free()
	registry.clear()


#endregion
