extends CharacterBody2D

# Mögliche States
enum PlayerState { IDLE, RUN, JUMP, FALL, DASH }

# Basic Movement Variables
const SPEED: int = 170
const JUMP_VELOCITY: int = -450
const DASH_SPEED: int = 400
const GRAVITY: int = 1800

# Coyote Time: Kurz nach Plattform-Verlassen noch springen können  
const COYOTE_TIME: float = 0.15

# Jump Buffer: z. B. Wenn man kurz vor dem Boden erneut spring
const JUMP_BUFFER: float = 0.1

# Double Jump System
const MAX_JUMPS: int = 2  # Boden-Jump + Luft-Jump

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	GameManager.player = self
	GameManager.playerOriginPosition = position

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	updateAnimation()

func _physics_process(delta: float) -> void:

	# GRAVITY: 
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y += JUMP_VELOCITY
		
	# Richtung des Spielers:	
	var direction: float = Input.get_axis("Left","Right")
	
	# Laufen:
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
		
	# Reset Player, wenn eine Fallgrenze überschreitet:
	if position.y >= 800:
		GameManager.RespawnPlayer()
		
	# Runter von der OneWay Platform:
	if Input.is_action_just_pressed("Down") && is_on_floor():
		position.y += 3
		
	# Bewegung ausführen
	move_and_slide()
	
func updateAnimation():
	if velocity.x != 0:
		animated_sprite_2d.flip_h = velocity.x < 0
		
	if is_on_floor():
		if abs(velocity.x) >= 0.1:
			animated_sprite_2d.play("Run")
		else:
			animated_sprite_2d.play("Idle")
			
