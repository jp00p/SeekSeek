extends KinematicBody2D

var speed = 0
var walk_speed = 125
var run_speed = 175

var velocity = Vector2()
var frames
var direction

var character_graphics = {
	"pokey" : preload("res://Characters/pokey.tres"),
	"pizzagirl" : preload("res://Characters/pizzagirl.tres"),
	"mrsaturn" : preload("res://Characters/mrsaturn.tres"),
	"frank" : preload("res://Characters/frank.tres")
}

# position/direction of players that aren't the network master
slave var slave_position = Vector2()
slave var slave_direction = ""

func _ready():
	if is_network_master():
		$Camera2D.make_current() # one camera per player

func _physics_process(delta):
	if is_network_master():
		# network master (you) gets to move each frame
		get_input()
		velocity = move_and_slide(velocity)
		# these 2 lines set where you show up on other player's screens
		rset_unreliable("slave_position", position)
		rset_unreliable("slave_direction", direction)
	else:
		# other players just update the position
		position = slave_position
		_set_direction(slave_direction)
	
	if get_tree().is_network_server():
		ConnectionManager.update_position(int(name), position)

func get_input():
	velocity = Vector2.ZERO
	if Input.is_action_pressed('run'):
		speed = run_speed
	else:
		speed = walk_speed
	if Input.is_action_pressed('move_right'):
		velocity.x += 1
		direction = "right"
	if Input.is_action_pressed('move_left'):
		velocity.x -= 1
		direction = "left"
	if Input.is_action_pressed('move_down'):
		direction = "down"
		velocity.y += 1
	if Input.is_action_pressed('move_up'):
		direction = "up"
		velocity.y -= 1
	# Make sure diagonal movement isn't faster
	_set_direction(direction)
	velocity = velocity.normalized() * speed

func _set_direction(dir):
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

func init(nickname, start_position, character):
	$Label.text = nickname
	global_position = start_position
	frames = character_graphics[character]
	$Sprite.set_sprite_frames(frames)
