extends CharacterBody2D

@onready var slime_animation: AnimatedSprite2D = $SlimeAnimation
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Node2D = $InteractionArea/Prompt

# Velocità molto ridotta per passi brevi
const SPEED = 30.0
const DIALOGO_SLIME = preload("res://Asset/Dialogue/DialogueChat/Slime_Dialogue.dialogue")

## The balloon that is currently open for this NPC (if any).
var active_balloon: Node = null

## True while the player is inside our interaction area.
var is_player_nearby: bool = false

var move_timer: float = 0.0
var is_moving: bool = false
var last_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	pick_random_state()
	interaction_prompt.visible = false
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)

func _physics_process(delta: float) -> void:
	move_timer -= delta
	
	if move_timer <= 0.0:
		pick_random_state()
	
	process_animation()
	move_and_slide()

#----------------------------------------------
#		ANIMATION AND MOVEMENT
#----------------------------------------------

func pick_random_state() -> void:
	# 75% di probabilità di stare FERMO, 25% di probabilità di muoversi
	is_moving = randf() < 0.4
	
	if is_moving:
		# Genera una direzione casuale
		var random_x = randf_range(-1.0, 1.0)
		var random_y = randf_range(-1.0, 1.0)
		var direction = Vector2(random_x, random_y).normalized()
		
		velocity = direction * SPEED
		if direction != Vector2.ZERO:
			last_direction = direction
		
		# Movimento brevissimo (da 0.3 a 0.7 secondi)
		move_timer = randf_range(0.3, 0.7)
	else:
		velocity = Vector2.ZERO
		# Sta fermo a lungo (da 1.5 a 2.5 secondi)
		move_timer = randf_range(0.5, 3.5)


func process_animation() -> void:
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)


func play_animation(prefix: String, dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		slime_animation.flip_h = dir.x < 0
		slime_animation.play(prefix + "_right")
	else:
		slime_animation.flip_h = false
		if dir.y < 0:
			slime_animation.play(prefix + "_up")
		elif dir.y > 0:
			slime_animation.play(prefix + "_down")

#----------------------------------------------
#		INTERACTION
#----------------------------------------------

## Called by the player when they press the interact button next to us.
func interact(interactor: Node = null) -> void:
	# Never open a second dialogue on top of an existing one
	if is_instance_valid(active_balloon):
		return

	# Stand still and hide the prompt while we talk
	set_physics_process(false)
	velocity = Vector2.ZERO
	interaction_prompt.visible = false

	# Pass ourselves (and the player) to the dialogue so it can read our variables
	var extra_game_states: Array = [self]
	if interactor != null:
		extra_game_states.append(interactor)

	active_balloon = DialogueManager.show_dialogue_balloon(DIALOGO_SLIME, "start", extra_game_states)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	active_balloon = null
	set_physics_process(true)
	interaction_prompt.visible = is_player_nearby


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		interaction_prompt.visible = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		interaction_prompt.visible = false
