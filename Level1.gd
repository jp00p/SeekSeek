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

var player_list = []

func _ready():
	Engine.set_target_fps(Engine.get_iterations_per_second()) # this cleans up camera smoothing (but why?!)
	$TileMap.set_visible(false)
	$MaskLayer/Mask.modulate.a = 0
	
	yield(get_tree().create_timer(6.5), "timeout") # wait for music
	$MaskLayer/CenterContainer.queue_free()
	get_node("UI/Chat").set_visible(true)
	
		
func set_night():
	# setup nighttime power 
	rpc("nighttime")
	get_node("UI").set_cooldown(2) # skills are 0,1,2 (hotkeys are 1,2,3)
	
func set_xray():
	# setup xray power
	xray()
	rpc("xray_blast")
	get_node("UI").set_cooldown(1)
	
remotesync func xray_blast():
	# show the xray animation to everyone
	$MaskLayer/XrayBlast.play()
	$XRaySound.play()

remotesync func nighttime():
	# show the nighttime stuff for everyone
	is_night = true
	$AnimationPlayer.play("nighttime")
	$NightTimer.start()
	$BGM.set_stream_paused(true)
	$NightMusic.play()
	for p in $YSort/Players.get_children():
		if p.team != "seeker":
			p.set_flashlight(true)
	
master func xray():
	# show xray stuff (only for person who used it)
	is_xray = true
	$Tops.modulate.a = 0.5
	$XrayTimer.start()

func _on_NightTimer_timeout():
	# end the night effect
	is_night = false
	$NightMusic.stop()
	$BGM.set_stream_paused(false)
	for p in $YSort/Players.get_children():
		p.set_flashlight(false)
	$AnimationPlayer.play_backwards("nighttime")

func _on_XrayTimer_timeout():
	# end xray
	is_xray = false
	$Tops.modulate.a = 1
