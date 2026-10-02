## Gioca tutta la storia da sola, senza finestra, e controlla che arrivi in fondo.
##
## [b]Come si usa[/b] (e' una scena, non uno script: servono gli autoload):
## [codeblock]
## godot --headless --path . res://Cards/tools/check_story.tscn
## [/codeblock]
## Usa [member StoryDirector.auto_pilot]: sceglie sempre il primo pulsante e
## fa giocare un'IA al posto tuo. Esce con codice 1 se qualcosa non torna.
extends Node


var _done: bool = false
var _ending: StringName = &""
var _frames: int = 0


func _ready() -> void:
	StoryDirector.auto_pilot = true
	SaveGame.erase()

	var scene: PackedScene = load("res://Story/story.tscn")
	var story: StoryDirector = scene.instantiate()
	story.run_finished.connect(_on_finished)
	add_child(story)


func _process(_delta: float) -> void:
	_frames += 1
	if _done:
		var ok: bool = _ending != &"" and not SaveGame.has_save()
		if ok:
			print("[check_story] OK: storia completata in %d frame, finale '%s'." % [_frames, _ending])
			get_tree().quit(0)
		else:
			print("[check_story] ERRORE: finale '%s', salvataggio ancora presente: %s" % [_ending, SaveGame.has_save()])
			get_tree().quit(1)
		set_process(false)
		return
	if _frames > 200000:
		print("[check_story] ERRORE: la storia non e' arrivata in fondo.")
		get_tree().quit(1)
		set_process(false)


func _on_finished(ending_id: StringName) -> void:
	_ending = ending_id
	_done = true
