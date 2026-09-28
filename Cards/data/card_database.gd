## L'indice di tutte le carte del gioco: la fonte unica e ordinata.
##
## [b]Perche' esiste:[/b] con centinaia di carte non puoi cercarle una per una
## nel FileSystem. Questa [Resource] tiene l'elenco completo e degli indici
## pronti per essere interrogati dal gioco, dall'editor e dai tool:
##
## [codeblock]
##   var db := CardDatabase.load_default()
##   db.find(&"fire_inferno")            # per id
##   db.by_element(CardTypes.Element.FIRE)
##   db.by_rarity(CardTypes.Rarity.UNIQUE)
##   db.search("veleno")                 # id + nome + tag
## [/codeblock]
##
## [b]Le carte vere vivono nei .tres[/b] dentro [code]res://Cards/data/cards/[/code],
## organizzate per elemento. Questo indice le elenca; [method rebuild_from_folder]
## lo rigenera scandendo la cartella, cosi' non va mai tenuto a mano.
##
## Se l'indice non esiste ancora, [method load_default] ripiega sulla tabella
## in codice ([CardLibrary]): il gioco funziona comunque mentre popoli il database.
@tool
class_name CardDatabase extends Resource


## Dove vive l'indice salvato.
const DEFAULT_PATH: String = "res://Cards/data/card_database.tres"

## La cartella che contiene i .tres delle carte (una sottocartella per elemento).
const CARDS_ROOT: String = "res://Cards/data/cards"

## Tutte le carte del gioco. E' l'unico dato salvato: gli indici sono derivati.
@export var cards: Array[CardData] = []

# --- Indici derivati (non salvati, ricostruiti su richiesta) ------------------

var _by_id: Dictionary = {}
var _indexed: bool = false


#region Interrogazione


## Tutte le carte, ordinate per costo e poi per nome.
func all() -> Array[CardData]:
	if cards.is_empty():
		return cards
	var result: Array[CardData] = cards.duplicate()
	result.sort_custom(_compare_cards)
	return result


## Quante carte contiene l'indice.
func size() -> int:
	return cards.size()


## Trova una carta dal suo id. Ritorna null se non esiste.
func find(card_id: StringName) -> CardData:
	_ensure_index()
	return _by_id.get(card_id, null)


## True se l'id esiste gia' (per evitare duplicati mentre crei carte).
func has_id(card_id: StringName) -> bool:
	_ensure_index()
	return _by_id.has(card_id)


## Tutte le carte con una certa rarita'.
func by_rarity(rarity: CardTypes.Rarity) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in cards:
		if card != null and card.rarity == rarity:
			result.append(card)
	return result


## Tutte le carte di un certo elemento.
func by_element(element: CardTypes.Element) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in cards:
		if card != null and card.element == element:
			result.append(card)
	return result


## Tutte le carte che hanno almeno uno dei tag indicati.
func by_tag(tag: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in cards:
		if card == null:
			continue
		if card.tags.has(tag):
			result.append(card)
	return result


## Tutte le carte con il costo in un intervallo (estremi inclusi).
func with_cost_range(min_cost: int, max_cost: int) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in cards:
		if card != null and card.cost >= min_cost and card.cost <= max_cost:
			result.append(card)
	return result


## Ricerca testuale su id, nome e tag (senza distinguere maiuscole).
func search(text: String) -> Array[CardData]:
	var needle: String = text.strip_edges().to_lower()
	if needle.is_empty():
		return all()

	var result: Array[CardData] = []
	for card: CardData in all():
		if card == null:
			continue
		if String(card.id).to_lower().contains(needle):
			result.append(card)
			continue
		if card.display_name.to_lower().contains(needle):
			result.append(card)
			continue
		for tag: String in card.tags:
			if tag.to_lower().contains(needle):
				result.append(card)
				break
	return result


## Quante carte ci sono per rarita'. Ritorna [code]{ CardTypes.Rarity: int }[/code].
func count_by_rarity() -> Dictionary:
	var counts: Dictionary = {}
	for card: CardData in cards:
		if card != null:
			counts[card.rarity] = counts.get(card.rarity, 0) + 1
	return counts


## Controlla l'intero indice contro il modello di potenza.
func validate(table: RarityTable = null) -> Dictionary:
	var used_table: RarityTable = table if table != null else RarityTable.load_default()
	return CardValidator.validate(cards, used_table)


## Gli id che compaiono piu' di una volta.
func duplicate_ids() -> PackedStringArray:
	var seen: Dictionary = {}
	var duplicates: PackedStringArray = []
	for card: CardData in cards:
		if card == null:
			continue
		var id_text: String = String(card.id)
		if id_text.is_empty():
			continue
		if seen.has(id_text):
			if not duplicates.has(id_text):
				duplicates.append(id_text)
		else:
			seen[id_text] = true
	return duplicates


#endregion

#region Modifica


## Aggiunge una carta all'indice. Ritorna false se e' nulla o se l'id esiste gia'.
func add_card(card: CardData) -> bool:
	if card == null:
		return false
	if card.id != &"" and has_id(card.id):
		push_warning("CardDatabase: l'id '%s' esiste gia'." % card.id)
		return false
	cards.append(card)
	_invalidate()
	return true


## Rimuove una carta dall'indice (non cancella il file).
func remove_card(card: CardData) -> bool:
	var index: int = cards.find(card)
	if index < 0:
		return false
	cards.remove_at(index)
	_invalidate()
	return true


## Riordina l'elenco per costo, poi per nome.
func sort_by_cost() -> void:
	cards.sort_custom(_compare_cards)
	_invalidate()


## Cancella gli indici: verranno ricostruiti alla prossima richiesta.
func _invalidate() -> void:
	_indexed = false
	_by_id.clear()


func _ensure_index() -> void:
	if _indexed:
		return
	_by_id.clear()
	for card: CardData in cards:
		if card != null and card.id != &"":
			_by_id[card.id] = card
	_indexed = true


#endregion

#region Sincronizzazione con la cartella


## Rigenera l'indice scandendo la cartella dei .tres.
##
## [b]Non cancella nulla se non trova file[/b]: se la cartella e' vuota lascia
## l'indice com'e' e avvisa. Cosi' premere "rigenera" su un progetto vuoto non
## distrugge il lavoro.
##
## Ritorna quante carte ha trovato (0 se non ha cambiato nulla).
func rebuild_from_folder(root: String = CARDS_ROOT) -> int:
	var files: PackedStringArray = _scan_tres(root)

	if files.is_empty():
		push_warning("CardDatabase: nessun .tres trovato in %s. Indice invariato." % root)
		return 0

	var found: Array[CardData] = []
	for path: String in files:
		# CACHE_MODE_REPLACE: obbliga a rileggere il file dal disco invece di
		# usare la copia in cache di Godot.
		#
		# [b]Serve davvero:[/b] l'editor tiene in memoria le risorse caricate.
		# Se una carta viene riscritta da [code]generate_cards.gd[/code], la
		# cache continua a restituire la versione vecchia, e il dock mostra
		# numeri che non esistono piu' sul disco. Senza questo flag l'unico
		# modo di aggiornare sarebbe riavviare Godot.
		var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if resource is CardData:
			found.append(resource as CardData)
		else:
			push_warning("CardDatabase: %s non e' una CardData." % path)

	cards = found
	sort_by_cost()
	return cards.size()


## Riempie l'indice dalla libreria in codice, senza toccare il disco.
## Serve quando non e' ancora stata materializzata nessuna carta.
func rebuild_from_library() -> int:
	cards = CardLibrary.build_all()
	sort_by_cost()
	return cards.size()


## Materializza in .tres le carte definite in codice.
##
## [b]Non sovrascrive i file esistenti:[/b] se hai gia' modificato una carta
## dall'inspector, quella resta. Serve solo per il primo popolamento.
##
## Per RIGENERARE tutto dal codice (sovrascrivendo le modifiche a mano) usa
## invece [code]res://Cards/tools/generate_cards.gd[/code].
##
## Ritorna [code]{ "written": int, "skipped": int }[/code].
static func seed_from_library(root: String = CARDS_ROOT) -> Dictionary:
	var written: int = 0
	var skipped: int = 0
	for card: CardData in CardLibrary.build_all():
		if card == null or card.id == &"":
			continue

		var folder: String = root.path_join(element_folder(card.element))
		DirAccess.make_dir_recursive_absolute(folder)

		var path: String = folder.path_join("%s.tres" % card.id)
		if ResourceLoader.exists(path):
			skipped += 1
			continue

		if ResourceSaver.save(card, path) == OK:
			written += 1
		else:
			push_error("CardDatabase: impossibile salvare %s." % path)

	return {"written": written, "skipped": skipped}


## La sottocartella di un elemento, dentro [constant CARDS_ROOT].
static func element_folder(element: CardTypes.Element) -> String:
	match element:
		CardTypes.Element.FIRE:
			return "fire"
		CardTypes.Element.ICE:
			return "ice"
		CardTypes.Element.POISON:
			return "poison"
		CardTypes.Element.LIGHTNING:
			return "lightning"
		CardTypes.Element.NATURE:
			return "nature"
		CardTypes.Element.DARK:
			return "dark"
	return "support"


## Il percorso del file .tres di una carta, se rispetta la convenzione.
static func path_for_card(card: CardData, root: String = CARDS_ROOT) -> String:
	return root.path_join(element_folder(card.element)).path_join("%s.tres" % card.id)


## Crea le sottocartelle per tutti gli elementi.
static func ensure_folders(root: String = CARDS_ROOT) -> void:
	for raw_element: Variant in [
		CardTypes.Element.FIRE,
		CardTypes.Element.ICE,
		CardTypes.Element.POISON,
		CardTypes.Element.LIGHTNING,
		CardTypes.Element.NATURE,
		CardTypes.Element.DARK,
		CardTypes.Element.NONE,
	]:
		var element: CardTypes.Element = raw_element
		DirAccess.make_dir_recursive_absolute(root.path_join(element_folder(element)))


## Raccoglie i percorsi dei .tres in una cartella, ricorsivamente.
##
## Ritorna l'elenco invece di riempire un parametro: in GDScript i tipi
## packed (come [PackedStringArray]) si passano [b]per valore[/b], quindi un
## accumulatore passato da fuori non verrebbe modificato.
static func _scan_tres(dir_path: String) -> PackedStringArray:
	var found: PackedStringArray = []

	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found

	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if not name.begins_with("."):
			var full: String = dir_path.path_join(name)
			if dir.current_is_dir():
				found.append_array(_scan_tres(full))
			elif name.ends_with(".tres"):
				found.append(full)
		name = dir.get_next()
	dir.list_dir_end()

	return found


#endregion

#region Salvataggio


## Carica l'indice dal disco. Se manca, ripiega sulla libreria in codice.
##
## E' il punto d'ingresso da usare nel gioco: funziona sia che tu abbia
## materializzato le carte, sia che tu sia ancora in fase di prototipo.
static func load_default() -> CardDatabase:
	if ResourceLoader.exists(DEFAULT_PATH):
		var loaded: Resource = ResourceLoader.load(DEFAULT_PATH)
		if loaded is CardDatabase:
			return loaded as CardDatabase

	var fallback: CardDatabase = CardDatabase.new()
	fallback.rebuild_from_library()
	return fallback


## Salva l'indice nel percorso di default.
func save_default() -> Error:
	return ResourceSaver.save(self, DEFAULT_PATH)


#endregion

#region Report


## Un riassunto leggibile dell'indice, per i tool e i report.
func describe() -> String:
	var lines: PackedStringArray = []
	var sep: String = "=".repeat(66)

	lines.append(sep)
	lines.append("  DATABASE CARTE  (%d carte)" % cards.size())
	lines.append(sep)

	var counts: Dictionary = count_by_rarity()
	lines.append("  Per rarita':")
	for raw_rarity: Variant in [
		CardTypes.Rarity.BASE,
		CardTypes.Rarity.RARE,
		CardTypes.Rarity.EPIC,
		CardTypes.Rarity.LEGENDARY,
		CardTypes.Rarity.UNIQUE,
	]:
		var rarity: CardTypes.Rarity = raw_rarity
		lines.append("    %-14s %3d" % [CardTypes.rarity_name(rarity), counts.get(rarity, 0)])

	lines.append("")
	lines.append("  Per elemento:")
	for raw_element: Variant in [
		CardTypes.Element.FIRE,
		CardTypes.Element.ICE,
		CardTypes.Element.POISON,
		CardTypes.Element.LIGHTNING,
		CardTypes.Element.NATURE,
		CardTypes.Element.DARK,
		CardTypes.Element.NONE,
	]:
		var element: CardTypes.Element = raw_element
		lines.append("    %-14s %3d" % [CardTypes.element_name(element), by_element(element).size()])

	lines.append(sep)
	return "\n".join(lines)


## Ordine stabile per gli elenchi: prima il costo, poi il nome.
static func _compare_cards(a: CardData, b: CardData) -> bool:
	if a.cost != b.cost:
		return a.cost < b.cost
	return a.display_name.naturalnocasecmp_to(b.display_name) < 0


#endregion
