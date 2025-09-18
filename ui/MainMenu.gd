extends CanvasLayer

@onready var sp_button: Button = %SP_Button
@onready var mp_button: Button = %MP_Button
@onready var quit_button: Button = %Quit_Button

func _ready() -> void:
	sp_button.grab_focus()

func _on_sp_button_pressed() -> void:
	get_tree().change_scene_to_file("res://features/levels/Level_01.tscn")


func _on_mp_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/MultiplayerMenu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
