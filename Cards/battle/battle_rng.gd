## Ritorna sempre lo stesso risultato a parita' di seme.
##
## E' il motivo per cui una partita puo' essere riprodotta esattamente:
## se il simulatore trova un numero "strano", con lo stesso seme puoi
## rivedere quella identica partita e capire cosa e' successo.
##
## [b]Questa e' l'unica fonte di casualita' del gioco[/b]: gli effetti delle
## carte hanno valori fissi, quindi tutto il resto e' deterministico.
class_name BattleRNG extends RefCounted


## Il seme usato per questa battaglia. Salvalo nei log per riprodurre la partita.
var seed_value: int = 0

var _rng: RandomNumberGenerator


func _init(battle_seed: int = 0) -> void:
	if battle_seed == 0:
		battle_seed = randi()
	seed_value = battle_seed
	_rng = RandomNumberGenerator.new()
	_rng.seed = battle_seed


## Numero intero tra [param from] e [param to] (inclusi).
func range_int(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


## Numero decimale tra [param from] e [param to].
func range_float(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


## True con la probabilita' indicata (0.0 - 1.0).
func chance(probability: float) -> bool:
	return _rng.randf() < probability


## Mescola l'array sul posto. E' l'unica cosa che serve per la "fortuna nel pescare".
func shuffle(array: Array) -> void:
	# Fisher-Yates manuale: cosi' il risultato dipende solo dal nostro seme.
	for i: int in range(array.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp


## Sceglie un elemento a caso da un array.
func pick(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[_rng.randi_range(0, array.size() - 1)]


func _to_string() -> String:
	return "<BattleRNG seed=%d>" % seed_value
