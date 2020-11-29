extends Panel

var background
var icon_image
var skill_name
var hotkey
var cooldown

func _ready():
	$Background.texture = load("res://sprites/skills/"+str(background))
	$Icon.texture = load("res://sprites/skills/"+str(icon_image))
	$Hotkey.text = str(hotkey)
