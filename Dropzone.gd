extends Area2D

signal quest_item_dropped

func _on_Dropzone_area_entered(area):
	# we only care about PickupItems in the dropzone
	if !"PickupItem" in area.get_parent().name:
		return
	
	var dropped_item = area.get_parent()
	
	# check if the item is in the quest book
	for i in range(gamestate.item_quest.size()):
		if dropped_item.item_type == gamestate.item_quest[i][1]:
			#print(dropped_item.item_type)
			dropped_item.queue_free()
			gamestate.item_quest[i][0] = max(gamestate.item_quest[i][0]-1, 0)
			emit_signal("quest_item_dropped")
			return
