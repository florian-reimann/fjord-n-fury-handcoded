extends Area2D

@onready var bullet_sprite_2d: Sprite2D = $Bullet_Sprite2D

const SPEED: int = 500
const DAMAGE: int = 20
var direction: int = 1

func _physics_process(_delta: float) -> void:
	if direction == -1:
		bullet_sprite_2d.flip_h = true
		
	position.x += SPEED * direction * _delta



func _on_body_entered(body: Node2D) -> void:
	print("Etwas getroffen: ", body.name)
	
	queue_free() #Und wieder weg mit der Bullet
