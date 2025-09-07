extends CharacterBody2D
class_name EnemyController

const SPEED: int = 50
var direction: int = 1
const GRAVITY: int = 1800

var currentHealth: int = 90
var isDeath: bool = false

var isShooting: bool = false
const SHOOTING_DURATION: float = 1.25

var isSpottingPlayer: bool = false
var attentionTriggered: bool = false
var firstShotPending: bool = true
var firstShotDelayStarted: bool = false
var attentionNode: Node2D = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d_forward: RayCast2D = $CollisionShape2D/RayCast2D_Forward
@onready var ray_cast_2d_downward: RayCast2D = $CollisionShape2D/RayCast2D_Downward
@onready var area_2d_player_detector: Area2D = $Area2D_PlayerDetector
@onready var shooting_point: Node2D = $Shooting_Point
@onready var attention_point: Node2D = $Attention_Point

func _process(_delta: float) -> void:
	updateAnimation()
	
	if isSpottingPlayer:
		SpottingPlayer()
	
func _physics_process(_delta: float) -> void:
	#Wenn der Gegner in der Luft ist, gehts abwärts
	if not is_on_floor():
		velocity.y = GRAVITY * _delta
	
	if isDeath:
		return
	
	#Wenn etwas vor dem Gegner ist oder der Abgrund bevorsteht:
	if ray_cast_2d_forward.is_colliding() || ray_cast_2d_downward.is_colliding() == false:
		direction = -direction #Und umkehren bitte
		ray_cast_2d_forward.target_position.x = -ray_cast_2d_forward.target_position.x #flippen (vom pointer)
		ray_cast_2d_downward.position.x = -ray_cast_2d_downward.position.x #flippen (vom raycast selbst)
	
	if animated_sprite_2d.flip_h:
		area_2d_player_detector.scale.x = -1
	else:
		area_2d_player_detector.scale.x = 1
		
	#Bewegung in eine Richtung
	if not isSpottingPlayer:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
	
	move_and_slide()
	
func updateAnimation():
	if isDeath:
		return
		
	if velocity.x != 0:
		animated_sprite_2d.flip_h = velocity.x < 0 #Ergibt true oder false, dementsprechend wird "geflippt"
	
		if velocity.x < 0:
			shooting_point.position.x = -22
		else:
			shooting_point.position.x = 22
	
	if not isSpottingPlayer:
		animated_sprite_2d.play("Walk")
	else:
		animated_sprite_2d.play("Idle")
	
func ApplyDamage(damage: int):
	#Er ist Tot Jim
	if isDeath:
		return
	
	currentHealth -= damage
	
	StartBlink()
	GameManager.StartCameraShake()
	
	if currentHealth <= 0:
		isDeath = true
		if attentionNode:
			attentionNode.call("StopNow")
		animated_sprite_2d.play("Die")
		set_collision_layer_value(3, false)
		await  get_tree().create_timer(2).timeout
		queue_free()
		
func StartBlink():
	var blink_tween = get_tree().create_tween()
	blink_tween.tween_method(UpdateBlink, 1.0, 0.0, 0.3)
	
func UpdateBlink(newValue: float):
	animated_sprite_2d.set_instance_shader_parameter("Blink", newValue)
	
func SpottingPlayer():
	# Beim ersten Erspähen:
	if not attentionTriggered:
		attentionTriggered = true
		PlayAttentionVFX()
	
	# Erster Schuss:
	if firstShotPending:
		# Wenn der erste Schuss Delay noch nicht ausgelöst wurde:
		if not firstShotDelayStarted:
			firstShotDelayStarted = true
			await get_tree().create_timer(2).timeout
			firstShotDelayStarted = false
			# Wenn er in der Zwischenzeit nicht mehr den Player spotted ODER gestorben ist:
			if not isSpottingPlayer || isDeath:
				return
			# Erste Schuss-Phase erledigt...
			firstShotPending = false
			TryToShoot() # Erster Schuss
	else:
		TryToShoot()

func Shoot():
	var bulletToSpawn = preload("res://features/bullet/Bullet.tscn")
	var bulletInstance = GameManager.SpawnVFX(bulletToSpawn, shooting_point.global_position)
	bulletInstance.damage = 50
	
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

func PlayAttentionVFX():
	var vfxToSpawn = preload("res://fx/vfx_Attention.tscn")
	attentionNode = GameManager.SpawnVFX(vfxToSpawn, attention_point.global_position)

func PlayFireVFX():
	var vfxToSpawn = preload("res://fx/vfx_Shoot_Fire.tscn")
	var vfxInstance = GameManager.SpawnVFX(vfxToSpawn, shooting_point.global_position)
	
	if animated_sprite_2d.flip_h:
		vfxInstance.scale.x = -1		
		
func _on_area_2d_player_detector_body_entered(_body: Node2D) -> void:
	await  get_tree().create_timer(0.4).timeout
	isSpottingPlayer = true

func _on_area_2d_player_detector_body_exited(_body: Node2D) -> void:
	await  get_tree().create_timer(1).timeout
	if attentionNode:
		attentionNode.call("StopNow")
	isSpottingPlayer = false
	attentionTriggered = false
	firstShotPending = true
	firstShotDelayStarted = false
