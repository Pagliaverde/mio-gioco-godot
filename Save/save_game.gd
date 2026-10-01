## Il salvataggio della partita: uno solo, in [code]user://savegame.txt[/code].
##
## [b]Non sa niente del gioco.[/b] Quando salvi, attraversa la scena aperta e
## chiede i dati ai nodi iscritti al gruppo [code]save_state[/code] che sanno
## rispondere a due domande:
## [codeblock]
## func get_save_data() -> Variant:
##     return {"vite": 3, "dove": position}
##
## func apply_save_data(data: Variant) -> void:
##     position = data["dove"]
## [/codeblock]
##
## Un nodo senza niente da salvare non si iscrive e fine: non c'e' niente da
## registrare da nessun'altra parte, ne' da toccare in questo file.
##
## [b]Formato:[/b] [method var_to_str], non JSON. Cosi' [Vector2], [Color],
## [NodePath], i dizionari e gli array si scrivono e si rileggono da soli, senza
## conversioni a mano.
##
## Vedi [code]Save/README.md[/code].
class_name SaveGame
extends RefCounted


## Dove finisce il salvataggio. Uno solo, per ora.
const SAVE_PATH := "user://savegame.txt"

## Il gruppo dei nodi che partecipano al salvataggio.
const GROUP := &"save_state"

## Versione del formato. Alzala quando cambia la forma dei dati: cosi' i
## salvataggi vecchi vengono rifiutati invece di essere letti male.
const VERSION := 1

## Dopo quanto scade un caricamento rimasto in attesa, in millisecondi.
##
## Serve perche' caricare una partita puo' voler dire cambiare scena, e chi
## chiama [method load_into] non puo' sapere quando i nodi nuovi sono pronti.
## Sono loro a presentarsi con [method apply_to] appena entrano nell'albero.
## Questa e' la rete di sicurezza: se nessuno si presenta, i dati non restano
## appesi per sempre.
const PENDING_TIMEOUT_MS := 5000


## I dati in attesa di essere applicati, per nodo.
static var _pending: Dictionary = {}

## Quando sono stati messi in attesa (millisecondi di engine).
static var _pending_since: int = 0


#region Leggere e scrivere


## True se c'e' un salvataggio su disco.
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Il salvataggio su disco, o un dizionario vuoto se non c'e' o non si legge.
##
## Un file corrotto o di una versione vecchia viene ignorato con un avviso in
## Output: meglio una partita nuova che dati letti male.
static func read() -> Dictionary:
	if not has_save():
		return {}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveGame: salvataggio illeggibile (%s)." % error_string(FileAccess.get_open_error()))
		return {}

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = str_to_var(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveGame: il salvataggio non ha il formato giusto, lo ignoro.")
		return {}

	var data: Dictionary = parsed
	var version: int = int(data.get("version", 0))
	if version != VERSION:
		push_warning("SaveGame: salvataggio di una versione diversa (%d invece di %d), lo ignoro." % [
			version, VERSION,
		])
		return {}

	return data


## Salva la partita e ritorna un referto:
## [code]{"ok": bool, "nodes": int, "reason": String, "scene": String}[/code].
##
## [b][code]nodes[/code] e' quanti nodi hanno davvero risposto.[/b] Se e' zero
## il file viene scritto lo stesso: e' un salvataggio valido, solo vuoto. Succede
## nelle scene dove non c'e' ancora niente da ricordare.
static func save_now(tree: SceneTree) -> Dictionary:
	var scene: Node = tree.current_scene
	if scene == null:
		return {"ok": false, "nodes": 0, "reason": "no_scene"}

	var nodes: Dictionary = _collect(scene, tree)
	var payload: Dictionary = {
		"version": VERSION,
		"scene": scene.scene_file_path,
		"time": Time.get_unix_time_from_system(),
		"nodes": nodes,
	}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: non riesco a scrivere il salvataggio (%s)." % error_string(FileAccess.get_open_error()))
		return {"ok": false, "nodes": nodes.size(), "reason": "write_error"}

	file.store_string(var_to_str(payload))
	file.close()

	return {"ok": true, "nodes": nodes.size(), "scene": scene.scene_file_path}


## Carica il salvataggio. Cambia scena se serve, poi i nodi si servono da soli.
##
## Ritorna [code]{"ok": bool, "nodes": int, "changed": bool}[/code]. Con
## [code]changed = true[/code] i dati sono in attesa e verranno applicati dai
## nodi della scena nuova (vedi [method apply_to]), quindi [code]nodes[/code] e'
## quanti ne verranno toccati, non quanti ne sono gia' stati.
static func load_into(tree: SceneTree) -> Dictionary:
	var data: Dictionary = read()
	if data.is_empty():
		return {"ok": false, "nodes": 0, "changed": false, "reason": "no_save"}

	var nodes: Dictionary = data.get("nodes", {})
	var path: String = String(data.get("scene", ""))

	# Il salvataggio e' della scena in cui siamo gia': applichiamo e basta.
	var scene: Node = tree.current_scene
	if scene != null and not path.is_empty() and scene.scene_file_path == path:
		return {"ok": true, "nodes": _apply(scene, nodes), "changed": false}

	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("SaveGame: la scena del salvataggio non esiste piu': %s" % path)
		return {"ok": false, "nodes": 0, "changed": false, "reason": "missing_scene"}

	_pending = nodes
	_pending_since = Time.get_ticks_msec()
	tree.change_scene_to_file(path)
	return {"ok": true, "nodes": nodes.size(), "changed": true, "scene": path}


## Cancella il salvataggio.
static func erase() -> void:
	if not has_save():
		return
	var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK:
		push_warning("SaveGame: non riesco a cancellare il salvataggio (%s)." % error_string(error))


#endregion

#region Partecipare al salvataggio


## Un nodo si presenta coi suoi dati salvati: li applica se erano i suoi.
##
## Da chiamare in [method Node._ready]. Serve perche' caricando si puo' passare
## da un'altra scena, e in quel momento i nodi non esistono ancora: sono loro a
## farsi avanti quando nascono.
##
## Ritorna true se c'erano dati per lui.
static func apply_to(node: Node) -> bool:
	if _pending.is_empty():
		return false
	if Time.get_ticks_msec() - _pending_since > PENDING_TIMEOUT_MS:
		_pending = {}
		return false
	if not node.is_inside_tree():
		return false

	var scene: Node = node.get_tree().current_scene
	if scene == null:
		return false

	var key: String = String(scene.get_path_to(node))
	if not _pending.has(key):
		return false

	var data: Variant = _pending[key]
	_pending.erase(key)
	return _apply_one(node, data)


#endregion

#region Per i menu


## Una riga leggibile sul salvataggio ("3 elementi, 2 ore fa"), o "" se non c'e'.
static func describe() -> String:
	var data: Dictionary = read()
	if data.is_empty():
		return ""

	var nodes: Dictionary = data.get("nodes", {})
	var parts: PackedStringArray = []

	var when: float = float(data.get("time", 0.0))
	if when > 0.0:
		parts.append(_ago(when))

	parts.append("%d element%s" % [nodes.size(), "o" if nodes.size() == 1 else "i"])
	return ", ".join(parts)


## Quanti nodi verrebbero toccati dal salvataggio su disco.
static func saved_node_count() -> int:
	var data: Dictionary = read()
	var nodes: Dictionary = data.get("nodes", {})
	return nodes.size()


#endregion

#region Interni


## Raccoglie i dati di tutti i nodi iscritti che stanno dentro la scena.
static func _collect(scene: Node, tree: SceneTree) -> Dictionary:
	var out: Dictionary = {}
	for node: Node in tree.get_nodes_in_group(GROUP):
		if not scene.is_ancestor_of(node):
			continue
		if not node.has_method(&"get_save_data"):
			push_warning("SaveGame: '%s' e' nel gruppo di salvataggio ma non ha get_save_data()." % node.name)
			continue
		out[String(scene.get_path_to(node))] = node.get_save_data()
	return out


## Applica i dati a tutti i nodi della scena che li ritrova. Ritorna quanti.
static func _apply(scene: Node, nodes: Dictionary) -> int:
	var applied: int = 0
	for key: String in nodes:
		var node: Node = scene.get_node_or_null(NodePath(key))
		if node == null:
			continue
		if _apply_one(node, nodes[key]):
			applied += 1
	return applied


static func _apply_one(node: Node, data: Variant) -> bool:
	if not node.has_method(&"apply_save_data"):
		push_warning("SaveGame: '%s' e' nel gruppo di salvataggio ma non ha apply_save_data()." % node.name)
		return false
	node.apply_save_data(data)
	return true


## "2 ore fa", "3 giorni fa"... da un'ora Unix.
static func _ago(unix_time: float) -> String:
	var seconds: int = int(maxf(Time.get_unix_time_from_system() - unix_time, 0.0))
	if seconds < 60:
		return "adesso"
	if seconds < 3600:
		var minutes: int = seconds / 60
		return "%d minut%s fa" % [minutes, "o" if minutes == 1 else "i"]
	if seconds < 86400:
		var hours: int = seconds / 3600
		return "%d or%s fa" % [hours, "a" if hours == 1 else "e"]
	var days: int = seconds / 86400
	return "%d giorn%s fa" % [days, "o" if days == 1 else "i"]


#endregion
