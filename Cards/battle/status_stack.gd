## Strato di status attivo su un giocatore (Brucia, Veleno, ecc.).
class_name StatusStack extends RefCounted


## Quale status e'.
var status: CardTypes.StatusType = CardTypes.StatusType.BURN

## Quanti strati sono attivi. Piu' strati = effetto piu' forte.
var stacks: int = 0

## Quanti strati si perdono a ogni turno.
## 0 significa che lo status [b]non si esaurisce mai[/b] (e' il caso del Veleno).
var decay_per_turn: int = 1


func _init(status_type: CardTypes.StatusType = CardTypes.StatusType.BURN, amount: int = 0, decay: int = 1) -> void:
	status = status_type
	stacks = amount
	decay_per_turn = decay


## Aggiunge strati allo status esistente.
func add(amount: int) -> void:
	stacks += amount


## Consuma gli strati previsti dal decadimento e ritorna quanti ne restavano
## [b]prima[/b] del consumo (il valore da usare per l'effetto di questo turno).
func consume() -> int:
	var effective: int = stacks
	stacks = maxi(stacks - decay_per_turn, 0)
	return effective


## True se lo status non ha piu' effetto e va rimosso.
func is_expired() -> bool:
	return stacks <= 0


func _to_string() -> String:
	return "%s x%d" % [CardTypes.status_name(status), stacks]
