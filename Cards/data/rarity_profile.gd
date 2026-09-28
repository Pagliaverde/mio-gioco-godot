## Il profilo di una fascia di rarita': quanto vale, quanto costa, quanto esce.
##
## [b]Qui vive il modello di potenza del gioco.[/b] Ogni fascia definisce
## quattro cose, e insieme generano la progressione della collezione:
##
## [codeblock]
##   power_per_mana   quanto rende una carta per punto di mana
##   cost_min / max   la banda di costo in cui la carta si muove
##   copy_limit       quante copie puo' avere in un mazzo (0 = illimitate)
##   drop_weight      con che frequenza esce dai pacchetti
## [/codeblock]
##
## Cosi' i numeri della progressione stanno in un posto solo: per ribilanciare
## il gioco si modifica questa tabella, non le singole carte. Le carte vengono
## poi [i]validate[/i] contro il budget della loro rarita' da [CardValidator].
##
## [b]Il modello:[/b] la rarita' e' un moltiplicatore di potenza [i]e[/i] una
## spinta sul costo. Salendo di rarita' la carta rende di piu' e costa meno:
##
## [codeblock]
##   Base          costosa e debole      materiale di partenza, illimitato
##   Rara          costosa, poco resa    la prima fascia "pullata"
##   Epica         buon rendimento
##   Leggendaria   economica e forte     una sola copia
##   Unica         economica e devastante  il vertice della collezione
## [/codeblock]
##
## La potenza si misura con [code]power_score[/code] degli effetti (1 punto di
## danno = 1.0 di potenza, 1 di scudo = 0.5, 1 di cura = 0.6), quindi i numeri
## qui sotto sono confrontabili tra tutte le carte del gioco.
@tool
class_name RarityProfile extends Resource


## Quale fascia descrive questo profilo.
@export var rarity: CardTypes.Rarity = CardTypes.Rarity.BASE

## Nome mostrato in gioco ("Base", "Rara", "Unica"...).
@export var display_name: String = "Base"

## Potenza attesa per ogni punto di mana speso.
##
## E' l'efficienza di riferimento: una carta da [code]cost[/code] mana di questa
## rarita' dovrebbe avere un [code]power_score[/code] vicino a
## [code]cost * power_per_mana[/code].
@export_range(0.1, 10.0, 0.1) var power_per_mana: float = 1.6

## Margine di tolleranza sul budget, in percentuale (0.25 = +/-25%).
## Lascia spazio alle carte "sfumate" senza far fallire la validazione.
@export_range(0.0, 1.0, 0.05) var tolerance: float = 0.25

## Costo minimo consentito per questa rarita'.
@export_range(0, 100, 1) var cost_min: int = 10

## Costo massimo consentito per questa rarita'.
@export_range(0, 100, 1) var cost_max: int = 30

## Copie massime per mazzo. 0 = illimitate.
@export_range(0, 10, 1) var copy_limit: int = 0

## Peso relativo nei pacchetti. Piu' e' alto, piu' spesso esce.
@export_range(0.0, 1000.0, 0.5) var drop_weight: float = 100.0

## Colore della cornice della carta (per la UI).
@export var border_color: Color = Color(0.75, 0.75, 0.78)

## Riga di sapore, per la UI e per orientarsi nel design.
@export_multiline var flavor: String = ""


## Il [code]power_score[/code] atteso per una carta di questa rarita' a questo costo.
func power_budget(cost: int) -> float:
	return float(cost) * power_per_mana


## True se il costo rientra nella banda di questa rarita'.
func is_cost_in_band(cost: int) -> bool:
	return cost >= cost_min and cost <= cost_max


## Etichetta della banda di costo, es. "10-30".
func band_label() -> String:
	return "%d-%d" % [cost_min, cost_max]


## Etichetta delle copie, es. "illimitate" oppure "max 2".
func copies_label() -> String:
	return "illimitate" if copy_limit <= 0 else "max %d" % copy_limit


func _to_string() -> String:
	return "<RarityProfile %s %.1f pwr/mana, costo %s>" % [
		display_name, power_per_mana, band_label(),
	]
