## Un personaggio del mondo che non e' il giocatore: boss, negozianti, comparse.
##
## Si costruisce da solo: lo sprite (dallo stesso set del protagonista, o dai
## manichini, o dallo spritesheet degli NPC), la collisione ai piedi, l'area di
## interazione. Sa girarsi, camminare fino a un punto e mostrare un fumetto
## ("!" quando ti vede, come gli allenatori dei giochi di mostri).
class_name WorldCharacter extends CharacterBody2D


## Emesso quando il giocatore gli parla.
signal talked(player: Node)

## Che sprite usa: [code]mc[/code] (il set del protagonista, colorato con
## [member tint]), [code]manichino[/code] o [code]npc[/code] (lo spritesheet
## degli abitanti).
@export_enum("mc", "manichino", "npc") var look: String = "mc"

## Il colore che moltiplica lo sprite: i boss sono il protagonista, di un
## altro colore.
@export var tint: Color = Color.WHITE

## Da che parte guarda all'inizio.
@export var facing: Vector2 = Vector2.DOWN

## Lo stile della maschera dipinta sulla faccia (vuoto = nessuna). Vedi
## [method MaskCard.paint_face].
@export var face_style: String = ""

## Il colore della maschera dipinta.
@export var face_accent: Color = Color(0.85, 0.8, 0.7)

## Scala dello sprite.
@export var sprite_scale: float = 1.0

## Il testo del fumetto di interazione.
@export var prompt: String = "Parla"

var sprite: AnimatedSprite2D
var interaction: Interactable
var _face: Sprite2D = null
var _walk_tween: Tween = null

const NPC_SHEET := "res://Asset/Sprite/NPC/Basic Charakter Spritesheet.png"


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	# Gli abitanti dello spritesheet NPC sono disegnati piu' piccoli.
	if look == "npc" and is_equal_approx(sprite_scale, 1.0):
		sprite_scale = 1.35
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _frames_for(look)
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.position = Vector2(0, -30.0 * sprite_scale) if look != "npc" else Vector2(0, -18.0 * sprite_scale)
	sprite.modulate = tint
	add_child(sprite)

	if face_style != "":
		_face = Sprite2D.new()
		_face.texture = MaskCard.paint_face(22, 24, face_style, face_accent)
		sprite.add_child(_face)

	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(18, 10)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -4)
	add_child(collision)

	interaction = Interactable.create(self, 30.0, Vector2(0, -12))
	interaction.prompt = prompt
	interaction.interacted.connect(func(player: Node) -> void: talked.emit(player))

	face(facing)


## Si gira verso una direzione.
func face(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	facing = dir
	_play("idle", dir)


## Si gira verso un punto (di solito il giocatore).
func face_point(point: Vector2) -> void:
	face(global_position.direction_to(point))


## Cammina fino a [param target] (in coordinate globali), poi si ferma.
func walk_to(target: Vector2, speed: float = 110.0) -> void:
	var distance: float = global_position.distance_to(target)
	if distance < 1.0:
		return
	var dir: Vector2 = global_position.direction_to(target)
	_play("run", dir)
	if _walk_tween != null and _walk_tween.is_valid():
		_walk_tween.kill()
	_walk_tween = create_tween()
	_walk_tween.tween_property(self, "global_position", target, distance / speed)
	await _walk_tween.finished
	face(dir)


## Un fumetto sopra la testa per un attimo ("!", "?", "...").
func emote(text: String, seconds: float = 0.8) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-6, -86 * sprite_scale)
	label.z_index = 60
	add_child(label)
	label.scale = Vector2(0.2, 0.2)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(seconds)
	tween.tween_callback(label.queue_free)
	await tween.finished


func _play(prefix: String, dir: Vector2) -> void:
	if sprite == null:
		return
	WorldSprites.play(sprite, prefix, dir)
	if _face != null:
		var info: Array = WorldSprites.direction_of(dir)
		# La maschera si vede solo di fronte o di lato.
		_face.visible = info[0] != "back"
		_face.position = Vector2(0, -15) + (Vector2(-4 if info[1] else 4, 0) if info[0] == "right" else Vector2.ZERO)
		_face.scale = Vector2(0.7, 1) if info[0] == "right" else Vector2.ONE


func _frames_for(kind: String) -> SpriteFrames:
	match kind:
		"manichino":
			return WorldSprites.frames(WorldSprites.MANNEQUIN_FOLDER)
		"npc":
			return _npc_frames()
	return WorldSprites.frames(WorldSprites.MC_FOLDER)


## Lo spritesheet degli abitanti: 4x4 fotogrammi da 48, una riga per direzione
## (giu', su, sinistra, destra). La sinistra la facciamo specchiando la destra.
static func _npc_frames() -> SpriteFrames:
	var out: SpriteFrames = SpriteFrames.new()
	out.remove_animation(&"default")
	var sheet: Texture2D = load(NPC_SHEET)
	var rows: Dictionary = {"front": 0, "back": 1, "right": 3}
	for direction: String in rows:
		for prefix: String in ["idle", "run"]:
			var animation: StringName = StringName("%s_%s" % [prefix, direction])
			out.add_animation(animation)
			out.set_animation_speed(animation, 3.0 if prefix == "idle" else 8.0)
			var count: int = 2 if prefix == "idle" else 4
			for i: int in count:
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(i * 48, rows[direction] * 48, 48, 48)
				out.add_frame(animation, atlas)
	return out
