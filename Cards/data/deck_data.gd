## Un mazzo completo, assegnabile a un giocatore o a un NPC.
##
## E' una [Resource], quindi la assegni direttamente nell'inspector di una
## scena (es. [code]SlimeNpc.tscn[/code]): ogni personaggio puo' avere il suo
## mazzo, esattamente come ha il suo file di dialogo.
##
## Il mazzo e' un [b]ciclo infinito[/b]: le carte giocate tornano nel mazzo,
## che viene rimescolato a fine turno. Un mazzo non si esaurisce mai davvero.
class_name DeckData extends Resource


## Nome mostrato nel menu' di deck building.
@export var display_name: String = "Nuovo mazzo"

## Le carte del mazzo, con le loro quantita'.
@export var entries: Array[DeckEntry] = []


## Numero totale di carte nel mazzo.
func card_count() -> int:
	var total: int = 0
	for entry: DeckEntry in entries:
		if entry != null and entry.card != null:
			total += entry.count
	return total


## Crea una [CardInstance] per ogni copia di ogni carta.
## Il risultato non e' ancora mescolato: usa [method BattlePlayer.reshuffle].
func build_instances() -> Array[CardInstance]:
	var instances: Array[CardInstance] = []
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue
		for _i: int in entry.count:
			instances.append(CardInstance.new(entry.card))
	return instances


## Quante copie di ogni elemento contiene il mazzo.
## Ritorna un dizionario [code]{ CardTypes.Element: int }[/code].
func element_counts() -> Dictionary:
	var counts: Dictionary = {}
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue
		var element: CardTypes.Element = entry.card.element
		counts[element] = counts.get(element, 0) + entry.count
	return counts


## Quante copie esistono di ogni costo. Serve all'IA per calcolare il rischio di bust.
## Ritorna un dizionario [code]{ int: int }[/code].
func cost_histogram() -> Dictionary:
	var histogram: Dictionary = {}
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue
		var cost: int = entry.card.cost
		histogram[cost] = histogram.get(cost, 0) + entry.count
	return histogram


## Costo medio delle carte del mazzo. Utile per un controllo rapido del bilanciamento.
func average_cost() -> float:
	var total_cost: int = 0
	var total_cards: int = 0
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue
		total_cost += entry.card.cost * entry.count
		total_cards += entry.count
	if total_cards == 0:
		return 0.0
	return float(total_cost) / float(total_cards)


## Il costo piu' alto presente nel mazzo.
##
## [b]E' il numero chiave del rischio:[/b] finche' hai piu' mana di cosi',
## non puoi fare bust. Piu' e' alto, prima entra in gioco la zona di rischio.
func highest_cost() -> int:
	var highest: int = 0
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue
		highest = maxi(highest, entry.card.cost)
	return highest


## Il costo piu' basso presente nel mazzo.
func lowest_cost() -> int:
	var lowest: int = 999
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue
		lowest = mini(lowest, entry.card.cost)
	return lowest if lowest != 999 else 0


## Quanto mana puoi spendere in totale senza nessun rischio di bust.
##
## Con carte fino a 9 mana, puoi spenderne 8 senza rischi: il nono mana
## e' il primo che puo' farti pescare una carta troppo cara.
func safe_spending_budget() -> int:
	return maxi(highest_cost() - 1, 0)


## Probabilita' di fare bust con un certo mana disponibile.
##
## E' semplicemente la frazione del mazzo che costa piu' di quel mana.
## Essendo il mazzo l'unica fonte di casualita', questo valore e' esatto.
func bust_probability_at(mana: int) -> float:
	var total: int = card_count()
	if total == 0:
		return 0.0

	var too_expensive: int = 0
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue
		if entry.card.cost > mana:
			too_expensive += entry.count

	return float(too_expensive) / float(total)


## Il "profilo di rischio" del mazzo in un singolo numero: la probabilita'
## media di bust lungo un turno che parte con [param mana_start] mana.
##
## Confronta questo valore tra mazzi diversi:
## - sotto 10% = mazzo prudente, raramente fa bust
## - 15-25% = mazzo avido, rischia spesso
## - sopra 30% = mazzo temerario, il bust sara' frequente
func average_risk(mana_start: int) -> float:
	if mana_start <= 0:
		return 1.0

	var total: float = 0.0
	for mana: int in range(mana_start, -1, -1):
		total += bust_probability_at(mana)

	return total / float(mana_start + 1)


## Efficienza media del mazzo: potenza per punto di mana.
##
## [b]E' la ricompensa del rischio.[/b] Un mazzo con carte costose deve avere
## un valore piu' alto di uno prudente, altrimenti nessuno rischierebbe mai.
## Se il mazzo avido non e' piu' efficiente, le carte costose servono a nulla.
func average_efficiency() -> float:
	var total: float = 0.0
	var weight: int = 0

	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue

		var instance: CardInstance = CardInstance.new(entry.card)
		var cost: float = maxf(float(entry.card.cost), 1.0)
		total += (instance.power_score() / cost) * float(entry.count)
		weight += entry.count

	if weight == 0:
		return 0.0
	return total / float(weight)


## Potenza totale stimata del mazzo (somma di tutte le copie).
func total_power() -> float:
	var total: float = 0.0
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			continue
		var instance: CardInstance = CardInstance.new(entry.card)
		total += instance.power_score() * float(entry.count)
	return total


## Quante carte di ogni costo, ordinate dal piu' economico.
## Ritorna un array di [code]{ cost, count, risk_at }[/code].
func cost_spread(mana_start: int) -> Array:
	var histogram: Dictionary = cost_histogram()
	var costs: Array = histogram.keys()
	costs.sort()

	var result: Array = []
	for cost: Variant in costs:
		result.append({
			"cost": cost,
			"count": histogram[cost],
			"probability": bust_probability_at(cost),
			"risky": cost >= mana_start,
		})
	return result


## Un'etichetta che descrive il carattere del mazzo.
func risk_archetype(mana_start: int) -> String:
	var risk: float = average_risk(mana_start)
	if risk < 0.10:
		return "prudente"
	elif risk < 0.20:
		return "equilibrato"
	elif risk < 0.30:
		return "avido"
	return "temerario"


## Verifica veloce che il mazzo sia giocabile.
## Ritorna un array di problemi (vuoto = tutto ok).
func validate() -> PackedStringArray:
	var problems: PackedStringArray = []

	if card_count() == 0:
		problems.append("Il mazzo non contiene nessuna carta.")

	var seen_ids: Dictionary = {}
	for entry: DeckEntry in entries:
		if entry == null or entry.card == null:
			problems.append("Una riga del mazzo non ha una carta assegnata.")
			continue
		if entry.card.id == &"":
			problems.append("La carta '%s' non ha un id." % entry.card.display_name)
		elif seen_ids.has(entry.card.id):
			pass  # Duplicato voluto: piu' copie della stessa carta sono normali.
		else:
			seen_ids[entry.card.id] = true

	return problems


func _to_string() -> String:
	return "<DeckData %s, %d carte, costo medio %.1f>" % [display_name, card_count(), average_cost()]
