extends Node

var player: CharacterBody2D
var playerOriginPosition: Vector2

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func RespawnPlayer():
	print("Respawn")
	player.position = playerOriginPosition
