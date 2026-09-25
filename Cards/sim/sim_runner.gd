extends Node

# Lancia la simulazione di bilanciamento e stampa i report a console.
#
# Come si usa:
#   1. Apri res://Cards/sim/sim_runner.tscn
#   2. Premi F6 (Esegui scena corrente)
#   3. Guarda il pannello Output in basso
#
# Cambia il campo Mode nell'inspector per scegliere cosa analizzare.
# Nessuna finestra di gioco: gira tutto a velocita' macchina.


enum Mode {
	QUICK,      ## Solo il report base: veloce, buono per iniziare.
	FULL,       ## Tutto: report, mazzi, analisi carte, confronti.
	POLICIES,   ## Solo il confronto tra strategie di gioco.
	BUST,       ## Solo il confronto tra le varianti di penalita' del bust.
	DECKS,      ## Confronta mazzi diversi tra loro.
	AUDIT,      ## Analizza solo la potenza delle singole carte.
	TUNING,     ## Cerca i numeri giusti provando mana x vita.
	TORNEO,     ## Fa combattere gli archetipi di mazzo e produce una classifica.
	RISCHIO,    ## Mostra il profilo di rischio di ogni archetipo di mazzo.
}

## Cosa analizzare.
@export var mode: Mode = Mode.FULL

## Quante partite per ogni scenario. Alzalo per risultati piu' solidi
## (1000 partite richiedono meno di un secondo).
@export_range(10, 20000, 10) var battle_count: int = 300

## Mostra anche i log completi di una partita di esempio.
@export var show_example_battle: bool = true

## Se true la finestra si chiude da sola a fine simulazione.
## Metti false se vuoi tenere la finestra aperta (e' vuota: i risultati sono
## nel pannello Output dell'editor).
@export var quit_when_done: bool = true


func _ready() -> void:
	var simulator: BattleSimulator = BattleSimulator.new()

	print("")
	match mode:
		Mode.QUICK:
			print(simulator.format_report(simulator.run(battle_count), "REPORT RAPIDO"))
		Mode.FULL:
			_run_full(simulator)
		Mode.POLICIES:
			print(simulator.compare_policies(battle_count))
		Mode.BUST:
			print(simulator.compare_bust_penalties(battle_count))
		Mode.DECKS:
			_run_deck_comparison(simulator)
		Mode.AUDIT:
			print(simulator.audit_cards())
		Mode.TUNING:
			_run_tuning(simulator)
		Mode.TORNEO:
			_run_tournament(simulator)
		Mode.RISCHIO:
			_run_risk_profiles(simulator)

	if show_example_battle:
		_print_example_battle(simulator)

	print("")
	print("Simulazione completata. I risultati sono qui sopra nel pannello Output.")
	print("")

	if quit_when_done:
		# Aspetta un frame per essere sicuri che l'output sia stato scritto,
		# poi chiude la finestra e torna all'editor.
		await get_tree().process_frame
		get_tree().quit()


func _run_full(simulator: BattleSimulator) -> void:
	# 1. Report principale con le due verifiche di salute del gioco.
	print(simulator.format_report(simulator.run(battle_count), "REPORT PRINCIPALE"))

	# 2. Com'e' fatto il mazzo di partenza.
	print("")
	print("=".repeat(66))
	print("  MAZZI IN USO")
	print("=".repeat(66))
	print(simulator.describe_deck(simulator.deck_a))

	# 3. Controllo della potenza delle singole carte.
	print("")
	print(simulator.audit_cards())

	# 4. Esiste una strategia che domina le altre?
	print("")
	print(simulator.compare_policies(maxi(battle_count / 5, 40)))

	# 5. Quale penalita' di bust rende il rischio una scelta vera?
	print("")
	print(simulator.compare_bust_penalties(maxi(battle_count / 3, 60)))

	# 6. E infine: con quale mana e quale vita il gioco funziona meglio?
	print("")
	_run_tuning(simulator)

	# 7. Esiste un mazzo che domina tutti gli altri?
	print("")
	print(simulator.run_deck_tournament(maxi(battle_count / 4, 40)))


## Fa combattere tutti gli archetipi di mazzo tra loro.
## Serve a scoprire se esiste un mazzo che domina gli altri.
func _run_tournament(simulator: BattleSimulator) -> void:
	# Prima vediamo com'e' fatto ogni mazzo.
	print(CardLibrary.describe_archetypes(simulator.balance.mana_base))

	# Poi la classifica del torneo.
	print("")
	print(simulator.run_deck_tournament(maxi(battle_count / 4, 40)))

	# E infine il report generale con la nuova configurazione.
	print("")
	print(simulator.format_report(simulator.run(battle_count), "REPORT CON MAZZO EQUILIBRATO"))


## Mostra quanto e' rischioso giocare con poco mana, per ogni archetipo.
func _run_risk_profiles(simulator: BattleSimulator) -> void:
	for deck: DeckData in CardLibrary.meta_decks():
		print("")
		print(simulator.format_deck_risk(deck))


## Cerca i numeri giusti provando combinazioni di mana e vita.
## E' la modalita' da usare quando il bilanciamento non convince.
func _run_tuning(simulator: BattleSimulator) -> void:
	# Griglia: si provano tutte le combinazioni di questi due valori.
	var mana_values: Array = [12, 14, 16, 18, 20]
	var health_values: Array = [60, 80, 100, 120]

	var per_combo: int = maxi(battle_count / 4, 60)
	print(simulator.tune_mana_and_health(mana_values, health_values, per_combo))

	# E quanto compenso serve a chi gioca per secondo?
	print("")
	print(simulator.tune_second_player_bonus([0, 8, 12, 16, 20, 25, 30], maxi(battle_count / 3, 80)))


## Prova anche diverse combinazioni di sinergie: quanto devono essere
## difficili da attivare perche' il deck building conti davvero?
func _run_tuning_synergies(simulator: BattleSimulator) -> void:
	print("")
	print("=" .repeat(66))
	print("  Le sinergie si attivano troppo facilmente?")
	print("=" .repeat(66))
	print("  Guarda il log di una partita: se compare una sinergia quasi ogni turno,")
	print("  la soglia minima di carte e' troppo bassa.")
	print("")
	print(simulator.format_report(simulator.run(battle_count), "Con sinergie min 2 carte"))


func _run_deck_comparison(simulator: BattleSimulator) -> void:
	var starter: DeckData = CardLibrary.build_starter_deck()
	var aggressive: DeckData = CardLibrary.build_aggressive_deck()
	var fortress: DeckData = CardLibrary.build_fortress_deck()

	print(simulator.compare_decks(starter, aggressive, battle_count))
	print("")
	print(simulator.compare_decks(starter, fortress, battle_count))
	print("")
	print(simulator.compare_decks(aggressive, fortress, battle_count))

	print("")
	print("=".repeat(66))
	print("  MAZZI A CONFRONTO")
	print("=".repeat(66))
	print(simulator.describe_deck(starter))
	print("")
	print(simulator.describe_deck(aggressive))
	print("")
	print(simulator.describe_deck(fortress))

	# E un mazzo mono-elemento contro uno bilanciato.
	var elements_to_test: Array = [
		CardTypes.Element.FIRE,
		CardTypes.Element.POISON,
		CardTypes.Element.ICE,
	]
	for raw_element: Variant in elements_to_test:
		var element: CardTypes.Element = raw_element
		print("")
		print(simulator.compare_decks(
			CardLibrary.build_elemental_deck(element),
			CardLibrary.build_starter_deck(),
			battle_count
		))


## Stampa una partita completa riga per riga.
## E' il modo migliore per verificare a mano che le regole funzionino.
func _print_example_battle(simulator: BattleSimulator) -> void:
	print("")
	print("=".repeat(66))
	print("  ESEMPIO DI PARTITA (log completo)")
	print("=".repeat(66))

	var state: BattleState = simulator.run_single(simulator.base_seed, true)

	print("")
	print("=".repeat(66))
	print("  STATO FINALE")
	print("=".repeat(66))
	print("  %s" % state.player_a.describe_state())
	print("  %s" % state.player_b.describe_state())
	print("  Turni totali: %d" % state.turn_number)
	if state.is_draw:
		print("  Esito: PAREGGIO")
	else:
		print("  Vincitore: %s" % state.winner.display_name)
	print("=".repeat(66))
