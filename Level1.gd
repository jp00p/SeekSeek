extends Node

# task ideas
# transcribe
# match something
# quick maths
# sift thru trash
# find correlating notes
# find puzzle pieces

func _ready():
	
	# this cleans up camera smoothing (but why?!)
	Engine.set_target_fps(Engine.get_iterations_per_second())
	
	# connect player/server disconnect signals
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	# instance a new player	
	var new_player = preload('res://Player.tscn').instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id()) # set network owner of player
	$YSort.add_child(new_player) # add them to ysort
	var info = ConnectionManager.self_data # get the character info
	new_player.init(info.name, info.position, info.character) # start em up

func _on_player_disconnected(id):
	print(str(id)+" disconnected")
	$YSort.get_node(str(id)).queue_free() # remove player from scene
	
func _on_server_disconnected():
	get_tree().change_scene('res://LobbySetup.tscn') # go back to main menu

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		var task = load("res://TestTask.tscn").instance()
		$CanvasLayer.add_child(task)
