extends VBoxContainer

var player_name
var sprite

func _ready():
	$PlayerName.text = player_name
	$TextureRect.texture = load("res://sprites/char/"+str(sprite)+"/"+str(sprite)+"_front_1.png")
