## Applica uno status (Brucia, Veleno, Congelato, Potenziato, Rigenerazione).
##
## Il comportamento di ogni status nel tempo e' deciso da [BattleBalance]:
## alcuni si affievoliscono, altri (come il Veleno) si accumulano per sempre.
class_name ApplyStatusEffect extends CardEffect


## Quale status applicare.
@export var status: CardTypes.StatusType = CardTypes.StatusType.BURN

## Quanti "strati" (stack) applicare. Piu' stack = effetto piu' forte.
@export_range(1, 50, 1) var stacks: int = 2

## Se true lo status va su di te (es. Rigenerazione, Potenziato),
## altrimenti sull'avversario (es. Brucia, Veleno, Congelato).
@export var to_self: bool = false


func apply(ctx: EffectContext) -> void:
	ctx.add_status(status, stacks, to_self)


func describe() -> String:
	var target: String = "te stesso" if to_self else "l'avversario"
	return "Applica %d %s a %s" % [stacks, CardTypes.status_name(status), target]


## Il Veleno vale di piu' perche' non si affievolisce; il Congelato e' situazionale.
func power_score(_card: CardData) -> float:
	var value_per_stack: float
	match status:
		CardTypes.StatusType.POISON:
			value_per_stack = 2.0
		CardTypes.StatusType.BURN:
			value_per_stack = 1.5
		CardTypes.StatusType.CHILL:
			value_per_stack = 2.5
		CardTypes.StatusType.EMPOWER:
			value_per_stack = 2.0
		CardTypes.StatusType.REGEN:
			value_per_stack = 1.2
		_:
			value_per_stack = 1.0
	return float(stacks) * value_per_stack
