extends Control

func _ready():
	print(ConnectionManager.players)
	_load_players()
	
func _load_players():
	for p in ConnectionManager.players:
		var card = load("res://LobbyUI/CharReadyBox.tscn").instance()
		card.player_name = ConnectionManager.players[p].name
		card.sprite = ConnectionManager.players[p].character
		$MarginContainer/VBoxContainer/CharGrid.add_child(card)	
