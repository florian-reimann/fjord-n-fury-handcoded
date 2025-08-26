extends CharacterBody2D

const SPEED: int = 50
var direction: int = 1
const GRAVITY: int = 1800

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d_forward: RayCast2D = $CollisionShape2D/RayCast2D_Forward
@onready var ray_cast_2d_downward: RayCast2D = $CollisionShape2D/RayCast2D_Downward

func _process(_delta: float) -> void:
	updateAnimation()
	
func _physics_process(_delta: float) -> void:
	#Wenn der Gegner in der Luft ist, gehts abwärts
	if not is_on_floor():
		velocity.y = GRAVITY
	
	#Wenn etwas vor dem Gegner ist oder der Abgrund bevorsteht:
	if ray_cast_2d_forward.is_colliding() || ray_cast_2d_downward.is_colliding() == false:
		direction = -direction #Und umkehren bitte
		ray_cast_2d_forward.target_position.x = -ray_cast_2d_forward.target_position.x #flippen (vom pointer)
		ray_cast_2d_downward.position.x = -ray_cast_2d_downward.position.x #flippen (vom raycast selbst)
		
	#Bewegung in eine Richtung
	velocity.x = direction * SPEED
	
	move_and_slide()
	
func updateAnimation():
	if velocity.x != 0:
		animated_sprite_2d.flip_h = velocity.x < 0 #Ergibt true oder false, dementsprechend wird "geflippt"
	
	animated_sprite_2d.play("Walk")
