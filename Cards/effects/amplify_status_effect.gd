## Aumenta gli strati di [b]tutti[/b] gli status applicati questo turno.
##
## [b]E' l'equivalente di [TurnDamageBuffEffect] per i mazzi ad attrito.[/b]
## Dove i mazzi esplosivi usano "+25% danno", i mazzi di attrito usano
## "+3 strati a ogni Veleno": potenziano la loro risorsa invece del danno.
##
## Senza una carta del genere, i mazzi ad attrito non avrebbero modo di
## accelerare la propria strategia, mentre i mazzi esplosivi hanno i
## moltiplicatori. Questa e' la loro carta di supporto.
##
## [b]Esempio:[/b] giochi "Ricetta Tossica" (+3) insieme a Dardo Tossico (4 poison)
## e Nube Venefica (8 poison) → applichi 7 + 11 = 18 Veleno invece di 12. Con
## un decadimento di 1 per turno, sono 3 turni di danno in piu'.
class_name AmplifyStatusEffect extends CardEffect


## Strati extra aggiunti a ogni status applicato.
@export_range(1, 20, 1) var extra_stacks: int = 3


func apply(ctx: EffectContext) -> void:
	ctx.status_bonus += extra_stacks


func describe() -> String:
	return "Questo turno: +%d a ogni status inflitto" % extra_stacks


## Vale in proporzione a quante carte di status giochi nel turno.
## La stima assume circa una carta di status per turno.
func power_score(_card: CardData) -> float:
	return float(extra_stacks) * 1.8
