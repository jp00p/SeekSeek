extends Node2D

var item_type

func _ready():
	_set_graphic("banana")

func _set_graphic(g):
	item_type = g
	$Sprite.texture = Globals.item_graphics[g]

func _on_Area2D_body_entered(body):
	print(body)
	if body.team == "seeker":
		pass
	if body.has_item():
		print("Already has something")
		return
	body.gain_item(item_type)
	queue_free()
