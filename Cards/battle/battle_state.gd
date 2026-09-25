## Il motore della battaglia: gestisce i turni, la pesca, il bust e la risoluzione.
##
## [b]Contiene solo dati e regole, zero nodi.[/b] Per questo puo' girare
## migliaia di volte in pochi secondi nel simulatore, senza aprire una finestra.
##
## [b]Flusso di un turno:[/b]
## [codeblock]
## start()
##   -> begin_turn()            recupera mana, applica gli status
##   -> draw_and_play()         pesca una carta; se costa troppo = BUST
##   -> draw_and_play()         ...ripeti finche' non dici STOP
##   -> stop_turn()             risolve tutto e passa il turno
## [/codeblock]
##
## Il giocatore non ha una mano: pesca e gioca finche' ha mana, oppure si ferma.
## Le carte non si consumano mai: a fine turno tornano nel mazzo, che si rimescola.
class_name BattleState extends RefCounted


## Emesso all'inizio di ogni turno, con il riassunto del mana e degli status.
signal turn_started(report: Dictionary)

## Emesso quando una carta viene giocata con successo.
signal card_played(instance: CardInstance)

## Emesso quando si pesca una carta troppo cara.
signal busted(instance: CardInstance)

## Emesso a fine turno con il dettaglio completo della risoluzione.
signal turn_resolved(report: Dictionary)

## Emesso una sola volta quando la battaglia finisce.
signal battle_finished(winner: BattlePlayer)

## Emesso per ogni riga di log (utile per stamparla a schermo in futuro).
signal message(text: String)


## La configurazione dei numeri del gioco.
var balance: BattleBalance

## La fonte di casualita' (seme fisso = partita riproducibile).
var rng: BattleRNG

## I due combattenti.
var player_a: BattlePlayer
var player_b: BattlePlayer

## Di chi e' il turno adesso.
var active: BattlePlayer

## Chi subisce gli effetti del turno attivo.
var defender: BattlePlayer

## Le regole di sinergia attive in questa battaglia.
var synergy_rules: Array[SynergyRule] = []

## Fase corrente.
var phase: CardTypes.Phase = CardTypes.Phase.NOT_STARTED

## Numero di turno complessivo (non per giocatore).
var turn_number: int = 0

## Tutte le righe di log della battaglia.
var log: Array[String] = []

## Il vincitore, se la battaglia e' finita.
var winner: BattlePlayer = null

## True se la battaglia e' finita in parità (raro: solo per limite di turni o morte simultanea).
var is_draw: bool = false

## Se true stampa ogni riga di log a console mentre gioca.
var verbose: bool = false


## Prepara una battaglia tra due mazzi.
func setup(
	config: BattleBalance,
	deck_a: DeckData,
	deck_b: DeckData,
	synergies: Array[SynergyRule] = [],
	battle_seed: int = 0,
	name_a: String = "Giocatore",
	name_b: String = "Avversario",
	level_a: int = 1,
	level_b: int = 1
) -> void:
	balance = config
	rng = BattleRNG.new(battle_seed)
	synergy_rules = synergies

	player_a = BattlePlayer.new()
	player_a.setup(name_a, deck_a, config, level_a)

	player_b = BattlePlayer.new()
	player_b.setup(name_b, deck_b, config, level_b)

	active = player_a
	defender = player_b

	log.clear()
	turn_number = 0
	winner = null
	is_draw = false
	phase = CardTypes.Phase.NOT_STARTED


## Fa partire la battaglia (mescola e comincia il primo turno).
func start() -> void:
	player_a.start_battle(rng)
	player_b.start_battle(rng)

	_add_log("=== BATTAGLIA: %s vs %s (seme %d) ===" % [player_a.display_name, player_b.display_name, rng.seed_value])
	_add_log("Bilanciamento: %s" % balance.describe())

	# Compenso per chi gioca per secondo: senza, il primo giocatore vince
	# troppo spesso, perche' da' il colpo iniziale e spesso anche quello finale.
	if balance.second_player_bonus_shield > 0:
		player_b.add_shield(balance.second_player_bonus_shield)
		_add_log("%s inizia con %d scudo di compenso (gioca per secondo)." % [
			player_b.display_name,
			balance.second_player_bonus_shield,
		])

	_begin_turn()


## Il seme usato per questa partita, da salvare se vuoi riprodurla.
func get_seed() -> int:
	return rng.seed_value


## True se la battaglia e' conclusa.
func is_finished() -> bool:
	return phase == CardTypes.Phase.FINISHED


#region Turno


## Comincia il turno del giocatore attivo.
func _begin_turn() -> void:
	turn_number += 1

	if turn_number > balance.max_turns:
		_end_battle_draw("limite di turni raggiunto")
		return

	var report: Dictionary = active.begin_turn(rng)

	# Compenso extra per chi gioca per secondo, solo nel suo primo turno.
	if active == player_b and active.turns_taken == 1 and balance.second_player_bonus_mana > 0:
		active.mana += balance.second_player_bonus_mana
		active.mana_at_turn_start += balance.second_player_bonus_mana
		report["mana"] = active.mana
		report["second_player_bonus"] = balance.second_player_bonus_mana

	phase = CardTypes.Phase.AWAITING_ACTION

	# Log del mana
	var mana_text: String = "mana %d" % report["mana"]
	if report["mana_bonus"] > 0:
		mana_text += " (base %d +%d casuale)" % [report["mana_base"], report["mana_bonus"]]
	if report.get("second_player_bonus", 0) > 0:
		mana_text += " (+%d compenso)" % report["second_player_bonus"]
	if report["chill_penalty"] > 0:
		mana_text += " (-%d congelato)" % report["chill_penalty"]

	_add_log("--- Turno %d: %s, %s ---" % [turn_number, active.display_name, mana_text])

	# Log degli status
	var status_report: Dictionary = report["status_report"]
	if status_report["burn_damage"] > 0:
		_add_log("  %s brucia: -%d vita" % [active.display_name, status_report["burn_damage"]])
	if status_report["poison_damage"] > 0:
		_add_log("  %s avvelenato: -%d vita" % [active.display_name, status_report["poison_damage"]])
	if status_report["regen_heal"] > 0:
		_add_log("  %s si rigenera: +%d vita" % [active.display_name, status_report["regen_heal"]])
	if status_report["empower_percent"] > 0:
		_add_log("  %s potenziato: +%d%% danno" % [active.display_name, status_report["empower_percent"]])
	if report["crit"] > 1.0:
		_add_log("  %s ha il CRITICO x%.1f attivo!" % [active.display_name, report["crit"]])

	# Lo status potrebbe aver ucciso il giocatore prima ancora di giocare.
	if active.is_defeated():
		_add_log("  %s crolla per gli status!" % active.display_name)
		_finish_battle()
		return

	turn_started.emit(report)


## Pesca una carta e prova a giocarla.
##
## Questo e' il momento della scommessa: se la carta costa piu' del mana
## che ti resta, [b]sali il turno[/b] e l'avversario ottiene un critico.
func draw_and_play() -> CardTypes.TurnResult:
	if phase != CardTypes.Phase.AWAITING_ACTION:
		return CardTypes.TurnResult.BATTLE_OVER

	# Se il mazzo e' vuoto non c'e' nulla da pescare: equivale a fermarsi.
	if active.is_deck_empty():
		_add_log("  %s non ha piu' carte: si ferma." % active.display_name)
		return stop_turn()

	var instance: CardInstance = active.draw_card()
	var cost: int = instance.get_cost()

	# --- BUST: la carta costa piu' del mana disponibile -------------------
	if not active.can_afford(cost):
		_add_log("  ✖ BUST! %s pesca %s (costo %d) con solo %d mana." % [
			active.display_name, instance.get_display_name(), cost, active.mana,
		])

		# La carta non e' stata giocata: torna subito nel mazzo, cosi'
		# nessuna carta viene mai persa dal ciclo.
		active.draw_pile.append(instance)
		active.bust_count += 1
		busted.emit(instance)

		# Il critico va all'avversario, se la variante scelta lo prevede.
		var crit: float = balance.crit_multiplier_for_penalty()
		if crit > 1.0:
			defender.pending_crit = crit
			_add_log("  %s ottiene il CRITICO x%.1f al prossimo turno." % [defender.display_name, crit])

		# Le carte gia' giocate: si risolvono o si perdono, secondo la variante.
		_resolve_turn(balance.resolves_on_bust(), false)

		if not is_finished():
			_finish_turn()

		return CardTypes.TurnResult.BUSTED

	# --- Carta giocata ---------------------------------------------------
	active.play_card(instance)
	_add_log("  %s gioca %s (costo %d, restano %d mana)" % [
		active.display_name, instance.get_display_name(), cost, active.mana,
	])
	card_played.emit(instance)

	# Se il mana e' finito non serve chiedere: si passa automaticamente.
	if active.mana <= 0:
		stop_turn()
		return CardTypes.TurnResult.STOPPED

	return CardTypes.TurnResult.PLAYING


## Il giocatore decide di fermarsi. Si risolve il turno e si passa la mano.
func stop_turn() -> CardTypes.TurnResult:
	if phase != CardTypes.Phase.AWAITING_ACTION:
		return CardTypes.TurnResult.BATTLE_OVER

	active.stopped_turns += 1
	_add_log("  %s dice STOP con %d mana rimasti." % [active.display_name, active.mana])

	_resolve_turn(true, true)

	if not is_finished():
		_finish_turn()

	return CardTypes.TurnResult.STOPPED


## Chiude il turno: le carte tornano nel mazzo (rimescolato) e si cambia giocatore.
func _finish_turn() -> void:
	active.reshuffle(rng)
	_switch_active()


## Passa il turno all'altro giocatore.
func _switch_active() -> void:
	var previous: BattlePlayer = active
	active = defender
	defender = previous
	_begin_turn()


#endregion

#region Risoluzione


## Applica tutti gli effetti accumulati in un [EffectContext].
##
## Ordine di calcolo (identico per tutti, cosi' l'ordine delle carte non conta):
## 1. Le sinergie impostano i moltiplicatori
## 2. Ogni carta accumula i suoi effetti
## 3. Si calcola il danno finale (sinergie + globali + critico + Potenziato)
## 4. Lo scudo riduce e assorbe, il resto va sulla vita
## 5. Cure, scudo guadagnato e status vengono applicati
## 6. Il mana non speso diventa scudo
func _resolve_turn(apply_card_effects: bool, convert_mana_to_shield: bool) -> void:
	phase = CardTypes.Phase.RESOLVING

	var ctx: EffectContext = EffectContext.new()
	ctx.state = self
	ctx.owner = active
	ctx.opponent = defender
	ctx.card = null

	# 1. Sinergie (contano le carte che hai giocato).
	if apply_card_effects:
		for rule: SynergyRule in synergy_rules:
			if rule != null:
				rule.evaluate(ctx)

	# 2. Effetti delle carte.
	if apply_card_effects:
		for instance: CardInstance in active.played:
			ctx.card = instance.data
			instance.apply_effects(ctx)
		ctx.card = null
	else:
		ctx.add_log("  (le carte giocate vengono perse)")

	# 3. Danno finale.
	var raw_damage: int = ctx.total_damage()
	var final_damage: int = int(round(
		float(raw_damage) * active.turn_damage_multiplier() * active.current_crit
	))

	var breakdown: Dictionary = ctx.damage_breakdown()
	var breakdown_text: String = _format_breakdown(breakdown)

	# 4. Il danno colpisce l'avversario.
	var damage_report: Dictionary = {}
	if final_damage > 0:
		damage_report = defender.take_damage(final_damage)
		active.total_damage_dealt += damage_report["to_health"]
		active.total_raw_damage += final_damage
		active.total_absorbed += damage_report["absorbed"]

		_add_log("  %s infligge %d danni%s" % [
			active.display_name,
			final_damage,
			(" (%s)" % breakdown_text) if not breakdown_text.is_empty() else "",
		])
		if damage_report["reduction_percent"] > 0.0:
			_add_log("    scudo avversario: -%d%% (-%d danni)" % [
				int(round(damage_report["reduction_percent"] * 100.0)),
				damage_report["raw"] - damage_report["after_reduction"],
			])
		if damage_report["absorbed"] > 0:
			_add_log("    assorbe %d con lo scudo" % damage_report["absorbed"])
		_add_log("    %s subisce %d danni alla vita (ora %d/%d)" % [
			defender.display_name,
			damage_report["to_health"],
			defender.health,
			defender.max_health,
		])

	# 5. Cure, scudo e status.
	var healed: int = active.heal(ctx.health_to_heal)
	if healed > 0:
		_add_log("  %s recupera %d vita (ora %d/%d)" % [active.display_name, healed, active.health, active.max_health])

	var self_damage: int = ctx.self_damage
	if self_damage > 0:
		active.health = maxi(active.health - self_damage, 0)
		_add_log("  %s paga %d vita per la propria carta" % [active.display_name, self_damage])

	for entry: Dictionary in ctx.statuses_to_apply:
		var target: BattlePlayer = active if entry["target_self"] else defender
		target.add_status(entry["status"], entry["stacks"])
		_add_log("  %s riceve %d %s" % [
			target.display_name,
			entry["stacks"],
			CardTypes.status_name(entry["status"]),
		])

	# 6. Il mana non speso diventa scudo: fermarsi presto e' una scelta difensiva.
	#    Dopo un bust invece il mana e' sprecato, per non premiare l'errore.
	var leftover: int = active.leftover_mana()
	var shield_from_mana: int = 0
	if convert_mana_to_shield and leftover > 0:
		shield_from_mana = int(round(float(leftover) * balance.mana_to_shield_ratio))
		active.mana = 0

	var shield_from_cards: int = ctx.shield_to_gain
	if shield_from_cards > 0:
		active.add_shield(shield_from_cards)
		_add_log("  %s guadagna %d scudo dalle carte (totale %d)" % [
			active.display_name, shield_from_cards, active.shield,
		])
	if shield_from_mana > 0:
		active.add_shield(shield_from_mana)
		_add_log("  %s converte %d mana in scudo (totale %d)" % [
			active.display_name, shield_from_mana, active.shield,
		])

	for line: String in ctx.log:
		_add_log(line)

	var report: Dictionary = {
		"turn": turn_number,
		"attacker": active,
		"defender": defender,
		"damage": final_damage,
		"damage_breakdown": breakdown,
		"damage_report": damage_report,
		"healed": healed,
		"self_damage": self_damage,
		"shield_from_cards": shield_from_cards,
		"shield_from_mana": shield_from_mana,
		"cards_played": active.played.size(),
		"log": ctx.log.duplicate(),
	}
	turn_resolved.emit(report)

	_finish_battle_if_over()


## Controlla se qualcuno e' morto e, solo in quel caso, chiude la battaglia.
func _finish_battle_if_over() -> void:
	if is_finished():
		return
	if player_a.is_defeated() or player_b.is_defeated():
		_finish_battle()


## Determina il vincitore (o il pareggio) e chiude.
func _finish_battle() -> void:
	if phase == CardTypes.Phase.FINISHED:
		return

	var a_dead: bool = player_a.is_defeated()
	var b_dead: bool = player_b.is_defeated()

	phase = CardTypes.Phase.FINISHED

	if a_dead and b_dead:
		is_draw = true
		_add_log("=== PAREGGIO: entrambi a terra ===")
		battle_finished.emit(null)
		return

	if b_dead:
		winner = player_a
	elif a_dead:
		winner = player_b
	else:
		# Non e' morto nessuno: non dovrebbe succedere, ma meglio chiudere
		# piuttosto che lasciare il motore in uno stato incoerente.
		is_draw = true
		_add_log("=== PAREGGIO ===")
		battle_finished.emit(null)
		return

	_add_log("=== VINCE %s al turno %d ===" % [winner.display_name, turn_number])
	battle_finished.emit(winner)


## Chiude la battaglia dichiarando un pareggio (es. per limite di turni).
func _end_battle_draw(reason: String) -> void:
	phase = CardTypes.Phase.FINISHED
	is_draw = true
	_add_log("=== PAREGGIO: %s ===" % reason)
	battle_finished.emit(null)


## Formatta il dettaglio del danno per elemento, es. "Fuoco 12, Ghiaccio 5".
func _format_breakdown(breakdown: Dictionary) -> String:
	if breakdown.is_empty():
		return ""

	var parts: PackedStringArray = []
	for raw_element: Variant in breakdown:
		var element: CardTypes.Element = raw_element
		parts.append("%s %d" % [CardTypes.element_name(element), breakdown[element]])
	return ", ".join(parts)


#endregion

#region Utility


## Aggiunge una riga al log e, se richiesto, la stampa a console.
func _add_log(text: String) -> void:
	log.append(text)
	if verbose:
		print(text)
	message.emit(text)


## Statistiche riassuntive della battaglia, per il report del simulatore.
func get_stats() -> Dictionary:
	return {
		"seed": rng.seed_value,
		"turns": turn_number,
		"winner": winner.display_name if winner != null else ("pareggio" if is_draw else "?"),
		"is_draw": is_draw,
		"player_a": {
			"name": player_a.display_name,
			"health": player_a.health,
			"busts": player_a.bust_count,
			"damage": player_a.total_damage_dealt,
			"shield": player_a.total_shield_gained,
			"cards_played": player_a.cards_played,
			"stopped": player_a.stopped_turns,
			"mana_spent": player_a.total_mana_spent,
			"healed": player_a.total_healed,
		},
		"player_b": {
			"name": player_b.display_name,
			"health": player_b.health,
			"busts": player_b.bust_count,
			"damage": player_b.total_damage_dealt,
			"shield": player_b.total_shield_gained,
			"cards_played": player_b.cards_played,
			"stopped": player_b.stopped_turns,
			"mana_spent": player_b.total_mana_spent,
			"healed": player_b.total_healed,
		},
	}


## True se il giocatore attivo puo' ancora fare qualcosa.
func can_act() -> bool:
	return phase == CardTypes.Phase.AWAITING_ACTION and not active.is_deck_empty()


## Il mana rimasto al giocatore attivo.
func remaining_mana() -> int:
	return active.mana


#endregion
