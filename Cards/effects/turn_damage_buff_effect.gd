## Aumenta in percentuale il danno di [b]tutte[/b] le carte giocate questo turno.
##
## Esempio: "Grido di battaglia: +25% danno". Se lo giochi insieme a due carte
## da 10 danni, il turno fa 25 danni invece di 20.
##
## [b]Nota:[/b] non e' "potenzia la prossima carta". Essendo la risoluzione
## simultanea, potenziare "la prossima" non avrebbe senso: qui il bonus vale
## per tutto il turno. E' il modo giusto di fare sinergie in questo sistema.
class_name TurnDamageBuffEffect extends CardEffect


## Percentuale di aumento. 25 = +25% danno.
@export_range(-100, 500, 1) var percent: int = 25


func apply(ctx: EffectContext) -> void:
	ctx.multiply_all_damage(1.0 + float(percent) / 100.0)


func describe() -> String:
	if percent >= 0:
		return "Questo turno: +%d%% danno" % percent
	return "Questo turno: %d%% danno" % percent


## Un +N% vale in proporzione a quanto danno fai nel turno, quindi il valore
## reale dipende dal mazzo. La stima usa un turno medio da circa 2 carte offensive:
##   +25% su ~25 danno = +6 danno effettivo
## Per questo il moltiplicatore e' 0.3 e non 0.15: sottostimarlo farebbe
## sembrare deboli delle carte che in realta' sono forti.
func power_score(_card: CardData) -> float:
	return float(percent) * 0.3
