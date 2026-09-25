## Aggiunge un valore [b]piatto[/b] al danno di tutte le carte del turno.
##
## Diverso da [TurnDamageBuffEffect]: quello moltiplica (ottimo quando hai
## molte carte forti), questo somma (ottimo quando giochi tante carte deboli).
## Ecco due carte di supporto con identita' diverse.
class_name FlatDamageBonusEffect extends CardEffect


## Quanto danno piatto aggiungere a ciascuna carta del turno.
@export_range(-50, 50, 1) var amount: int = 3


func apply(ctx: EffectContext) -> void:
	ctx.flat_damage_bonus += amount


func describe() -> String:
	if amount >= 0:
		return "Questo turno: +%d danno a ogni carta" % amount
	return "Questo turno: %d danno a ogni carta" % amount


func power_score(_card: CardData) -> float:
	return float(amount) * 1.5
