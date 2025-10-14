extends CanvasLayer

# GAME UI
@onready var health_bar: ProgressBar = %HealthBar
@onready var equipped_item: Label = %EquippedItem

# CARD MENU
@onready var pick_card_ui: Control = $PickCardUI
@onready var choose_card_h_box_container: HBoxContainer = %ChooseCardHBoxContainer
const CHOOSE_CARD_PANEL = preload("uid://b2oht7viyiv22")
var cards: Array[CardPanel] = []

func _ready() -> void:
	# UI soll auch im Pause-Zustand Eingaben bekommen
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Per default ausblenden:
	pick_card_ui.visible = false
	
	var player = get_tree().get_root().get_node("Root").get_node("Player") as PlayerController
	player.playerHealthUpdated.connect(UpdateHealthBar) # Signal verknpüfen
	
	GlobalSignals.cardChoices.connect(onCardChoices)

func UpdateHealthBar(newValue: int, maxValue: int):
	var barValue = float(newValue) / float(maxValue) * 100
	health_bar.value = barValue

func PickCardAndClose(card: ItemData) -> void:
	if pick_card_ui.visible:
		pick_card_ui.visible = false
		GlobalSignals.setGameState.emit(GameManager.GameState.PLAYING)
		equipped_item.text =  card.title
		GameManager.player.EquipItem(card)
		
			
func onCardChoices(choices: Array[ItemData]) -> void:
	for c in choose_card_h_box_container.get_children():
		c.queue_free()
	cards.clear()
	
	print(choices)
	await  get_tree().create_timer(0.5).timeout
	pick_card_ui.visible = true
	GlobalSignals.setGameState.emit(GameManager.GameState.MENU_OPEN)
	# Die drei Karten zur Auswahl anzeigen:
	for cardItem in choices:
		print(cardItem.title)
		var new_card: CardPanel = CHOOSE_CARD_PANEL.instantiate()
		new_card.title = cardItem.title
		new_card.description = cardItem.description
		#new_card.cardImage = cardItem.icon
		choose_card_h_box_container.add_child(new_card)
		cards.append(new_card)
		new_card.pressed.connect(PickCardAndClose.bind(cardItem))
		
	# Fokus-Navigation links/rechts verketten
	for i in cards.size():
		var left  := cards[(i - 1 + cards.size()) % cards.size()]
		var right := cards[(i + 1) % cards.size()]
		cards[i].focus_neighbor_left  = left.get_path()
		cards[i].focus_neighbor_right = right.get_path()

	# Anfangsfokus setzen
	if cards.size() > 0:
		await get_tree().process_frame
		cards[0].grab_focus()
