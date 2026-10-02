## La memoria della storia: cio' che resta anche dopo un finale.
##
## Il [b]progresso[/b] (zona, gavetta, maschere) passa dal salvataggio del
## gioco, [SaveGame]: [StoryDirector] e' iscritto al gruppo [code]save_state[/code]
## e risponde a [code]get_save_data[/code] / [code]apply_save_data[/code]. Cosi'
## "Salva" nel menu di pausa e "Riprendi" nel menu principale funzionano anche
## per la storia, senza un secondo sistema.
##
## Qui c'e' solo quello che un salvataggio non deve toccare: quante volte hai
## cominciato (il numero sul muro del camerino) e quali finali hai visto.
## In [code]user://story.cfg[/code].
class_name StorySave extends RefCounted


const PATH := "user://story.cfg"


## Quante volte hai cominciato: e' il numero sul muro del camerino.
static func run_count() -> int:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	return int(config.get_value("memory", "runs", 0))


## Una partita nuova: il numero sul muro sale di uno. Ritorna il nuovo numero.
static func begin_new_run() -> int:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	var runs: int = int(config.get_value("memory", "runs", 0)) + 1
	config.set_value("memory", "runs", runs)
	_save(config)
	return runs


## Ricorda un finale visto.
static func remember_ending(ending_id: StringName) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	var seen: Array = config.get_value("memory", "endings", [])
	if not seen.has(str(ending_id)):
		seen.append(str(ending_id))
	config.set_value("memory", "endings", seen)
	_save(config)


## I finali gia' visti.
static func endings_seen() -> PackedStringArray:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	var out: PackedStringArray = []
	for raw: Variant in config.get_value("memory", "endings", []):
		out.append(str(raw))
	return out


static func _save(config: ConfigFile) -> void:
	var error: Error = config.save(PATH)
	if error != OK:
		push_warning("StorySave: impossibile salvare %s (errore %d)" % [PATH, error])
