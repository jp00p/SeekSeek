extends Control

onready var ip_addr = $Margin/LobbyContainer/TabPanel/TabMargin/TabContainer/Join/ipwrap/IpBox/IpAddr
var pname = "" # nickname placeholder
var character = "pokey" # character selection

# hosting a game
func _on_HostButton_pressed():
	if pname == "":
		return
	ConnectionManager.create_server(pname, character)
	_start_game()

# joining a game
func _on_JoinButton_pressed():
	var ip = ip_addr.text
	if pname == "" or ip == "":
		return
	ConnectionManager.connect_to_server(ip, pname, character)
	_start_game()

# update name
func _on_NameEdit_text_changed(new_text):
	pname = new_text

# start the game (go to level 1... could go to a lobby instead)
func _start_game():
	get_tree().change_scene("res://Level1.tscn")

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
