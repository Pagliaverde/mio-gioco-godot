## La [b]definizione[/b] di una carta: nome, costo, elemento ed effetti.
##
## [b]Questo oggetto non cambia mai durante una partita.[/b] Rappresenta il
## "progetto" della carta, non una copia in gioco. Se giochi tre copie della
## stessa carta, esiste un solo [CardData] e tre [CardInstance] che lo
## puntano: e' cosi' che due copie non si danneggiano a vicenda.
##
## Per creare una carta nuova:
## [codeblock]
## FileSystem > tasto destro > Nuova risorsa > CardData
## [/codeblock]
## e salvala in [code]res://Cards/data/cards/[/code].
class_name CardData extends Resource


## Identificativo unico e stabile della carta (usato da salvataggi e pacchetti).
## Consiglio: minuscolo con underscore, es. [code]&"fire_inferno"[/code].
@export var id: StringName = &""

## Nome mostrato sulla carta.
@export var display_name: String = "Nuova carta"

## Testo descrittivo. Se lo lasci vuoto viene generato dagli effetti.
@export_multiline var description: String = ""

@export_group("Costo e tipo")

## Quanto mana serve per giocarla. Le carte bilanciate stanno tra 3 e 9.
@export_range(0, 20, 1) var cost: int = 3

## Elemento di appartenenza: decide sinergie e (in futuro) resistenze.
@export var element: CardTypes.Element = CardTypes.Element.NONE

## Rarita': influisce sulla potenza e sulla probabilita' nei pacchetti.
@export var rarity: CardTypes.Rarity = CardTypes.Rarity.COMMON

@export_group("Contenuto")

## Gli effetti della carta, applicati [b]tutti insieme[/b] a fine turno.
## Puoi combinarne quanti vuoi: es. danno + applica Brucia.
@export var effects: Array[CardEffect] = []

## Etichette libere per cercare carte (es. "starter", "boss", "dungeon_1").
@export var tags: PackedStringArray = []

@export_group("Presentazione")

## Immagine della carta (pixel art).
@export var art: Texture2D


## Restituisce la descrizione scritta a mano, oppure una generata dagli effetti.
func get_description() -> String:
	if not description.strip_edges().is_empty():
		return description
	return generate_description()


## Costruisce automaticamente il testo della carta a partire dai suoi effetti.
## Utile per non dover riscrivere la descrizione ogni volta che cambi un numero.
func generate_description() -> String:
	if effects.is_empty():
		return ""

	var parts: PackedStringArray = []
	for effect: CardEffect in effects:
		if effect == null:
			continue
		var text: String = effect.describe()
		if not text.is_empty():
			parts.append(text)

	return "\n".join(parts)


## Colore del bordo/etichetta, derivato dall'elemento.
func get_color() -> Color:
	return CardTypes.element_color(element)


## Rappresentazione breve per i log.
func _to_string() -> String:
	return "<CardData %s (%d mana)>" % [display_name, cost]
