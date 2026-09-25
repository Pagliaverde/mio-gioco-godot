## [b]Tutti i numeri che puoi tarare, in un unico posto.[/b]
##
## Questa e' la regolazione del gioco. Il simulatore fa girare migliaia di
## partite cambiando questi valori per trovare quelli divertenti.
##
## [b]Le due invarianti da rispettare[/b] (altrimenti il gioco si rompe):
##
## 1. [code]danno per mana > scudo per mana[/code]
##    Se lo scudo rendesse quanto il danno, la mossa migliore sarebbe non
##    giocare mai niente e accumulare difesa: partite infinite.
##
## 2. [code]il bust deve restare una scelta, non una punizione certa[/code]
##    Se rischiare non conviene mai, nessuno rischia e la meccanica muore.
##    Vedi [member bust_penalty]: le quattro varianti servono a misurarlo.
class_name BattleBalance extends Resource


@export_group("Mana")

## Mana base a ogni turno (dipende dal livello del giocatore).
##
## [b]E' il numero piu' importante del gioco.[/b] Determina dove inizia la zona
## di rischio: il bust e' possibile solo quando il mana scende sotto il costo
## massimo del mazzo. Il simulatore ha trovato che con 12 mana il primo
## giocatore non e' piu' avvantaggiato (win rate 50.7% invece del 76%).
@export_range(1, 100, 1) var mana_base: int = 12

## Mana in piu' per ogni livello del giocatore (meta-progressione permanente).
@export_range(0, 10, 1) var mana_per_level: int = 2

## Bonus di mana casuale, minimo e massimo (la "fortuna" del turno).
@export_range(0, 30, 1) var mana_bonus_min: int = 0
@export_range(0, 30, 1) var mana_bonus_max: int = 3

@export_group("Scudo")

## Quanti punti di scudo ottieni per ogni punto di mana non speso.
##
## [b]Deve essere piu' basso del danno per mana,[/b] altrimenti fermarsi e
## accumulare difesa diventa meglio che attaccare e le partite si trascinano.
##
## Riferimento: le carte fanno circa 2,0-2,5 danno per mana, quindi 0,75 rende
## fermarsi una scelta sicura ma non conveniente.
@export_range(0.0, 3.0, 0.05) var mana_to_shield_ratio: float = 0.75

## Riduzione percentuale dei danni per ogni punto di scudo.
## 0.0075 = 0.75% per punto: con 20 scudo riduci del 15%.
@export_range(0.0, 0.02, 0.0005) var shield_percent_reduction_per_point: float = 0.0075

## Tetto massimo alla riduzione percentuale (0.5 = 50%).
@export_range(0.0, 0.9, 0.05) var shield_max_percent_reduction: float = 0.5

@export_group("Pesca e Bust")

## La penalita' quando peschi una carta troppo cara.
## Confronta le quattro varianti col simulatore prima di scegliere.
@export var bust_penalty: CardTypes.BustPenalty = CardTypes.BustPenalty.DISCARD_AND_CRIT_2

## Moltiplicatore del critico quando l'avversario ha fatto bust.
## Usato solo dalle varianti DISCARD_AND_CRIT_* (1.5 o 2.0).
@export_range(1.0, 5.0, 0.1) var bust_crit_multiplier: float = 2.0

@export_group("Status")

## Decadimento per turno di ogni status. 0 = non decade mai.
##
## [b]⚠ IL VELENO DEVE DECADERE. Non metterlo a 0.[/b]
##
## Un Veleno che non decade si accumula in modo permanente, quindi il suo
## danno totale dipende da quanto dura la partita. In partite lunghe (15-20
## turni) vale [b]3-4 volte[/b] una carta di danno immediato:
##
## [codeblock]
##   Veleno 4 permanente, su 15 turni  ->  60 danni per 5 mana = 12 danno/mana
##   Carta burst da 9 mana             ->  23 danni               =  2.6 danno/mana
## [/codeblock]
##
## Il simulatore ha misurato che con [code]poison_decay = 0[/code] il mazzo ad
## attrito vinceva l'89,8% delle partite e quello aggressivo il 9,6%.
##
## [b]Con il decadimento, l'identita' del Veleno resta:[/b] e' lo status con
## gli strati piu' grandi e la durata piu' lunga. Brucia 3 dura 3 turni e fa
## 6 danni; Veleno 8 dura 8 turni e ne fa 36. Semplicemente [b]non e' piu'
## gratis per sempre[/b].
@export_range(0, 5, 1) var poison_decay: int = 1

## Gli altri status.
@export_range(0, 5, 1) var burn_decay: int = 1
@export_range(0, 5, 1) var chill_decay: int = 1
@export_range(0, 5, 1) var empower_decay: int = 1
@export_range(0, 5, 1) var regen_decay: int = 1

@export_group("Battaglia")

## Vita iniziale dei combattenti. Bassa = partite brevi.
## Con 100 vita le partite durano ~20 turni: adatto a dungeon e boss.
@export_range(10, 500, 5) var starting_health: int = 100

## Numero massimo di turni prima che la battaglia finisca in pareggio.
## Serve solo a impedire loop infiniti nel simulatore.
@export_range(10, 1000, 10) var max_turns: int = 200

@export_group("Compenso secondo giocatore")

## Scudo iniziale regalato a chi gioca per [b]secondo[/b].
##
## [b]Serve a correggere uno squilibrio strutturale.[/b] In un gioco a turni
## alternati dove ci si colpisce a vicenda, chi gioca per primo ha sempre un
## vantaggio: da' il colpo iniziale e spesso anche quello finale. Con i numeri
## di partenza il primo giocatore vinceva il 76% delle partite.
##
## Alza questo valore finche' il win rate non si avvicina al 50%.
## La modalita' TUNING del simulatore ti dice quanto serve.
@export_range(0, 200, 1) var second_player_bonus_shield: int = 12

## Mana in piu' a chi gioca per secondo, solo nel [b]primo[/b] turno.
## Alternativa allo scudo: premia chi e' indietro invece di difenderlo.
@export_range(0, 50, 1) var second_player_bonus_mana: int = 0


## Quanti mana ha un giocatore all'inizio del turno (escluso il bonus casuale).
func mana_for_level(level: int) -> int:
	return mana_base + mana_per_level * (level - 1)


## Il decadimento configurato per uno status.
func decay_for_status(status: CardTypes.StatusType) -> int:
	match status:
		CardTypes.StatusType.BURN:
			return burn_decay
		CardTypes.StatusType.POISON:
			return poison_decay
		CardTypes.StatusType.CHILL:
			return chill_decay
		CardTypes.StatusType.EMPOWER:
			return empower_decay
		CardTypes.StatusType.REGEN:
			return regen_decay
	return 1


## Il moltiplicatore critico implicito nella penalita' di bust scelta.
## Ritorna 1.0 se la penalita' non prevede critico.
func crit_multiplier_for_penalty() -> float:
	match bust_penalty:
		CardTypes.BustPenalty.DISCARD_AND_CRIT_1_5:
			return 1.5
		CardTypes.BustPenalty.DISCARD_AND_CRIT_2:
			return bust_crit_multiplier
	return 1.0


## True se con questa penalita' le carte gia' giocate si risolvono comunque.
func resolves_on_bust() -> bool:
	return bust_penalty == CardTypes.BustPenalty.RESOLVE_AND_END


## True se con questa penalita' le carte gia' giocate vengono perse.
func discards_on_bust() -> bool:
	return bust_penalty != CardTypes.BustPenalty.RESOLVE_AND_END


## Un riassunto leggibile della configurazione, per il report del simulatore.
func describe() -> String:
	var text: String = "mana %d (+%d-%d) | scudo %.2f/mana, -%.2f%% per punto | bust: %s | vita %d" % [
		mana_base,
		mana_bonus_min,
		mana_bonus_max,
		mana_to_shield_ratio,
		shield_percent_reduction_per_point * 100.0,
		CardTypes.bust_penalty_name(bust_penalty),
		starting_health,
	]
	if second_player_bonus_shield > 0 or second_player_bonus_mana > 0:
		text += " | 2do: +%d scudo +%d mana" % [second_player_bonus_shield, second_player_bonus_mana]
	return text


## Crea una configurazione di default pronta all'uso.
static func create_default() -> BattleBalance:
	return BattleBalance.new()
