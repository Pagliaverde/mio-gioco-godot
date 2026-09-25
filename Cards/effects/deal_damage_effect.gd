## Infligge danno diretto all'avversario.
##
## Passa dal calcolo del turno, quindi beneficia automaticamente di:
## - sinergie di elemento (es. "3+ carte Fuoco: +50% danno Fuoco")
## - carte di supporto (es. "Grido di battaglia: +25% danno")
## - critico da bust dell'avversario
class_name DealDamageEffect extends CardEffect


## Quanto danno infligge, [b]prima[/b] dei moltiplicatori.
@export_range(0, 100, 1) var amount: int = 5

## Elemento del danno. Se cambia dall'elemento della carta, serve a creare
## carte "miste" (es. una carta Fuoco che fa anche danno Ghiaccio).
## Lascialo a [code]NONE[/code] per usare l'elemento della carta.
@export var element_override: CardTypes.Element = CardTypes.Element.NONE


## L'elemento effettivo del danno.
func resolve_element(card: CardData) -> CardTypes.Element:
	if element_override != CardTypes.Element.NONE:
		return element_override
	if card != null:
		return card.element
	return CardTypes.Element.NONE


func apply(ctx: EffectContext) -> void:
	ctx.add_damage(amount, resolve_element(ctx.card))


func describe() -> String:
	if element_override != CardTypes.Element.NONE:
		return "Infliggi %d danni (%s)" % [amount, CardTypes.element_name(element_override)]
	return "Infliggi %d danni" % amount


## Il danno e' la valuta principale: 1 punto di danno = 1 punto di potenza.
func power_score(_card: CardData) -> float:
	return float(amount)
