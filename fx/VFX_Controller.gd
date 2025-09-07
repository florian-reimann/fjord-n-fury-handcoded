extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite_2d.play("Start")
	
func _process(_delta: float) -> void:
	if animated_sprite_2d.is_playing() == false:
		queue_free()

func StopNow():
	queue_free()
