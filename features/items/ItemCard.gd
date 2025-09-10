extends Area2D

signal choicesReady(choices: Array[ItemData])

func _on_body_entered(body: Node2D) -> void:
	var player = body as PlayerController
	if player:
		emit_signal("choicesReady", ItemDB.PickThreeUnique())
		queue_free()
	
	# Das hinzufühgen zum Player kommt jetzt demnächst in das UI Script
	# Wenn der Spieler eine von drei Optionen gewählt hat
	#var player = body as PlayerController
	#if player:
	#	player.CollectedItemCard()
