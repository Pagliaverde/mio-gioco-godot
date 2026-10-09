## Le monete e le carte comprate: quello che il negozio ricorda.
##
## [b]Perche' un file suo e non [SaveGame]:[/b] il negozio si apre dal menu
## principale, dove una partita non e' ancora in corso. [SaveGame] salva i nodi
## della [i]scena aperta[/i]: dal menu non c'e' nessuna scena da salvare, quindi
## le monete non ci sarebbero. [ShopWallet] le tiene in
## [code]user://wallet.cfg[/code], come [StorySave] tiene i finali visti.
##
## [b]Cosa ci sta dentro:[/b] le monete e gli id delle carte comprate. Nient'altro.
## Le carte vere vivono in [CardDatabase]; qui c'e' solo "quali ho".
##
## Vedi [code]Shop/README.md[/code].
class_name ShopWallet extends RefCounted


## Dove finisce il portafoglio.
const PATH := "user://wallet.cfg"

const SECTION_MONEY := "money"
const SECTION_CARDS := "cards"

const KEY_COINS := "coins"
const KEY_OWNED := "owned"


#region Primo avvio


## True se non hai mai aperto il negozio: non c'e' ancora un portafoglio.
static func is_first_time() -> bool:
	return not FileAccess.file_exists(PATH)


## Crea il portafoglio la prima volta, con [param starting_coins] monete.
##
## [b]Quanto[/b] si parte lo decide [constant ShopCatalog.STARTING_COINS], non
## questa classe: qui c'e' solo la memoria.
##
## Chiamala all'apertura del negozio: se il file c'e' gia' non fa niente, quindi
## non si possono ricevere monete due volte. Per [b]regalare[/b] monete durante
## il gioco usa [method add_coins], non questa.
static func ensure_started(starting_coins: int) -> void:
	if not is_first_time():
		return

	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_MONEY, KEY_COINS, starting_coins)
	_save(config)


#endregion


#region Monete


## Quante monete hai.
static func coins() -> int:
	var config: ConfigFile = _load()
	return int(config.get_value(SECTION_MONEY, KEY_COINS, 0))


## Aggiunge monete (o le toglie, con un numero negativo). Ritorna il nuovo totale.
##
## Non scende mai sotto zero: e' una rete di sicurezza, non una regola di gioco.
static func add_coins(amount: int) -> int:
	var config: ConfigFile = _load()
	var total: int = maxi(int(config.get_value(SECTION_MONEY, KEY_COINS, 0)) + amount, 0)
	config.set_value(SECTION_MONEY, KEY_COINS, total)
	_save(config)
	return total


## Prova a spendere [param amount] monete.
##
## Ritorna [code]true[/code] se ce l'hai fatta e le monete sono state scalate,
## [code]false[/code] se non bastavano (e in quel caso non tocca niente).
static func spend(amount: int) -> bool:
	if amount <= 0:
		return true

	var config: ConfigFile = _load()
	var total: int = int(config.get_value(SECTION_MONEY, KEY_COINS, 0))
	if total < amount:
		return false

	config.set_value(SECTION_MONEY, KEY_COINS, total - amount)
	_save(config)
	return true


#endregion

#region Carte possedute


## True se possiedi gia' questa carta.
static func owns(card_id: StringName) -> bool:
	return owned_ids().has(str(card_id))


## Registra una carta come comprata. Chiamarla due volte non fa danno.
static func own(card_id: StringName) -> void:
	var id: String = str(card_id)
	if id.is_empty():
		return

	var config: ConfigFile = _load()
	var owned: Array = config.get_value(SECTION_CARDS, KEY_OWNED, [])
	if owned.has(id):
		return

	owned.append(id)
	config.set_value(SECTION_CARDS, KEY_OWNED, owned)
	_save(config)


## Gli id delle carte che possiedi.
static func owned_ids() -> PackedStringArray:
	var config: ConfigFile = _load()
	var out: PackedStringArray = []
	for raw: Variant in config.get_value(SECTION_CARDS, KEY_OWNED, []):
		out.append(str(raw))
	return out


## Quante carte possiedi.
static func owned_count() -> int:
	return owned_ids().size()


#endregion


## Azzera tutto: monete e carte. Serve ai test e per ricominciare da capo.
static func reset() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_MONEY, KEY_COINS, 0)
	config.set_value(SECTION_CARDS, KEY_OWNED, [])
	_save(config)


static func _load() -> ConfigFile:
	var config: ConfigFile = ConfigFile.new()
	# Se il file non esiste ancora, load() fallisce e la config resta vuota:
	# e' il caso della prima partita, e va benissimo cosi'.
	config.load(PATH)
	return config


static func _save(config: ConfigFile) -> void:
	var error: Error = config.save(PATH)
	if error != OK:
		push_warning("ShopWallet: impossibile salvare %s (errore %d)" % [PATH, error])
