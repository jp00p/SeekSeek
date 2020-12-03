extends Control

onready var ip_addr = $Margin/LobbyContainer/TabPanel/TabMargin/TabContainer/Join/ipwrap/IpBox/IpAddr
onready var error_text = $Margin/LobbyContainer/ErrorText
onready var player_list = $Margin/Players/MarginContainer/VBoxContainer/List

var pname = "" # nickname placeholder
var character = "pokey" # character selection
var item_types = 3
var item_count = 3

func _ready():
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")

func _set_buttons_disabled(d):
	$Margin/LobbyContainer/TabPanel/TabMargin/TabContainer/Host/Center/VBoxContainer/HostButton.disabled = d
	$Margin/LobbyContainer/TabPanel/TabMargin/TabContainer/Join/ipwrap/IpBox/JoinButton.disabled = d

# hosting a game
func _on_HostButton_pressed():
	if pname == "":
		error_text.text = "Please enter a name."
		return
	$Margin/LobbyContainer.hide()
	$Margin/Players.show()
	error_text.text = ""
	gamestate.host_game(pname, character, item_types, item_count)
	refresh_lobby()

# joining a game
func _on_JoinButton_pressed():
	var ip = ip_addr.text
	if not ip.is_valid_ip_address():
		error_text.text = "Invalid IP address."
		return
	if pname == "":
		error_text.text = "Please enter a name."
		return
	
	error_text.text = ""
	_set_buttons_disabled(true)
	gamestate.join_game(ip, pname, character)
	

# update name
func _on_NameEdit_text_changed(new_text):
	pname = new_text

func _on_connection_success():
	$Margin/LobbyContainer.hide()
	$Margin/Players.show()
	
func _on_connection_failed():
	_set_buttons_disabled(false)
	error_text.text = "Connection failed."

func _on_game_ended():
	show()
	$Margin/LobbyContainer.show()
	$Margin/Players.hide()
	
func _on_game_error(msg):
	$ErrorDialog.dialog_text = msg
	$ErrorDialog.popup_centered_minsize()
	_set_buttons_disabled(false)

func refresh_lobby():
	var players = gamestate.get_player_list()
	print(players)
	players.sort()
	player_list.clear()
	player_list.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		player_list.add_item(p.name)
	$Margin/Players/MarginContainer/VBoxContainer/Start.disabled = not get_tree().is_network_server()	

func _start_game():
	gamestate.begin_game()

# character selection -- there must be a better way (build buttons with code, connect programmatically)
func _on_Pokey_pressed():
	character = "pokey"

func _on_Pizzagirl_pressed():
	character = "pizzagirl"

func _on_MrSaturn_pressed():
	character = "mrsaturn"

func _on_Frank_pressed():
	character = "frank"

# quick ip connections
func _on_localhost_pressed():
	ip_addr.text = "127.0.0.1"

func _on_jeremy_pressed():
	ip_addr.text = "192.168.0.50"

func _on_ashley_pressed():
	ip_addr.text = "24.53.110.145"


func _on_ItemTypes_text_changed(new_text):
	item_types = int(new_text)

func _on_ItemCount_text_changed(new_text):
	item_count = int(new_text)
