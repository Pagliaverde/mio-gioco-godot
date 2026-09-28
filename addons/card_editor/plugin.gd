## Plugin dell'editor: aggiunge il dock "Carte".
##
## [b]E' volutamente minuscolo:[/b] tutta l'interfaccia vive in
## [code]res://addons/card_editor/card_browser.gd[/code]. Qui c'e' solo
## l'aggancio al dock, cosi' il plugin resta facile da leggere e da aggiornare.
##
## Per attivarlo: Progetto > Impostazioni progetto > Plugin > "Card Editor".
@tool
extends EditorPlugin


const CARD_BROWSER_SCRIPT: Script = preload("res://addons/card_editor/card_browser.gd")

var _browser: Control


func _enter_tree() -> void:
	_browser = CARD_BROWSER_SCRIPT.new()
	_browser.name = "Carte"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _browser)


func _exit_tree() -> void:
	if is_instance_valid(_browser):
		remove_control_from_docks(_browser)
		_browser.queue_free()
	_browser = null
