extends TileMapLayer

func _ready() -> void:
	FootstepSoundManager.clearTimemap()
	FootstepSoundManager.tilemaps.push_back(self)
