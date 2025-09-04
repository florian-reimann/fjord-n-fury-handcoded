extends Area2D

@onready var bullet_sprite_2d: Sprite2D = $Bullet_Sprite2D

const SPEED: int = 500
const DAMAGE: int = 30
var direction: int = 1

func _physics_process(_delta: float) -> void:
	if direction == -1:
		bullet_sprite_2d.flip_h = true
		
	position.x += SPEED * direction * _delta



func _on_body_entered(body: Node2D) -> void:
	print("Etwas getroffen: ", body.name)
	
	var vfxToSpawn = preload("res://fx/vfx_bulletHit.tscn")
	var vfxInstance = GameManager.SpawnVFX(vfxToSpawn, global_position)
	
	# Sprite umdrehen, wenn nach links geschossen wird
	if direction == -1:
		vfxInstance.scale.x = -1
		
	var enemy = body as EnemyController
	if enemy:
		enemy.ApplyDamage(DAMAGE)
	
	queue_free() #Und wieder weg mit der Bullet
