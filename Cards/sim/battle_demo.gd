## Dimostra una battaglia step-by-step, come se la giocassi tu.
##
## [b]A cosa serve:[/b] a verificare con gli occhi che le regole funzionino
## come le hai immaginate. Il simulatore ti da' i numeri, questa scena ti
## fa vedere il [i]perche'[/i].
##
## [b]Come si usa:[/b] apri [code]res://Cards/sim/battle_demo.tscn[/code] e premi [b]F6[/b].
##
## Modifica le opzioni nell'inspector per esplorare situazioni diverse.
extends Node


enum DemoMode {
	ONE_BATTLE,      ## Una partita completa, riga per riga.
	SAME_SEED_TWICE, ## Due partite con lo stesso seme: devono essere identiche.
	RISK_ANALYSIS,   ## Mostra la probabilita' di bust a ogni livello di mana.
}

@export var mode: DemoMode = DemoMode.ONE_BATTLE

## Il seme: cambialo per vedere un'altra partita. Mettilo a 0 per uno casuale.
@export var battle_seed: int = 12345

@export var balance: BattleBalance

## Se true la finestra si chiude da sola a fine demo.
@export var quit_when_done: bool = true


func _ready() -> void:
	if balance == null:
		balance = BattleBalance.create_default()

	print("")
	match mode:
		DemoMode.ONE_BATTLE:
			_run_one_battle()
		DemoMode.SAME_SEED_TWICE:
			_run_determinism_check()
		DemoMode.RISK_ANALYSIS:
			_run_risk_analysis()
	print("")

	if quit_when_done:
		await get_tree().process_frame
		get_tree().quit()


## Una partita completa, con ogni decisione spiegata.
func _run_one_battle() -> void:
	var synergies: Array[SynergyRule] = CardLibrary.build_synergies()
	var state: BattleState = BattleState.new()
	state.setup(
		balance,
		CardLibrary.build_starter_deck(),
		CardLibrary.build_elemental_deck(CardTypes.Element.FIRE),
		synergies,
		battle_seed,
		"Tu",
		"Slime"
	)

	# Le sinergie attive: buono saperlo prima di leggere la partita.
	print("SINERGIE ATTIVE IN QUESTA PARTITA:")
	for rule: SynergyRule in synergies:
		print("  - %s: %s -> %s" % [rule.display_name, rule.describe_condition(), rule.describe_effect()])
	print("")

	state.start()

	# IA: una ragionevole per entrambi, cosi' la partita e' sensata.
	var smart: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	smart.risk_tolerance = 0.25

	var steps: int = 0
	while not state.is_finished() and steps < 2000:
		steps += 1
		if state.phase != CardTypes.Phase.AWAITING_ACTION:
			break

		if smart.should_continue(state):
			# Spieghiamo la decisione, cosi' si capisce il ragionamento.
			var probability: float = smart.bust_probability(state)
			print("  >> %s pesca (rischio bust %.0f%%, mana %d)" % [
				state.active.display_name, probability * 100.0, state.active.mana,
			])
			state.draw_and_play()
		else:
			state.stop_turn()

	print("")
	print("RISULTATO: %s" % ("PAREGGIO" if state.is_draw else "vince %s" % state.winner.display_name))
	print("Turni: %d | Seme: %d" % [state.turn_number, state.get_seed()])
	print("  %s" % state.player_a.describe_state())
	print("  %s" % state.player_b.describe_state())


## Gioca la stessa partita due volte: il risultato [b]deve[/b] essere identico.
## Se non lo e', c'e' una fonte di casualita' nascosta da qualche parte.
func _run_determinism_check() -> void:
	var simulator: BattleSimulator = BattleSimulator.new()
	var first: BattleState = simulator.run_single(battle_seed)
	var second: BattleState = simulator.run_single(battle_seed)

	print("CONTROLLO DETERMINISMO (seme %d)" % battle_seed)
	print("  Prima partita : turni %d, %s, %d/%d HP" % [
		first.turn_number,
		"pareggio" if first.is_draw else first.winner.display_name,
		first.player_a.health,
		first.player_a.max_health,
	])
	print("  Seconda partita: turni %d, %s, %d/%d HP" % [
		second.turn_number,
		"pareggio" if second.is_draw else second.winner.display_name,
		second.player_a.health,
		second.player_a.max_health,
	])

	var identical: bool = (
		first.turn_number == second.turn_number
		and first.player_a.health == second.player_a.health
		and first.player_b.health == second.player_b.health
	)

	print("  Risultato: %s" % ("IDENTICI, corretto." if identical else "DIVERSI! C'e' casualita' nascosta."))


## Mostra quanto e' rischioso pescare, a ogni livello di mana.
## E' la tabella che spiega perche' il bust e' una scelta interessante (o no).
func _run_risk_analysis() -> void:
	var deck: DeckData = CardLibrary.build_starter_deck()
	print("PROBABILITA' DI BUST a inizio partita")
	print("Mazzo: %s (costo medio %.2f)" % [deck.display_name, deck.average_cost()])
	print("")
	print("  %-10s %-12s %s" % ["MANA", "RISCHIO", "CARTE NON GIOCABILI"])

	var histogram: Dictionary = deck.cost_histogram()
	var total_cards: int = deck.card_count()
	var max_cost: int = 0
	for cost: Variant in histogram:
		max_cost = maxi(max_cost, cost)

	for mana: int in range(max_cost, -1, -1):
		var affordable: int = 0
		var too_expensive: int = 0
		for cost: Variant in histogram:
			if cost <= mana:
				affordable += histogram[cost]
			else:
				too_expensive += histogram[cost]

		var probability: float = float(too_expensive) / float(total_cards)

		var bar: String = "#".repeat(int(round(probability * 30.0)))
		print("  %-10s %-12s %s %s" % [
			"%d mana" % mana,
			"%.0f%%" % (probability * 100.0),
			bar,
			"(%d/%d)" % [too_expensive, total_cards],
		])

	print("")
	print("  Leggi cosi': a quanti mana conviene ancora rischiare?")
	print("  Se il rischio arriva al 100% troppo presto, il bust e' troppo punitivo.")
	print("  Se resta basso fino alla fine, nessuno si fermera' mai.")
