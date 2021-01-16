extends KinematicBody2D

# moving after being tagged???
# game doesn't fully restart
# turn to zombie?!

signal player_gained_item(item_type, player_id)

var is_zombie = false

var can_move = false
var can_run = true

var speed = 0
var hider_walk_speed = 125
var hider_run_speed = 175

var seeker_walk_speed = 115
var seeker_run_speed = 185

var zombie_walk_speed = 50
var zombie_run_speed = 75

var walk_speed
var run_speed

var running = false
var max_stamina = 500
var seeker_max_stamina = 250
var stamina = max_stamina

var team
var carried_item = ""
var throw_distance = 22
var throw_dir = Vector2()

var step_size = 12.0

var velocity = Vector2()
var frames = Globals.character_graphics["pokey"]
var direction = "down"

var player_name
var close_calls = 0
var steps = 0.0
var footsteps = false

var cam_scale_normal = Vector2(0.25, 0.25)
var cam_scale_running = Vector2(0.2, 0.2)

# info of players that aren't the network master
puppet var puppet_info = { "puppet_pos": Vector2(), "puppet_dir": "", "footsteps": footsteps }

func _ready():

	$PlayerName.text = str(team)
	$Sprite.set_sprite_frames(frames)
	$Flashlight.set_visible(false)
	
	if is_network_master():
		$Camera2D.make_current() # one camera per player
	
	# seeker is a little slower but can run longer
	if is_network_master() and team == "seeker":
		set_speed(seeker_walk_speed, seeker_run_speed)
		max_stamina = seeker_max_stamina
		get_tree().get_root().get_node("Level1/MaskLayer/Mask").set_visible(false)
	if is_network_master() and team != "seeker":
		set_speed(hider_walk_speed, hider_run_speed)
		
	if team == "seeker":
		$SeekerTrail.set_visible(true)
		
	yield(get_tree().create_timer(6.5), "timeout")
	can_move = true


func _physics_process(delta):
	
	var t = delta
	
	if is_network_master():
		# handle yourself
		get_input()
		if running:
			$Camera2D.zoom = $Camera2D.zoom.linear_interpolate(cam_scale_running, t)
		else:
			$Camera2D.zoom = $Camera2D.zoom.linear_interpolate(cam_scale_normal, t)
		if velocity != Vector2.ZERO:
			steps += 1.0
			footsteps = true
		else:
			footsteps = false
		velocity = move_and_slide(velocity)
			
		$RayCast2D.cast_to = throw_dir

		# set your info for other people to see! 
		rset_unreliable("puppet_info", { "puppet_pos": position, "puppet_dir": direction, "footsteps": footsteps })
		
	else:
		# handle the fakes!
		position = puppet_info.puppet_pos # x,y
		_set_direction(puppet_info.puppet_dir) # which way are you facing
		if not $Footsteps.is_playing() and puppet_info.footsteps:
			$Footsteps.play()





# seeker attempting to kill a hider
func try_kill():
	assert(is_network_master())
	var bodies = $KillRadius.get_overlapping_bodies()
	bodies.erase(self)
	if bodies.size() > 0:
		bodies.shuffle() # kill a random person in range
		if !bodies[0].is_zombie:
			self.position = bodies[0].position
			rpc("kill_player", bodies[0].name)
			get_tree().get_root().get_node("Level1/UI").set_cooldown(0)



# function that fires when a successful kill is made
sync func kill_player(p_id):
	var p = get_tree().get_root().get_node("Level1/YSort/Players/"+str(p_id))
	p.become_zombie()
	$PlayerDeathSound.play()

# when a hider dies, they become a zombie
func become_zombie():
	set_speed(zombie_walk_speed, zombie_run_speed)
	is_zombie = true
	$ZombieRadius.set_monitoring(true)
	$Sprite.set_sprite_frames(Globals.character_graphics["zombie"])
	gamestate.check_game_over()

func get_input():
	velocity = Vector2.ZERO
	
	if !can_move:
		return
	
	if team == "seeker" and (Input.is_action_just_pressed('hotkey1') or Input.is_action_just_pressed("ui_select")):
		if Globals.seeker_skills[0].cooldown_active:
			return
		try_kill()
	if team == "seeker" and Input.is_action_just_pressed('hotkey2'):
		if Globals.seeker_skills[1].cooldown_active:
			return
		get_tree().get_root().get_node("Level1").set_xray()
	if team == "seeker" and Input.is_action_just_pressed('hotkey3'):
		if Globals.seeker_skills[2].cooldown_active:
			return
		get_tree().get_root().get_node("Level1").set_night()
	

	if carried_item != "" and Input.is_action_just_pressed("drop_item") and team != "seeker":
		drop_item()
	
	# are we pressing run and can we run?
	if Input.is_action_pressed('run') and can_run:
		speed = run_speed
		$Sprite.speed_scale = 2
		running = true
	else:
	# normal walking
		speed = walk_speed
		$Sprite.speed_scale = 1
		running = false
		if can_run:
			stamina = min(stamina+1, max_stamina)
	
	if carried_item != "":
		speed = speed - 25
		$Sprite.speed_scale = 0.5
	
	# once stamina hits 0, no more running and start the timer
	if stamina <= 0 and running:
		can_run = false
		$StaminaCooldown.start()
	
		# handle movement keys, and if we're running reduce the stamina
	if Input.is_action_pressed('move_right'):
		velocity.x += 1
		direction = "right"
		throw_dir = velocity.normalized() * throw_distance
		if running:
			stamina = max(stamina-1, 0)
	if Input.is_action_pressed('move_left'):
		velocity.x -= 1
		direction = "left"
		throw_dir = velocity.normalized() * throw_distance
		if running:
			stamina = max(stamina-1, 0)
	if Input.is_action_pressed('move_down'):
		direction = "down"
		velocity.y += 1
		throw_dir = velocity.normalized() * throw_distance
		if running:
			stamina = max(stamina-1, 0)
	if Input.is_action_pressed('move_up'):
		direction = "up"
		velocity.y -= 1
		throw_dir = velocity.normalized() * throw_distance
		if running:
			stamina = max(stamina-1, 0)
			
	_set_direction(direction) # set sprite direction
	velocity = velocity.normalized() * speed # normalize so diagonals are same speed
	

func _set_direction(dir):
	# sets sprite direction
	match dir:
		"right":
			$Sprite.animation = "side"
			$Sprite.flip_h = false
		"left":
			$Sprite.animation = "side"
			$Sprite.flip_h = true
		"down":
			$Sprite.animation = "default"
		"up":
			$Sprite.animation = "back"


func set_player_name(new_name):
	player_name = new_name
	#$PlayerName.text = str(new_name)
	
func pass_through_door():
	can_move = false
	yield(get_tree().create_timer(0.33), "timeout")
	can_move = true
	
func set_player_frames(char_name):
	frames = Globals.character_graphics[char_name]
	
func set_player_team(team_choice):
	team = team_choice
	$PlayerName.text = str(team_choice)
	
func set_flashlight(state):
	$Flashlight.set_visible(state)
	
func _on_StaminaCooldown_timeout():
	can_run = true

func gain_item(item_type):
	emit_signal("player_gained_item", item_type, self.name)

func set_held_item(item_type):
	#print("Setting held item to " + str(item_type))
	if item_type == "none" or item_type == "":
		carried_item = ""
		$HeldItem.texture = null
	else:
		carried_item = item_type
		$HeldItem.texture = Globals.item_graphics[carried_item]

func drop_item():
	var throw_loc = throw_dir + global_position
	rpc("player_dropped_item", carried_item, throw_loc, self.name)

func has_item():
	if carried_item != "":
		return true
	return false

sync func player_dropped_item(item_type, location, player_id):
	#print("GAMESTATE: Dropping item " + str(item_type) + " at location: " + str(location))
	var new_item = load("res://PickupItem.tscn").instance()
	new_item.global_position = location
	get_tree().get_root().get_node("Level1/YSort/Items").add_child(new_item)
	new_item._set_graphic(item_type)
	var p = get_tree().get_root().get_node("Level1/YSort/Players").get_node(player_id)
	p.set_held_item("none")

func set_speed(ws, rs):
	walk_speed = ws
	run_speed = rs

func _on_ZombieRadius_body_entered(body):
	# if someone gets in range of a zombie
	if body == self or body.is_zombie:
		return
	body.infect()
	
func infect():
	# when a zombie touches another player they get infected
	set_speed(50, 50)
	$SlowTimer.start()
	
func _on_SlowTimer_timeout():
	# reset hider speed
	set_speed(hider_walk_speed, hider_run_speed)


func _on_KillRadius_body_entered(body):
	pass # Replace with function body.
