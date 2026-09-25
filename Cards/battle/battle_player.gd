## Un combattente: il giocatore o un NPC.
##
## Contiene [b]solo dati e regole[/b], nessun nodo e nessuna grafica.
## Cosi' il simulatore puo' far girare migliaia di partite in pochi secondi
## e possiamo bilanciare il gioco prima ancora di disegnare una carta.
##
## [b]Ciclo di un turno:[/b]
## 1. [method begin_turn] - recupera mana e applica gli status
## 2. [method draw_card] ripetuto finche' non dici STOP o fai bust
## 3. La risoluzione viene fatta da [BattleState]
## 4. [method end_turn_cleanup] - il mana resta, il resto si azzera
class_name BattlePlayer extends RefCounted


## Nome mostrato nei log.
var display_name: String = "Giocatore"

## La configurazione dei numeri del gioco (condivisa da entrambi i giocatori).
var balance: BattleBalance

## Il mazzo, come definito nell'inspector.
var deck: DeckData

## Livello del giocatore: determina il mana base (meta-progressione permanente).
var level: int = 1

# --- Vita e difesa -----------------------------------------------------------

var max_health: int = 60
var health: int = 60

## Scudo accumulato: riduce i danni in percentuale e ne assorbe una parte.
## [b]Non si azzera a fine turno[/b]: accumulare difesa e' una strategia.
var shield: int = 0

## Vita massima effettivamente recuperabile in una battaglia (per le statistiche).
var total_healed: int = 0

# --- Mana --------------------------------------------------------------------

var mana: int = 0

## Mana con cui hai iniziato il turno, serve a misurare il rischio e il mana sprecato.
var mana_at_turn_start: int = 0

## Quanto mana hai speso in totale nella battaglia.
var total_mana_spent: int = 0

# --- Carte -------------------------------------------------------------------

## Il mazzo da cui pescare (si rimescola, non si esaurisce mai).
var draw_pile: Array[CardInstance] = []

## Le carte giocate questo turno. A fine turno tornano nel mazzo.
var played: Array[CardInstance] = []

# --- Status ------------------------------------------------------------------

## Status attivi: [code]{ CardTypes.StatusType: StatusStack }[/code]
var statuses: Dictionary = {}

# --- Stato del turno ---------------------------------------------------------

## Critico accumulato (l'avversario ha fatto bust). Si consuma al primo turno utile.
var pending_crit: float = 1.0

## Il critico effettivo di [b]questo[/b] turno. Viene fissato in [method begin_turn]
## e usato al momento della risoluzione.
var current_crit: float = 1.0

## Bonus di danno percentuale derivato dallo status Potenziato.
var turn_damage_percent: float = 0.0

# --- Statistiche per il simulatore -------------------------------------------

var bust_count: int = 0
var turns_taken: int = 0

## Danno che e' effettivamente arrivato alla vita dell'avversario.
var total_damage_dealt: int = 0

## Danno da status (Brucia, Veleno) inflitto a se stessi.
##
## [b]Va contato a parte perche' non passa da [method take_damage][/b]: ignora
## lo scudo, quindi non appaiono ne' nel danno inflitto ne' in quello assorbito.
## Senza questa voce il Veleno sembrava molto piu' debole di quanto fosse,
## e la causa principale dello squilibrio restava invisibile nei report.
var total_status_damage: int = 0

## Danno lordo inviato all'avversario, prima di riduzioni e assorbimento.
var total_raw_damage: int = 0

## Quanto del danno inviato e' stato assorbito dallo scudo avversario.
var total_absorbed: int = 0

var total_shield_gained: int = 0
var cards_played: int = 0
var stopped_turns: int = 0


## Prepara il giocatore per una battaglia.
func setup(owner_name: String, player_deck: DeckData, config: BattleBalance, player_level: int = 1) -> void:
	display_name = owner_name
	deck = player_deck
	balance = config
	level = player_level

	max_health = config.starting_health
	health = max_health

	level = maxi(level, 1)


## Mette il mazzo in gioco e lo mescola. Chiamato una volta a inizio battaglia.
func start_battle(rng: BattleRNG) -> void:
	draw_pile = deck.build_instances() if deck != null else []
	played = []
	statuses = {}
	shield = 0
	health = max_health
	mana = 0

	bust_count = 0
	turns_taken = 0
	total_damage_dealt = 0
	total_status_damage = 0
	total_raw_damage = 0
	total_absorbed = 0
	total_shield_gained = 0
	cards_played = 0
	stopped_turns = 0
	total_mana_spent = 0
	total_healed = 0

	reshuffle(rng)


## Rimette tutte le carte giocate nel mazzo e lo rimescola.
## E' cio' che rende il mazzo un ciclo infinito: nessuna carta viene mai persa.
func reshuffle(rng: BattleRNG) -> void:
	for instance: CardInstance in played:
		instance.reset_for_new_turn()
		draw_pile.append(instance)
	played.clear()

	rng.shuffle(draw_pile)


## Inizia il turno: recupera mana e applica gli status che ti riguardano.
## Ritorna un riassunto di cosa e' successo (per i log e la UI).
func begin_turn(rng: BattleRNG) -> Dictionary:
	turns_taken += 1
	turn_damage_percent = 0.0

	# Il critico si applica al turno in cui lo si e' guadagnato, poi sparisce.
	var crit_this_turn: float = pending_crit
	pending_crit = 1.0
	current_crit = crit_this_turn

	# 1. Gli status fanno effetto [b]prima[/b] di giocare.
	var status_report: Dictionary = _tick_statuses()

	# 2. Mana del turno: base dal livello + bonus casuale, meno il congelamento.
	var base_mana: int = balance.mana_for_level(level)
	var bonus: int = rng.range_int(balance.mana_bonus_min, balance.mana_bonus_max)
	var chill_penalty: int = status_report.get("chill_penalty", 0)

	mana = maxi(base_mana + bonus - chill_penalty, 0)
	mana_at_turn_start = mana

	return {
		"player": self,
		"turn": turns_taken,
		"mana_base": base_mana,
		"mana_bonus": bonus,
		"chill_penalty": chill_penalty,
		"mana": mana,
		"crit": crit_this_turn,
		"status_report": status_report,
	}


## True se il giocatore puo' pagare questa carta.
func can_afford(cost: int) -> bool:
	return cost <= mana


## Pesca la carta in cima al mazzo. Ritorna null se non c'e' nulla da pescare.
func draw_card() -> CardInstance:
	if draw_pile.is_empty():
		return null
	return draw_pile.pop_back()


## True se non ci sono piu' carte da pescare.
func is_deck_empty() -> bool:
	return draw_pile.is_empty()


## Prova a giocare una carta. Ritorna true se e' stata giocata.
## [b]Non tocca il mazzo[/b]: se la carta non si puo' pagare, il chiamante
## deve gestire il bust.
func play_card(instance: CardInstance) -> bool:
	var cost: int = instance.get_cost()
	if not can_afford(cost):
		return false

	mana -= cost
	total_mana_spent += cost
	played.append(instance)
	cards_played += 1
	return true


## Quante carte di questo elemento hai giocato questo turno.
func played_count_of_element(element: CardTypes.Element) -> int:
	var count: int = 0
	for instance: CardInstance in played:
		if instance.data != null and instance.data.element == element:
			count += 1
	return count


## Quanto mana ti e' rimasto (diventera' scudo a fine turno).
func leftover_mana() -> int:
	return mana


# --- Danno e cura ------------------------------------------------------------

## La riduzione percentuale che lo scudo applica ai danni in arrivo.
##
## Non consuma lo scudo: e' la parte "difesa passiva", che vale anche contro
## il danno da status.
func shield_reduction() -> float:
	return minf(
		float(shield) * balance.shield_percent_reduction_per_point,
		balance.shield_max_percent_reduction
	)


## Quanto danno passa dopo la riduzione percentuale dello scudo.
##
## [b]Nota:[/b] usato sia per il danno diretto sia per quello da status.
## Il danno da status [b]non consuma[/b] lo scudo (altrimenti Brucia e Veleno
## lo azzererebbero in un turno), ma ne subisce la riduzione: cosi' la difesa
## resta utile anche contro gli status invece di essere inutile.
func reduce_by_shield(amount: int) -> int:
	if amount <= 0:
		return 0
	return maxi(int(ceil(float(amount) * (1.0 - shield_reduction()))), 0)


## Applica danno in ingresso seguendo la pipeline:
## 1. riduzione percentuale data dallo scudo
## 2. assorbimento piatto consumando lo scudo
## 3. il resto va sulla vita
##
## Ritorna il dettaglio del calcolo (utile per i log e per capire il bilanciamento).
func take_damage(raw_amount: int) -> Dictionary:
	if raw_amount <= 0:
		return {"raw": 0, "reduction_percent": 0.0, "after_reduction": 0, "absorbed": 0, "to_health": 0}

	# 1. Lo scudo riduce i danni in percentuale (non si consuma per questo).
	var reduction: float = shield_reduction()
	var after_reduction: int = reduce_by_shield(raw_amount)

	# 2. Lo scudo assorbe il danno rimanente e si consuma.
	var absorbed: int = mini(shield, after_reduction)
	shield -= absorbed

	# 3. Il resto va sulla vita.
	var to_health: int = after_reduction - absorbed
	health = maxi(health - to_health, 0)

	return {
		"raw": raw_amount,
		"reduction_percent": reduction,
		"after_reduction": after_reduction,
		"absorbed": absorbed,
		"to_health": to_health,
	}


## Recupera vita, senza superare il massimo. Ritorna quanta ne hai recuperata davvero.
func heal(amount: int) -> int:
	if amount <= 0:
		return 0
	var before: int = health
	health = mini(health + amount, max_health)
	var healed: int = health - before
	total_healed += healed
	return healed


## Aggiunge scudo e aggiorna le statistiche.
func add_shield(amount: int) -> void:
	if amount <= 0:
		return
	shield += amount
	total_shield_gained += amount


## True se il giocatore e' a terra.
func is_defeated() -> bool:
	return health <= 0


# --- Status ------------------------------------------------------------------

## Aggiunge strati a uno status.
func add_status(status: CardTypes.StatusType, stacks: int) -> void:
	if stacks <= 0:
		return
	if statuses.has(status):
		(statuses[status] as StatusStack).add(stacks)
	else:
		statuses[status] = StatusStack.new(status, stacks, balance.decay_for_status(status))


## Quanti strati di uno status sono attivi (0 se assente).
func get_status_stacks(status: CardTypes.StatusType) -> int:
	if statuses.has(status):
		return (statuses[status] as StatusStack).stacks
	return 0


## Applica tutti gli status attivi. Ritorna un riassunto numerico.
##
## Ordine: prima il danno (Brucia, Veleno), poi il Congelato (che riduce il mana),
## poi cio' che ti aiuta (Rigenerazione, Potenziato).
func _tick_statuses() -> Dictionary:
	var report: Dictionary = {
		"burn_damage": 0,
		"poison_damage": 0,
		"regen_heal": 0,
		"chill_penalty": 0,
		"empower_percent": 0,
		"expired": [],
	}

	# Il danno da status subisce la riduzione percentuale dello scudo ma
	# [b]non lo consuma[/b]. Senza la riduzione, Brucia e Veleno renderebbero
	# inutile tutta la difesa: era la causa principale dello squilibrio.
	var damaging_statuses: Array = [CardTypes.StatusType.BURN, CardTypes.StatusType.POISON]
	for raw_status: Variant in damaging_statuses:
		var status: CardTypes.StatusType = raw_status
		if not statuses.has(status):
			continue
		var stack: StatusStack = statuses[status]
		var effective: int = stack.consume()
		var dealt: int = reduce_by_shield(effective)
		health = maxi(health - dealt, 0)
		total_status_damage += dealt
		if status == CardTypes.StatusType.BURN:
			report["burn_damage"] = dealt
		else:
			report["poison_damage"] = dealt

	# Congelato: ti toglie mana per questo turno.
	if statuses.has(CardTypes.StatusType.CHILL):
		var chill: StatusStack = statuses[CardTypes.StatusType.CHILL]
		report["chill_penalty"] = chill.consume()

	# Rigenerazione: cura.
	if statuses.has(CardTypes.StatusType.REGEN):
		var regen: StatusStack = statuses[CardTypes.StatusType.REGEN]
		var regen_amount: int = regen.consume()
		report["regen_heal"] = heal(regen_amount)

	# Potenziato: bonus percentuale al danno, valido per tutto il turno.
	if statuses.has(CardTypes.StatusType.EMPOWER):
		var empower: StatusStack = statuses[CardTypes.StatusType.EMPOWER]
		turn_damage_percent = float(empower.consume())
		report["empower_percent"] = int(turn_damage_percent)

	# Rimuove gli status esauriti.
	var to_remove: Array = []
	for raw_key: Variant in statuses:
		var key: CardTypes.StatusType = raw_key
		if (statuses[key] as StatusStack).is_expired():
			to_remove.append(key)
			report["expired"].append(key)
	for raw_key: Variant in to_remove:
		var key: CardTypes.StatusType = raw_key
		statuses.erase(key)

	return report


## Il moltiplicatore definitivo del turno: critico da bust + Potenziato.
func turn_damage_multiplier() -> float:
	return (1.0 + turn_damage_percent / 100.0)


## Un riassunto compatto dello stato, per i log.
func describe_state() -> String:
	var parts: PackedStringArray = []
	parts.append("%s: %d/%d HP" % [display_name, health, max_health])
	if shield > 0:
		parts.append("%d scudo" % shield)
	if mana > 0:
		parts.append("%d mana" % mana)
	if not statuses.is_empty():
		var status_parts: PackedStringArray = []
		for raw_key: Variant in statuses:
			status_parts.append(str(statuses[raw_key]))
		parts.append(", ".join(status_parts))
	return " | ".join(parts)


func _to_string() -> String:
	return "<BattlePlayer %s %d/%dHP %dM>" % [display_name, health, max_health, mana]
