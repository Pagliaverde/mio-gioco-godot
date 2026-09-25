extends CharacterBody2D

@onready var slime_animation: AnimatedSprite2D = $SlimeAnimation

# Velocità molto ridotta per passi brevi
const SPEED = 30.0
const DIALOGO_SLIME = preload("res://Asset/Dialogue/DialogueChat/Slime_Dialogue.dialogue")

var move_timer: float = 0.0
var is_moving: bool = false
var last_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	pick_random_state()

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
			
# Esempio: quando premi il tasto "ui_accept" (Invio/Spazio)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		DialogueManager.show_example_dialogue_balloon(DIALOGO_SLIME, "start")
