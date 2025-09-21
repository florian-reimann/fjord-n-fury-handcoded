extends Node

var Items: Array[ItemData] = []

# Zufallszahlengenerator für Shuffle und Auswahl
var RandomGenerator: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	# Zufallszahlengenerator initialisieren
	RandomGenerator.randomize()

	# Ordner öffnen, in dem die .tres Dateien liegen
	var dir: DirAccess = DirAccess.open("res://features/items/resources")
	if dir:
		dir.list_dir_begin()  # Verzeichnisdurchlauf starten

		# Datei für Datei abarbeiten
		var fileName: String = dir.get_next()
		while fileName != "":
			# Nur Dateien mit .tres berücksichtigen (keine Ordner)
			if not dir.current_is_dir() and fileName.ends_with(".tres"):
				# ItemData laden
				var item: ItemData = load("res://features/items/resources/%s" % fileName)
				if item:
					Items.append(item)

			# Nächste Datei
			fileName = dir.get_next()
		dir.list_dir_end()


# Wählt drei zufällige, unterschiedliche Items aus der Liste aus
func PickThreeUnique() -> Array[ItemData]:
	# Kopie des Arrays erstellen, damit das Original unverändert bleibt
	var pool: Array[ItemData] = Items.duplicate()
	pool.shuffle()
	# Ersten drei Einträge zurückgeben
	return pool.slice(0, min(3, pool.size()))
