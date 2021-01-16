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
			$CollisionShape2D.set_deferred("disabled", true)
			dropped_item.queue_free()
			if is_network_master():
				print("Sending quest update to host...")
				rpc_id(1, "update_quest", i)
			$CollisionShape2D.set_deferred("disabled", false)
			return

master func update_quest(item):
	#print("We should only see this text once!")
	#print("Sending quest update to everyone...")
	rpc("send_quest_update", item)
	
remotesync func send_quest_update(item):
	#print("Everyone gets a quest update!")
	#print("Changing quest: "+ gamestate.item_quest[item][1] + " - new value: " + str(gamestate.item_quest[item][0]))
	gamestate.item_quest[item][0] = max(gamestate.item_quest[item][0]-1, 0) # reduce quest item count by one, no less than 0
	emit_signal("quest_item_dropped")
