## Il "foglio di calcolo" di un turno: raccoglie tutti gli effetti prima di applicarli.
##
## [b]Perche' esiste:[/b] nel tuo gioco l'ordine delle carte non conta, si somma
## tutto insieme a fine turno. Se ogni effetto applicasse subito il danno, l'ordine
## tornerebbe a contare (una cura giocata dopo un danno non salverebbe nessuno).
##
## Invece ogni effetto [i]accumula[/i] qui dentro, e solo alla fine
## [BattleState] applica il totale. Cosi' il risultato e' sempre lo stesso,
## qualunque sia l'ordine in cui hai giocato le carte.
##
## Contiene anche i moltiplicatori del turno: le sinergie e le carte di supporto
## (es. "Grido di battaglia: +25% danno") li scrivono qui, e vengono applicati
## a [b]tutte[/b] le carte giocate, non solo a quelle successive.
class_name EffectContext extends RefCounted


## Stato della battaglia in corso.
var state: BattleState

## Chi sta giocando questo turno (la fonte degli effetti).
var owner: BattlePlayer

## Chi subisce gli effetti.
var opponent: BattlePlayer

## La carta attualmente in esame (utile per i log e per effetti particolari).
var card: CardData

## Moltiplicatore globale applicato a tutto il danno del turno. 1.0 = nessun bonus.
var global_damage_multiplier: float = 1.0

## Moltiplicatori per singolo elemento (li scrivono le sinergie). Vuoto = tutti a 1.0.
var element_multipliers: Dictionary = {}

## Danno piatto aggiunto a tutto il danno del turno (da carte tipo "Focus").
var flat_damage_bonus: int = 0

## Strati extra aggiunti a [b]ogni[/b] status applicato questo turno.
##
## E' l'equivalente di [member flat_damage_bonus] per le carte di status:
## un amplificatore che rende piu' forti tutte le carte Veleno/Brucia del turno.
## Serve a dare ai mazzi ad attrito una carta di supporto, cosi' come i mazzi
## esplosivi hanno i moltiplicatori di danno.
##
## Funziona anche senza rispettare l'ordine: essendo tutto accumulato e
## applicato a fine turno, l'amplificatore vale per tutte le carte comunque.
var status_bonus: int = 0

# --- Accumulatori -------------------------------------------------------------

## Danno grezzo accumulato, per elemento: { CardTypes.Element: int }
var damage_by_element: Dictionary = {}

## Scudo che il giocatore guadagnera'.
var shield_to_gain: int = 0

## Vita che il giocatore recuperera'.
var health_to_heal: int = 0

## Danno che il giocatore infligge a se stesso (carte rischiose).
var self_damage: int = 0

## Status da applicare: array di { status, stacks, target_self }
var statuses_to_apply: Array[Dictionary] = []

## Righe di log generate durante la risoluzione.
var log: Array[String] = []


## Aggiunge danno di un certo elemento. Piu' chiamate si sommano.
func add_damage(amount: int, element: CardTypes.Element = CardTypes.Element.NONE) -> void:
	if amount <= 0:
		return
	damage_by_element[element] = damage_by_element.get(element, 0) + amount


## Aggiunge scudo da guadagnare.
func add_shield(amount: int) -> void:
	if amount > 0:
		shield_to_gain += amount


## Aggiunge cura.
func add_heal(amount: int) -> void:
	if amount > 0:
		health_to_heal += amount


## Aggiunge danno auto-inflitto.
func add_self_damage(amount: int) -> void:
	if amount > 0:
		self_damage += amount


## Mette in coda uno status. Se [param target_self] e' true va su chi gioca,
## altrimenti sull'avversario.
##
## Il bonus di [member status_bonus] viene sommato, ma [b]solo per gli status
## dannosi[/b] (Brucia, Veleno, Congelato): potenziare anche le cure gratuite
## sarebbe eccessivo.
func add_status(status: CardTypes.StatusType, stacks: int, target_self: bool = false) -> void:
	if stacks <= 0:
		return

	var final_stacks: int = stacks
	if status_bonus > 0 and not target_self:
		final_stacks += status_bonus

	statuses_to_apply.append({
		"status": status,
		"stacks": final_stacks,
		"target_self": target_self,
	})


## Moltiplica il danno di un elemento (usato dalle sinergie).
## Moltiplicatori successivi si moltiplicano tra loro.
func multiply_element_damage(element: CardTypes.Element, multiplier: float) -> void:
	if is_equal_approx(multiplier, 1.0):
		return
	var current: float = element_multipliers.get(element, 1.0)
	element_multipliers[element] = current * multiplier


## Moltiplica il danno di [b]tutti[/b] gli elementi.
func multiply_all_damage(multiplier: float) -> void:
	global_damage_multiplier *= multiplier


## Calcola il danno finale totale, applicando in ordine:
## 1. moltiplicatore per elemento (sinergie)
## 2. moltiplicatore globale
## 3. bonus piatto
func total_damage() -> int:
	var total: float = 0.0
	for raw_element: Variant in damage_by_element:
		var element: CardTypes.Element = raw_element
		var raw: float = float(damage_by_element[element])
		var element_multiplier: float = element_multipliers.get(element, 1.0)
		total += raw * element_multiplier

	total *= global_damage_multiplier
	total += float(flat_damage_bonus)

	return maxi(int(round(total)), 0)


## Dettaglio del danno per elemento, dopo i moltiplicatori.
## Ritorna [code]{ CardTypes.Element: int }[/code].
func damage_breakdown() -> Dictionary:
	var breakdown: Dictionary = {}
	for raw_element: Variant in damage_by_element:
		var element: CardTypes.Element = raw_element
		var raw: float = float(damage_by_element[element])
		var element_multiplier: float = element_multipliers.get(element, 1.0)
		var value: int = int(round(raw * element_multiplier * global_damage_multiplier))
		if value > 0:
			breakdown[element] = value
	return breakdown


## Quante carte di un dato elemento sono state giocate questo turno.
func count_played_of_element(element: CardTypes.Element) -> int:
	var count: int = 0
	for instance: CardInstance in owner.played:
		if instance.data != null and instance.data.element == element:
			count += 1
	return count


## Tutti gli elementi presenti tra le carte giocate questo turno.
func played_elements() -> Array:
	var found: Array = []
	for instance: CardInstance in owner.played:
		if instance.data == null:
			continue
		var element: CardTypes.Element = instance.data.element
		if not found.has(element):
			found.append(element)
	return found


## Aggiunge una riga al log della risoluzione.
func add_log(text: String) -> void:
	log.append(text)