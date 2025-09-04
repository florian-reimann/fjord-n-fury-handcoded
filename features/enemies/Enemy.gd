extends CharacterBody2D
class_name EnemyController

const SPEED: int = 50
var direction: int = 1
const GRAVITY: int = 1800

var currentHealth: int = 90
var isDeath: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d_forward: RayCast2D = $CollisionShape2D/RayCast2D_Forward
@onready var ray_cast_2d_downward: RayCast2D = $CollisionShape2D/RayCast2D_Downward

func _process(_delta: float) -> void:
	updateAnimation()
	
func _physics_process(_delta: float) -> void:
	#Wenn der Gegner in der Luft ist, gehts abwärts
	if not is_on_floor():
		velocity.y = GRAVITY
	
	if isDeath:
		return
	
	#Wenn etwas vor dem Gegner ist oder der Abgrund bevorsteht:
	if ray_cast_2d_forward.is_colliding() || ray_cast_2d_downward.is_colliding() == false:
		direction = -direction #Und umkehren bitte
		ray_cast_2d_forward.target_position.x = -ray_cast_2d_forward.target_position.x #flippen (vom pointer)
		ray_cast_2d_downward.position.x = -ray_cast_2d_downward.position.x #flippen (vom raycast selbst)
		
	#Bewegung in eine Richtung
	velocity.x = direction * SPEED
	
	move_and_slide()
	
func updateAnimation():
	if isDeath:
		return
		
	if velocity.x != 0:
		animated_sprite_2d.flip_h = velocity.x < 0 #Ergibt true oder false, dementsprechend wird "geflippt"
	
	animated_sprite_2d.play("Walk")
	
func ApplyDamage(damage: int):
	#Er ist Tot Jim
	if isDeath:
		return
	
	currentHealth -= damage
	
	var blink_tween = get_tree().create_tween()
	blink_tween.tween_method(UpdateBlink, 1.0, 0.0, 0.3)
	
	if currentHealth <= 0:
		isDeath = true
		animated_sprite_2d.play("Die")
		set_collision_layer_value(3, false)
		await  get_tree().create_timer(2).timeout
		queue_free()
		
func UpdateBlink(newValue: float):
	animated_sprite_2d.set_instance_shader_parameter("Blink", newValue)
