extends Control

onready var ip_addr = $Margin/LobbyContainer/VBoxContainer/TabPanel/TabMargin/TabContainer/Join/MarginContainer/HBoxContainer/VBoxContainer/ipwrap/IpBox/HBoxContainer/IpAddr
onready var error_text = $Margin/LobbyContainer/VBoxContainer/ErrorText
onready var player_list = $Margin/PCenter/Players/Margin/Vbox/List
onready var game_list = $Margin/LobbyContainer/VBoxContainer/TabPanel/TabMargin/TabContainer/Join/MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/ListOfGames
onready var host_button = $Margin/LobbyContainer/VBoxContainer/TabPanel/TabMargin/TabContainer/Host/Center/VBoxContainer/HostButton
onready var join_button = $Margin/LobbyContainer/VBoxContainer/TabPanel/TabMargin/TabContainer/Join/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/JoinButton
onready var refresh_button = $Margin/LobbyContainer/VBoxContainer/TabPanel/TabMargin/TabContainer/Join/MarginContainer/HBoxContainer/VBoxContainer/ipwrap/IpBox/Refresh
onready var lobby_container = $Margin/LobbyContainer
onready var lobby_player_list = $Margin/PCenter
onready var lock_icon = load("res://sprites/lock.png")

var pname = "" # nickname placeholder
var game_name = ""
var game_password = ""
var player_password = ""
var current_game_password = ""
var character = "pokey" # character selection
var item_types = 3
var item_count = 3
var dropzone_count = 3
var max_items
var max_dropzones
var active_game_list
var ip

var random_game_name_parts_one = ["RunawayDog", "SpitefulCrow", "CoilSnake", "StarmanJr", "PogoPunk", "YesManJunior", "SkatePunk", "MasterBelch", "Frankystein", "BoogeyTent", "ManiMani", "MasterBarf", "Giygas", "TitanicAnt", "MondoMole", "TrillionageSprout", "Shrooom"]
var random_game_name_parts_two = ["Lumine", "Fourside", "Twoson", "Threed", "Onett", "Summers", "PeacefulRest", "DustyDunes", "EagleLand", "Stonehenge", "GiantStep", "HappyHappy", "LakeTess", "Winters", "Magicant"]
var random_player_name_parts = ["Aloysius", "Orange", "Andonuts", "Saturn", "Montague", "Geldegarde", "Talah", "Tessie", "Agerate", "Lardna", "Maxwell", "Carpainter", "Poochyfud", "NoName", "Buzz", "Strong", "Ruffini", "Giovanni", "Runaway"]

func _ready():
	randomize()
	var level1 = load("res://Level1.tscn").instance()
	max_items = level1.get_node("YSort/PickupSpawns").get_child_count()
	max_dropzones = level1.get_node("DropzoneSpawns").get_child_count()
	level1.queue_free()
	print("Max items: " + str(max_items))
	print("Max dropzones: " + str(max_dropzones))
	$Margin.set_visible(false)
	$Title.set_visible(true)
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")
	$SendHostData.connect("request_completed", self, "host_data_sent")
	error_text.text = ""
	
	# setup random game names
	var g1 = get_random_name(random_game_name_parts_two,1)
	var g2 = get_random_name(random_game_name_parts_one,1)
	game_name = str(g1)+str(g2)
	$Margin/LobbyContainer/VBoxContainer/TabPanel/TabMargin/TabContainer/Host/Center/VBoxContainer/HBoxContainer/VBoxContainer2/GameNameContainer/GameName.text = game_name
	
# get a random name with multiple parts
func get_random_name(parts, num):
	parts.shuffle()
	var r = ""
	for i in range(num):
		r += str(parts[i])
	return r

func _set_buttons_disabled(d):
	host_button.disabled = d
	join_button.disabled = d

# hosting a game
func _on_HostButton_pressed():
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_-]*$")
	
	if pname == "" || !regex.search(pname):
		error_text.text = "Please enter a valid name."
		return
	if game_name == "" || !regex.search(game_name):
		error_text.text = "Please enter a valid game name."
		return
	if !str(item_count).is_valid_integer() or !str(item_types).is_valid_integer() or !str(dropzone_count).is_valid_integer():
		error_text.text = "Please use numbers only for the items/dropzones."
		return
	if (int(item_count)*int(item_types)) > max_items:
		error_text.text = "Too many items!  Max items: " + str(max_items)
		return
	if int(dropzone_count) > max_dropzones:
		error_text.text = "Too many dropzones!  Max dropzones: "  + str(max_dropzones)
		return
	
	$SFX.play()
	lobby_container.hide()
	lobby_player_list.show()
	# make http request to lobby server
	send_game_data(pname)
	$SendHostData/Ping.start()
	error_text.text = ""
	gamestate.host_game(pname, character, int(item_types), int(item_count), int(dropzone_count))
	refresh_lobby()

func send_game_data(player_name):
	#print("Pinging jp00p.com with gamedata...")
	var request_url = str("http://jp00p.com/seekseek/host.php?name={name}&game_name={game_name}&password={password}").format({ "name" : player_name, "game_name": game_name, "password" : game_password })
	$SendHostData.request(request_url)

func _on_Ping_timeout():
	send_game_data(pname)

func host_data_sent(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	#print("Host result:" + str(json.result) + " / " + str(result) + " / " + str(headers) + " / " + str(response_code))

# joining a game
func _on_JoinButton_pressed():
	
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_-]*$")
	
	if !ip:
		ip = ip_addr.text
	if !ip.is_valid_ip_address():
		error_text.text = "Invalid IP address."
		return
	if pname == "" || !regex.search(pname):
		error_text.text = "Please enter a valid name."
		return
	if current_game_password != player_password:
		error_text.text = "Invalid password"
		return
	error_text.text = ""
	_set_buttons_disabled(true)
	$GetGameData/GameListPing.stop()
	gamestate.join_game(ip, pname, character)

func _on_connection_success():
	lobby_container.hide()
	lobby_player_list.show()

# failed to connect	
func _on_connection_failed():
	_set_buttons_disabled(false)
	error_text.text = "Connection failed."

# game is completely over, soft restart
func _on_game_ended():
	show()
	lobby_container.show()
	lobby_player_list.hide()
	
# when a breaking game error happens	
func _on_game_error(msg):
	$ErrorDialog.dialog_text = msg
	$ErrorDialog.popup_centered_minsize()
	_set_buttons_disabled(false)

# update list of players ready to start
func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	player_list.clear()
	player_list.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		player_list.add_item(p.name)
	
	$Margin/PCenter/Players/Margin/Vbox/StartGame.disabled = not get_tree().is_network_server()	

func _start_game():
	$SendHostData/Ping.stop()
	rpc("stop_music")
	gamestate.begin_game()
	
remotesync func stop_music():
	$BGM.stop()

# change number of item types for game
func _on_ItemTypes_text_changed(new_text):
	item_types = new_text

# change number of items per type for game
func _on_ItemCount_text_changed(new_text):
	item_count = new_text

# change number of dropzones for hiders
func _on_DropzoneCount_text_changed(new_text):
	dropzone_count = new_text
	
# update name
func _on_NameEdit_text_changed(new_text):
	pname = new_text

# yikes... should use an instanced scene that connects itself for these
func _on_SwimsuitGuy_pressed():
	$SFX.play()
	character = "swimsuitguy"

func _on_BunnyStatue_pressed():
	$SFX.play()
	character = "bunnystatue"

func _on_Grandma_pressed():
	$SFX.play()
	character = "grandma"

func _on_Magicant_pressed():
	$SFX.play()
	character = "magicant"

func _on_MissFake_pressed():
	$SFX.play()
	character = "missfake"

func _on_Nurse_pressed():
	$SFX.play()
	character = "nurse"

func _on_Photographer_pressed():
	$SFX.play()
	character = "photographer"

func _on_Punk_pressed():
	$SFX.play()
	character = "punk"

func _on_Tenda_pressed():
	$SFX.play()
	character = "tenda"

func _on_Tracy_pressed():
	$SFX.play()
	character = "tracy"

func _on_Venus_pressed():
	$SFX.play()
	character = "venus"

func _on_Pokey_pressed():
	$SFX.play()
	character = "pokey"

func _on_Pizzagirl_pressed():
	$SFX.play()
	character = "pizzagirl"

func _on_MrSaturn_pressed():
	$SFX.play()
	character = "mrsaturn"

func _on_Frank_pressed():
	$SFX.play()
	character = "frank"

func _on_Applekid_pressed():
	$SFX.play()
	character = "applekid"

func _on_Bellhop_pressed():
	$SFX.play()
	character = "bellhop"

func _on_Hippie_pressed():
	$SFX.play()
	character = "hippie"

func _on_ArmsDealer_pressed():
	$SFX.play()
	character = "armsdealer"

# make http request to get game list
func get_game_list():
	print("Loading list of lobbies...")
	refresh_button.set_disabled(true)
	game_list.clear()
	$GetGameData.request("http://jp00p.com/seekseek/get_list.php")

# when player chooses to join a game, load up the game list and refresh intervals
func _on_TabContainer_tab_changed(tab):
	if tab == 1:
		$GetGameData/GameListPing.start()
		get_game_list()
	else:
		$GetGameData/GameListPing.stop()

# get list of games from my server once request is complete
func _on_GetGameData_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	active_game_list = json.result
	refresh_button.set_disabled(false)
	for game in json.result:
		if game[2]:
			var _gamestring = game[2]
			if game[3] != "":
				game_list.add_item(_gamestring, lock_icon)
			else:
				game_list.add_item(_gamestring)
		
# when a player selects a game from the list
func _on_ListOfGames_item_selected(index):
	var selected_game_ip = active_game_list[index][1]
	ip_addr.clear()
	ip = selected_game_ip
	current_game_password = str(active_game_list[index][3])
	print(ip + ":" + current_game_password)

# when a user wants to refresh the list of games
func _on_Refresh_pressed():
	$GetGameData/GameListPing.start(0)
	get_game_list()

# set player password (has to match game password)
func _on_Password_text_changed(new_text):
	player_password = new_text

# set game name
func _on_GameName_text_changed(new_text):
	game_name = new_text

# set game password
func _on_GamePassword_text_changed(new_text):
	game_password = new_text

# refresh gamelist every 5 sec
func _on_GameListPing_timeout():
	get_game_list()

# when endgame report is done sending (nothing to do yet)
func _on_EndgameReport_request_completed(result, response_code, headers, body):
	pass

# give player random name if they click the button
func _on_RandomName_pressed():
	$SFX.play()
	var n = get_random_name(random_player_name_parts,2)
	pname = n
	$Margin/LobbyContainer/Name/HBoxContainer/NameEdit.text = n

# when player is focused on game list, stop refreshing
func _on_ListOfGames_focus_entered():
	$GetGameData/GameListPing.stop()

# start refreshing if they leave game list focus
func _on_ListOfGames_focus_exited():
	$GetGameData/GameListPing.start()

func _on_Title_title_start():
	$Title.set_visible(false)
	$Margin.set_visible(true)

func _on_Title_show_help():
	$Title.set_visible(false)
	$HelpContainer.set_visible(true)

func _on_CloseHelp_pressed():
	$HelpContainer.set_visible(false)
	$Title.set_visible(true)
