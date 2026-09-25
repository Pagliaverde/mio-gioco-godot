## L'IA che decide se pescare ancora o fermarsi.
##
## Serve al simulatore per capire se il "dilemma del rischio" esiste davvero.
## Se anche l'IA piu' intelligente non trova mai conveniente rischiare,
## o se rischia sempre e perde sempre, il bilanciamento e' sbagliato.
class_name SimAI extends RefCounted


## La strategia da usare.
var policy: CardTypes.AiPolicy = CardTypes.AiPolicy.ESTIMATED_RISK

## Soglia di mana per [code]STOP_AT_MANA[/code]: si ferma sotto questo valore.
var mana_threshold: int = 6

## Percentuale di mana per [code]STOP_AT_RATIO[/code]. 0.3 = fermati al 30%.
var mana_ratio: float = 0.3

## Rischio massimo accettato per [code]ESTIMATED_RISK[/code].
## 0.25 = pesca finche' la probabilita' di bust resta sotto il 25%.
var risk_tolerance: float = 0.25

## Tolleranza al rischio quando il colpo di grazia e' a portata.
##
## [b]E' cio' che farebbe un giocatore vero:[/b] se sei a un passo dal vincere,
## rischi tutto. Senza questo, l'IA si fermerebbe sempre in modo prudente e il
## bust non succederebbe mai, rendendo invisibile una meccanica centrale.
var lethal_risk_tolerance: float = 0.70


func _init(ai_policy: CardTypes.AiPolicy = CardTypes.AiPolicy.ESTIMATED_RISK) -> void:
	policy = ai_policy


## Crea una copia dell'IA (per usare la stessa configurazione in piu' partite).
func duplicate_ai() -> SimAI:
	var copy: SimAI = SimAI.new(policy)
	copy.mana_threshold = mana_threshold
	copy.mana_ratio = mana_ratio
	copy.risk_tolerance = risk_tolerance
	copy.lethal_risk_tolerance = lethal_risk_tolerance
	return copy


## Decide se pescare ancora.
## [param state] e' lo [BattleState] corrente: la decisione dipende dal mana
## rimasto e da cosa resta nel mazzo.
func should_continue(state: BattleState) -> bool:
	var player: BattlePlayer = state.active

	# Con zero mana non c'e' niente da fare.
	if player.mana <= 0:
		return false

	# Senza carte nel mazzo non si puo' pescare.
	if player.is_deck_empty():
		return false

	match policy:
		CardTypes.AiPolicy.NEVER_STOP:
			# Rischia sempre: e' il termine di paragone "sconsiderato".
			return true

		CardTypes.AiPolicy.STOP_AT_MANA:
			return player.mana > mana_threshold

		CardTypes.AiPolicy.STOP_AT_RATIO:
			var threshold: float = float(player.mana_at_turn_start) * mana_ratio
			return float(player.mana) > threshold

		CardTypes.AiPolicy.ESTIMATED_RISK:
			# Se il colpo di grazia e' a portata, alza la tolleranza: e' esattamente
			# cio' che farebbe un giocatore vero, e senza questo il bust non
			# succederebbe mai (l'IA prudente si fermerebbe sempre in tempo).
			var tolerance: float = risk_tolerance
			if lethal_pressure(state) >= 1.0:
				tolerance = lethal_risk_tolerance
			return bust_probability(state) <= tolerance

	return false


## Spiega, in italiano, su cosa si basa la decisione di adesso.
##
## [b]Serve a rendere leggibile il comportamento dell'avversario:[/b] senza
## spiegazione un'IA prudente sembra "rotta" invece che prudente. Guardando
## il limite e il rischio attuale si capisce subito perche' si ferma.
func explain_decision(state: BattleState) -> String:
	var player: BattlePlayer = state.active

	if player.mana <= 0:
		return "mana esaurito"
	if player.is_deck_empty():
		return "mazzo esaurito"

	match policy:
		CardTypes.AiPolicy.NEVER_STOP:
			return "rischia sempre, non si ferma mai"

		CardTypes.AiPolicy.STOP_AT_MANA:
			if player.mana > mana_threshold:
				return "%d mana, sopra la soglia di %d" % [player.mana, mana_threshold]
			return "%d mana, sotto la soglia di %d" % [player.mana, mana_threshold]

		CardTypes.AiPolicy.STOP_AT_RATIO:
			var ratio_threshold: int = int(float(player.mana_at_turn_start) * mana_ratio)
			return "%d mana, rispetto al %d%% di %d iniziali" % [
				player.mana, int(round(mana_ratio * 100.0)), ratio_threshold,
			]

		CardTypes.AiPolicy.ESTIMATED_RISK:
			var risk: int = int(round(bust_probability(state) * 100.0))
			if is_going_for_lethal(state):
				return "rischio %d%%, ma il colpo di grazia e' a portata (limite alzato al %d%%)" % [
					risk, int(round(lethal_risk_tolerance * 100.0)),
				]
			var limit: int = int(round(risk_tolerance * 100.0))
			if risk <= limit:
				return "rischio %d%%, entro il limite del %d%%" % [risk, limit]
			return "rischio %d%% OLTRE il limite del %d%%" % [risk, limit]

	return ""


## True se l'IA sta alzando la tolleranza perche' puo' chiudere la partita.
func is_going_for_lethal(state: BattleState) -> bool:
	if policy != CardTypes.AiPolicy.ESTIMATED_RISK:
		return false
	return lethal_pressure(state) >= 1.0


## La tolleranza al rischio valida in questo momento.
func current_tolerance(state: BattleState) -> float:
	if is_going_for_lethal(state):
		return lethal_risk_tolerance
	return risk_tolerance
##
## Ritorna un rapporto tra danno previsto e vita necessaria:
## 1.0 o piu' significa "il colpo di grazia e' a portata".
##
## La stima usa la potenza delle carte (che include anche scudo e cure),
## quindi e' approssimativa: serve solo a far ragionare l'IA come un umano,
## non a prevedere il danno esatto.
func lethal_pressure(state: BattleState) -> float:
	var player: BattlePlayer = state.active
	var defender: BattlePlayer = state.defender

	# Danno gia' schierato in questo turno.
	var committed: float = 0.0
	for instance: CardInstance in player.played:
		committed += instance.power_score()

	# Danno atteso da una carta in piu'.
	var expected_next: float = expected_damage_gain(state)

	# Moltiplicatori del turno (critico da bust + Potenziato).
	var multiplier: float = player.turn_damage_multiplier() * player.current_crit

	var projected: float = (committed + expected_next) * multiplier

	# Lo scudo assorbe parte del danno, quindi va contato nel totale da abbattere.
	var needed: float = float(defender.health + defender.shield)

	return projected / maxf(needed, 1.0)


## Stima la probabilita' di fare bust pescando un'altra carta.
##
## Calcola quanta parte del mazzo rimasto costa piu' del mana disponibile.
## E' la probabilita' esatta, perche' il mazzo e' l'unica fonte di casualita'.
func bust_probability(state: BattleState) -> float:
	var player: BattlePlayer = state.active
	if player.draw_pile.is_empty():
		return 0.0

	var too_expensive: int = 0
	for instance: CardInstance in player.draw_pile:
		if instance.get_cost() > player.mana:
			too_expensive += 1

	return float(too_expensive) / float(player.draw_pile.size())


## Quanto danno ci si aspetta di guadagnare pescando ancora.
## Serve a ragionare sul rapporto rischio/rendimento.
func expected_damage_gain(state: BattleState) -> float:
	var player: BattlePlayer = state.active
	if player.draw_pile.is_empty():
		return 0.0

	var total_power: float = 0.0
	var affordable: int = 0
	for instance: CardInstance in player.draw_pile:
		if instance.get_cost() <= player.mana:
			total_power += instance.power_score()
			affordable += 1

	if affordable == 0:
		return 0.0
	return total_power / float(player.draw_pile.size())


## Descrizione leggibile della strategia, per il report.
func describe() -> String:
	match policy:
		CardTypes.AiPolicy.NEVER_STOP:
			return "Non si ferma mai"
		CardTypes.AiPolicy.STOP_AT_MANA:
			return "Ferma sotto %d mana" % mana_threshold
		CardTypes.AiPolicy.STOP_AT_RATIO:
			return "Ferma sotto il %d%% del mana" % int(round(mana_ratio * 100.0))
		CardTypes.AiPolicy.ESTIMATED_RISK:
			return "Rischio max %d%%" % int(round(risk_tolerance * 100.0))
	return "?"


## Nome breve per le colonne della tabella.
func short_name() -> String:
	match policy:
		CardTypes.AiPolicy.NEVER_STOP:
			return "Mai stop"
		CardTypes.AiPolicy.STOP_AT_MANA:
			return "Soglia %d" % mana_threshold
		CardTypes.AiPolicy.STOP_AT_RATIO:
			return "%d%% mana" % int(round(mana_ratio * 100.0))
		CardTypes.AiPolicy.ESTIMATED_RISK:
			return "Rischio %d%%" % int(round(risk_tolerance * 100.0))
	return "?"


func _to_string() -> String:
	return "<SimAI %s>" % describe()
