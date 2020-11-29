extends Node


# item quest
# gather 3 items of 3 types
# eg. 3 apples, 3 bananas, 3 shrooms
# find the drop location
# bring the items to the drop location
# hiders win when all 9 items are placed!


var character_graphics = {
	"pokey" : preload("res://Characters/pokey.tres"),
	"pizzagirl" : preload("res://Characters/pizzagirl.tres"),
	"mrsaturn" : preload("res://Characters/mrsaturn.tres"),
	"frank" : preload("res://Characters/frank.tres")
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
	"strawberry" : load("res://sprites/items/strawberry.png")
}

func create_item_quest(num_items, num_types):
	var item_quest = []
	var item_names = item_graphics.keys()
	for _type in range(num_types):
		item_names.shuffle()
		var this_type = item_names[0]
		item_names.pop_front()
		item_quest.append([num_items, this_type])
	print(item_quest)
	return item_quest
	
func _ready():
	randomize()

var seeker_skills = [
	{
		"name" : "Kill",
		"background" : "16_1.png",
		"icon" : "kill.png",
		"cooldown" : 100
	},
	{
		"name" : "X-Ray",
		"background" : "16_18.png",
		"icon" : "16_43.png",
		"cooldown" : 100
	},
	{
		"name" : "Night",
		"background" : "32_14.png",
		"icon" : "night.png",
		"cooldown" : 100
	},
	
	
]