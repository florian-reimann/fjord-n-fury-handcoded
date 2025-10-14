class_name ItemData
extends Resource

enum Type { POWER, HEALTH, INVULN, UTILITY }

@export var id: String
@export var title: String
@export var description: String
@export var type: Type = Type.POWER
@export var icon: Texture2D
@export var rarity: float = 1.0
@export var duration: float = 0.0
@export var spawn_scene: PackedScene
@export var params := {}   # z.B. {"heal":20} oder {"damage_bonus":2}
