extends Area2D

signal quest_item_dropped

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Dropzone_area_entered(area):
	# we only care about items in the dropzone
	if !"PickupItem" in area.get_parent().name:
		return
	
	var dropped_item = area.get_parent()
	
	# check if the item is in the quest book
	for i in range(gamestate.item_quest.size()):
		print(dropped_item.item_type)
		if dropped_item.item_type == gamestate.item_quest[i][1]:
			dropped_item.queue_free()
			gamestate.item_quest[i][0] = max(gamestate.item_quest[i][0]-1, 0)
			emit_signal("quest_item_dropped")
			break
			
	
