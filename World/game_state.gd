## Lo stato della partita nel mondo esplorabile: dove sei, cosa hai, chi hai
## battuto. E' un autoload ([code]GameState[/code]): vive sopra le scene, cosi'
## sopravvive ai cambi di mappa e alle battaglie.
##
## [b]Non disegna niente e non decide niente:[/b] tiene i numeri. Chi gioca e'
## [Overworld] (le mappe, il giocatore) con [WorldDirector] (la storia, le
## scene, i negozi).
##
## [b]Salvataggio:[/b] [SaveGame] raccoglie solo i nodi [i]dentro[/i] la scena
## aperta, e un autoload non lo e'. Per questo [Overworld] ha un nodo figlio
## [code]Progresso[/code] iscritto al gruppo [code]save_state[/code] che
## gira le due domande a [method get_save_data] / [method apply_save_data]
## (lo stesso schema di [StoryDirector]).
##
## [codeblock]
## GameState.new_game()
## GameState.add_money(50)
## GameState.defeat_boss(&"comparsa")
## var deck: DeckData = GameState.build_deck()
## [/codeblock]
extends Node


## Emesso quando cambia qualcosa che la HUD mostra (vita, biglietti, maschere...).
signal changed()


# --- Dove sei ---

## La mappa in cui ti trovi (id di [WorldData.map_ids]).
var map_id: StringName = WorldData.START_MAP

## Il punto d'arrivo da usare entrando nella mappa (vuoto = usa [member position]).
var spawn: StringName = WorldData.START_SPAWN

## Dove eri l'ultima volta che la partita e' stata salvata.
var position: Vector2 = Vector2.ZERO

## Da che parte guardavi.
var facing: Vector2 = Vector2.DOWN

# --- Chi sei ---

## La gavetta: decide il pubblico (mana) a ogni scena. Sale battendo i boss.
var level: int = 1

## Le maschere che hai, in ordine di arrivo.
var masks: Array[StringName] = []

## La maschera che indossi per le scene con le comparse (vuoto = a volto
## scoperto). Contro i boss si sceglie ogni volta.
var worn_mask: StringName = &""

## La vita, che resta tra una scena e l'altra.
var hp: int = 400
var max_hp: int = 400

## I biglietti: la moneta del teatro.
var money: int = 0

## Gli oggetti: id -> quanti.
var items: Dictionary = {}

## Le battute comprate: id carta -> quante copie ci sono nel repertorio.
var deck_extra: Dictionary = {}

## Le battute comprate ma messe da parte (non nel repertorio): id -> quante.
var deck_shelf: Dictionary = {}

## Favore con cui comincia la prossima scena (dal Mazzo di fiori).
var next_battle_shield: int = 0

# --- Cosa hai fatto ---

## I boss battuti (id di [StoryData]).
var bosses_defeated: Array[StringName] = []

## I bauli gia' aperti (chiave: "mappa/nome").
var chests_opened: Array[String] = []

## Segnalini liberi: intro di zona viste, tutorial, ecc.
var flags: Dictionary = {}

## Quante volte hai guardato la platea (il manichino che si sposta).
var audience_visits: int = 0

## Il numero sul muro del camerino.
var runs: int = 1

## True quando c'e' una partita in corso (nuova o ripresa).
var started: bool = false

## Il bilanciamento del motore delle carte: lo stesso per tutte le scene.
var balance: BattleBalance = null


func _ready() -> void:
	balance = BattleBalance.create_default()
	_reset()


#region Partita


## Comincia una partita nuova: il numero sul muro sale di uno.
func new_game() -> void:
	_reset()
	runs = StorySave.begin_new_run()
	started = true
	changed.emit()


func _reset() -> void:
	map_id = WorldData.START_MAP
	spawn = WorldData.START_SPAWN
	position = Vector2.ZERO
	facing = Vector2.DOWN
	level = 1
	masks = []
	worn_mask = &""
	max_hp = balance.starting_health if balance != null else 400
	hp = max_hp
	money = 0
	items = {}
	deck_extra = {}
	deck_shelf = {}
	next_battle_shield = 0
	bosses_defeated = []
	chests_opened = []
	flags = {}
	audience_visits = 0
	runs = maxi(StorySave.run_count(), 1)
	started = false


#endregion

#region Salvataggio


## Tutto quello che serve per riprendere: mappa, posizione, inventario, progresso.
func get_save_data() -> Variant:
	return {
		"map": str(map_id),
		"position": position,
		"facing": facing,
		"level": level,
		"masks": _names_to_strings(masks),
		"worn_mask": str(worn_mask),
		"hp": hp,
		"money": money,
		"items": _keys_to_strings(items),
		"deck_extra": _keys_to_strings(deck_extra),
		"deck_shelf": _keys_to_strings(deck_shelf),
		"next_battle_shield": next_battle_shield,
		"bosses": _names_to_strings(bosses_defeated),
		"chests": chests_opened.duplicate(),
		"flags": flags.duplicate(true),
		"audience_visits": audience_visits,
		"runs": runs,
	}


## Riprende da un salvataggio. I valori strani vengono ripuliti invece di
## rompere la partita.
func apply_save_data(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var saved: Dictionary = data
	_reset()

	var saved_map: StringName = StringName(str(saved.get("map", WorldData.START_MAP)))
	map_id = saved_map if WorldData.map_ids().has(saved_map) else WorldData.START_MAP
	spawn = &""
	if typeof(saved.get("position")) == TYPE_VECTOR2:
		position = saved["position"]
	else:
		spawn = WorldData.START_SPAWN
	if typeof(saved.get("facing")) == TYPE_VECTOR2:
		facing = saved["facing"]

	level = maxi(int(saved.get("level", 1)), 1)
	for raw: Variant in saved.get("masks", []):
		var mask_id: StringName = StringName(str(raw))
		if MaskLibrary.find_by_id(mask_id) != null and not masks.has(mask_id):
			masks.append(mask_id)
	var worn: StringName = StringName(str(saved.get("worn_mask", "")))
	worn_mask = worn if masks.has(worn) else &""

	hp = clampi(int(saved.get("hp", max_hp)), 1, max_hp)
	money = maxi(int(saved.get("money", 0)), 0)
	items = _clean_counts(saved.get("items", {}), func(id: StringName) -> bool: return not WorldData.item(id).is_empty())
	deck_extra = _clean_counts(saved.get("deck_extra", {}), func(id: StringName) -> bool: return CardLibrary.find_by_id(id) != null)
	deck_shelf = _clean_counts(saved.get("deck_shelf", {}), func(id: StringName) -> bool: return CardLibrary.find_by_id(id) != null)
	next_battle_shield = maxi(int(saved.get("next_battle_shield", 0)), 0)

	for raw: Variant in saved.get("bosses", []):
		var boss_id: StringName = StringName(str(raw))
		if StoryData.find_boss(boss_id) != null and not bosses_defeated.has(boss_id):
			bosses_defeated.append(boss_id)
	for raw: Variant in saved.get("chests", []):
		if not chests_opened.has(str(raw)):
			chests_opened.append(str(raw))
	if typeof(saved.get("flags")) == TYPE_DICTIONARY:
		flags = saved["flags"].duplicate(true)
	audience_visits = maxi(int(saved.get("audience_visits", 0)), 0)
	runs = maxi(int(saved.get("runs", StorySave.run_count())), 1)
	started = true
	changed.emit()


func _names_to_strings(list: Array[StringName]) -> Array:
	var out: Array = []
	for value: StringName in list:
		out.append(str(value))
	return out


func _keys_to_strings(counts: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in counts:
		out[str(key)] = int(counts[key])
	return out


func _clean_counts(raw: Variant, is_valid: Callable) -> Dictionary:
	var out: Dictionary = {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key: Variant in raw:
		var id: StringName = StringName(str(key))
		var count: int = int(raw[key])
		if count > 0 and is_valid.call(id):
			out[id] = count
	return out


#endregion

#region Vita e biglietti


## Cura (amount < 0 = tutta). Ritorna quanta vita e' tornata davvero.
func heal(amount: int) -> int:
	var before: int = hp
	hp = max_hp if amount < 0 else mini(hp + amount, max_hp)
	changed.emit()
	return hp - before


## La vita dopo una scena (mai sotto 1: a zero ci pensa la sconfitta).
func set_hp(value: int) -> void:
	hp = clampi(value, 1, max_hp)
	changed.emit()


func add_money(amount: int) -> void:
	money = maxi(money + amount, 0)
	changed.emit()


## Paga, se puoi. Ritorna false se i biglietti non bastano.
func spend(amount: int) -> bool:
	if amount > money:
		return false
	money -= amount
	changed.emit()
	return true


#endregion

#region Maschere e boss


func has_mask(mask_id: StringName) -> bool:
	return masks.has(mask_id)


func gain_mask(mask_id: StringName) -> void:
	if MaskLibrary.find_by_id(mask_id) == null or masks.has(mask_id):
		return
	masks.append(mask_id)
	changed.emit()


## Le maschere che hai, come dati.
func owned_masks() -> Array[MaskData]:
	var out: Array[MaskData] = []
	for mask_id: StringName in masks:
		var mask: MaskData = MaskLibrary.find_by_id(mask_id)
		if mask != null:
			out.append(mask)
	return out


## Le maschere dei Bauli che non hai ancora.
func missing_chest_masks() -> Array[MaskData]:
	var out: Array[MaskData] = []
	for mask: MaskData in MaskLibrary.chest_masks():
		if not masks.has(mask.id):
			out.append(mask)
	return out


func wear(mask_id: StringName) -> void:
	worn_mask = mask_id if (mask_id == &"" or masks.has(mask_id)) else &""
	changed.emit()


func worn_mask_data() -> MaskData:
	return MaskLibrary.find_by_id(worn_mask) if worn_mask != &"" else null


func is_boss_defeated(boss_id: StringName) -> bool:
	return bosses_defeated.has(boss_id)


## Un boss battuto: si sale di gavetta e la vita torna piena.
func defeat_boss(boss_id: StringName) -> void:
	if bosses_defeated.has(boss_id):
		return
	bosses_defeated.append(boss_id)
	level += 1
	hp = max_hp
	changed.emit()


## Il boss con la difficolta' delle impostazioni gia' applicata.
func boss(boss_id: StringName) -> StoryData.StoryBoss:
	var found: StoryData.StoryBoss = StoryData.find_boss(boss_id)
	if found != null:
		StoryData.apply_difficulty(found)
	return found


#endregion

#region Bauli e segnalini


func is_chest_opened(key: String) -> bool:
	return chests_opened.has(key)


func open_chest(key: String) -> void:
	if not chests_opened.has(key):
		chests_opened.append(key)


func flag(key: String) -> bool:
	return bool(flags.get(key, false))


func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value


#endregion

#region Oggetti


func item_count(item_id: StringName) -> int:
	return int(items.get(item_id, 0))


func add_item(item_id: StringName, amount: int = 1) -> void:
	if WorldData.item(item_id).is_empty():
		return
	items[item_id] = item_count(item_id) + amount
	changed.emit()


## Usa un oggetto. Ritorna una frase su cosa e' successo, o "" se non l'hai.
func use_item(item_id: StringName) -> String:
	var data: Dictionary = WorldData.item(item_id)
	if data.is_empty() or item_count(item_id) <= 0:
		return ""
	var heal_amount: int = int(data.get("heal", 0))
	var shield: int = int(data.get("shield", 0))
	if heal_amount != 0 and shield == 0 and hp >= max_hp:
		return "Stai gia' bene: lo tieni per dopo."

	items[item_id] = item_count(item_id) - 1
	if int(items[item_id]) <= 0:
		items.erase(item_id)

	var parts: PackedStringArray = []
	if heal_amount != 0:
		parts.append("Ti tornano %d di vita." % heal(heal_amount))
	if shield > 0:
		next_battle_shield += shield
		parts.append("La prossima scena cominci con %d di Favore." % next_battle_shield)
	changed.emit()
	return " ".join(parts)


#endregion

#region Repertorio


## Il repertorio con cui reciti: il mazzo Equilibrato piu' le battute comprate.
func build_deck() -> DeckData:
	var deck: DeckData = CardLibrary.build_starter_deck()
	deck.display_name = "Il tuo repertorio"
	var entries: Array[DeckEntry] = deck.entries.duplicate()
	for card_id: Variant in deck_extra:
		var card: CardData = CardLibrary.find_by_id(card_id)
		var count: int = int(deck_extra[card_id])
		if card == null or count <= 0:
			continue
		var merged: bool = false
		for entry: DeckEntry in entries:
			if entry.card != null and entry.card.id == card.id:
				var copy: DeckEntry = DeckEntry.of(card, entry.count + count)
				entries[entries.find(entry)] = copy
				merged = true
				break
		if not merged:
			entries.append(DeckEntry.of(card, count))
	deck.entries = entries
	return deck


## Quante copie di una battuta ci sono nel repertorio.
func card_copies(card_id: StringName) -> int:
	for entry: DeckEntry in build_deck().entries:
		if entry.card != null and entry.card.id == card_id:
			return entry.count
	return 0


## Le copie massime di una battuta in un mazzo, dalla sua rarita' (0 = illimitate).
func card_limit(card_id: StringName) -> int:
	var card: CardData = CardLibrary.find_by_id(card_id)
	if card == null:
		return 0
	var profile: RarityProfile = RarityTable.load_default().get_profile(card.rarity)
	return profile.copy_limit if profile != null else 0


## True se un'altra copia ci sta ancora (le rarita' alte hanno un limite).
func can_add_card(card_id: StringName) -> bool:
	var limit: int = card_limit(card_id)
	return limit <= 0 or card_copies(card_id) < limit


## Una battuta comprata entra nel repertorio.
func add_card(card_id: StringName) -> void:
	deck_extra[card_id] = int(deck_extra.get(card_id, 0)) + 1
	changed.emit()


## Sposta una copia comprata tra repertorio e "messe da parte".
func shelve_card(card_id: StringName, to_shelf: bool) -> bool:
	if not to_shelf and not can_add_card(card_id):
		return false
	var source: Dictionary = deck_extra if to_shelf else deck_shelf
	var target: Dictionary = deck_shelf if to_shelf else deck_extra
	if int(source.get(card_id, 0)) <= 0:
		return false
	source[card_id] = int(source[card_id]) - 1
	if int(source[card_id]) <= 0:
		source.erase(card_id)
	target[card_id] = int(target.get(card_id, 0)) + 1
	changed.emit()
	return true


#endregion
