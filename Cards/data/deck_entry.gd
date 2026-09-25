## Una riga di un mazzo: "questa carta, in questa quantita'".
##
## Serve perche' nell'inspector e' molto piu' comodo scrivere
## [code]Inferno x3[/code] che trascinare la stessa carta tre volte.
class_name DeckEntry extends Resource


## La carta da includere nel mazzo.
@export var card: CardData

## Quante copie di quella carta.
@export_range(1, 10, 1) var count: int = 1


## Costruisce una riga al volo (utile da codice).
static func of(card_data: CardData, amount: int = 1) -> DeckEntry:
	var entry: DeckEntry = DeckEntry.new()
	entry.card = card_data
	entry.count = amount
	return entry


func _to_string() -> String:
	return "%s x%d" % [card.display_name if card != null else "?", count]
