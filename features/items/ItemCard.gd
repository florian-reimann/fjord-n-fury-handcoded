extends Area2D
class_name ItemCard

func _on_body_entered(body: Node2D) -> void:
	var player = body as PlayerController
	if player:
		# Übergibt die drei Karten an den UIManager, dort wird das Anzeigen geregelt:
		GlobalSignals.cardChoices.emit(ItemDB.PickThreeUnique())
		queue_free()
	
	# Das hinzufühgen zum Player kommt jetzt demnächst in das UI Script
	# Wenn der Spieler eine von drei Optionen gewählt hat
	#var player = body as PlayerController
	#if player:
	#	player.CollectedItemCard()
