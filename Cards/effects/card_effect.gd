## Classe base di tutti gli effetti di carta.
##
## Un effetto e' una piccola [Resource] riutilizzabile: la scrivi una volta
## e la attacchi a quante carte vuoi, cambiando solo i parametri
## (es. [code]InfliggiX[5][/code] e [code]InfliggiX[12][/code]).
##
## [b]Per creare un effetto nuovo:[/b]
## [codeblock]
## class_name MioEffetto extends CardEffect
##
## @export var quantita: int = 1
##
## func apply(ctx: EffectContext) -> void:
##     ctx.add_log("fai qualcosa")
##
## func describe() -> String:
##     return "Fai qualcosa x%d" % quantita
## [/codeblock]
## Un file nuovo, e non devi toccare nient'altro.
##
## [b]Regola d'oro:[/b] non modificare mai lo stato direttamente dentro
## [method apply]. Accumula tutto in [param ctx] e lascia che sia
## [BattleState] ad applicarlo. Cosi' l'ordine delle carte non conta.
class_name CardEffect extends Resource


## Chiamato una volta per ogni carta giocata, durante la risoluzione del turno.
## Accumula gli effetti in [param ctx], non applicarli subito.
func apply(_ctx: EffectContext) -> void:
	push_error("CardEffect.apply() non implementato in %s" % get_script().resource_path)


## Testo leggibile mostrato sulla carta. Sovrascrivilo sempre.
func describe() -> String:
	return ""


## Se l'effetto puo' essere ridotto a un numero "di potenza" per il bilanciamento,
## ritornalo qui. Il simulatore usa questo valore per stimare l'energia di una carta.
## Ritorna 0.0 se non applicabile.
func power_score(_card: CardData) -> float:
	return 0.0
