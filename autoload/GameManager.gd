extends Node

var player: PlayerController
var playerOriginPosition: Vector2

# Für Camera Shakes:
var playerCamera: Camera2D
var cameraShakeNoise: FastNoiseLite
var playerCameraOriginOffset: Vector2

# Mögliche Game States
enum GameState { PLAYING, MENU_OPEN, GAMEOVER, PAUSED }
var state: GameState = GameState.PLAYING

func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Noise für eventuellen Camerashake generieren:
	cameraShakeNoise = FastNoiseLite.new()
	GlobalSignals.setGameState.connect(onSetGameState)

func RespawnPlayer():
	print("Respawn")
	#player.position = playerOriginPosition
	get_tree().reload_current_scene()

func onSetGameState(new_state: GameState):
	print(new_state)
	if state == new_state:
		return
	state = new_state
	ApplySideEffects()
	
func SpawnVFX(vfxToSpawn:Resource, position: Vector2):
	var vfxInstance = vfxToSpawn.instantiate()
	vfxInstance.global_position = position
	
	get_tree().get_root().get_node("Root").add_child(
		vfxInstance
	)
	
	return vfxInstance
	
func ApplySideEffects() -> void:
	# Godots globale Pause nutzen:
	var should_pause := (state == GameState.PAUSED or state == GameState.MENU_OPEN)
	get_tree().paused = should_pause	
	
# Screen zum Beben bringen:
func StartCameraShake():
	var cameraShakeTween = get_tree().create_tween()
	cameraShakeTween.tween_method(UpdateCameraShake, 6.0, 0.0, 0.3)

# Offset für den Camerashake holen:	
func UpdateCameraShake(intensity: float):
	# Offset aus dem prozedural Generierten "Noise" holen:
	# Random anhand der Spielzeit holen * Intensität
	var cameraOffset = cameraShakeNoise.get_noise_1d(Time.get_ticks_msec()) * intensity
	playerCamera.offset.x = playerCameraOriginOffset.x + cameraOffset
	playerCamera.offset.y = playerCameraOriginOffset.y + cameraOffset
