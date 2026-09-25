## Guadagni scudo.
##
## Lo scudo fa due cose (vedi [BattleBalance]):
## 1. riduce in percentuale i danni subiti
## 2. assorbe il danno rimanente, consumandosi
##
## Lo scudo che non viene consumato [b]resta[/b] anche nei turni successivi,
## quindi accumulare difesa e' una strategia legittima.
class_name GainShieldEffect extends CardEffect


## Quanto scudo guadagni.
@export_range(0, 100, 1) var amount: int = 5


func apply(ctx: EffectContext) -> void:
	ctx.add_shield(amount)


func describe() -> String:
	return "Guadagni %d scudo" % amount


## Lo scudo vale meno del danno, altrimenti nessuno attaccherebbe mai.
const POWER_RATIO: float = 0.5


## Uno scudo vale la meta' di un punto di danno.
## Se questo rapporto non e' minore di 1, la strategia "accumulo scudo"
## diventa dominante e il gioco si blocca. Il simulatore controlla che non accada.
func power_score(_card: CardData) -> float:
	return float(amount) * POWER_RATIO
