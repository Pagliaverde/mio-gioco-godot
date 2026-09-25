extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword: AudioStreamPlayer2D = $Sword
@onready var walking: AudioStreamPlayer2D = $Walking
@onready var interaction_area: Area2D = $InteractionArea




const SPEED = 300.0

## The input action used to talk to the characters around us.
const INTERACT_ACTION := &"interact"

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false

## Every interaction area (group "interactable") currently in range.
var nearby_interactables: Array[Area2D] = []

## True while a dialogue balloon is open: the player can't move or attack.
var is_in_dialogue: bool = false

## Small cooldown used to swallow the button press that closed the dialogue
## (Space is both "attack" and the key used to advance the dialogue).
var attack_cooldown: float = 0.0


func _ready() -> void:
	interaction_area.area_entered.connect(_on_interaction_area_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_area_exited)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(INTERACT_ACTION) and not is_in_dialogue:
		try_interact()


func _physics_process(_delta: float) -> void:
	# Freeze the player while a dialogue is open
	if is_in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	attack_cooldown = maxf(attack_cooldown - _delta, 0.0)
	if attack_cooldown <= 0.0 and Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
		
	if is_attacking:
		velocity = Vector2.ZERO
		return
	process_movement()
	process_animation()
	move_and_slide()

#----------------------------------------------
#		INTERACTION
#----------------------------------------------

## Called when the player presses the interact button. Talks to the closest
## interactable around us (if there is one).
func try_interact() -> void:
	var area: Area2D = get_closest_interactable()
	if area == null:
		return

	# The "interact()" method can be on the area itself or on its parent (the NPC).
	var target: Node = area if area.has_method("interact") else area.get_parent()
	if target != null and target.has_method("interact"):
		target.interact(self)


## Returns the interaction area that is closest to the player (or null).
func get_closest_interactable() -> Area2D:
	var closest: Area2D = null
	var closest_distance: float = INF
	for area: Area2D in nearby_interactables:
		if not is_instance_valid(area):
			continue
		var distance: float = global_position.distance_to(area.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = area
	return closest


func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable") and not nearby_interactables.has(area):
		nearby_interactables.append(area)


func _on_interaction_area_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)


func _on_dialogue_started(_resource: DialogueResource) -> void:
	is_in_dialogue = true
	velocity = Vector2.ZERO
	if walking.playing:
		walking.stop()
	play_animation("idle", last_direction)


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	is_in_dialogue = false
	# Ignore the same key press that closed the dialogue
	attack_cooldown = 0.1

#----------------------------------------------
#		ANIMATION AND MOVEMENT
#----------------------------------------------

func process_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity =  Vector2.ZERO


func process_animation() -> void:
	if is_attacking:
		return
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
		if not walking.playing:
			walking.play()
	else:
		play_animation("idle", last_direction)
		if walking.playing:
			walking.stop()


func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")

#----------------------------------------------
#		ATTACK
#----------------------------------------------

func attack() -> void:
	is_attacking = true
	sword.play()
	play_animation("attack", last_direction)
	if walking.playing:
		walking.stop()
	


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
	if sword.playing:
		sword.stop()
