## Fotografa le schermate della storia, per controllarle senza giocare.
##
## Serve una finestra (anche virtuale, es. [code]xvfb-run[/code]):
## [codeblock]
## xvfb-run -a godot --path . --rendering-driver opengl3 res://Cards/tools/screenshot_story.tscn
## [/codeblock]
## Scrive i PNG in [code]user://screenshots/[/code]: il camerino, una carta
## maschera, la platea, la scelta della maschera, una battaglia, il finale.
extends Node


const OUT_DIR: String = "user://screenshots/"

var _story: StoryDirector
var _shots: int = 0
var _last_text: String = ""
var _wanted: Array[String] = [
	"Ti svegli", "La mano trova", "Da qui si vede la platea", "Per la scena con",
	"Si sono girati", "Tre modi di finire",
]
var _battle_shot: bool = false
var _frames: int = 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	StoryDirector.auto_pilot = false
	SaveGame.erase()
	_story = (load("res://Story/story.tscn") as PackedScene).instantiate()
	add_child(_story)
	_story.run_finished.connect(func(_id: StringName) -> void: get_tree().quit(0))


func _process(_delta: float) -> void:
	_frames += 1
	if _frames > 120000:
		get_tree().quit(1)
		return
	if _frames % 6 != 0:
		return

	# La battaglia: la fotografiamo appena compare, poi la facciamo giocare all'IA.
	var battle: StoryBattle = _find_battle()
	if battle != null:
		if not _battle_shot and battle.state != null and battle.state.turn_number >= 3 and _frames % 30 == 0:
			_battle_shot = true
			_snap("battaglia")
		if _frames % 6 == 0:
			var ai: SimAI = SimAI.new(CardTypes.AiPolicy.ESTIMATED_RISK)
			ai.risk_tolerance = 0.3
			if battle._ended:
				battle._on_result_pressed()
			else:
				battle.autoplay_my_turn(ai)
		return

	var text: String = _story._narration.text
	if text == _last_text:
		return
	# Aspetta che il testo sia tutto comparso.
	if _story._narration.visible_ratio < 1.0:
		_story._narration.visible_ratio = 1.0
		return
	_last_text = text

	for key: String in _wanted:
		if text.begins_with(key) or text.contains(key):
			_snap(key.to_lower().replace(" ", "_"))
			_wanted.erase(key)
			break

	# Avanti: il primo pulsante (Riprova compreso, se perde).
	await get_tree().create_timer(0.25).timeout
	_story._on_choice_pressed(0)


func _find_battle() -> StoryBattle:
	for child: Node in _story._battle_holder.get_children():
		if child is StoryBattle:
			return child
	return null


func _snap(label: String) -> void:
	# Sotto una finestra virtuale (xvfb) Godot non disegna da solo: forziamo noi.
	RenderingServer.force_draw(false)
	var image: Image = get_viewport().get_texture().get_image()
	_shots += 1
	var path: String = "%s%02d_%s.png" % [OUT_DIR, _shots, label]
	image.save_png(path)
	print("[screenshot_story] %s" % path)
