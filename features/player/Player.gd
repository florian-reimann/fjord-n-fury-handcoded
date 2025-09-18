extends CharacterBody2D
class_name PlayerController

# VARIABLEN:

# Mögliche States
enum PlayerState { IDLE, RUN, JUMP, FALL, DASH, HURT, DEAD, NORMAL }

var currentState: PlayerState = PlayerState.NORMAL:
	set(new_value):
		currentState = new_value
		match currentState:
			PlayerState.DEAD:
				set_collision_layer_value(2, false)

# Basic Movement Variables
const SPEED: int = 170
const JUMP_VELOCITY: int = -450
const DASH_SPEED: int = 400
const GRAVITY: int = 1800
const GRAVITY_WALL: int = 700 # Wenn man an der Wand "runterrutscht"
const WALL_JUMP_PUSH_FORCE: int = 150 # Abdrücken von der Wand

# Coyote Time: Kurz nach Plattform-Verlassen noch springen können  
const COYOTE_TIME: float = 0.15

# Jump Buffer: z. B. Wenn man kurz vor dem Boden erneut spring
const JUMP_BUFFER: float = 0.1

# Double Jump System
const MAX_JUMPS: int = 2  # Boden-Jump + Luft-Jump

# --- Laufzeitvariablen ---
var coyote_timer: float = 0.0      # zählt runter, wenn in der Luft
var jump_buffer_timer: float = 0.0 # merkt Jump-Input kurz vor Landung
var jumps_left: int = MAX_JUMPS    # wie viele Sprünge sind noch übrig?

# True/False ist in der Luft
var AirborneLastFrame: bool

var isShooting: bool = false
const SHOOTING_DURATION: float = 0.25

var currentHealth: 
	set(new_value):
		currentHealth = new_value
		emit_signal("playerHealthUpdated", currentHealth, MAX_HEALTH)
		
const MAX_HEALTH: int = 100
	
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var shooting_point: Node2D = $Shooting_Point
@onready var playerCamera: Camera2D = %Camera2D

var bulletScene: PackedScene = preload("uid://dk5eg5ivs8brj")

signal playerHealthUpdated(newValue, maxValue)

func _ready() -> void:
	currentHealth = MAX_HEALTH
	GameManager.player = self
	GameManager.playerOriginPosition = position
	
	GameManager.playerCamera = playerCamera
	GameManager.playerCameraOriginOffset = playerCamera.offset

func _process(_delta: float) -> void:
	updateAnimation()

func _physics_process(_delta: float) -> void:
	if currentState == PlayerState.DEAD:
		return
	# GRAVITY: 
	if not is_on_floor():
		velocity.y += GRAVITY * _delta
		AirborneLastFrame = true
	elif AirborneLastFrame:
		PlayLandVFX()
		AirborneLastFrame = false
		
	if is_on_floor():
		# Am Boden: volle Coyote-Zeit, und alle Sprünge wieder verfügbar
		coyote_timer = COYOTE_TIME
		jumps_left = MAX_JUMPS
	else:
		# In der Luft: Coyote-Zeit läuft ab
		coyote_timer = maxf(0.0, coyote_timer - _delta)
		
	# Setze den Jump-Buffer, für kleine Toleranz, falls man minimal zu früh die Sprungtaste drückt:
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - _delta)

	# Boden-ähnlicher Sprung möglich? (am Boden ODER noch in Coyote-Zeit)
	var can_ground_like_jump := is_on_floor() or (coyote_timer > 0.0)

	# Luftsprung möglich? (nicht am Boden, noch Sprünge übrig)
	# Hinweis: Wenn MAX_JUMPS = 2, bedeutet das in der Praxis:
	# - 1. Sprung (Boden oder Coyote) verbraucht NICHT jumps_left (wir resetten am Boden ja auf 2)
	# - 2. Sprung in der Luft verbraucht 1
	var can_air_jump := not is_on_floor() and jumps_left > 0

	# Bedingungen:
	# - Es wurde kürzlich gesprungen (Buffer > 0)
	# - UND entweder Boden/Coyote verfügbar ODER ein Luftsprung ist erlaubt
	if jump_buffer_timer > 0.0 and (can_ground_like_jump or can_air_jump):
		# Sprung ausführen
		animated_sprite_2d.play("Jump")
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0     # Buffer verbraucht
		jumps_left -= 1
		
		#Boden VFX nur abspielen, wenn man auf dem Boden ist:
		if can_ground_like_jump:
			PlayJumpUpVFX()

		# Nach dem Sprung zählt Coyote nicht mehr (Verhindert „Dauer-Coyote“)
		coyote_timer = 0.0
		
	# Richtung des Spielers:	
	var direction: float = Input.get_axis("Left","Right")
	
	# Laufen:
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
		
	# Runter von der OneWay Platform:
	if Input.is_action_just_pressed("Down") && is_on_floor():
		position.y += 3
		
	if Input.is_action_just_pressed("Shoot") || Input.is_action_pressed("Shoot"):
		TryToShoot()
		
	# Bewegung ausführen
	move_and_slide()
	
	# Reset Player, wenn eine Fallgrenze überschreitet:
	if position.y >= 800:
		GameManager.RespawnPlayer()
	
func updateAnimation():
	if currentState == PlayerState.DEAD:
		return
	
	if velocity.x != 0:
		animated_sprite_2d.flip_h = velocity.x < 0
		# Je nach Laufrichtung muss der Shooting-Pointer verschoben werden:
		if velocity.x < 0:
			shooting_point.position.x = -22
		else:
			shooting_point.position.x = 22
		
	if is_on_floor():
		if abs(velocity.x) >= 0.1:
			
			var playAnimationFrame = animated_sprite_2d.frame
			var playAnimationName = animated_sprite_2d.animation
			
			if isShooting:
				animated_sprite_2d.play("Shoot_Run")
				
				# Syncing Shoot Animation, falls man vorher gerannt ist 
				# (direkt bei dem richtigen Frame beginnen)
				if playAnimationName == "Run":
					animated_sprite_2d.frame = playAnimationFrame
			else:
				# Animation zu Ende spielen:
				if playAnimationName == "Shoot_Run" && animated_sprite_2d.is_playing():
					pass
				else:
					animated_sprite_2d.play("Run")
		else:
			if isShooting:
				animated_sprite_2d.play("Shoot_Stand")
			else:
				animated_sprite_2d.play("Idle")
	else:
		animated_sprite_2d.play("Jump")
		
		if isShooting:
			animated_sprite_2d.play("Shoot_Jump")

func ApplyDamage(damage: int):
	#Er ist Tot Jim
	if currentState == PlayerState.DEAD:
		return
		
	currentHealth -= damage
	
	StartBlink()
	GameManager.StartCameraShake()
	
	if currentHealth <= 0:
		currentState = PlayerState.DEAD
		#animated_sprite_2d.play("Die")
		await  get_tree().create_timer(2).timeout
		GameManager.RespawnPlayer()
				
func Shoot():
	var bulletInstance = GameManager.SpawnVFX(bulletScene, shooting_point.global_position) as BulletController
	bulletInstance.damage = 30
	
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
		PlayFireVFX()
		await get_tree().create_timer(SHOOTING_DURATION).timeout
		isShooting = false

func CollectedItemCard():
	print("Collect Cards")

func StartBlink():
	var blink_tween = get_tree().create_tween()
	blink_tween.tween_method(UpdateBlink, 1.0, 0.0, 0.3)
	
func UpdateBlink(newValue: float):
	animated_sprite_2d.set_instance_shader_parameter("Blink", newValue)
	
func PlayJumpUpVFX():
	var vfxToSpawn = preload("res://fx/vfx_jump_up.tscn")
	GameManager.SpawnVFX(vfxToSpawn, global_position)	
	
func PlayLandVFX():
	var vfxToSpawn = preload("res://fx/vfx_land.tscn")
	GameManager.SpawnVFX(vfxToSpawn, global_position)			
	
func PlayFireVFX():
	var vfxToSpawn = preload("res://fx/vfx_Shoot_Fire.tscn")
	var vfxInstance = GameManager.SpawnVFX(vfxToSpawn, shooting_point.global_position)
	
	if animated_sprite_2d.flip_h:
		vfxInstance.scale.x = -1
