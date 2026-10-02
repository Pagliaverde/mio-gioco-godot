## Verifica rapida delle maschere, senza finestra.
##
## Fa giocare l'IA contro se stessa con ogni maschera addosso e controlla che
## le regole dell'azzardo scattino davvero: perdono, riflesso, guardia,
## inganno, presagio, catarsi, gabbia.
##
## [b]Come si usa:[/b]
## [codeblock]
## godot --headless --path . --script res://Cards/tools/check_masks.gd
## [/codeblock]
## Esce con codice 1 se qualcosa non torna.
extends SceneTree


var _failures: PackedStringArray = []


func _init() -> void:
	_check_library()
	_check_gambits()

	if _failures.is_empty():
		print("[check_masks] OK: tutte le maschere funzionano.")
		quit(0)
	else:
		for failure: String in _failures:
			print("[check_masks] ERRORE: %s" % failure)
		quit(1)


func _expect(condition: bool, what: String) -> void:
	if not condition:
		_failures.append(what)


func _check_library() -> void:
	var masks: Array[MaskData] = MaskLibrary.build_all()
	_expect(masks.size() == 9, "attese 9 maschere, trovate %d" % masks.size())
	var seen: Dictionary = {}
	for mask: MaskData in masks:
		_expect(mask.id != &"", "maschera senza id: %s" % mask.display_name)
		_expect(not seen.has(mask.id), "id duplicato: %s" % mask.id)
		seen[mask.id] = true
		if mask.replaces_synergies():
			_expect(not mask.synergies.is_empty(), "%s ha affinita' ma nessuna sinergia" % mask.display_name)
	_expect(MaskLibrary.chest_masks().size() == 4, "i bauli devono contenere 4 maschere")
	_expect(MaskLibrary.find_by_id(&"tutte") != null, "manca la maschera Tutte")


## Gioca una partita completa con l'IA da entrambi i lati.
func _play(mask_a: MaskData, mask_b: MaskData, battle_seed: int, cage: int = 0) -> Dictionary:
	var balance: BattleBalance = BattleBalance.create_default()
	var state: BattleState = BattleState.new()
	state.setup(balance, CardLibrary.build_starter_deck(), CardLibrary.build_veteran_deck(),
		CardLibrary.build_synergies(), battle_seed, "A", "B")
	state.set_masks(mask_a, mask_b)
	state.player_b.cage_strength = cage

	var counters: Dictionary = {"forgiven": 0, "busted": 0, "peeked": 0, "lines": 0}
	state.forgiven.connect(func(_i: CardInstance) -> void: counters["forgiven"] += 1)
	state.busted.connect(func(_i: CardInstance) -> void: counters["busted"] += 1)
	state.message.connect(func(_t: String) -> void: counters["lines"] += 1)

	# Un'IA spericolata fa bust spesso: serve per vedere le regole scattare.
	var ai: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
	ai.risk_tolerance = 0.6
	ai.lethal_risk_tolerance = 0.9

	state.start()
	var safety: int = 5000
	while not state.is_finished() and safety > 0:
		safety -= 1
		if state.peek_next_card() != null:
			counters["peeked"] += 1
		if ai.should_continue(state):
			state.draw_and_play()
		else:
			state.stop_turn()
	_expect(safety > 0, "partita infinita con %s / %s" % [mask_a, mask_b])

	counters["state"] = state
	counters["log"] = "\n".join(state.log)
	return counters


func _check_gambits() -> void:
	# Perdono: con la Commedia addosso i bust perdonati devono esserci.
	var comedy: Dictionary = _play(MaskLibrary.comedy(), null, 11)
	_expect(comedy["forgiven"] > 0, "la Commedia non ha perdonato nessun bust")

	# Essere Amato: al massimo un perdono per incontro, per giocatore.
	var beloved: Dictionary = _play(MaskLibrary.beloved(), null, 12)
	_expect(beloved["forgiven"] <= 1, "l'Essere Amato ha perdonato %d volte" % beloved["forgiven"])

	# Tragedia: il critico diventa x3. Cerchiamo un seme in cui succede un bust.
	var tragedy: Dictionary = {}
	for battle_seed: int in range(13, 40):
		tragedy = _play(MaskLibrary.tragedy(), null, battle_seed)
		if tragedy["busted"] > 0:
			break
	_expect(tragedy["busted"] > 0, "nessun bust in 27 partite: impossibile verificare la Tragedia")
	if tragedy["busted"] > 0:
		_expect((tragedy["log"] as String).contains("CRITICO x3.0"), "la Tragedia non ha dato il critico x3")

	# Presagio: la prossima carta si vede.
	var omen: Dictionary = _play(MaskLibrary.omen(), null, 14)
	_expect(omen["peeked"] > 0, "il Presagio non mostra la prossima carta")
	var blind: Dictionary = _play(null, null, 14)
	_expect(blind["peeked"] == 0, "senza maschera la prossima carta non deve vedersi")

	# Specchio: le carte riflesse costano meno.
	var mirror: Dictionary = _play(MaskLibrary.mirror(), null, 15)
	_expect((mirror["log"] as String).contains("RIFLESSO"), "lo Specchio non ha riflesso nulla")

	# Dovere: la guardia regge una volta.
	var duty: Dictionary = _play(MaskLibrary.duty(), null, 16)
	_expect((duty["log"] as String).contains("GUARDIA"), "il Dovere non ha retto nessun colpo")

	# Inganno: lo scudo raddoppia.
	var deceit: Dictionary = _play(MaskLibrary.deceit(), null, 17)
	_expect((deceit["log"] as String).contains("INGANNO"), "l'Inganno non ha raddoppiato lo scudo")

	# Gabbia: il mana del giocatore viene tagliato.
	var caged: Dictionary = _play(null, MaskLibrary.duty(), 18, 10)
	_expect((caged["log"] as String).contains("gabbia"), "la gabbia non ha tolto mana")

	# Tutte: ogni regola buona attiva, e la partita finisce lo stesso.
	var everything: Dictionary = _play(MaskLibrary.all_masks(), MaskLibrary.all_masks(), 19)
	_expect(everything["peeked"] > 0, "Tutte non mostra la prossima carta")

	# Determinismo: stesso seme, stessa partita.
	var first: Dictionary = _play(MaskLibrary.tragedy(), MaskLibrary.comedy(), 21)
	var second: Dictionary = _play(MaskLibrary.tragedy(), MaskLibrary.comedy(), 21)
	_expect(first["log"] == second["log"], "la stessa partita con lo stesso seme e' diversa")

	print("[check_masks] Commedia: %d perdoni, %d bust | Essere Amato: %d perdoni | Tragedia: %d bust" % [
		comedy["forgiven"], comedy["busted"], beloved["forgiven"], tragedy["busted"],
	])
