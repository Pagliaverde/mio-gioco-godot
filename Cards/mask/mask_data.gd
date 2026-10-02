## Una maschera: [b]non cambia le carte, cambia le regole intorno alle carte.[/b]
##
## E' il modello descritto in [code]Docs/TRAMA_E_MASCHERE.md[/code]. Una maschera
## e' quattro cose:
##
## [br]- [b]Affinita'[/b]: gli elementi con cui sei in sinergia. Con una maschera
##   addosso valgono [b]solo[/b] le sinergie dei suoi elementi, e quegli elementi
##   fanno piu' danno; gli altri un po' meno. Le stesse carte Fuoco sono ottime
##   sotto la Tragedia e scarse sotto la Commedia.
## [br]- [b]Regola dell'azzardo[/b] ([member gambit]): tocca il rischio. Il bust,
##   lo scudo, l'informazione. E' un hook in [BattleState].
## [br]- [b]Postura[/b]: ritocchi ai numeri ([member damage_scale], [member mana_bonus]).
## [br]- [b]Il prezzo[/b] ([member drawback]): scritto in chiaro, il giocatore lo legge.
##
## Le maschere base si trovano nei Bauli di Scena; quelle dei boss si vincono.
## Vedi [MaskLibrary] per le nove maschere del gioco.
@tool
class_name MaskData extends Resource


## Identificativo stabile, usato dai salvataggi (es. [code]&"tragedia"[/code]).
@export var id: StringName = &""

## Nome mostrato al giocatore.
@export var display_name: String = "Maschera"

## La frase che la presenta.
@export_multiline var quote: String = ""

## Cosa fa, spiegato al giocatore.
@export_multiline var description: String = ""

## Il prezzo, in chiaro.
@export_multiline var drawback: String = ""

## Rarita': le maschere riusano il modello delle carte.
@export var rarity: CardTypes.Rarity = CardTypes.Rarity.RARE

## Quale boss la lascia. Vuoto = si trova in un Baule di Scena.
@export var won_from: StringName = &""

@export_group("Affinita'")

## Gli elementi affini (valori di [enum CardTypes.Element]).
## Vuoto = nessuna affinita': valgono le sinergie normali del gioco.
@export var element_affinity: Array[int] = []

## Il pacchetto di sinergie che la maschera attiva al posto di quelle globali.
## [MaskLibrary] lo riempie con le regole degli elementi affini.
@export var synergies: Array[SynergyRule] = []

## Moltiplicatore di danno per le carte degli elementi affini.
@export_range(1.0, 2.0, 0.05) var affinity_multiplier: float = 1.3

## Moltiplicatore per le carte degli altri elementi (le neutre non sono toccate).
@export_range(0.5, 1.0, 0.05) var off_affinity_multiplier: float = 0.85

@export_group("Regola dell'azzardo")

## Quale regola del rischio attiva.
@export var gambit: CardTypes.MaskGambit = CardTypes.MaskGambit.NONE

@export_group("Postura")

## Moltiplicatore su tutto il danno che infliggi.
@export_range(0.5, 1.5, 0.05) var damage_scale: float = 1.0

## Mana in piu' (o in meno) a ogni turno.
@export_range(-20, 20, 1) var mana_bonus: int = 0

@export_group("Presentazione")

## Il colore della maschera, per la carta e i contorni.
@export var accent: Color = Color(0.75, 0.70, 0.60)

## Che faccia disegnare: "empty", "smile", "frown", "half", "eye", "mirror",
## "heart", "bars", "many". Vedi [MaskCard].
@export var face: String = "empty"


## True se questa maschera e' una ricompensa di un boss.
func is_boss_mask() -> bool:
	return won_from != &""


## True se, con questa maschera addosso, le sinergie globali vengono sostituite
## dal suo pacchetto.
func replaces_synergies() -> bool:
	return not element_affinity.is_empty()


## True se l'elemento e' affine.
func is_affine(element: CardTypes.Element) -> bool:
	return element_affinity.has(int(element))


## True se questa maschera attiva la regola indicata.
##
## [b]Tutte[/b] attiva ogni regola [i]buona[/i]: non la Catarsi, che e' un prezzo,
## e non l'Improvvisazione, perche' il Perdono la copre gia'.
func has_gambit(which: CardTypes.MaskGambit) -> bool:
	if gambit == which:
		return true
	if gambit == CardTypes.MaskGambit.ALL:
		return which in [
			CardTypes.MaskGambit.OMEN,
			CardTypes.MaskGambit.MIRROR,
			CardTypes.MaskGambit.FORGIVENESS,
			CardTypes.MaskGambit.GUARD,
			CardTypes.MaskGambit.DECEIT,
		]
	return false


## Gli elementi affini come nomi, per i testi.
func affinity_text() -> String:
	if element_affinity.is_empty():
		return "nessuna"
	var names: PackedStringArray = []
	for raw: int in element_affinity:
		names.append(CardTypes.element_name(raw as CardTypes.Element))
	return ", ".join(names)


func _to_string() -> String:
	return "<MaskData %s (%s)>" % [display_name, CardTypes.mask_gambit_name(gambit)]
