extends Node

var player: CharacterBody2D
var playerOriginPosition: Vector2

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func RespawnPlayer():
	print("Respawn")
	player.position = playerOriginPosition

func SpawnVFX(vfxToSpawn:Resource, position: Vector2):
	var vfxInstance = vfxToSpawn.instantiate()
	vfxInstance.global_position = position
	
	get_tree().get_root().get_node("World").add_child(
		vfxInstance
	)
