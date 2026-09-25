@tool
extends EditorScript

# Converte le carte definite in CardLibrary in file .tres modificabili dall'inspector.
#
# Come si usa:
#   1. Apri questo file nell'editor di Godot
#   2. Menu' File > Esegui (oppure Ctrl+Shift+X)
#   3. Controlla il pannello Output
#
# Crea:
#   res://Cards/data/cards/       un .tres per ogni carta
#   res://Cards/data/decks/       i mazzi di esempio
#   res://Cards/synergy/rules/    le regole di sinergia
#
# Nota: i file generati sono copie. Modificarli NON cambia CardLibrary,
# che resta il riferimento usato dal simulatore. Se vuoi che delle modifiche
# fatte a mano abbiano effetto, sposta il mazzo sui .tres generati e smetti
# di usare CardLibrary.


const CARDS_DIR: String = "res://Cards/data/cards"
const DECKS_DIR: String = "res://Cards/data/decks"
const SYNERGY_DIR: String = "res://Cards/synergy/rules"


func _run() -> void:
	print("")
	print("=== GENERAZIONE RISORSE CARTE ===")
	print("")

	_ensure_dir(CARDS_DIR)
	_ensure_dir(DECKS_DIR)
	_ensure_dir(SYNERGY_DIR)

	var card_count: int = _write_cards()
	var deck_count: int = _write_decks()
	var synergy_count: int = _write_synergies()

	print("")
	print("Fatto: %d carte, %d mazzi, %d sinergie." % [card_count, deck_count, synergy_count])
	print("Puoi ora modificarli dall'inspector di Godot.")
	print("")


## Scrive un .tres per ogni carta e ritorna quante ne ha salvate.
func _write_cards() -> int:
	var written: int = 0
	var cards: Array[CardData] = CardLibrary.build_all()

	for card: CardData in cards:
		if card.id == &"":
			push_warning("Carta '%s' senza id: saltata." % card.display_name)
			continue

		var path: String = "%s/%s.tres" % [CARDS_DIR, card.id]
		var error: Error = ResourceSaver.save(card, path)

		if error == OK:
			written += 1
			print("  carta   -> %s" % path)
		else:
			push_error("Errore salvando %s (codice %d)" % [path, error])

	return written


## Scrive i mazzi di esempio.
func _write_decks() -> int:
	var written: int = 0

	var decks: Array[DeckData] = [
		CardLibrary.build_starter_deck(),
		CardLibrary.build_aggressive_deck(),
		CardLibrary.build_fortress_deck(),
		CardLibrary.build_elemental_deck(CardTypes.Element.FIRE),
		CardLibrary.build_elemental_deck(CardTypes.Element.ICE),
		CardLibrary.build_elemental_deck(CardTypes.Element.POISON),
		CardLibrary.build_elemental_deck(CardTypes.Element.LIGHTNING),
		CardLibrary.build_elemental_deck(CardTypes.Element.NATURE),
		CardLibrary.build_elemental_deck(CardTypes.Element.DARK),
	]

	for deck: DeckData in decks:
		var file_name: String = deck.display_name.to_lower().replace(" ", "_").replace("'", "")
		var path: String = "%s/%s.tres" % [DECKS_DIR, file_name]
		var error: Error = ResourceSaver.save(deck, path)

		if error == OK:
			written += 1
			print("  mazzo   -> %s" % path)
		else:
			push_error("Errore salvando %s (codice %d)" % [path, error])

	return written


## Scrive le regole di sinergia.
func _write_synergies() -> int:
	var written: int = 0
	var rules: Array[SynergyRule] = CardLibrary.build_synergies()

	for rule: SynergyRule in rules:
		if rule.id == &"":
			push_warning("Sinergia '%s' senza id: saltata." % rule.display_name)
			continue

		var path: String = "%s/%s.tres" % [SYNERGY_DIR, rule.id]
		var error: Error = ResourceSaver.save(rule, path)

		if error == OK:
			written += 1
			print("  sinergia -> %s" % path)
		else:
			push_error("Errore salvando %s (codice %d)" % [path, error])

	return written


## Crea una cartella se non esiste.
func _ensure_dir(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		return
	var error: Error = DirAccess.make_dir_recursive_absolute(path)
	if error != OK:
		push_error("Impossibile creare la cartella %s (codice %d)" % [path, error])
