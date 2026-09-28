## L'insieme dei profili di rarita': il modello di potenza del gioco.
##
## E' una [Resource], quindi puoi salvarla come
## [code]res://Cards/data/rarity_table.tres[/code] e modificarla dall'inspector:
## tutti i numeri della progressione stanno qui, in un posto solo.
##
## Se non ne assegni una, gli strumenti usano [method create_default].
@tool
class_name RarityTable extends Resource


## Dove vive la tabella modificabile dall'inspector.
const DEFAULT_PATH: String = "res://Cards/data/rarity_table.tres"

## I profili, uno per fascia. L'ordine non conta: si cerca per [code]rarity[/code].
@export var profiles: Array[RarityProfile] = []


## Carica la tabella dal disco, oppure crea quella di default se non esiste.
static func load_default() -> RarityTable:
	if ResourceLoader.exists(DEFAULT_PATH):
		var loaded: Resource = ResourceLoader.load(DEFAULT_PATH)
		if loaded is RarityTable:
			return loaded as RarityTable
	return create_default()


## Salva questa tabella nel percorso di default, cosi' diventa modificabile.
func save_default() -> Error:
	return ResourceSaver.save(self, DEFAULT_PATH)


## Carica la tabella e, se manca il file, lo crea con i valori di default.
## Ritorna la tabella utilizzabile.
static func ensure_default_file() -> RarityTable:
	var table: RarityTable = load_default()
	if not ResourceLoader.exists(DEFAULT_PATH):
		table.save_default()
	return table


## Il profilo di una fascia. Ritorna null (con un avviso) se manca.
func get_profile(rarity: CardTypes.Rarity) -> RarityProfile:
	for profile: RarityProfile in profiles:
		if profile != null and profile.rarity == rarity:
			return profile
	push_warning("RarityTable: manca il profilo per la rarita' '%s'." % CardTypes.rarity_name(rarity))
	return null


## Il [code]power_score[/code] atteso per una carta a questo costo e rarita'.
## Ritorna 0.0 se il profilo non esiste.
func power_budget(cost: int, rarity: CardTypes.Rarity) -> float:
	var profile: RarityProfile = get_profile(rarity)
	if profile == null:
		return 0.0
	return profile.power_budget(cost)


## True se il costo rientra nella banda della rarita' indicata.
func is_cost_in_band(cost: int, rarity: CardTypes.Rarity) -> bool:
	var profile: RarityProfile = get_profile(rarity)
	if profile == null:
		return true
	return profile.is_cost_in_band(cost)


## Tutti i profili presenti, in ordine di rarita' crescente.
func ordered() -> Array[RarityProfile]:
	var result: Array[RarityProfile] = []
	for raw_rarity: Variant in [
		CardTypes.Rarity.BASE,
		CardTypes.Rarity.RARE,
		CardTypes.Rarity.EPIC,
		CardTypes.Rarity.LEGENDARY,
		CardTypes.Rarity.UNIQUE,
	]:
		var rarity: CardTypes.Rarity = raw_rarity
		var profile: RarityProfile = get_profile(rarity)
		if profile != null:
			result.append(profile)
	return result


## Crea la tabella di default: le cinque fasce con i numeri consigliati.
##
## Nota come la banda di costo si [b]restringa[/b] salendo di rarita': le carte
## comuni possono costare qualsiasi cosa, le Uniche solo poco. Insieme
## all'efficienza crescente, e' questo che produce la progressione.
static func create_default() -> RarityTable:
	var table: RarityTable = RarityTable.new()

	var base: RarityProfile = RarityProfile.new()
	base.rarity = CardTypes.Rarity.BASE
	base.display_name = "Base"
	base.power_per_mana = 1.6
	base.cost_min = 10
	base.cost_max = 30
	base.copy_limit = 0
	base.drop_weight = 100.0
	base.border_color = Color(0.72, 0.72, 0.75)
	base.flavor = "Materiale di partenza: costosa e debole. Non vince da sola."
	table.profiles.append(base)

	var rare: RarityProfile = RarityProfile.new()
	rare.rarity = CardTypes.Rarity.RARE
	rare.display_name = "Rara"
	rare.power_per_mana = 2.2
	rare.cost_min = 16
	rare.cost_max = 30
	rare.copy_limit = 3
	rare.drop_weight = 40.0
	rare.border_color = Color(0.30, 0.55, 0.95)
	rare.flavor = "Poco rendimento e costo alto: la fascia da sostituire."
	table.profiles.append(rare)

	var epic: RarityProfile = RarityProfile.new()
	epic.rarity = CardTypes.Rarity.EPIC
	epic.display_name = "Epica"
	epic.power_per_mana = 3.0
	epic.cost_min = 12
	epic.cost_max = 26
	epic.copy_limit = 2
	epic.drop_weight = 12.0
	epic.border_color = Color(0.65, 0.35, 0.90)
	epic.flavor = "Buon rendimento a costo ragionevole: il cuore di un mazzo curato."
	table.profiles.append(epic)

	var legendary: RarityProfile = RarityProfile.new()
	legendary.rarity = CardTypes.Rarity.LEGENDARY
	legendary.display_name = "Leggendaria"
	legendary.power_per_mana = 4.0
	legendary.cost_min = 10
	legendary.cost_max = 20
	legendary.copy_limit = 1
	legendary.drop_weight = 3.0
	legendary.border_color = Color(0.95, 0.75, 0.20)
	legendary.flavor = "Economica e forte: una sola copia, ma si sente."
	table.profiles.append(legendary)

	var unique: RarityProfile = RarityProfile.new()
	unique.rarity = CardTypes.Rarity.UNIQUE
	unique.display_name = "Unica"
	unique.power_per_mana = 5.2
	unique.cost_min = 10
	unique.cost_max = 16
	unique.copy_limit = 1
	unique.drop_weight = 0.5
	unique.border_color = Color(1.0, 0.42, 0.18)
	unique.flavor = "Il vertice della collezione: costa poco e fa malissimo."
	table.profiles.append(unique)

	return table


## Tabella riassuntiva leggibile, per i report dei tool.
func describe() -> String:
	var lines: PackedStringArray = []
	var sep: String = "=".repeat(78)
	lines.append(sep)
	lines.append("  MODELLO DI POTENZA  (potenza per mana, banda costo, copie, peso drop)")
	lines.append(sep)
	lines.append("  %-14s %9s %10s %13s %7s" % ["RARITA'", "PWR/MANA", "COSTO", "COPIE/MAZZO", "DROP"])
	lines.append("-".repeat(78))
	for profile: RarityProfile in ordered():
		lines.append("  %-14s %9.1f %10s %13s %7.1f" % [
			profile.display_name,
			profile.power_per_mana,
			profile.band_label(),
			profile.copies_label(),
			profile.drop_weight,
		])
	lines.append(sep)
	return "\n".join(lines)
