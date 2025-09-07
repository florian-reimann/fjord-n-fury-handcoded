extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar

func _ready() -> void:
	var player = get_tree().get_root().get_node("Root").get_node("Player") as PlayerController
	player.playerHealthUpdated.connect(UpdateHealthBar) # Signal verknpüfen

func UpdateHealthBar(newValue: int, maxValue: int):
	var barValue = float(newValue) / float(maxValue) * 100
	health_bar.value = barValue
