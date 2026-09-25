## Una regola di sinergia: un bonus che si attiva in base a [b]quante carte[/b]
## di un certo elemento hai giocato nello stesso turno.
##
## [b]Perche' funziona cosi':[/b] nel tuo gioco l'ordine delle carte non conta,
## quindi le combo non possono essere sequenziali ("+danno, poi attacco").
## Devono essere di [i]composizione[/i]: contano cosa hai schierato insieme.
##
## [b]Esempi che puoi creare con questa classe:[/b]
## [codeblock]
## # 3 o piu' carte Fuoco: +50% danno Fuoco
## primary_element = FIRE, min_primary = 3
## damage_multiplier = 1.5, applies_to_element = FIRE
##
## # Fuoco + Ghiaccio insieme: applica 3 Veleno (vapore tossico)
## primary_element = FIRE, min_primary = 1
## secondary_element = ICE, min_secondary = 1
## bonus_status = POISON, bonus_status_stacks = 3
##
## # Almeno 2 carte Natura: cura l'8% della vita massima
## ...
## [/codeblock]
class_name SynergyRule extends Resource


## Identificativo unico della regola.
@export var id: StringName = &""

## Nome mostrato al giocatore quando la sinergia si attiva.
@export var display_name: String = "Sinergia"

@export_group("Condizione")

## L'elemento principale richiesto. [code]NONE[/code] disattiva la regola.
@export var primary_element: CardTypes.Element = CardTypes.Element.FIRE

## Quante carte di quell'elemento servono come minimo.
@export_range(1, 10, 1) var min_primary: int = 3

## Secondo elemento richiesto (opzionale). Lascia [code]NONE[/code] per non richiederne.
@export var secondary_element: CardTypes.Element = CardTypes.Element.NONE

## Quante carte del secondo elemento servono (se richiesto).
@export_range(1, 10, 1) var min_secondary: int = 1

@export_group("Effetto")

## Moltiplicatore di danno applicato dalla sinergia.
## 1.0 = nessun bonus, 1.5 = +50%, 2.0 = raddoppia.
@export_range(1.0, 5.0, 0.05) var damage_multiplier: float = 1.0

## A quale elemento si applica il moltiplicatore.
## [code]NONE[/code] = a tutti gli elementi del turno.
@export var applies_to_element: CardTypes.Element = CardTypes.Element.NONE

## Status applicato all'avversario quando la sinergia scatta.
@export var bonus_status: CardTypes.StatusType = CardTypes.StatusType.BURN

## Strati dello status bonus. Metti 0 per non applicare nessuno status.
@export_range(0, 20, 1) var bonus_status_stacks: int = 0

## Scudo bonus che guadagni quando la sinergia scatta.
@export_range(0, 50, 1) var bonus_shield: int = 0


## Verifica se la condizione e' soddisfatta dalle carte giocate.
func is_satisfied(ctx: EffectContext) -> bool:
	if primary_element == CardTypes.Element.NONE:
		return false

	if ctx.count_played_of_element(primary_element) < min_primary:
		return false

	if secondary_element != CardTypes.Element.NONE:
		if ctx.count_played_of_element(secondary_element) < min_secondary:
			return false

	return true


## Applica la sinergia al contesto, se le condizioni sono soddisfatte.
## Ritorna true se e' scattata.
func evaluate(ctx: EffectContext) -> bool:
	if not is_satisfied(ctx):
		return false

	var parts: PackedStringArray = []

	# 1. Moltiplicatore di danno
	if not is_equal_approx(damage_multiplier, 1.0):
		if applies_to_element == CardTypes.Element.NONE:
			ctx.multiply_all_damage(damage_multiplier)
			parts.append("danno +%d%%" % int(round((damage_multiplier - 1.0) * 100.0)))
		else:
			ctx.multiply_element_damage(applies_to_element, damage_multiplier)
			parts.append("%s +%d%%" % [
				CardTypes.element_name(applies_to_element),
				int(round((damage_multiplier - 1.0) * 100.0)),
			])

	# 2. Status bonus
	if bonus_status_stacks > 0:
		ctx.add_status(bonus_status, bonus_status_stacks, false)
		parts.append("+%d %s" % [bonus_status_stacks, CardTypes.status_name(bonus_status)])

	# 3. Scudo bonus
	if bonus_shield > 0:
		ctx.add_shield(bonus_shield)
		parts.append("+%d scudo" % bonus_shield)

	if not parts.is_empty():
		ctx.add_log("✦ SINERGIA %s: %s" % [display_name, ", ".join(parts)])

	return true


## Descrizione leggibile della condizione richiesta.
func describe_condition() -> String:
	if primary_element == CardTypes.Element.NONE:
		return "(nessuna condizione)"

	var text: String = "%d+ %s" % [min_primary, CardTypes.element_name(primary_element)]

	if secondary_element != CardTypes.Element.NONE:
		text += " + %d+ %s" % [min_secondary, CardTypes.element_name(secondary_element)]

	return text


## Descrizione leggibile dell'effetto.
func describe_effect() -> String:
	var parts: PackedStringArray = []

	if not is_equal_approx(damage_multiplier, 1.0):
		parts.append("+%d%% danno" % int(round((damage_multiplier - 1.0) * 100.0)))
	if bonus_status_stacks > 0:
		parts.append("%d %s" % [bonus_status_stacks, CardTypes.status_name(bonus_status)])
	if bonus_shield > 0:
		parts.append("%d scudo" % bonus_shield)

	if parts.is_empty():
		return "(nessun effetto)"
	return ", ".join(parts)


func _to_string() -> String:
	return "<SynergyRule %s: %s -> %s>" % [display_name, describe_condition(), describe_effect()]
