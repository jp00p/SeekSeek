extends Node

# game ideas:
# find & gather certain number & combination of items
# bring to certain building (players must find building?)
# avoid getting tagged by seeker
# knocked out players can explore the map to help?
# time limit? who wins when it runs out? (hiders prob)
# items and locations are randomized each game
# seeker is slower but has more stamina, hiders are faster but can only run in bursts
# seeker power: see through trees/buildings for a bit
# seeker power: teleport using connected portals
# seeker power: change to night for hiders for a bit
# seeker power: shoot PSI to stun hider
# seeker power: up-close instant knock out
# turn knocked out players into zombies???  maybe they chase/slow down the seeker

var is_night = false
var is_xray = false

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
	$TileMap.set_visible(false)
	$MaskLayer/Mask.modulate.a = 0
	
func _on_Area2D_body_entered(body):
	print(body.name)
	body.position = $"Floors/burger-shop-inside/Position2D".global_position
	body.get_node("Camera2D").force_update_scroll()
	pass

func _on_ShopExit_body_entered(body):
	body.position = $"SpawnPoints/0".global_position
	pass
	
func set_night():
	rpc("nighttime")
	get_node("UI").set_cooldown(2) # skills are 0,1,2 (hotkeys are 1,2,3)
	
func set_xray():
	xray()
	rpc("xray_blast")
	get_node("UI").set_cooldown(1)
	
remotesync func xray_blast():
	$MaskLayer/XrayBlast.play()

remotesync func nighttime():
	print("night :O")
	is_night = true
	$AnimationPlayer.play("nighttime")
	$NightTimer.start()
	for p in $YSort/Players.get_children():
		if p.team != "seeker":
			p.set_flashlight(true)
	
master func xray():
	is_xray = true
	$Tops.modulate.a = 0.5
	$XrayTimer.start()

func _on_NightTimer_timeout():
	print("Night time is over!")
	is_night = false
	for p in $YSort/Players.get_children():
		p.set_flashlight(false)
	$AnimationPlayer.play_backwards("nighttime")


func _on_XrayTimer_timeout():
	is_xray = false
	$Tops.modulate.a = 1
