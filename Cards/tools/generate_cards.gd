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
#   res://Cards/data/cards/<elemento>/   un .tres per ogni carta, diviso per elemento
#   res://Cards/data/decks/              i mazzi di esempio
#   res://Cards/synergy/rules/           le regole di sinergia
#   res://Cards/data/card_database.tres  l'indice di tutte le carte
#
# Nota: le carte vengono SOVRASCRITTE dalla libreria in codice. Se vuoi
# modificare una carta dall'inspector, non rieseguire questo tool: usa
# rebuild_database.gd per aggiornare solo l'indice, e crea le carte nuove
# dal dock "Carte".


const CARDS_DIR: String = CardDatabase.CARDS_ROOT
const DECKS_DIR: String = "res://Cards/data/decks"
const SYNERGY_DIR: String = "res://Cards/synergy/rules"


func _run() -> void:
	print("")
	print("=== GENERAZIONE RISORSE CARTE ===")
	print("")

	CardDatabase.ensure_folders(CARDS_DIR)
	_ensure_dir(DECKS_DIR)
	_ensure_dir(SYNERGY_DIR)

	var card_count: int = _write_cards()
	var deck_count: int = _write_decks()
	var synergy_count: int = _write_synergies()

	# Aggiorna e salva l'indice, cosi' il database riflette subito i file scritti.
	var database: CardDatabase = CardDatabase.new()
	var indexed: int = database.rebuild_from_folder(CARDS_DIR)
	var index_error: Error = database.save_default()
	if index_error != OK:
		push_error("Impossibile salvare l'indice carte (codice %d)." % index_error)

	print("")
	print("Fatto: %d carte, %d mazzi, %d sinergie, %d carte indicizzate." % [
		card_count, deck_count, synergy_count, indexed,
	])
	print("Puoi ora modificarle dall'inspector di Godot.")
	print("")


## Scrive un .tres per ogni carta, dentro la sottocartella del suo elemento.
func _write_cards() -> int:
	var written: int = 0
	var cards: Array[CardData] = CardLibrary.build_all()

	for card: CardData in cards:
		if card.id == &"":
			push_warning("Carta '%s' senza id: saltata." % card.display_name)
			continue

		var path: String = CardDatabase.path_for_card(card, CARDS_DIR)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
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
