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

const DEFAULT_PORT = 6073 #10567
const MAX_PEERS = 12
const DEFAULT_TEAMS = ["seeker"]

var game_item_count
var game_item_types
var game_dropzone_count = 2
sync var item_quest

# these are always the details for YOU
var player_name = "DEFAWLT"
var player_char = "pokey"
var player_team

# details for NOT YOU
# { id: {name:string, character:string} }
var players = {}
var players_ready = []

var time_start = 0
var time_now = 0
var elapsed = 0

signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)

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
	players[id] = {"name" : new_player_name, "character" : new_player_char, "team" : "" }
	emit_signal("player_list_changed")

func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

remote func pre_start_game(spawn_points, item_spawn_points, drop_points, tc):
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
	var temp_team_choices = tc
	for p_id in spawn_points:
		# spawn the players in random spots!
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position  # warning: we need a spawn point for each player!
		var player = player_scene.instance()
		
		player.set_name(str(p_id)) # sets the player node name to their network ID
		player.position = spawn_pos # set spawn position
		player.set_network_master(p_id) # set yourself as network master
			
		if p_id == get_tree().get_network_unique_id():
			#print("Setting " + str(p_id) + " to " + str(team_choices[0]))
			# handle setting network master info (you)
			player.set_player_name(player_name)
			player.set_player_frames(player_char)
			player.set_player_team(temp_team_choices[0])
		else:
			#print("Setting " + str(p_id) + " to " + str(team_choices[0]))
			# handle setting other players (not you)
			player.set_player_name(players[p_id].name)
			player.set_player_frames(players[p_id].character)
			player.set_player_team(temp_team_choices[0])
			
		temp_team_choices.pop_front()
		
		# add to Level1 Ysort node (this is brittle)
		world.get_node("YSort/Players").add_child(player)
		player.connect("player_gained_item", self, "_player_gained_item")
	
	
	var item_spawn_locations = world.get_node("YSort/PickupSpawns").get_children()
	var ii = 0
	
	
	for item in item_spawn_points:
		var Item = load("res://PickupItem.tscn").instance()
		var item_graphic = item
		var item_pos = item_spawn_locations[ii].global_position
		Item.global_position = item_pos
		#print("Spawning  " + item_graphic + " at " + str(item_pos))
		get_tree().get_root().get_node("Level1/YSort/Items").add_child(Item)
		Item._set_graphic(item_graphic)
		ii += 1
	
	var dropzone_spawn_locations = get_tree().get_root().get_node("Level1/DropzoneSpawns").get_children()
	
	for i in drop_points:
		var dropzone = load("res://Dropzone.tscn").instance()
		dropzone.global_position = dropzone_spawn_locations[i].global_position
		#print("Spawning a drop point at " + str(dropzone.global_position))
		get_tree().get_root().get_node("Level1/YSort").add_child(dropzone)
		dropzone.connect("quest_item_dropped", self, "ui_quest_update")
	
	var ui = load('res://UI.tscn').instance()
	world.add_child(ui)
	
	
	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()
		

remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!
	time_start = OS.get_unix_time()
	set_process(true)

remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()

func host_game(new_player_name, new_player_char, item_types, item_count, dropzone_count):
	player_name = new_player_name
	player_char = new_player_char
	game_item_types = item_types
	game_item_count = item_count
	game_dropzone_count = dropzone_count
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
	assert(get_tree().is_network_server()) # ONLY HOST
	
	
	# create item quest for seekers
	item_quest = Globals.create_item_quest(game_item_count,game_item_types)
	rset("item_quest", item_quest)
	
	
	var world = load("res://Level1.tscn").instance() # just peeking at level1 before we actually add it to the tree
	var spawn_nodes = range(world.get_node("SpawnPoints").get_children().size())
	var item_spawn_nodes = range(world.get_node("YSort/PickupSpawns").get_children().size()-(game_item_count*game_item_types))
	var dropzone_spawn_nodes = range(world.get_node("DropzoneSpawns").get_children().size())
	spawn_nodes.shuffle() # [2, 0, 1, 3...]
	dropzone_spawn_nodes.shuffle()
	world.queue_free()
	

	var spawn_points = {}
	# { 1 : Position2D[0],  12585822: Position2D[1] ... }
	spawn_points[1] = spawn_nodes[0] # Server in spawn point 0.
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_nodes[spawn_point_idx]
		spawn_point_idx += 1
	
	# set up the teams
	# one seeker, everyone else a hider
	var team_choices = DEFAULT_TEAMS.duplicate() # start with one seeker always
	for _n in range(spawn_points.size()-1): # size-1 because we already have a seeker
		team_choices.append("hider") # fill the array with hiders based on how many players are spawning
	team_choices.shuffle() # randomize the team array
	

	# create arrays of the items and where they go
	# then send to pre_start_game to generate same items for each player	
	var all_items = Globals.item_graphics.keys() # item names
	var item_spawns = {}
	
	
	# random item placement
	var item_spawn_points = [] # ["apple", "banana", "pizza", ...]
	for i in item_quest:
		for _num_items in i[0]:
			item_spawn_points.append(i[1])
	#print("Spawning " + str(item_spawn_points.size()) + " quest items...")
	var leftovers = item_spawn_nodes.size()-item_spawn_points.size()
	#print("Spawning " + str(leftovers) + " random items!")
	for i in range(item_spawn_nodes.size()-item_spawn_points.size()): # subtract the number of quest items from the total number of spawn points
		item_spawn_points.append(all_items[randi()%all_items.size()])
	
	# random dropzone placement
	var dropzone_spawn_points = []
	for i in range(game_dropzone_count):
		dropzone_spawn_points.append(dropzone_spawn_nodes[randi()%dropzone_spawn_nodes.size()])
	
		
	# Call to pre-start game with all the random choices
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points, item_spawn_points, dropzone_spawn_points, team_choices) # runs on everyone else
	pre_start_game(spawn_points, item_spawn_points, dropzone_spawn_points, team_choices) # runs on this machine



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
	set_process(false)


func _process(delta):
	# keep track of total game time
	time_now = OS.get_unix_time()
	elapsed = time_now - time_start

func _player_gained_item(item_type, player_id):
	#print("Player: " + str(player_id) + " gained item: " + str(item_type))
	var p = get_tree().get_root().get_node("Level1/YSort/Players").get_node(player_id)
	p.set_held_item(item_type)


func ui_quest_update():
	check_game_over()
	var q = get_tree().get_root().get_node("Level1/UI")
	q.update_quest_text()
	var s = get_tree().get_root().get_node("Level1/ItemGetSound")
	s.play()


func get_all_players():
	# used for network request
	var ps = []
	for p in get_tree().get_root().get_node("Level1/YSort/Players").get_children():
		ps.append([p.player_name, p.team, p.steps])
	return ps
		
master func send_game_data(winner):
	var endgamehttp = get_tree().get_root().get_node("LobbySetup/EndgameReport")
	var gamedata = {
		"players" : get_all_players(),
		"duration" : elapsed,
		"winner" : winner
	}
	print("Sending over:" + str(gamedata))
	endgamehttp.request("http://jp00p.com/seekseek/endgame.php", ["Content-type: application/json"], false, HTTPClient.METHOD_POST, JSON.print(gamedata))


func check_all_zombies():
	# returns true if all hiders are zombies
	var all_players = get_all_players()
	var zombie_count = 0
	for p in get_tree().get_root().get_node("Level1/YSort/Players").get_children():
		if p.is_zombie:
			zombie_count += 1
	if zombie_count >= (all_players.size()-1):
		return true
	return false

func check_hider_quest():
	# returns true if hider quest is complete
	var total = 0
	for i in item_quest:
		total += int(i[0])
	return total <= 0
	
master func check_game_over():
	# check if the game is over
	print("Checking game state...")
	if check_hider_quest():
		rpc("game_over", "hider")
		send_game_data("hider")
	if check_all_zombies():
		rpc("game_over", "seeker")
		send_game_data("seeker")
		
remotesync func game_over(winning_team):
	#get_tree().set_pause(true)
	print("Triggering game over")
	for p in get_tree().get_root().get_node("Level1/YSort/Players").get_children():
		p.can_move = false
	#get_tree().get_root().get_node("Level1/UI").queue_free()
	var game_over_screen = load("res://GameOver.tscn").instance()
	get_tree().get_root().get_node("Level1/BGM").stop()
	get_tree().get_root().get_node("Level1/NightMusic").stop()
	if winning_team == "seeker":
		get_tree().get_root().get_node("Level1/SeekerWins").play()
	else:
		get_tree().get_root().get_node("Level1/HiderWins").play()
	get_tree().get_root().get_node("Level1").add_child(game_over_screen)
	game_over_screen.declare_winner(winning_team)
