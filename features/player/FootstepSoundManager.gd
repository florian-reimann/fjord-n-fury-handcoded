extends Node

var tilemaps: Array[TileMapLayer] = []

const footstepSounds = {
	"dirt":[
		preload("res://features/player/sounds/Dirt_FS_1.wav"),
		preload("res://features/player/sounds/Dirt_FS_2.wav"),
		preload("res://features/player/sounds/Dirt_FS_3.wav"),
		preload("res://features/player/sounds/Dirt_FS_4.wav")
	],
	"grass":[
		preload("res://features/player/sounds/Grass_FS_1.wav"),
		preload("res://features/player/sounds/Grass_FS_2.wav"),
		preload("res://features/player/sounds/Grass_FS_3.wav"),
		preload("res://features/player/sounds/Grass_FS_4.wav"),
		preload("res://features/player/sounds/Grass_FS_5.wav")
	],
	"snow":[
		#preload("res://features/player/sounds/Footsteps_Snow_01.wav"),
		#preload("res://features/player/sounds/Footsteps_Snow_02.wav"),
		#preload("res://features/player/sounds/Footsteps_Snow_03.wav"),
		#preload("res://features/player/sounds/Footsteps_Snow_04.wav")
		preload("res://features/player/sounds/Grass_FS_1.wav"),
		preload("res://features/player/sounds/Grass_FS_2.wav"),
		preload("res://features/player/sounds/Grass_FS_3.wav"),
		preload("res://features/player/sounds/Grass_FS_4.wav"),
		preload("res://features/player/sounds/Grass_FS_5.wav")
	],
	"snow_grass":[
		preload("res://features/player/sounds/Grass_FS_1.wav"),
		preload("res://features/player/sounds/Grass_FS_2.wav"),
		preload("res://features/player/sounds/Grass_FS_3.wav"),
		preload("res://features/player/sounds/Grass_FS_4.wav"),
		preload("res://features/player/sounds/Grass_FS_5.wav")
	],
	"wood":[
		preload("res://features/player/sounds/Wood_Fs_1.wav"),
		preload("res://features/player/sounds/Wood_Fs_2.wav"),
		preload("res://features/player/sounds/Wood_Fs_3.wav"),
		preload("res://features/player/sounds/Wood_Fs_4.wav"),
		preload("res://features/player/sounds/Wood_Fs_5.wav")
	],
	"water":[
		preload("res://features/player/sounds/Footsteps_Water_4.mp3")
	]
}

func playFootstep(position: Vector2):
	var tile_data = []
	for tilemap in tilemaps:
		var tile_position = tilemap.local_to_map(position)
		var data = tilemap.get_cell_tile_data(tile_position)
		if data:
			tile_data.push_back(data)
		
	if tile_data.size() > 0:
		var tile_type = tile_data.back().get_custom_data("footstep_sound")
		
		if footstepSounds.has(tile_type):
			var audio_player = AudioStreamPlayer2D.new()
			audio_player.stream = footstepSounds[tile_type].pick_random()
			get_tree().root.add_child(audio_player)
			audio_player.global_position = position
			audio_player.play()
			await audio_player.finished
			audio_player.queue_free()
			
func clearTimemap():
	tilemaps.clear()
