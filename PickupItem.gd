extends Node2D

var item_type

func _ready():
	_set_graphic("banana")
	yield(get_tree().create_timer(rand_range(0, 1)), "timeout")
	$AnimationPlayer.play("bounce")

func _set_graphic(g):
	item_type = g
	$Sprite.texture = Globals.item_graphics[g]

func _on_Area2D_body_entered(body):
	if body.filename != "res://Player.tscn":
		return
	if body.team == "seeker":
		return
	if body.has_item():
		print("Already has something")
		return
	body.gain_item(item_type)
	queue_free()
