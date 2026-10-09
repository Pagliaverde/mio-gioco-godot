## Il palco della battaglia: i due attori uno di fronte all'altro, sotto i
## riflettori, con il pubblico di manichini in primo piano.
##
## [b]Non cambia niente del motore delle carte:[/b] e' una finestra su
## [BattleState]. Ascolta i suoi segnali e li fa vedere: chi recita una battuta
## si muove e lancia la carta, chi va fuori copione diventa rosso, chi prende
## un colpo trema e perde i numeri sopra la testa.
##
## Sta dentro [StoryBattle] ([member StoryBattle.stage]), al centro.
class_name BattleStage extends Control


## Come appare il rivale: [code]{"look", "tint", "face_style", "face_accent"}[/code]
## (vedi [WorldCharacter]).
var enemy_look: Dictionary = {}

var _state: BattleState = null
var _player_sprite: AnimatedSprite2D
var _enemy_sprite: AnimatedSprite2D
var _enemy_face: Sprite2D = null
var _last_health: Dictionary = {}
var _audience: Array[AnimatedSprite2D] = []
var _time: float = 0.0


func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(420, 300)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_enemy_sprite = AnimatedSprite2D.new()
	var look: String = str(enemy_look.get("look", "mc"))
	_enemy_sprite.sprite_frames = WorldSprites.frames(WorldSprites.MANNEQUIN_FOLDER if look == "manichino" else WorldSprites.MC_FOLDER)
	_enemy_sprite.modulate = enemy_look.get("tint", Color.WHITE)
	_enemy_sprite.scale = Vector2(3, 3)
	add_child(_enemy_sprite)
	var face_style: String = str(enemy_look.get("face_style", ""))
	if face_style != "":
		_enemy_face = Sprite2D.new()
		_enemy_face.texture = MaskCard.paint_face(22, 24, face_style, enemy_look.get("face_accent", Color(0.85, 0.8, 0.7)))
		_enemy_face.position = Vector2(0, -15)
		_enemy_sprite.add_child(_enemy_face)
	WorldSprites.play(_enemy_sprite, "idle", Vector2.DOWN)

	_player_sprite = AnimatedSprite2D.new()
	_player_sprite.sprite_frames = WorldSprites.frames(WorldSprites.MC_FOLDER)
	_player_sprite.scale = Vector2(3.6, 3.6)
	add_child(_player_sprite)
	WorldSprites.play(_player_sprite, "idle", Vector2.UP)

	# Il pubblico: teste di manichino in primo piano, di spalle.
	for i: int in 9:
		var head: AnimatedSprite2D = AnimatedSprite2D.new()
		head.sprite_frames = WorldSprites.frames(WorldSprites.MANNEQUIN_FOLDER)
		head.scale = Vector2(2.2, 2.2)
		head.modulate = Color(0.35, 0.28, 0.4)
		WorldSprites.play(head, "idle", Vector2.UP)
		head.speed_scale = 0.0
		add_child(head)
		_audience.append(head)

	resized.connect(_layout)
	_layout()


## Collega il palco a una battaglia gia' cominciata.
func attach(state: BattleState) -> void:
	_state = state
	_last_health = {state.player_a: state.player_a.health, state.player_b: state.player_b.health}
	state.card_played.connect(_on_card_played)
	state.busted.connect(_on_busted)
	state.turn_resolved.connect(_on_turn_resolved)


func _layout() -> void:
	_enemy_sprite.position = Vector2(size.x * 0.68, size.y * 0.42)
	_player_sprite.position = Vector2(size.x * 0.30, size.y * 0.70)
	for i: int in _audience.size():
		_audience[i].position = Vector2(size.x * (i + 0.5) / _audience.size(), size.y + 30)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	# Il fondale.
	draw_rect(Rect2(0, 0, w, h), Color("1a0f22"))
	for i: int in 12:
		var t: float = float(i) / 12.0
		draw_rect(Rect2(0, h * 0.55 * t, w, h * 0.55 / 12.0 + 1.0), Color("2d1b3d").lerp(Color("4a2a4f"), t))
	# Le assi del palco.
	var floor_top: float = h * 0.55
	draw_rect(Rect2(0, floor_top, w, h - floor_top), Color("5a3c24"))
	for i: int in 9:
		var y: float = floor_top + (h - floor_top) * pow(float(i) / 9.0, 1.4)
		draw_line(Vector2(0, y), Vector2(w, y), Color("3a2416"), 2.0)
	draw_rect(Rect2(0, floor_top - 4, w, 4), Color("c9a24a"))
	# I coni dei riflettori.
	var flicker: float = 0.9 + 0.1 * sin(_time * 3.0)
	_cone(Vector2(w * 0.68, -10), _enemy_sprite.position + Vector2(0, 60), 90.0, Color(1.0, 0.9, 0.6, 0.12 * flicker))
	_cone(Vector2(w * 0.30, -10), _player_sprite.position + Vector2(0, 70), 110.0, Color(0.8, 0.85, 1.0, 0.12 * flicker))
	draw_set_transform(Vector2.ZERO)
	# Le ombre ai piedi.
	_oval(_enemy_sprite.position + Vector2(0, 88), Vector2(60, 14), Color(0, 0, 0, 0.35))
	_oval(_player_sprite.position + Vector2(0, 104), Vector2(70, 16), Color(0, 0, 0, 0.35))
	# Il sipario ai lati.
	for side: int in 2:
		var x0: float = 0.0 if side == 0 else w - w * 0.1
		for k: int in 6:
			var fold: float = 0.5 + 0.5 * sin(float(k) * 1.7)
			draw_rect(Rect2(x0 + k * w * 0.1 / 6.0, 0, w * 0.1 / 6.0 + 1.0, h), Color("5e0f1e").lerp(Color("b8283f"), fold))
	draw_rect(Rect2(0, 0, w, 22), Color("7a1f33"))
	for k: int in int(w / 30.0) + 1:
		draw_circle(Vector2(k * 30.0 + 15.0, 22), 10.0, Color("7a1f33"))
	draw_rect(Rect2(0, 18, w, 3), Color("c9a24a"))


func _cone(top: Vector2, bottom: Vector2, half_width: float, color: Color) -> void:
	var points: PackedVector2Array = [top + Vector2(-12, 0), top + Vector2(12, 0), bottom + Vector2(half_width, 0), bottom - Vector2(half_width, 0)]
	draw_colored_polygon(points, color)


func _oval(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, radii.y / radii.x))
	draw_circle(Vector2.ZERO, radii.x, color)
	draw_set_transform(Vector2.ZERO)


#region Reazioni


func _sprite_of(player: BattlePlayer) -> AnimatedSprite2D:
	return _player_sprite if player == _state.player_a else _enemy_sprite


func _on_card_played(instance: CardInstance) -> void:
	var actor: AnimatedSprite2D = _sprite_of(_state.active)
	var target: AnimatedSprite2D = _enemy_sprite if actor == _player_sprite else _player_sprite
	var dir: Vector2 = Vector2.UP if actor == _player_sprite else Vector2.DOWN
	WorldSprites.play(actor, "pick", dir)
	actor.animation_finished.connect(func() -> void: WorldSprites.play(actor, "idle", dir), CONNECT_ONE_SHOT)
	_throw_card(actor.position + Vector2(0, -60), target.position + Vector2(0, -40), instance.data.get_color())


func _on_busted(_instance: CardInstance) -> void:
	var actor: AnimatedSprite2D = _sprite_of(_state.active)
	_float_text(actor.position + Vector2(0, -150), "FUORI COPIONE!", Color(1.0, 0.35, 0.35), 30)
	var base: Color = actor.modulate
	var tween: Tween = create_tween()
	tween.tween_property(actor, "modulate", Color(1.0, 0.3, 0.3), 0.1)
	tween.tween_property(actor, "modulate", base, 0.4)


func _on_turn_resolved(_report: Dictionary) -> void:
	for player: BattlePlayer in [_state.player_a, _state.player_b]:
		var before: int = int(_last_health.get(player, player.health))
		var delta: int = player.health - before
		_last_health[player] = player.health
		var sprite: AnimatedSprite2D = _sprite_of(player)
		if delta < 0:
			_float_text(sprite.position + Vector2(0, -120), str(delta), Color(1.0, 0.85, 0.4), 34)
			_shake(sprite)
		elif delta > 0:
			_float_text(sprite.position + Vector2(0, -120), "+%d" % delta, Color(0.5, 1.0, 0.6), 30)
		if player.is_defeated():
			var fall: Tween = create_tween().set_parallel(true)
			fall.tween_property(sprite, "rotation", deg_to_rad(80.0), 0.6)
			fall.tween_property(sprite, "modulate:a", 0.35, 0.6)


func _throw_card(from: Vector2, to: Vector2, color: Color) -> void:
	var card: ColorRect = ColorRect.new()
	card.color = color
	card.size = Vector2(22, 30)
	card.pivot_offset = card.size * 0.5
	card.position = from - card.size * 0.5
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var border: ReferenceRect = ReferenceRect.new()
	border.border_color = Color(1, 0.95, 0.8)
	border.editor_only = false
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(border)
	var tween: Tween = create_tween().set_parallel(true)
	var seconds: float = 0.45 * Settings.motion_scale()
	tween.tween_property(card, "position", to - card.size * 0.5, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "rotation", TAU, seconds)
	tween.chain().tween_property(card, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(card.queue_free)


func _float_text(at: Vector2, text: String, color: Color, font_size: int) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 8)
	label.position = at - Vector2(60, 0)
	label.size = Vector2(120, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", at.y - 50.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


func _shake(sprite: AnimatedSprite2D) -> void:
	if Settings.screen_shake() <= 0.0:
		return
	var origin: Vector2 = sprite.position
	var tween: Tween = create_tween()
	for i: int in 5:
		tween.tween_property(sprite, "position", origin + Vector2(randf_range(-8, 8), 0) * Settings.screen_shake(), 0.04)
	tween.tween_property(sprite, "position", origin, 0.04)


#endregion
