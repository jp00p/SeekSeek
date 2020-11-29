extends KinematicBody2D

signal gained_coin
signal player_gained_item(item_type, player_id)

var can_move = true
var can_run = true

var speed = 0
var walk_speed = 125
var run_speed = 175

var seeker_walk_speed = 115
var seeker_run_speed = 150

var running = false
var max_stamina = 50
var seeker_max_stamina = 150
var stamina = max_stamina

var team
var carried_item = ""
var throw_distance = 25
var throw_dir = Vector2()

var coins = 0


var velocity = Vector2()
var frames = Globals.character_graphics["pokey"]
var direction
var flashlight_on = true

# info of players that aren't the network master
puppet var puppet_info = { "puppet_pos": Vector2(), "puppet_dir": "", "puppet_flashlight_on": true, "carried_item" : "" }

func _ready():
	$PlayerName.text = str(team)
	$Sprite.set_sprite_frames(frames)
	
	if is_network_master():
		$Camera2D.make_current() # one camera per player
	
	# seeker is a little slower but can run longer
	if team == "seeker":
		print("You are the seeker!")
		walk_speed = seeker_walk_speed
		run_speed = seeker_run_speed
		max_stamina = seeker_max_stamina
		get_tree().get_root().get_node("Level1/Nighttime").set_visible(false)



func _physics_process(delta):
	
	if is_network_master():
		# YOUR OWN SETTINGS
		get_input()
		$Flashlight.enabled = flashlight_on
		velocity = move_and_slide(velocity)
		$RayCast2D.cast_to = throw_dir

		# set your info for other people to see!
		rset("puppet_info", { "puppet_pos": position, "puppet_dir": direction, "puppet_flashlight_on": flashlight_on })
		
	else:
		# WHAT OTHER PEOPLE SEE
		position = puppet_info.puppet_pos # x,y
		_set_direction(puppet_info.puppet_dir) # which way are you facing
		$Flashlight.enabled = puppet_info.puppet_flashlight_on # is your flashlight on

func get_input():
	velocity = Vector2.ZERO
	if !can_move:
		return
	
	if team == "seeker" and Input.is_action_just_pressed('hotkey2'):
		get_tree().get_root().get_node("Level1").set_night()
	
	# did we press the flashlight button		
	if Input.is_action_just_pressed('light'):
		flashlight_on = !flashlight_on
		rset("puppet_flashlight_on", flashlight_on)
	if carried_item != "" and Input.is_action_just_pressed("drop_item"):
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
	pass
	#$PlayerName.text = str(new_name)
	
func set_player_frames(char_name):
	frames = Globals.character_graphics[char_name]
	
func set_player_team(team_choice):
	team = team_choice
	$PlayerName.text = str(team_choice)
	
func _gain_coin():
	coins += 1
	emit_signal("gained_coin")

func _on_StaminaCooldown_timeout():
	can_run = true

func gain_item(item_type):
	emit_signal("player_gained_item", item_type, self.name)

func set_held_item(item_type):
	print("Setting held item to " + str(item_type))
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
	print("GAMESTATE: Dropping item " + str(item_type) + " at location: " + str(location))
	var new_item = load("res://PickupItem.tscn").instance()
	new_item.global_position = location
	get_tree().get_root().get_node("Level1").add_child(new_item)
	new_item._set_graphic(item_type)
	var p = get_tree().get_root().get_node("Level1/YSort").get_node(player_id)
	p.set_held_item("none")
