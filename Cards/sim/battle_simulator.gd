## Fa girare migliaia di partite automatiche e riporta le statistiche.
##
## [b]Perche' e' lo strumento piu' importante del progetto:[/b] il tuo gioco si
## basa su deck building e fortuna, quindi non puoi bilanciarlo "a sentimento".
## Con questo puoi rispondere a domande come:
##
## - Accumulare scudo blocca le partite? (guarda [code]stalls[/code])
## - Rischiare il bust conviene? (confronta le strategie IA)
## - Quale penalita' di bust rende il rischio una scelta vera?
## - Un mazzo mono-elemento e' troppo forte rispetto a uno bilanciato?
##
## Tutto senza aprire una finestra e in meno di un secondo per centinaia di partite.
class_name BattleSimulator extends RefCounted


## Il bilanciamento da testare.
var balance: BattleBalance

## I due mazzi a confronto.
var deck_a: DeckData
var deck_b: DeckData

## Le sinergie attive.
var synergies: Array[SynergyRule] = []

## Le IA dei due giocatori.
var ai_a: SimAI
var ai_b: SimAI

## Seme di partenza: ogni partita usa [code]base_seed + indice[/code],
## cosi' l'intera simulazione e' riproducibile.
var base_seed: int = 12345


func _init() -> void:
	balance = BattleBalance.create_default()
	deck_a = CardLibrary.build_starter_deck()
	deck_b = CardLibrary.build_starter_deck()
	synergies = CardLibrary.build_synergies()
	ai_a = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	ai_b = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)


## Gioca una singola partita e ritorna lo stato finale.
## Con lo stesso seme otterrai esattamente la stessa partita.
## Se non passi le IA, usa quelle configurate nel simulatore.
func run_single(battle_seed: int, verbose: bool = false, ai_one: SimAI = null, ai_two: SimAI = null) -> BattleState:
	var state: BattleState = BattleState.new()
	state.setup(balance, deck_a, deck_b, synergies, battle_seed, "A", "B")
	state.verbose = verbose
	state.start()

	var first: SimAI = ai_one if ai_one != null else ai_a
	var second: SimAI = ai_two if ai_two != null else ai_b
	_play_until_finished(state, first, second)
	return state


## Conduce una partita fino alla fine guidando i turni con le due IA.
func _play_until_finished(state: BattleState, ai_one: SimAI, ai_two: SimAI) -> void:
	# Rete di sicurezza: impedisce un loop infinito se c'e' un bug nel motore.
	var safety: int = balance.max_turns * 4 + 100
	var steps: int = 0

	while not state.is_finished() and steps < safety:
		steps += 1

		if state.phase != CardTypes.Phase.AWAITING_ACTION:
			break

		var ai: SimAI = ai_one if state.active == state.player_a else ai_two

		if ai.should_continue(state):
			state.draw_and_play()
		else:
			state.stop_turn()

	if not state.is_finished():
		# Se arriviamo qui c'e' qualcosa che non va nel motore: meglio saperlo.
		push_warning("Simulazione interrotta senza vincitore (seme %d, %d passi)." % [state.get_seed(), steps])


## Gioca [param count] partite e aggrega le statistiche.
func run(count: int = 200, ai_one: SimAI = null, ai_two: SimAI = null, _quiet: bool = true) -> Dictionary:
	var one: SimAI = ai_one if ai_one != null else ai_a
	var two: SimAI = ai_two if ai_two != null else ai_b

	var stats: Dictionary = {
		"battles": 0,
		"a_wins": 0,
		"b_wins": 0,
		"draws": 0,
		"stalls": 0,          # partite finite per limite di turni
		"turns_total": 0,
		"turns_min": 999999,
		"turns_max": 0,
		"busts_a": 0,
		"busts_b": 0,
		"damage_a": 0,
		"damage_b": 0,
		"raw_damage_a": 0,
		"raw_damage_b": 0,
		"absorbed_a": 0,
		"absorbed_b": 0,
		"status_damage_a": 0,
		"status_damage_b": 0,
		"shield_a": 0,
		"shield_b": 0,
		"mana_spent_a": 0,
		"mana_spent_b": 0,
		"cards_a": 0,
		"cards_b": 0,
		"stopped_a": 0,
		"stopped_b": 0,
		"healed_a": 0,
		"healed_b": 0,
		"health_a": 0,
		"health_b": 0,
		"ai_a": one.describe(),
		"ai_b": two.describe(),
	}

	for i: int in count:
		var state: BattleState = run_single(base_seed + i, false, one, two)

		stats["battles"] += 1
		stats["turns_total"] += state.turn_number
		stats["turns_min"] = mini(int(stats["turns_min"]), state.turn_number)
		stats["turns_max"] = maxi(int(stats["turns_max"]), state.turn_number)

		if state.is_draw:
			stats["draws"] += 1
			if state.turn_number >= balance.max_turns:
				stats["stalls"] += 1
		elif state.winner == state.player_a:
			stats["a_wins"] += 1
		elif state.winner == state.player_b:
			stats["b_wins"] += 1

		stats["busts_a"] += state.player_a.bust_count
		stats["busts_b"] += state.player_b.bust_count
		stats["damage_a"] += state.player_a.total_damage_dealt
		stats["damage_b"] += state.player_b.total_damage_dealt
		stats["raw_damage_a"] += state.player_a.total_raw_damage
		stats["raw_damage_b"] += state.player_b.total_raw_damage
		stats["absorbed_a"] += state.player_a.total_absorbed
		stats["absorbed_b"] += state.player_b.total_absorbed
		stats["status_damage_a"] += state.player_a.total_status_damage
		stats["status_damage_b"] += state.player_b.total_status_damage
		stats["shield_a"] += state.player_a.total_shield_gained
		stats["shield_b"] += state.player_b.total_shield_gained
		stats["mana_spent_a"] += state.player_a.total_mana_spent
		stats["mana_spent_b"] += state.player_b.total_mana_spent
		stats["cards_a"] += state.player_a.cards_played
		stats["cards_b"] += state.player_b.cards_played
		stats["stopped_a"] += state.player_a.stopped_turns
		stats["stopped_b"] += state.player_b.stopped_turns
		stats["healed_a"] += state.player_a.total_healed
		stats["healed_b"] += state.player_b.total_healed
		stats["health_a"] += state.player_a.health
		stats["health_b"] += state.player_b.health

	_derive_averages(stats)
	return stats


## Calcola medie e percentuali a partire dai totali.
func _derive_averages(stats: Dictionary) -> void:
	var battles: float = maxf(float(stats["battles"]), 1.0)
	var turns: float = maxf(float(stats["turns_total"]), 1.0)

	stats["avg_turns"] = float(stats["turns_total"]) / battles
	stats["win_rate_a"] = float(stats["a_wins"]) / battles
	stats["win_rate_b"] = float(stats["b_wins"]) / battles
	stats["draw_rate"] = float(stats["draws"]) / battles
	stats["stall_rate"] = float(stats["stalls"]) / battles

	stats["avg_busts_a"] = float(stats["busts_a"]) / battles
	stats["avg_busts_b"] = float(stats["busts_b"]) / battles
	# Bust per turno: misura quanto spesso si rischia davvero.
	stats["bust_rate_a"] = float(stats["busts_a"]) / turns
	stats["bust_rate_b"] = float(stats["busts_b"]) / turns

	stats["avg_damage_a"] = float(stats["damage_a"]) / battles
	stats["avg_damage_b"] = float(stats["damage_b"]) / battles
	stats["avg_raw_damage_a"] = float(stats["raw_damage_a"]) / battles
	stats["avg_raw_damage_b"] = float(stats["raw_damage_b"]) / battles
	stats["avg_absorbed_a"] = float(stats["absorbed_a"]) / battles
	stats["avg_absorbed_b"] = float(stats["absorbed_b"]) / battles
	stats["avg_status_damage_a"] = float(stats["status_damage_a"]) / battles
	stats["avg_status_damage_b"] = float(stats["status_damage_b"]) / battles
	stats["avg_shield_a"] = float(stats["shield_a"]) / battles
	stats["avg_shield_b"] = float(stats["shield_b"]) / battles
	stats["avg_mana_spent_a"] = float(stats["mana_spent_a"]) / battles
	stats["avg_mana_spent_b"] = float(stats["mana_spent_b"]) / battles
	stats["avg_cards_a"] = float(stats["cards_a"]) / battles
	stats["avg_cards_b"] = float(stats["cards_b"]) / battles
	stats["avg_stopped_a"] = float(stats["stopped_a"]) / battles
	stats["avg_stopped_b"] = float(stats["stopped_b"]) / battles
	stats["avg_healed_a"] = float(stats["healed_a"]) / battles
	stats["avg_healed_b"] = float(stats["healed_b"]) / battles
	stats["avg_health_a"] = float(stats["health_a"]) / battles
	stats["avg_health_b"] = float(stats["health_b"]) / battles

	# Le due metriche di salute del gioco.
	stats["avg_cards_per_turn_a"] = float(stats["cards_a"]) / turns
	stats["shield_per_battle"] = float(stats["shield_a"] + stats["shield_b"]) / (battles * 2.0)

	# Quanta parte del danno viene mangiata dallo scudo.
	# Se e' troppo alta, la difesa sta dominando e le partite si trascinano.
	var total_raw: float = float(stats["raw_damage_a"] + stats["raw_damage_b"])
	stats["absorption_rate"] = float(stats["absorbed_a"] + stats["absorbed_b"]) / maxf(total_raw, 1.0)

	# Quanto del danno totale e' da status (che ignora lo scudo).
	var total_damage: float = float(
		stats["damage_a"] + stats["damage_b"]
		+ stats["status_damage_a"] + stats["status_damage_b"]
	)
	stats["status_share"] = float(stats["status_damage_a"] + stats["status_damage_b"]) / maxf(total_damage, 1.0)

	# Danno effettivo per punto di mana speso. E' la metrica che conta davvero:
	# confronta quanto rende attaccare rispetto ad accumulare scudo.
	var total_mana: float = float(stats["mana_spent_a"] + stats["mana_spent_b"])
	stats["damage_per_mana"] = total_damage / maxf(total_mana, 1.0)

	# Efficienza difensiva: scudo guadagnato per punto di mana speso.
	stats["shield_per_mana"] = float(stats["shield_a"] + stats["shield_b"]) / maxf(total_mana, 1.0)


#region Report


## Trasforma le statistiche in un report leggibile.
func format_report(stats: Dictionary, title: String = "REPORT SIMULAZIONE") -> String:
	var lines: PackedStringArray = []
	var sep: String = "=".repeat(66)

	lines.append(sep)
	lines.append("  %s" % title)
	lines.append(sep)
	lines.append("  Partite giocate      : %d (semi da %d)" % [stats["battles"], base_seed])
	lines.append("  Bilanciamento        : %s" % balance.describe())
	lines.append("  IA giocatore A       : %s" % stats["ai_a"])
	lines.append("  IA giocatore B       : %s" % stats["ai_b"])
	lines.append("")
	lines.append("  --- ESITO ---")
	lines.append("  Vittorie A           : %d  (%.1f%%)" % [stats["a_wins"], stats["win_rate_a"] * 100.0])
	lines.append("  Vittorie B           : %d  (%.1f%%)" % [stats["b_wins"], stats["win_rate_b"] * 100.0])
	lines.append("  Pareggi              : %d  (%.1f%%)" % [stats["draws"], stats["draw_rate"] * 100.0])
	lines.append("  Turni medi           : %.1f  (min %d, max %d)" % [stats["avg_turns"], stats["turns_min"], stats["turns_max"]])
	lines.append("")
	lines.append("  --- RISCHIO ---")
	lines.append("  Bust per partita     : A %.2f  |  B %.2f" % [stats["avg_busts_a"], stats["avg_busts_b"]])
	lines.append("  Bust ogni 100 turni  : A %.1f  |  B %.1f" % [stats["bust_rate_a"] * 100.0, stats["bust_rate_b"] * 100.0])
	lines.append("")
	lines.append("  --- RITMO ---")
	lines.append("  Carte giocate        : A %.1f  |  B %.1f  (per partita)" % [stats["avg_cards_a"], stats["avg_cards_b"]])
	lines.append("  Carte per turno      : %.2f" % stats["avg_cards_per_turn_a"])
	lines.append("  Mana speso           : A %.1f  |  B %.1f" % [stats["avg_mana_spent_a"], stats["avg_mana_spent_b"]])

	lines.append("")
	lines.append("  --- DANNO ---")
	lines.append("  Danno alla vita      : A %.1f  |  B %.1f" % [stats["avg_damage_a"], stats["avg_damage_b"]])
	lines.append("  Danno da status      : A %.1f  |  B %.1f" % [stats["avg_status_damage_a"], stats["avg_status_damage_b"]])
	lines.append("  Danno lordo inviato  : A %.1f  |  B %.1f" % [stats["avg_raw_damage_a"], stats["avg_raw_damage_b"]])
	lines.append("  Assorbito dallo scudo: A %.1f  |  B %.1f" % [stats["avg_absorbed_a"], stats["avg_absorbed_b"]])
	lines.append("  Scudo guadagnato     : A %.1f  |  B %.1f" % [stats["avg_shield_a"], stats["avg_shield_b"]])
	lines.append("  Vita recuperata      : A %.1f  |  B %.1f" % [stats["avg_healed_a"], stats["avg_healed_b"]])
	lines.append("  Stop volontari       : A %.1f  |  B %.1f" % [stats["avg_stopped_a"], stats["avg_stopped_b"]])
	lines.append("")
	lines.append("  Danno per mana       : %.2f   (danno totale / mana speso)" % stats["damage_per_mana"])
	lines.append("  Scudo per mana       : %.2f" % stats["shield_per_mana"])
	lines.append("  Quota status         : %.1f%%  (del danno totale, ignora lo scudo)" % (stats["status_share"] * 100.0))

	lines.append("")
	lines.append("  --- VERIFICHE ---")
	lines.append(_verdict_lines(stats))

	lines.append(sep)
	return "\n".join(lines)


## Controlla automaticamente se il bilanciamento ha problemi noti.
func _verdict_lines(stats: Dictionary) -> String:
	var lines: PackedStringArray = []

	# Prova 1: attaccare rende piu' che accumulare scudo?
	#
	# Il confronto corretto e' danno per mana contro scudo per mana, NON
	# "danno che arriva alla vita / scudo generato" (che darebbe numeri falsi,
	# perche' non conta ne' il danno assorbito ne' quello da status).
	var damage_per_mana: float = stats["damage_per_mana"]
	var shield_per_mana: float = stats["shield_per_mana"]
	var efficiency_ratio: float = damage_per_mana / maxf(shield_per_mana, 0.01)

	if efficiency_ratio < 1.0:
		lines.append("  [!] Danno/mana = %.2f, scudo/mana = %.2f  -> LA DIFESA DOMINA" % [
			damage_per_mana, shield_per_mana,
		])
		lines.append("      Conviene difendersi invece di attaccare: alza il danno")
		lines.append("      delle carte o abbassa mana_to_shield_ratio.")
	elif stats["absorption_rate"] > 0.6:
		lines.append("  [~] Danno/mana = %.2f, scudo/mana = %.2f  -> attaccare conviene," % [
			damage_per_mana, shield_per_mana,
		])
		lines.append("      ma il %.0f%% del danno viene assorbito dallo scudo." % (stats["absorption_rate"] * 100.0))
		lines.append("      Le partite funzionano, ma la difesa e' molto forte.")
	else:
		lines.append("  [ok] Danno/mana = %.2f, scudo/mana = %.2f  -> attaccare conviene." % [
			damage_per_mana, shield_per_mana,
		])

	# Prova 2: il danno da status e' sotto controllo?
	#
	# E' il controllo piu' importante per questo design: gli status ignorano lo
	# scudo, quindi se valgono troppo diventano l'unica strategia possibile.
	var status_share: float = stats["status_share"]
	if status_share > 0.55:
		lines.append("  [!] Il %.0f%% del danno viene dagli STATUS  -> DOMINANO" % (status_share * 100.0))
		lines.append("      Gli status ignorano lo scudo: se valgono cosi' tanto,")
		lines.append("      conviene sempre giocarli e il resto delle carte e' inutile.")
		lines.append("      Controlla poison_decay in BattleBalance (deve essere 1).")
	elif status_share > 0.40:
		lines.append("  [~] Il %.0f%% del danno viene dagli status  -> forte, ma accettabile." % (status_share * 100.0))
		lines.append("      Sono una strategia valida senza essere l'unica.")
	else:
		lines.append("  [ok] Il %.0f%% del danno viene dagli status  -> equilibrato." % (status_share * 100.0))

	# Prova 3: ci sono partite che non finiscono?
	if stats["stall_rate"] > 0.05:
		lines.append("  [!] Partite bloccate = %.1f%%  -> TROPPE" % (stats["stall_rate"] * 100.0))
		lines.append("      Lo scudo sta dominando: riducilo o aumentano i danni.")
	elif stats["stall_rate"] > 0.0:
		lines.append("  [~] Partite bloccate = %.1f%%  -> poche, ma tienile d'occhio." % (stats["stall_rate"] * 100.0))
	else:
		lines.append("  [ok] Nessuna partita bloccata.")

	# Prova 3: il bust viene mai rischiato?
	var bust_rate: float = (stats["bust_rate_a"] + stats["bust_rate_b"]) * 0.5
	if bust_rate < 0.02:
		lines.append("  [!] Bust ogni 100 turni = %.1f  -> TROPPO RARO" % (bust_rate * 100.0))
		lines.append("      Nessuno rischia: il dilemma del rischio non esiste.")
		lines.append("      Rendi il bust meno punitivo, o i costi piu' vari.")
	elif bust_rate > 0.35:
		lines.append("  [~] Bust ogni 100 turni = %.1f  -> molto frequente." % (bust_rate * 100.0))
		lines.append("      Rischioso, ma potrebbe essere frustrante.")
	else:
		lines.append("  [ok] Bust ogni 100 turni = %.1f  -> il rischio e' una scelta reale." % (bust_rate * 100.0))

	# Prova 4: le partite sono troppo lunghe o troppo corte?
	var avg_turns: float = stats["avg_turns"]
	if avg_turns < 6.0:
		lines.append("  [~] Turni medi = %.1f  -> partite molto rapide." % avg_turns)
	elif avg_turns > 60.0:
		lines.append("  [!] Turni medi = %.1f  -> TROPPO LUNGO" % avg_turns)
		lines.append("      Riduci la vita iniziale o aumenta i danni.")
	else:
		lines.append("  [ok] Turni medi = %.1f  -> durata ragionevole." % avg_turns)

	return "\n".join(lines)


#endregion

#region Confronti


## Le strategie di riferimento da confrontare.
static func default_policies() -> Array[SimAI]:
	var policies: Array[SimAI] = []

	policies.append(SimAI.new(CardTypes.AiPolicy.NEVER_STOP))

	var mana_3: SimAI = SimAI.new(CardTypes.AiPolicy.STOP_AT_MANA)
	mana_3.mana_threshold = 3
	policies.append(mana_3)

	var mana_6: SimAI = SimAI.new(CardTypes.AiPolicy.STOP_AT_MANA)
	mana_6.mana_threshold = 6
	policies.append(mana_6)

	var mana_9: SimAI = SimAI.new(CardTypes.AiPolicy.STOP_AT_MANA)
	mana_9.mana_threshold = 9
	policies.append(mana_9)

	var ratio_20: SimAI = SimAI.new(CardTypes.AiPolicy.STOP_AT_RATIO)
	ratio_20.mana_ratio = 0.2
	policies.append(ratio_20)

	var ratio_35: SimAI = SimAI.new(CardTypes.AiPolicy.STOP_AT_RATIO)
	ratio_35.mana_ratio = 0.35
	policies.append(ratio_35)

	var risk_10: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	risk_10.risk_tolerance = 0.10
	policies.append(risk_10)

	var risk_25: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	risk_25.risk_tolerance = 0.25
	policies.append(risk_25)

	var risk_40: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	risk_40.risk_tolerance = 0.40
	policies.append(risk_40)

	return policies


## Confronta piu' strategie nella stessa partita e stampa una tabella.
## Serve a scoprire se esiste una strategia che domina tutte le altre.
func compare_policies(count: int = 60, policies: Array = []) -> String:
	var list: Array[SimAI] = []
	if policies.is_empty():
		list = default_policies()
	else:
		for raw_entry: Variant in policies:
			list.append(raw_entry as SimAI)

	var lines: PackedStringArray = []
	var sep: String = "=".repeat(104)

	lines.append(sep)
	lines.append("  CONFRONTO STRATEGIE  (%d partite per strategia, sempre contro 'Rischio 25%%')" % count)
	lines.append(sep)
	lines.append("  %-14s %8s %8s %8s %9s %9s %9s" % [
		"STRATEGIA", "VIN%", "TURNI", "BUST/part", "DANNO/p", "SCUDO/p", "CARTE/p",
	])
	lines.append("-".repeat(104))

	# L'avversario fisso, per un confronto equo.
	var reference: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	reference.risk_tolerance = 0.25

	for policy: SimAI in list:
		var stats: Dictionary = run(count, policy, reference, true)
		lines.append("  %-14s %7.1f%% %8.1f %8.2f %9.1f %9.1f %9.1f" % [
			policy.short_name(),
			stats["win_rate_a"] * 100.0,
			stats["avg_turns"],
			stats["avg_busts_a"],
			stats["avg_damage_a"],
			stats["avg_shield_a"],
			stats["avg_cards_a"],
		])

	lines.append(sep)
	lines.append("  Lettura: una strategia con VIN% molto alto domina le altre.")
	lines.append("  Se 'Rischio 40%' stravince, il bust e' troppo indulgente.")
	lines.append("  Se tutte le strategie sono vicine, il bilanciamento e' sano.")
	lines.append(sep)

	return "\n".join(lines)


## Prova le quattro varianti di penalita' del bust per trovare quella giusta.
func compare_bust_penalties(count: int = 120) -> String:
	var variations: Array = [
		CardTypes.BustPenalty.RESOLVE_AND_END,
		CardTypes.BustPenalty.DISCARD_AND_END,
		CardTypes.BustPenalty.DISCARD_AND_CRIT_1_5,
		CardTypes.BustPenalty.DISCARD_AND_CRIT_2,
	]

	var original: CardTypes.BustPenalty = balance.bust_penalty

	var lines: PackedStringArray = []
	var sep: String = "=".repeat(104)

	lines.append(sep)
	lines.append("  CONFRONTO PENALITA' DI BUST  (%d partite ciascuna)" % count)
	lines.append(sep)
	lines.append("  %-24s %7s %8s %9s %10s %9s" % [
		"PENALITA'", "VINC A%", "TURNI", "BUST/part", "DANNO/p", "BLOCC.",
	])
	lines.append("-".repeat(104))

	for raw_penalty: Variant in variations:
		var penalty: CardTypes.BustPenalty = raw_penalty
		balance.bust_penalty = penalty
		var stats: Dictionary = run(count, null, null, true)
		lines.append("  %-24s %6.1f%% %8.1f %9.2f %10.1f %8.1f%%" % [
			CardTypes.bust_penalty_name(penalty),
			stats["win_rate_a"] * 100.0,
			stats["avg_turns"],
			stats["avg_busts_a"] + stats["avg_busts_b"],
			stats["avg_damage_a"],
			stats["stall_rate"] * 100.0,
		])

	balance.bust_penalty = original

	lines.append(sep)
	lines.append("  Cerca la variante dove: pochi blocchi, bust frequente ma non letale.")
	lines.append(sep)

	return "\n".join(lines)


## Confronta due mazzi per capire se uno e' troppo forte.
func compare_decks(
	first: DeckData,
	second: DeckData,
	count: int = 120
) -> String:
	var saved_a: DeckData = deck_a
	var saved_b: DeckData = deck_b

	deck_a = first
	deck_b = second
	var forward: Dictionary = run(count, null, null, true)

	# Invertiamo i lati per annullare il vantaggio di chi gioca per primo.
	deck_a = second
	deck_b = first
	var reverse: Dictionary = run(count, null, null, true)

	deck_a = saved_a
	deck_b = saved_b

	var first_wins: float = (forward["win_rate_a"] + reverse["win_rate_b"]) * 0.5
	var second_wins: float = (forward["win_rate_b"] + reverse["win_rate_a"]) * 0.5

	var lines: PackedStringArray = []
	var sep: String = "=".repeat(72)

	lines.append(sep)
	lines.append("  CONFRONTO MAZZI  (%d partite per lato, entrambi i lati)" % count)
	lines.append(sep)
	lines.append("  %-28s %8s %8s" % ["MAZZO", "VITTORIE", "TURNI"])
	lines.append("-".repeat(72))
	lines.append("  %-28s %7.1f%% %8.1f" % [first.display_name, first_wins * 100.0, forward["avg_turns"]])
	lines.append("  %-28s %7.1f%% %8.1f" % [second.display_name, second_wins * 100.0, reverse["avg_turns"]])
	lines.append(sep)

	var gap: float = absf(first_wins - second_wins)
	if gap > 0.25:
		lines.append("  [!] Squilibrio di %.0f punti: un mazzo domina l'altro." % (gap * 100.0))
	else:
		lines.append("  [ok] Squilibrio di %.0f punti: i due mazzi sono comparabili." % (gap * 100.0))

	lines.append(sep)
	return "\n".join(lines)


#endregion

#region Taratura automatica


## Prova una griglia di configurazioni (mana x vita) e le confronta.
##
## [b]E' il modo piu' veloce per trovare i numeri giusti[/b]: invece di indovinare,
## si fanno girare centinaia di partite per ogni combinazione e si guarda quale
## soddisfa i criteri.
##
## Cerca la combinazione con:
## - vantaggio del primo giocatore contenuto (meno di 60/40)
## - bust presente ma non letale (tra 2% e 20% dei turni)
## - partite di durata ragionevole (8-40 turni)
func tune_mana_and_health(
	mana_values: Array = [12, 14, 16, 20],
	health_values: Array = [60, 80, 100],
	count: int = 120,
	ai_one: SimAI = null,
	ai_two: SimAI = null
) -> String:
	var saved_mana: int = balance.mana_base
	var saved_health: int = balance.starting_health

	var lines: PackedStringArray = []
	var sep: String = "=".repeat(104)

	lines.append(sep)
	lines.append("  TARATURA AUTOMATICA: mana x vita  (%d partite per combinazione)" % count)
	lines.append(sep)
	lines.append("  %-8s %-8s %8s %9s %10s %9s" % [
		"MANA", "VITA", "A VINCE", "TURNI", "BUST/100t", "ESITO",
	])
	lines.append("-".repeat(104))

	var best_score: float = -1.0
	var best_line: String = ""

	for raw_mana: Variant in mana_values:
		var mana: int = raw_mana
		for raw_health: Variant in health_values:
			var health: int = raw_health

			balance.mana_base = mana
			balance.starting_health = health

			var stats: Dictionary = run(count, ai_one, ai_two, true)

			var verdict: String = _judge_tuning(stats)
			var score: float = _tuning_score(stats)

			lines.append("  %-8d %-8d %7.1f%% %9.1f %10.1f %9s" % [
				mana,
				health,
				stats["win_rate_a"] * 100.0,
				stats["avg_turns"],
				(stats["bust_rate_a"] + stats["bust_rate_b"]) * 50.0,
				verdict,
			])

			if score > best_score:
				best_score = score
				best_line = "mana %d, vita %d" % [mana, health]

	balance.mana_base = saved_mana
	balance.starting_health = saved_health

	lines.append(sep)
	lines.append("  Legenda esito:")
	lines.append("    OK    = vantaggio contenuto, bust sensato, durata giusta")
	lines.append("    SBIL. = un giocatore vince troppo (problema di struttura)")
	lines.append("    NOBUST= il bust non succede mai (rischio inesistente)")
	lines.append("    LUNGA = partite troppo lunghe")
	lines.append("    CORTA = partite troppo rapide")
	lines.append("")
	if not best_line.is_empty():
		lines.append("  >> Combinazione migliore secondo i criteri: %s" % best_line)
	lines.append(sep)

	return "\n".join(lines)


## Valuta una singola configurazione e ritorna un'etichetta breve.
func _judge_tuning(stats: Dictionary) -> String:
	var problems: PackedStringArray = []

	var first_advantage: float = maxf(stats["win_rate_a"], stats["win_rate_b"])
	if first_advantage > 0.60:
		problems.append("SBIL.")

	var bust_rate: float = (stats["bust_rate_a"] + stats["bust_rate_b"]) * 50.0
	if bust_rate < 2.0:
		problems.append("NOBUST")

	if stats["avg_turns"] > 40.0:
		problems.append("LUNGA")
	elif stats["avg_turns"] < 7.0:
		problems.append("CORTA")

	if problems.is_empty():
		return "OK"
	return " ".join(problems)


## Punteggio numerico per scegliere la combinazione migliore.
## Piu' alto = meglio. Serve solo a ordinare i risultati.
func _tuning_score(stats: Dictionary) -> float:
	var score: float = 100.0

	# Penalizza il vantaggio del primo giocatore.
	var first_advantage: float = maxf(stats["win_rate_a"], stats["win_rate_b"])
	score -= absf(first_advantage - 0.5) * 300.0

	# Premia un bust presente ma non eccessivo (obbiettivo: 8% dei turni).
	var bust_rate: float = (stats["bust_rate_a"] + stats["bust_rate_b"]) * 50.0
	score -= absf(bust_rate - 8.0) * 2.0

	# Premia una durata intorno ai 20 turni.
	score -= absf(stats["avg_turns"] - 20.0) * 1.5

	# Penalizza gli stalli, che sono sempre un problema.
	score -= stats["stall_rate"] * 200.0

	return score


## Trova quanto compenso serve a chi gioca per secondo.
##
## In un gioco a turni alternati il primo giocatore ha sempre un vantaggio:
## da' il colpo iniziale e spesso anche quello finale. Questo metodo alza
## progressivamente lo scudo iniziale di chi gioca secondo e mostra quando
## il win rate si avvicina al 50%.
func tune_second_player_bonus(
	bonus_values: Array = [0, 8, 12, 16, 20, 25, 30],
	count: int = 150
) -> String:
	var saved_bonus: int = balance.second_player_bonus_shield

	var lines: PackedStringArray = []
	var sep: String = "=".repeat(88)

	lines.append(sep)
	lines.append("  COMPENSO SECONDO GIOCATORE  (%d partite per valore)" % count)
	lines.append(sep)
	lines.append("  %-10s %10s %10s %9s %9s" % ["BONUS", "A VINCE", "B VINCE", "TURNI", "ESITO"])
	lines.append("-".repeat(88))

	var best_gap: float = 999.0
	var best_bonus: int = 0

	for raw_bonus: Variant in bonus_values:
		var bonus: int = raw_bonus
		balance.second_player_bonus_shield = bonus

		var stats: Dictionary = run(count, null, null, true)
		var gap: float = absf(stats["win_rate_a"] - 0.5)

		var verdict: String = "ottimo"
		if gap > 0.15:
			verdict = "troppo squilibrato"
		elif gap > 0.08:
			verdict = "accettabile"

		lines.append("  %-10d %9.1f%% %9.1f%% %9.1f %9s" % [
			bonus,
			stats["win_rate_a"] * 100.0,
			stats["win_rate_b"] * 100.0,
			stats["avg_turns"],
			verdict,
		])

		if gap < best_gap:
			best_gap = gap
			best_bonus = bonus

	balance.second_player_bonus_shield = saved_bonus

	lines.append(sep)
	lines.append("  >> Compenso piu' bilanciato: %d scudo (squilibrio %.1f punti)" % [
		best_bonus, best_gap * 100.0,
	])
	lines.append("  Imposta second_player_bonus_shield = %d in BattleBalance." % best_bonus)
	lines.append(sep)

	return "\n".join(lines)


#endregion

#region Torneo tra mazzi


## Fa combattere [b]tutti gli archetipi di mazzo l'uno contro l'altro[/b]
## e produce una classifica.
##
## [b]E' lo strumento per trovare i "mazzi meta". [/b] Se scopri che un mazzo
## vince contro tutti gli altri, il deck building non e' una scelta ma una
## soluzione obbligata: il gioco diventa noioso.
##
## Ogni coppia viene giocata [b]due volte[/b] (una per lato) per annullare il
## vantaggio del primo giocatore.
func run_deck_tournament(count: int = 80, decks: Array[DeckData] = []) -> String:
	var list: Array[DeckData] = []
	if decks.is_empty():
		list = CardLibrary.meta_decks()
	else:
		for raw: Variant in decks:
			list.append(raw as DeckData)

	var deck_count: int = list.size()
	if deck_count < 2:
		return "Servono almeno due mazzi per un torneo."

	# wins[i][j] = quante volte il mazzo i ha battuto il mazzo j.
	var wins: Array = []
	var played: Array = []
	for i: int in deck_count:
		wins.append([])
		played.append([])
		for _j: int in deck_count:
			wins[i].append(0)
			played[i].append(0)

	var saved_a: DeckData = deck_a
	var saved_b: DeckData = deck_b

	for i: int in deck_count:
		for j: int in range(i + 1, deck_count):
			# Lato 1: i e' A, j e' B.
			deck_a = list[i]
			deck_b = list[j]
			var forward: Dictionary = run(count, null, null, true)
			wins[i][j] += forward["a_wins"]
			wins[j][i] += forward["b_wins"]
			played[i][j] += forward["battles"]
			played[j][i] += forward["battles"]

			# Lato 2: invertiti, per annullare il vantaggio di chi inizia.
			deck_a = list[j]
			deck_b = list[i]
			var reverse: Dictionary = run(count, null, null, true)
			wins[j][i] += reverse["a_wins"]
			wins[i][j] += reverse["b_wins"]
			played[j][i] += reverse["battles"]
			played[i][j] += reverse["battles"]

	deck_a = saved_a
	deck_b = saved_b

	# Calcola le percentuali di vittoria di ogni mazzo.
	var results: Array = []
	for i: int in deck_count:
		var total_wins: int = 0
		var total_played: int = 0
		for j: int in deck_count:
			if i == j:
				continue
			total_wins += wins[i][j]
			total_played += played[i][j]

		var deck: DeckData = list[i]
		results.append({
			"name": deck.display_name,
			"decks": deck,
			"wins": total_wins,
			"played": total_played,
			"rate": float(total_wins) / maxf(float(total_played), 1.0),
			"cost": deck.average_cost(),
			"max_cost": deck.highest_cost(),
			"efficiency": deck.average_efficiency(),
			"risk": deck.average_risk(balance.mana_base),
			"row": wins[i],
		})

	results.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return x["rate"] > y["rate"]
	)

	return _format_tournament(results, count)


## Compone la tabella del torneo.
func _format_tournament(results: Array, count: int) -> String:
	var lines: PackedStringArray = []
	var sep: String = "=".repeat(100)

	lines.append(sep)
	lines.append("  TORNEO TRA ARCHETIPI  (%d partite per coppia, entrambi i lati)" % count)
	lines.append("  Vita %d | mana %d | 2do giocatore +%d scudo" % [
		balance.starting_health,
		balance.mana_base,
		balance.second_player_bonus_shield,
	])
	lines.append(sep)
	lines.append("  %-3s %-16s %8s %8s %9s %10s %9s" % [
		"#", "MAZZO", "VITTORIE", "COSTO", "MAX COSTO", "EFFIC.", "RISCHIO",
	])
	lines.append("-".repeat(100))

	var rank: int = 1
	for entry: Dictionary in results:
		lines.append("  %-3d %-16s %7.1f%% %8.2f %9d %10.2f %8.1f%%" % [
			rank,
			entry["name"],
			entry["rate"] * 100.0,
			entry["cost"],
			entry["max_cost"],
			entry["efficiency"],
			entry["risk"] * 100.0,
		])
		rank += 1

	lines.append(sep)
	lines.append("  Verdetto:")
	lines.append(_tournament_verdict(results))
	lines.append(sep)

	return "\n".join(lines)


## Analizza la classifica e dice se il bilanciamento e' sano.
func _tournament_verdict(results: Array) -> String:
	if results.size() < 2:
		return "  Dati insufficienti."

	var lines: PackedStringArray = []

	var best: Dictionary = results[0]
	var worst: Dictionary = results[results.size() - 1]
	var spread: float = best["rate"] - worst["rate"]

	lines.append("    Migliore : %s (%.1f%%)" % [best["name"], best["rate"] * 100.0])
	lines.append("    Peggiore : %s (%.1f%%)" % [worst["name"], worst["rate"] * 100.0])
	lines.append("    Divario  : %.1f punti percentuali" % (spread * 100.0))
	lines.append("")

	if spread < 0.12:
		lines.append("    [ok] Nessun mazzo domina: il deck building e' una scelta vera.")
	elif spread < 0.22:
		lines.append("    [~] Divario accettabile: qualche mazzo e' piu' forte, ma giocabile.")
	else:
		lines.append("    [!] UN MAZZO DOMINA GLI ALTRI (%.1f%% di divario)." % (spread * 100.0))
		lines.append("        '%s' vince troppo: il deck building non e' piu' una scelta." % best["name"])
		lines.append("        Controlla la sua efficienza e il suo rischio:")
		lines.append("          - efficienza alta + rischio basso = mazzo troppo forte")
		lines.append("          - alza il costo delle sue carte, o abbassa la loro potenza")

	# Controlla se la "ricompensa del rischio" sta funzionando:
	# il mazzo che rischia di piu' deve anche vincere di piu'.
	lines.append("")
	var greedy: Dictionary = {}
	var attrition: Dictionary = {}
	for entry: Dictionary in results:
		if entry["name"] == "Esplosivo":
			greedy = entry
		elif entry["name"] == "Attrito":
			attrition = entry

	if not greedy.is_empty() and not attrition.is_empty():
		if greedy["rate"] > attrition["rate"]:
			lines.append("    [ok] Esplosivo (%.1f%%, rischio %.0f%%) batte Attrito (%.1f%%, rischio %.0f%%)." % [
				greedy["rate"] * 100.0, greedy["risk"] * 100.0,
				attrition["rate"] * 100.0, attrition["risk"] * 100.0,
			])
			lines.append("        Rischia di piu' = vinci di piu'. La meccanica del bust funziona.")
		else:
			lines.append("    [~] Esplosivo (%.1f%%) non batte Attrito (%.1f%%)." % [
				greedy["rate"] * 100.0, attrition["rate"] * 100.0,
			])
			lines.append("        Non e' per forza un male: significa che l'ATTrito e' una")
			lines.append("        strategia valida e non esiste un solo modo di vincere.")
			lines.append("        Ma controlla che Esplosivo non sia proprio ingiocabile:")
			lines.append("        se perde contro TUTTI, le carte costose non ripagano.")

	# Le due filosofie di vittoria ci sono davvero?
	lines.append("")
	lines.append("    Filosofie presenti nella classifica:")
	lines.append("      Attrito    = danno lento, zero rischi  (%s)" % _win_rate_of(results, "Attrito"))
	lines.append("      Esplosivo  = danno immediato, molto rischio (%s)" % _win_rate_of(results, "Esplosivo"))
	lines.append("      Se entrambe stanno sopra il 40%, il gioco ha due modi di vincere.")

	return "\n".join(lines)


## Ritrova la percentuale di vittorie di un mazzo, formattata.
func _win_rate_of(results: Array, deck_name: String) -> String:
	for entry: Dictionary in results:
		if entry["name"] == deck_name:
			return "%.1f%%" % (entry["rate"] * 100.0)
	return "n/d"


## Mostra il profilo di rischio di un mazzo: quanto e' pericoloso giocare
## con poco mana.
func format_deck_risk(deck: DeckData) -> String:
	var lines: PackedStringArray = []
	var sep: String = "=".repeat(76)
	var mana_start: int = balance.mana_base

	lines.append(sep)
	lines.append("  PROFILO DI RISCHIO: %s" % deck.display_name)
	lines.append(sep)
	lines.append("  Carte: %d | Costo medio: %.2f | Costo max: %d" % [
		deck.card_count(), deck.average_cost(), deck.highest_cost(),
	])
	lines.append("  Efficienza: %.2f potenza/mana | Rischio medio: %.1f%% (%s)" % [
		deck.average_efficiency(),
		deck.average_risk(mana_start) * 100.0,
		deck.risk_archetype(mana_start),
	])
	lines.append("  Mana spendibile senza rischi: %d su %d (%d%% del turno e' sicuro)" % [
		deck.safe_spending_budget(),
		mana_start,
		int(round(float(deck.safe_spending_budget()) / float(maxi(mana_start, 1)) * 100.0)),
	])
	lines.append("")
	lines.append("  %-10s %-12s %s" % ["MANA", "RISCHIO", "DISTRIBUZIONE CARTE"])
	lines.append("-".repeat(76))

	for mana: int in range(mana_start, -1, -1):
		var probability: float = deck.bust_probability_at(mana)
		var bar: String = "#".repeat(int(round(probability * 24.0)))

		var marker: String = ""
		if is_equal_approx(probability, 0.0):
			marker = "  (nessun rischio)"
		elif probability >= 1.0:
			marker = "  (bust garantito)"

		lines.append("  %-10s %-12s %s%s" % [
			"%d mana" % mana,
			"%.0f%%" % (probability * 100.0),
			bar,
			marker,
		])

	lines.append(sep)
	lines.append("  Quanto piu' la barra resta vuota a lungo, tanto piu' tardi")
	lines.append("  entra in gioco il rischio: piu' il mazzo e' prudente.")
	lines.append(sep)

	return "\n".join(lines)


#endregion

#region Analisi carte


## Controlla tutte le carte e segnala quelle sbilanciate.
##
## [b]Importante:[/b] le carte sono divise per categoria, perche' non sono
## confrontabili tra loro. Una carta di scudo ha "potenza" bassa per definizione
## (non fa danno), ma il suo valore sta nella sopravvivenza che ti da'.
##
## Il rapporto potenza/mana ha senso solo [b]dentro la stessa categoria[/b].
func audit_cards() -> String:
	var lines: PackedStringArray = []
	var sep: String = "=".repeat(94)

	lines.append(sep)
	lines.append("  ANALISI CARTE  (potenza stimata per punto di mana)")
	lines.append(sep)

	# Raggruppa le carte per tier di costo, che e' la struttura del gioco.
	var by_tier: Dictionary = {}
	for card: CardData in CardLibrary.build_all():
		var tier: int = _cost_tier(card.cost)
		if not by_tier.has(tier):
			by_tier[tier] = []
		by_tier[tier].append(card)

	var tier_order: Array = by_tier.keys()
	tier_order.sort()

	for raw_tier: Variant in tier_order:
		var tier: int = raw_tier
		var cards: Array = by_tier[tier]

		lines.append("")
		lines.append("  ── %s ──" % _tier_name(tier))
		lines.append("  %-24s %5s %8s %8s %6s  %s" % [
			"CARTA", "COSTO", "POTENZA", "RAPPORTO", "ESITO", "CATEGORIA",
		])
		lines.append("-".repeat(94))

		cards.sort_custom(func(x: CardData, y: CardData) -> bool:
			return x.cost < y.cost
		)

		for raw_card: Variant in cards:
			var card: CardData = raw_card
			var instance: CardInstance = CardInstance.new(card)
			var power: float = instance.power_score()
			var cost: float = maxf(float(card.cost), 1.0)
			var ratio: float = power / cost
			var category: String = _categorize(card)

			# Il verdetto ha senso solo per le carte offensive.
			var verdict: String = "—"
			if category == "danno":
				if ratio > 3.0:
					verdict = "FORTE"
				elif ratio < 1.4:
					verdict = "debole"
				else:
					verdict = "ok"

			lines.append("  %-24s %5d %8.1f %8.2f %6s  %s" % [
				card.display_name, card.cost, power, ratio, verdict, category,
			])

	lines.append("")
	lines.append(sep)
	lines.append("  CATEGORIE: non sono confrontabili tra loro.")
	lines.append("    danno   = carte offensive: il rapporto deve stare tra 1.4 e 3.0")
	lines.append("    difesa  = scudo e cura: potenza bassa e' normale, servono a sopravvivere")
	lines.append("    status  = Brucia/Veleno/Congelato: danno differito, non catturato bene dal numero")
	lines.append("    buff    = moltiplicatori: valgono in proporzione a quante carte giochi")
	lines.append("")
	lines.append("  ⚠ Il Veleno e' il caso piu' sottostimato: non decade mai, quindi il suo")
	lines.append("    valore reale cresce ogni turno. Il rapporto mostrato e' il minimo.")
	lines.append(sep)

	return "\n".join(lines)


## Determina il tier di costo di una carta (la struttura del gioco).
func _cost_tier(cost: int) -> int:
	if cost <= 4:
		return 1
	elif cost <= 6:
		return 2
	return 3


## Nome leggibile di un tier.
func _tier_name(tier: int) -> String:
	match tier:
		1:
			return "SETUP (3-4 mana) — nessun danno, difesa e preparazione"
		2:
			return "ATTrito (5-6 mana) — danno lento: Brucia e Veleno"
		3:
			return "BURST (7-9 mana) — danno immediato, rischioso"
	return "?"


## In che categoria rientra una carta, guardando i suoi effetti.
func _categorize(card: CardData) -> String:
	var has_damage: bool = false
	var has_defense: bool = false
	var has_status: bool = false
	var has_buff: bool = false

	for effect: CardEffect in card.effects:
		if effect is DealDamageEffect:
			has_damage = true
		elif effect is GainShieldEffect or effect is HealEffect:
			has_defense = true
		elif effect is ApplyStatusEffect:
			has_status = true
		elif effect is TurnDamageBuffEffect or effect is FlatDamageBonusEffect:
			has_buff = true

	# Ordine di priorita': quello che domina il carattere della carta.
	if has_buff and not has_damage:
		return "buff"
	if has_status and not has_damage:
		return "status"
	if has_damage and (has_defense or has_status):
		return "danno+mix"
	if has_damage:
		return "danno"
	if has_defense:
		return "difesa"
	return "?"


## Statistiche riassuntive di un mazzo.
func describe_deck(deck: DeckData) -> String:
	var lines: PackedStringArray = []
	var mana_start: int = balance.mana_base

	lines.append("  Mazzo: %s  (%s)" % [deck.display_name, deck.risk_archetype(mana_start)])
	lines.append("    Carte totali  : %d" % deck.card_count())
	lines.append("    Costo medio   : %.2f  (da %d a %d)" % [
		deck.average_cost(), deck.lowest_cost(), deck.highest_cost(),
	])
	lines.append("    Efficienza    : %.2f potenza per mana" % deck.average_efficiency())
	lines.append("    Rischio medio : %.1f%%" % (deck.average_risk(mana_start) * 100.0))
	lines.append("    Mana sicuro   : %d su %d" % [deck.safe_spending_budget(), mana_start])

	var elements: Dictionary = deck.element_counts()
	var element_parts: PackedStringArray = []
	for raw_element: Variant in elements:
		var element: CardTypes.Element = raw_element
		element_parts.append("%s %d" % [CardTypes.element_name(element), elements[element]])
	if not element_parts.is_empty():
		lines.append("    Elementi     : %s" % ", ".join(element_parts))

	var histogram: Dictionary = deck.cost_histogram()
	var costs: Array = histogram.keys()
	costs.sort()
	var cost_parts: PackedStringArray = []
	for cost: Variant in costs:
		cost_parts.append("%d mana x%d" % [cost, histogram[cost]])
	lines.append("    Costi        : %s" % ", ".join(cost_parts))

	var problems: PackedStringArray = deck.validate()
	if problems.is_empty():
		lines.append("    Validazione  : ok")
	else:
		for problem: String in problems:
			lines.append("    [!] %s" % problem)

	return "\n".join(lines)


#endregion
