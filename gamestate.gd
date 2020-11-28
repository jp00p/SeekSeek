extends Node

# lots of copy & pasting from the bomberman demo follows

# some notes
# YOU = person playing the game with keyboard/mouse
# NOT YOU = nodes controlled by network requests
# puppet vars = vars that are meant to be set by network requests
# remote func = function that only runs on NOT YOU machines
# sync func = function that runs on all machines
# master func = function that only runs on the host machine
# rset = set remote variables
# rpcs = run functions on some/all players' machines
# unreliable = for quick but dirty data (udp vs tcp)

const DEFAULT_PORT = 10567 # need to open this on router, or let host choose?
const MAX_PEERS = 12

const item_count = 12

# these are always the details for YOU
var player_name = "DEFAWLT"
var player_char = "pokey"
var player_team = ""

# details for NOT YOU
# { id: {name:string, character:string} }
var players = {}
var players_ready = []

signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	rpc_id(id, "register_player", player_name, player_char)

# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/Level1"): # Game is in progress.
		if get_tree().is_network_server():
			emit_signal("game_error", "Player " + players[id].name + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions.
remote func register_player(new_player_name, new_player_char):
	var id = get_tree().get_rpc_sender_id()
	players[id] = {"name" : new_player_name, "character" : new_player_char }
	emit_signal("player_list_changed")

func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

remote func pre_start_game(spawn_points):
	# could let the host choose a level... 
	# but for now most of the game is dependent on being in Level1
	var world = load("res://Level1.tscn").instance()
	
	# important: we don't change_scene() in this game.
	# we load the level here
	get_tree().get_root().add_child(world)
	
	# hide the lobby instead of freeing it
	# then we can pop back into it on error/exit
	get_tree().get_root().get_node("LobbySetup").hide()

	# prep the player
	var player_scene = load("res://Player.tscn")
	
	# set up the teams
	# one seeker, everyone else a hider
	var team_choices = ["seeker"] # start with one seeker always
	for _n in range(spawn_points.size()-1): # size-1 because we already have a seeker
		team_choices.append("hider") # fill the array with hiders based on how many players are spawning
	team_choices.shuffle() # randomize the team array
	
	for p_id in spawn_points:
		# spawn the players in specific spots! (todo: randomize these spots)
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position  # warning: we need a spawn point for each player!
		var player = player_scene.instance()
		
		player.set_name(str(p_id)) # sets the player node name to their network ID
		player.position = spawn_pos # set spawn position
		player.set_network_master(p_id) # set yourself as network master
		
		if p_id == get_tree().get_network_unique_id():
			# handle setting network master info (you)
			player.set_player_name(player_name)
			player.set_player_frames(player_char)
			var t = team_choices[randi()%team_choices.size()]
			player.set_player_team(t)
			team_choices.pop_front()
		else:
			# handle setting other players (not you)
			player.set_player_name(players[p_id].name)
			player.set_player_frames(players[p_id].character)
			var t = team_choices[randi()%team_choices.size()]
			player.set_player_team(t)
			team_choices.pop_front()
		
		# add to Level1 Ysort node (this is brittle)
		world.get_node("YSort").add_child(player)
		player.connect("player_gained_item", self, "_player_gained_item")
		
		var all_items = Globals.item_graphics.keys()
		var item_spawn_points = world.get_node("PickupSpawns").get_children()
		item_spawn_points.shuffle()
		for i in item_count:
			var item = load("res://PickupItem.tscn").instance()
			var item_graphic = all_items[randi()%all_items.size()]
			print("Spawning a " + str(item_graphic))
			var item_pos = item_spawn_points[0].global_position
			item_spawn_points.pop_front()
			item.global_position = item_pos
			world.add_child(item)
			item._set_graphic(item_graphic)
			
			

	# Set up score.
	#world.get_node("Score").add_player(get_tree().get_network_unique_id(), player_name)
	#for pn in players:
	#	world.get_node("Score").add_player(pn, players[pn])

	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()

remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!

remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()


func host_game(new_player_name, new_player_char):
	player_name = new_player_name
	player_char = new_player_char
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)


func join_game(ip, new_player_name, new_player_char):
	player_name = new_player_name
	player_char = new_player_char
	var client = NetworkedMultiplayerENet.new()
	client.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(client)


func get_player_list():
	return players.values()


func get_player_name():
	return player_name


func begin_game():
	assert(get_tree().is_network_server())

	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	# { 1 : Position2D[0],  12585822: Position2D[1] ... }
	spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	# Call to pre-start game with the spawn points.
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points)

	pre_start_game(spawn_points)


func end_game():
	if has_node("/root/Level1"): # Game is in progress.
		get_node("/root/Level1").queue_free()
	emit_signal("game_ended")
	players.clear()

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


func _player_gained_item(item_type, player_id):
	print("Player: " + str(player_id) + " gained item: " + str(item_type))
	var p = get_tree().get_root().get_node("Level1/YSort").get_node(player_id)
	p.set_held_item(item_type)


