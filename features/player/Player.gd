extends CharacterBody2D

# VARIABLEN:

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

# True/False ist in der Luft
var AirborneLastFrame: bool

var isShooting: bool = false
const SHOOTING_DURATION: float = 0.25

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var shooting_point: Node2D = $Shooting_Point

func _ready() -> void:
	GameManager.player = self
	GameManager.playerOriginPosition = position

func _process(_delta: float) -> void:
	updateAnimation()

func _physics_process(_delta: float) -> void:

	# GRAVITY: 
	if not is_on_floor():
		velocity.y += GRAVITY * _delta
		AirborneLastFrame = true
	elif AirborneLastFrame:
		PlayLandVFX()
		AirborneLastFrame = false
		
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y += JUMP_VELOCITY
		animated_sprite_2d.play("Jump")
		PlayJumpUpVFX()
		
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
		
	if Input.is_action_just_pressed("Shoot"):
		TryToShoot()
		
	# Bewegung ausführen
	move_and_slide()
	
func updateAnimation():
	if velocity.x != 0:
		animated_sprite_2d.flip_h = velocity.x < 0
		
	if is_on_floor():
		if abs(velocity.x) >= 0.1:
			animated_sprite_2d.play("Run")
		else:
			if isShooting:
				animated_sprite_2d.play("Shoot_Stand")
			else:
				animated_sprite_2d.play("Idle")
			
func PlayJumpUpVFX():
	var vfxToSpawn = preload("res://fx/vfx_jump_up.tscn")
	GameManager.SpawnVFX(vfxToSpawn, global_position)	
	
func PlayLandVFX():
	var vfxToSpawn = preload("res://fx/vfx_land.tscn")
	GameManager.SpawnVFX(vfxToSpawn, global_position)	
	
func Shoot():
	var bulletToSpawn = preload("res://features/bullet/Bullet.tscn")
	var bulletInstance = GameManager.SpawnVFX(bulletToSpawn, shooting_point.global_position)
	
	# Wenn der player nach links guckt, muss die Bullet auch in die Richtung:
	if animated_sprite_2d.flip_h:
		bulletInstance.direction = -1
	else:
		bulletInstance.direction = 1
		
func TryToShoot():
	if isShooting:
		return
	else:
		isShooting = true
		Shoot()
		await get_tree().create_timer(SHOOTING_DURATION).timeout
		isShooting = false
