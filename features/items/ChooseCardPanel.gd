extends Button
class_name CardPanel

@onready var cardTitle: Label = %CardTitle
@onready var cardDescription: Label = %CardDescription
@onready var cardImage: TextureRect = $TextureRect

var _title: String = ""
var _description: String = ""  

@export var title: String:
	get: return _title
	set(value):
		_title = value
		# Wenn Label schon existiert, direkt anzeigen:
		if is_instance_valid(cardTitle):
			cardTitle.text = value
			
@export var description: String:
	get: return _description
	set(value):
		_description = value
		# Wenn Label schon existiert, direkt anzeigen:
		if is_instance_valid(cardDescription):
			cardDescription.text = value

func _ready() -> void:
	# Falls title vor _ready() gesetzt wurde, hier anwenden:
	cardTitle.text = _title
	cardDescription.text = _description
