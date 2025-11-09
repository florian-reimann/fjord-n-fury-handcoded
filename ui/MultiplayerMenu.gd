extends CanvasLayer

@onready var create_server_button: Button = %CreateServer_Button
@onready var ip_text_edit: TextEdit = $Control/VBoxContainer/IP_TextEdit
@onready var port_text_edit: TextEdit = $Control/VBoxContainer/Port_TextEdit
@onready var join_server_button: Button = %JoinServer_Button

const PORT: int = 3000

# First Level
var main_scene: PackedScene = preload("uid://ba8qy3sml2uq6")

func _ready() -> void:
	create_server_button.grab_focus()
	multiplayer.connected_to_server.connect(_connected_to_server)

func _on_create_server_button_pressed() -> void:
	var server_peer := ENetMultiplayerPeer.new()
	server_peer.create_server(PORT)
	multiplayer.multiplayer_peer = server_peer
	get_tree().change_scene_to_packed(main_scene)

func _on_join_server_button_pressed() -> void:
	var client_peer := ENetMultiplayerPeer.new()
	client_peer.create_client("127.0.0.1", PORT) 
	multiplayer.multiplayer_peer = client_peer
	
func _connected_to_server():
	# Wenn man erfolgreich zum Server verbunden wurde, ab zum Level:
	get_tree().change_scene_to_packed(main_scene)
