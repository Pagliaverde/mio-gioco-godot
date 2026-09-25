## Recuperi vita.
##
## La cura arriva sempre [b]dopo[/b] il danno nel calcolo del turno, quindi
## curarsi non ti salva da un colpo letale micidiale nello stesso turno:
## e' una scelta strategica, non un pulsante di emergenza.
class_name HealEffect extends CardEffect


## Quanta vita recuperi.
@export_range(0, 200, 1) var amount: int = 8


func apply(ctx: EffectContext) -> void:
	ctx.add_heal(amount)


func describe() -> String:
	return "Recuperi %d vita" % amount


## Curarsi vale meno che fare danno: non fa avanzare la partita.
const POWER_RATIO: float = 0.6


func power_score(_card: CardData) -> float:
	return float(amount) * POWER_RATIO
