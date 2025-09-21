extends Button
class_name CardPanel

@onready var cardTitle: Label = %CardTitle

var _title: String = ""  # Backing-Field

@export var title: String:
	get: return _title
	set(value):
		_title = value
		# Wenn Label schon existiert, direkt anzeigen:
		if is_instance_valid(cardTitle):
			cardTitle.text = value

func _ready() -> void:
	# Falls title vor _ready() gesetzt wurde, hier anwenden:
	cardTitle.text = _title
