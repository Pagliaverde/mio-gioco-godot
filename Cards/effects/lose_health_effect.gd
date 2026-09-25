## Ti fai danno da solo.
##
## Serve per le "carte rischiose" che [b]pagano poco mana[/b] ma hanno un prezzo
## in vita. Sono quelle che rendono interessante decidere se rischiare.
class_name LoseHealthEffect extends CardEffect


## Quanta vita perdi.
@export_range(0, 100, 1) var amount: int = 3


func apply(ctx: EffectContext) -> void:
	ctx.add_self_damage(amount)


func describe() -> String:
	return "Perdi %d vita" % amount


## E' un costo, quindi contribuisce negativamente alla potenza della carta.
func power_score(_card: CardData) -> float:
	return -float(amount) * 1.0
