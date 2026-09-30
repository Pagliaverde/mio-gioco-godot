## Movimento, animazioni e interazione del protagonista.
##
## [b]Convenzione delle animazioni[/b] (set MC2):
## [codeblock]
##   idle_front / idle_back / idle_right
##   run_front  / run_back  / run_right
##   pick_front / pick_back / pick_right
## [/codeblock]
##
## [b]Non esiste "_left":[/b] il personaggio che va a sinistra e' quello che va
## a destra, specchiato con [code]flip_h[/code]. E' lo standard della pixel art
## e dimezza gli sprite da disegnare.
##
## [b]Le tre famiglie:[/b]
## - [code]idle[/code] fermo
## - [code]run[/code] in movimento
## - [code]pick[/code] interazione, una volta sola
##
## [b]Non ci sono animazioni di attacco.[/b] Vedi [member ANIM_ATTACK].
extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword: AudioStreamPlayer2D = $Sword
@onready var walking: AudioStreamPlayer2D = $Walking
@onready var interaction_area: Area2D = $InteractionArea




const SPEED := 300.0

## L'azione di input per parlare/interagire con chi ci sta intorno.
const INTERACT_ACTION := &"interact"

# --- Animazioni --------------------------------------------------------------

## Le tre famiglie di animazione.
const ANIM_IDLE := "idle"
const ANIM_RUN := "run"
const ANIM_PICK := "pick"

## Animazione da usare per l'attacco. Il set MC2 non ne ha una, quindi per ora
## l'attacco e' solo sonoro.
##
## [b]Quando avrai gli sprite:[/b] aggiungi al SpriteFrames le animazioni
## [code]attack_front[/code] / [code]attack_back[/code] / [code]attack_right[/code]
## e metti qui [code]"attack"[/code]. Nessun'altra modifica necessaria.
const ANIM_ATTACK := ""

## Suffissi di direzione. "_left" non esiste: si specchia "_right".
const DIR_FRONT := "front"
const DIR_BACK := "back"
const DIR_RIGHT := "right"

## L'ultima direzione in cui ci si e' mossi (usata a personaggio fermo).
var last_direction: Vector2 = Vector2.RIGHT

## True mentre suona l'animazione di interazione: blocca movimento e altre animazioni.
var is_picking: bool = false

## Animazioni gia' segnalate come mancanti: avvisa una volta sola, non a ogni frame.
var _reported_missing: Dictionary = {}

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

	# Collega il segnale da qui invece di fidarsi di quello salvato nella scena:
	# cosi' l'animazione di interazione funziona anche se la connessione viene
	# persa rifacendo il nodo AnimatedSprite2D.
	if not animated_sprite_2d.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		animated_sprite_2d.animation_finished.connect(_on_animated_sprite_2d_animation_finished)


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
	if attack_cooldown <= 0.0 and Input.is_action_just_pressed("attack") and not is_picking:
		attack()
		
	if is_picking:
		velocity = Vector2.ZERO
		move_and_slide()
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
		# Il personaggio si abbassa/porge verso cio' con cui interagisce.
		play_pick(global_position.direction_to(area.global_position))
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
	# Se l'interazione ha appena avviato il "pick", lo lasciamo finire:
	# sara' _end_pick a riportare il personaggio in idle.
	if not is_picking:
		play_animation(ANIM_IDLE, last_direction)


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
	if is_picking:
		return
	if velocity != Vector2.ZERO:
		play_animation(ANIM_RUN, last_direction)
		if not walking.playing:
			walking.play()
	else:
		play_animation(ANIM_IDLE, last_direction)
		if walking.playing:
			walking.stop()


## Riproduce [code]prefix_direzione[/code], specchiando a sinistra.
##
## [b]In diagonale e in orizzontale si guarda di lato:[/b] e' la vista piu'
## leggibile e servono cosi' solo tre set di sprite (front, back, right).
##
## [param restart] forza il riavvio anche se l'animazione e' la stessa.
## Serve alle animazioni una-tantum come "pick".
func play_animation(prefix: String, dir: Vector2, restart: bool = false) -> void:
	var frames: SpriteFrames = animated_sprite_2d.sprite_frames
	if frames == null:
		return

	var suffix: String = _direction_suffix(dir)

	# Il personaggio che va a sinistra e' quello che va a destra, specchiato.
	animated_sprite_2d.flip_h = suffix == DIR_RIGHT and dir.x < 0.0

	var animation: String = "%s_%s" % [prefix, suffix]
	if not frames.has_animation(animation):
		_warn_missing_animation(animation)
		return

	if restart or animated_sprite_2d.animation != StringName(animation):
		animated_sprite_2d.play(animation)


## La direzione da usare per gli sprite, a partire dal vettore di movimento.
func _direction_suffix(dir: Vector2) -> String:
	if not is_zero_approx(dir.x):
		return DIR_RIGHT
	if dir.y < 0.0:
		return DIR_BACK
	return DIR_FRONT


## Riproduce l'animazione di interazione (una volta sola).
##
## Dura quanto l'animazione stessa. Se per errore [code]pick_x[/code] fosse
## impostata in loop, [signal AnimatedSprite2D.animation_finished] non
## arriverebbe mai e il giocatore resterebbe bloccato: per questo c'e' anche
## un timer di sicurezza.
func play_pick(dir: Vector2 = Vector2.ZERO) -> void:
	if is_picking:
		return

	is_picking = true
	velocity = Vector2.ZERO
	if walking.playing:
		walking.stop()

	var facing: Vector2 = dir if dir != Vector2.ZERO else last_direction
	play_animation(ANIM_PICK, facing, true)

	# Rete di sicurezza contro un'animazione impostata in loop.
	var frames: SpriteFrames = animated_sprite_2d.sprite_frames
	var animation: String = "%s_%s" % [ANIM_PICK, _direction_suffix(facing)]
	if frames != null and frames.has_animation(animation):
		var fps: float = maxf(frames.get_animation_speed(animation), 0.01)
		var length: float = float(frames.get_frame_count(animation)) / fps
		get_tree().create_timer(length + 0.1).timeout.connect(_end_pick)


## Chiude l'animazione di interazione e torna alla posa di riposo.
func _end_pick() -> void:
	if not is_picking:
		return
	is_picking = false
	play_animation(ANIM_IDLE, last_direction)


## Avvisa una sola volta per ogni animazione mancante.
##
## [b]Serve a te:[/b] se rinomini gli sprite e il nome non torna, il gioco
## continua a girare ma in Output trovi il nome esatto che manca.
func _warn_missing_animation(animation: String) -> void:
	if _reported_missing.has(animation):
		return
	_reported_missing[animation] = true
	push_warning("player.gd: animazione '%s' mancante nello SpriteFrames." % animation)

#----------------------------------------------
#		ATTACK
#----------------------------------------------

## Attacco.
##
## [b]Il set MC2 non ha animazioni di attacco,[/b] quindi per ora parte solo il
## suono: il personaggio non si blocca, per non far "scattare" il movimento.
##
## Per aggiungerle: crea [code]attack_front[/code] / [code]attack_back[/code] /
## [code]attack_right[/code] nel SpriteFrames e imposta [member ANIM_ATTACK].
func attack() -> void:
	if walking.playing:
		walking.stop()

	if sword.playing:
		sword.stop()
	sword.play()

	if ANIM_ATTACK != "":
		play_animation(ANIM_ATTACK, last_direction, true)
	


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_picking:
		_end_pick()
	if sword.playing:
		sword.stop()
