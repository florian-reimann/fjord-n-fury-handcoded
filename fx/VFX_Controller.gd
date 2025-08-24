extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite_2d.play("Start")
	
@warning_ignore("unused_parameter")	
func _process(delta: float) -> void:
	if animated_sprite_2d.is_playing() == false:
		queue_free()
