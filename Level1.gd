extends Node

# game ideas:
# find & gather certain number of items
# bring to certain building (players must find building?)
# avoid getting tagged by seeker
# seeker can shoot projectiles that knock out players
# knocked out players can explore the map to help?
# time limit? who wins when it runs out? (hiders prob)
# items and locations are randomized each game
# seeker is slower but has more stamina, hiders are faster but can only run in bursts


remotesync var team_coins = 0

master func _add_team_coin():
	team_coins += 1
	_set_team_coins()
	
master func _set_team_coins():
	rset("team_coins", team_coins)
	
func _on_player_coin_gain():
	rpc_id(1, "_add_team_coin")

func _ready():
	# this cleans up camera smoothing (but why?!)
	Engine.set_target_fps(Engine.get_iterations_per_second())
	var ui = preload('res://UI.tscn').instance()
	add_child(ui)
	$TileMap.set_visible(false)

func _on_Area2D_body_entered(body):
	print(body.name)
	body.position = $"Floors/burger-shop-inside/Position2D".global_position
	body.get_node("Camera2D").force_update_scroll()
	pass

func _on_ShopExit_body_entered(body):
	body.position = $"SpawnPoints/0".global_position
	pass
