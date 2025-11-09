extends CharacterBody2D
class_name PlayerController

#STATE:
enum STATE { 
	FALL, 
	FLOOR,
	IDLE, 
	RUN, 
	JUMP,
	DOUBLE_JUMP,
	HURT, 
	LEDGE_CLIMP,
	WALL_SLIDE,
	WALL_JUMP,
	WALL_CLIMB,
	DASH,
	TURNING,
	DEAD
}

# NODES:
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var shooting_point: Node2D = $Shooting_Point
@onready var playerCamera: Camera2D = %Camera2D
@onready var wall_slide_ray_cast: RayCast2D = %WallSlideRayCast
@onready var coyote_timer: Timer = %CoyoteTimer
@onready var dash_cooldown: Timer = %DashCooldown
@onready var sfx_audio_stream_player_2d: AudioStreamPlayer2D = $SFXAudioStreamPlayer2D

var bulletScene: PackedScene = preload("uid://dk5eg5ivs8brj")

# SOUNDS
var bulletSound: AudioStream = preload("uid://do2n3xe242wsi")
var jumpSound: AudioStream = preload("uid://c4bm10lvna2mq")
var landSound: AudioStream = preload("uid://e17vjaok2oaj")
var hitSound: AudioStream = preload("uid://xkorhfakubnt")

# CONSTANTEN:
const FALL_VELOCITY: float = 1500.0
const FALL_GRAVITY: float = 1500.0
const WALK_VELOCITY: float = 200.0
const JUMP_VELOCITY: float = -500.0
const JUMP_DECELERATION: float = 1500.0
const DOUBLE_JUMP_VELOCITY: float = -400.0
const WALL_SLIDE_GRAVITY: float = 200.0
const WALL_SLIDE_VELOCITY: float = 400.0
const WALL_JUMP_LENGTH: float = 30.0
const WALL_JUMP_VELOCITY: float = -500.0
const WALL_CLIMB_VELOCITY: float = -300.0
const WALL_CLIMB_LENGTH: float = 65.0
const DASH_LENGTH: float = 100.0
const DASH_VELOCITY: float = 1500.0

const MAX_HEALTH: int = 100
const SHOOTING_DURATION: float = 0.25

# SIGNALS:
signal playerHealthUpdated(newValue, maxValue)

# VARIABLEN:
var active_state:= STATE.FALL
var isShooting: bool = false
var can_double_jump: bool = false
var can_dash: bool = false
var dash_jump_buffer: bool = false
var facing_direction: float = 1.0
var saved_position: Vector2 = Vector2.ZERO
var equippedItem: ItemData

var currentHealth: 
	set(new_value):
		currentHealth = new_value
		emit_signal("playerHealthUpdated", currentHealth, MAX_HEALTH)

func _ready() -> void:
	# Initialisiere den Ausgangs-STATE:
	switch_state(active_state)
	
	currentHealth = MAX_HEALTH
	
	GameManager.player = self
	GameManager.playerCamera = playerCamera
	GameManager.playerCameraOriginOffset = playerCamera.offset

func _physics_process(_delta: float) -> void:
	if active_state == STATE.DEAD:
		return
	process_state(_delta)
	move_and_slide()

	# Reset Player, wenn eine Fallgrenze überschreitet:
	if position.y >= 800:
		GameManager.RespawnPlayer()

func switch_state(to_state: STATE) -> void:
	var previous_state: STATE = active_state
	active_state = to_state
	
	# Dieser Code wird einmalig beim Wechsel des States ausgeführt:
	match active_state:
		STATE.FALL:
			if previous_state != STATE.DOUBLE_JUMP:
				if isShooting:
					animated_sprite_2d.play("Shoot_Jump")
				else:
					animated_sprite_2d.play("Jump") # Später: Fall
			if previous_state == STATE.FLOOR:
				coyote_timer.start()
		
		STATE.FLOOR:
			can_double_jump = true
			can_dash = true
		
		STATE.JUMP:
			if isShooting:
				animated_sprite_2d.play("Shoot_Jump")
			else:
				animated_sprite_2d.play("Jump")
			PlayJumpUpVFX()
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
		
		STATE.DOUBLE_JUMP:
			animated_sprite_2d.play("Jump")
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			
		STATE.WALL_SLIDE:
			animated_sprite_2d.play("Jump") # Später Wall Slide
			velocity.y = 0
			can_double_jump = true
			can_dash = true
			
		STATE.WALL_JUMP:
			animated_sprite_2d.play("Jump")
			velocity.y = WALL_JUMP_VELOCITY
			set_facing_direction(-facing_direction)
			saved_position = position
			
		STATE.WALL_CLIMB:
			animated_sprite_2d.play("Jump") # Später Wall Climp
			velocity.y = WALL_CLIMB_VELOCITY
			saved_position = position
			
		STATE.DASH:
			if dash_cooldown.time_left > 0:
				active_state = previous_state
				return
			animated_sprite_2d.play("Run") # Später Dash
			### Todo: DASH VFX ###
			velocity.y = 0
			set_facing_direction(signf(Input.get_axis("Left", "Right")))
			velocity.x = facing_direction * DASH_VELOCITY
			saved_position = position
			can_dash = previous_state == STATE.FLOOR or previous_state == STATE.WALL_SLIDE
			dash_jump_buffer = false

func process_state(_delta: float) -> void:
	match active_state:
		STATE.FALL:
			if Input.is_action_just_pressed("Shoot") or Input.is_action_pressed("Shoot"):
				TryToShoot()
					
			velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * _delta)
			handle_movement() # Der Player kann sich im "fallen" bewegen
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("Jump"):
				if coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
				elif can_double_jump:
					switch_state(STATE.DOUBLE_JUMP)
			elif is_input_toward_facing() and can_wall_slide():
				switch_state(STATE.WALL_SLIDE)
			elif Input.is_action_just_pressed("Dash") and can_dash:
				switch_state(STATE.DASH)
			
		STATE.FLOOR:
			if Input.is_action_just_pressed("Shoot") or Input.is_action_pressed("Shoot"):
				TryToShoot()
			if Input.get_axis("Left", "Right"):
				if isShooting:
					animated_sprite_2d.play("Shoot_Run")
				else:
					animated_sprite_2d.play("Run")
			else:
				if isShooting:
					animated_sprite_2d.play("Shoot_Stand")
				else:
					animated_sprite_2d.play("Idle")
			handle_movement()
			
			if not is_on_floor():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("Jump"):
				switch_state(STATE.JUMP)
			elif Input.is_action_just_pressed("Dash"): # Aufm Boden kann man unendlich dashen
				switch_state(STATE.DASH)
				
		STATE.JUMP, STATE.DOUBLE_JUMP, STATE.WALL_JUMP:
			velocity.y = move_toward(velocity.y, 0, JUMP_DECELERATION * _delta)
			if active_state == STATE.WALL_JUMP:
				var distance: float = absf(position.x - saved_position.x)
				if distance >= WALL_JUMP_LENGTH or can_wall_slide():
					active_state = STATE.JUMP
				else:
					handle_movement(facing_direction)
			
			if active_state != STATE.WALL_JUMP:
				handle_movement() # Der Player kann sich im "springen" bewegen
			
			if Input.is_action_just_released("Jump") or velocity.y >= 0:
				velocity.y = 0
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("Jump"):
				switch_state(STATE.DOUBLE_JUMP)
			elif Input.is_action_just_pressed("Dash") and can_dash:
				switch_state(STATE.DASH)
				
		STATE.WALL_SLIDE:
			velocity.y = move_toward(velocity.y, WALL_SLIDE_VELOCITY, WALL_SLIDE_GRAVITY * _delta)
			handle_movement() # Der Player kann sich im "fallen" bewegen
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif not can_wall_slide():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("Jump"):
				switch_state(STATE.WALL_JUMP)
			elif Input.is_action_just_pressed("Dash"):
				if is_input_toward_facing():
					switch_state(STATE.WALL_CLIMB)
				
		STATE.WALL_CLIMB:
			var distance: float = absf(position.y - saved_position.y)
			if distance >= WALL_CLIMB_LENGTH:
				velocity.y = 0
				switch_state(STATE.WALL_SLIDE)
				
		STATE.DASH:
			dash_cooldown.start()
			if is_on_floor():
				coyote_timer.start()
			if Input.is_action_just_pressed("Jump"):
				dash_jump_buffer = true
			var distance: float = absf(position.x - saved_position.x)
			if distance >= DASH_LENGTH or absf(get_last_motion().x) != facing_direction:
				if dash_jump_buffer and coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
				elif is_on_floor():
					switch_state(STATE.FLOOR)
				else:
					switch_state(STATE.FALL)
			elif can_wall_slide():
				switch_state(STATE.WALL_SLIDE)
			
func handle_movement(input_direction: float = 0) -> void:
	if input_direction == 0:
		input_direction = signf(Input.get_axis("Left", "Right"))
	set_facing_direction(input_direction)
	velocity.x = input_direction * WALK_VELOCITY

func can_wall_slide() -> bool:
	return is_on_wall_only() and wall_slide_ray_cast.is_colliding()
	
func is_input_toward_facing() -> bool:
	return signf(Input.get_axis("Left","Right")) == facing_direction
	
func set_facing_direction(direction: float) -> void:
	if direction:
		animated_sprite_2d.flip_h = direction < 0
		facing_direction = direction
		
		if shooting_point:
			shooting_point.position.x = direction * absf(shooting_point.position.x)
		
		# Flip Raycast:
		wall_slide_ray_cast.position.x = direction * absf(wall_slide_ray_cast.position.x)
		wall_slide_ray_cast.target_position.x = direction * absf(wall_slide_ray_cast.target_position.x)
		wall_slide_ray_cast.force_raycast_update()

func ApplyDamage(damage: int):
	#Er ist Tot Jim
	if active_state == STATE.DEAD:
		return
		
	currentHealth -= damage
	
	sfx_audio_stream_player_2d.stream = hitSound
	sfx_audio_stream_player_2d.play()
	
	StartBlink()
	GameManager.StartCameraShake()
	
	if currentHealth <= 0:
		active_state = STATE.DEAD
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
		
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = bulletSound
	get_tree().root.add_child(audio_player)
	audio_player.play()
	audio_player.global_position = shooting_point.position
	await audio_player.finished
	audio_player.queue_free()

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

func EquipItem(item: ItemData) -> void:
	equippedItem = item

func StartBlink():
	var blink_tween = get_tree().create_tween()
	blink_tween.tween_method(UpdateBlink, 1.0, 0.0, 0.3)
	
func UpdateBlink(newValue: float):
	animated_sprite_2d.set_instance_shader_parameter("Blink", newValue)
	
func PlayJumpUpVFX():
	var vfxToSpawn = preload("res://fx/vfx_jump_up.tscn")
	GameManager.SpawnVFX(vfxToSpawn, global_position)
	sfx_audio_stream_player_2d.stream = jumpSound
	sfx_audio_stream_player_2d.play()
	
func PlayLandVFX():
	var vfxToSpawn = preload("res://fx/vfx_land.tscn")
	GameManager.SpawnVFX(vfxToSpawn, global_position)	
	sfx_audio_stream_player_2d.stream = landSound
	sfx_audio_stream_player_2d.play()
	
func PlayFireVFX():
	var vfxToSpawn = preload("res://fx/vfx_Shoot_Fire.tscn")
	var vfxInstance = GameManager.SpawnVFX(vfxToSpawn, shooting_point.global_position)
	
	if animated_sprite_2d.flip_h:
		vfxInstance.scale.x = -1

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite_2d.animation == "Run":
		if animated_sprite_2d.frame % 2 == 0:
			FootstepSoundManager.playFootstep(global_position)
