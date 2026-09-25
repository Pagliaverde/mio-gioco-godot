## Una singola copia di una carta durante una battaglia.
##
## Pensa a [CardData] come al "progetto" e a [CardInstance] come alla "carta
## fisica" che sta sul tavolo. Se il tuo mazzo ha 3 copie di Inferno, esiste
## [b]un solo[/b] [CardData] ma [b]tre[/b] [CardInstance].
##
## Questo e' cio' che permette di avere modificatori per singola copia
## (buff, sconti, "questa carta vale doppio") senza rovinare le altre copie.
class_name CardInstance extends RefCounted


## Contatore globale, serve a dare un id unico a ogni istanza.
static var _next_id: int = 1


## Identificativo unico di questa copia (non si ripete mai).
var instance_id: int = 0

## La definizione della carta. Non modificarla mai.
var data: CardData

## Sconto sul costo, applicato solo a questa copia (buff temporanei).
var cost_modifier: int = 0

## Quante volte e' stata giocata in questa battaglia (per statistiche).
var times_played: int = 0


func _init(card_data: CardData = null) -> void:
	instance_id = _next_id
	_next_id += 1
	data = card_data


## Il costo effettivo da pagare ora.
func get_cost() -> int:
	if data == null:
		return 0
	return maxi(data.cost + cost_modifier, 0)


## L'elemento della carta (o [code]NONE[/code] se non e' definita).
func get_element() -> CardTypes.Element:
	return data.element if data != null else CardTypes.Element.NONE


## Il nome da mostrare.
func get_display_name() -> String:
	return data.display_name if data != null else "Carta sconosciuta"


## Applica tutti gli effetti della carta al contesto di risoluzione.
func apply_effects(ctx: EffectContext) -> void:
	if data == null:
		return
	times_played += 1
	for effect: CardEffect in data.effects:
		if effect != null:
			effect.apply(ctx)


## Somma degli effetti della carta, per stimare quanto "vale" in mana.
## Il simulatore la usa per trovare il rapporto danno/mana ideale.
func power_score() -> float:
	if data == null:
		return 0.0
	var total: float = 0.0
	for effect: CardEffect in data.effects:
		if effect != null:
			total += effect.power_score(data)
	return total


## Rapporto potenza/costo. Sopra 1.5 = carta efficiente.
func efficiency() -> float:
	var cost: int = get_cost()
	if cost <= 0:
		return 0.0
	return power_score() / float(cost)


## Azzera lo stato della copia a fine turno (le carte tornano nel mazzo).
func reset_for_new_turn() -> void:
	cost_modifier = 0


func _to_string() -> String:
	return "<CardInstance #%d %s>" % [instance_id, get_display_name()]
