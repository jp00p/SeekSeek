extends Node

var sound_muted = false

var character_graphics = {
	"pokey" : preload("res://Characters/pokey.tres"),
	"pizzagirl" : preload("res://Characters/pizzagirl.tres"),
	"mrsaturn" : preload("res://Characters/mrsaturn.tres"),
	"frank" : preload("res://Characters/frank.tres"),
	"zombie" : preload("res://Characters/zombie.tres"),
	"hippie": preload("res://Characters/hippie.tres"),
	"applekid": preload("res://Characters/applekid.tres"),
	"armsdealer": preload("res://Characters/armsdealer.tres"),
	"bellhop": preload("res://Characters/bellhop.tres"),
	"swimsuitguy": preload("res://Characters/bathingsuitguy.tres"),
	"bunnystatue": preload("res://Characters/bunnystatue.tres"),
	"grandma": preload("res://Characters/granny.tres"),
	"magicant": preload("res://Characters/magicant.tres"),
	"missfake": preload("res://Characters/missfake.tres"),
	"nurse": preload("res://Characters/nurse.tres"),
	"photographer": preload("res://Characters/photographer.tres"),
	"punk": preload("res://Characters/punk.tres"),
	"tenda": preload("res://Characters/tenda.tres"),
	"tracy": preload("res://Characters/tracy.tres"),
	"venus": preload("res://Characters/venus.tres")
}

var item_graphics = {
	"banana" : load("res://sprites/items/banana.png"),
	"apple" : load("res://sprites/items/apple.png"),
	"broccoli" : load("res://sprites/items/broccoli.png"),
	"carrot" : load("res://sprites/items/carrot.png"),
	"cheese" : load("res://sprites/items/cheese_02.png"),
	"donut" : load("res://sprites/items/donut_02.png"),
	"hamburger" : load("res://sprites/items/hamburger.png"),
	"milk" : load("res://sprites/items/milk.png"),
	"shroom" : load("res://sprites/items/mushroom_05.png"),
	"pizza" : load("res://sprites/items/pizza.png"),
	"orange" : load("res://sprites/items/orange.png"),
	"strawberry" : load("res://sprites/items/strawberry.png"),
	"tomato" : load("res://sprites/items/tomato.png"),
	"onion" : load("res://sprites/items/onion.png"),
	"onigiri" : load("res://sprites/items/onigiri.png"),
	"cake" : load("res://sprites/items/cake_01.png"),
	"avocado" : load("res://sprites/items/avocado.png"),
	"cucumber" : load("res://sprites/items/cucumber.png"),
	"garlic" : load("res://sprites/items/garlic.png"),
	
}

func create_item_quest(num_items, num_types):
	var item_quest = []
	var item_names = item_graphics.keys()
	for _type in range(num_types):
		item_names.shuffle()
		var this_type = item_names[0]
		item_names.pop_front()
		item_quest.append([num_items, this_type])
	return item_quest
	
func _ready():
	randomize()

var seeker_skills = [
	{
		"name" : "Kill",
		"background" : "16_1.png",
		"icon" : "kill.png",
		"cooldown" : 15,
		"cooldown_active" : false
	},
	{
		"name" : "X-Ray",
		"background" : "16_18.png",
		"icon" : "16_43.png",
		"cooldown" : 60,
		"cooldown_active" : false
	},
	{
		"name" : "Night",
		"background" : "32_14.png",
		"icon" : "night.png",
		"cooldown" : 120,
		"cooldown_active" : false
	}	
	
]
