extends CanvasLayer

onready var chat_display = $Chat/ChatText
var chat_visible = false

func _ready():
	var player = get_tree().get_root().get_node("Level1/YSort/Players/"+str(get_tree().get_network_unique_id()))
	chat_display.text = ""
	$Chat.modulate.a = 0.75
	if player.team == "seeker":
		$QPanel.set_visible(false)
		var _hotkey_count = 1
		for skill in Globals.seeker_skills:
			# show seeker skills
			var skillbox = load("res://SeekerPower.tscn").instance()
			skillbox.skill_name = skill.name
			skillbox.background = skill.background
			skillbox.icon_image = skill.icon
			skillbox.hotkey = _hotkey_count
			skillbox.cooldown = skill.cooldown
			skillbox.name = "Skill_" + str(_hotkey_count)
			_hotkey_count += 1
			$SeekerPowers.add_child(skillbox)
	
	for q in gamestate.item_quest:
		# show item quest
		var lab = Label.new()
		lab.text = str(q[0]) + " " + str(q[1])
		$QPanel/QMargin/Quests.add_child(lab)
		
func set_cooldown(skill):
	# start cooldown UI
	var skillbox = get_node("SeekerPowers/Skill_"+str(skill+1))
	skillbox.start_cooldown()

func update_quest_text():
	# update quest UI
	
	# remove text first
	for n in $QPanel/QMargin/Quests.get_children():
		$QPanel/QMargin/Quests.remove_child(n)
		n.queue_free()
	
	# re-add text
	for q in gamestate.item_quest:
		var lab = Label.new()
		lab.autowrap = true
		lab.text = str(q[0]) + " " + str(q[1])
		$QPanel/QMargin/Quests.add_child(lab)

func _on_ChatSend_pressed():
	$Chat/ChatControl/ChatInput.set_focus(false)
	var msg = $Chat/ChatControl/ChatInput.text
	if msg != "":
		$Chat/ChatControl/ChatInput.text = ""
		var id = get_tree().get_network_unique_id()
		$Chat/ChatControl/ChatInput.release_focus()
		rpc("receive_message", gamestate.player_name, msg)
	
	
#sync happens on all clients (including local/server!)
sync func receive_message(id, msg):
	chat_display.text += str(id) + ": " + msg + "\n"
	var curline = chat_display.get_line_count()
	chat_display.cursor_set_line(curline)

func _on_ChatInput_focus_entered():
	$Chat.modulate.a = 1
	var id = get_tree().get_network_unique_id()
	var p = get_tree().get_root().get_node("Level1/YSort/Players/"+str(id))
	p.can_move = false

func _on_ChatInput_focus_exited():
	$Chat.modulate.a = 0.75
	var id = get_tree().get_network_unique_id()
	var p = get_tree().get_root().get_node("Level1/YSort/Players/"+str(id))
	p.can_move = true

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		$Chat/ChatControl/ChatInput.text = ""
		$Chat/ChatControl/ChatInput.release_focus()
	if event.is_action_pressed("ui_accept"):
		_on_ChatSend_pressed()
	if Input.is_action_just_pressed("chat") and !$Chat/ChatControl/ChatInput.has_focus():
		if chat_visible:
			#$Chat/AnimationPlayer.play_backwards("show_chat")
			chat_visible = false
		else:
			#$Chat/AnimationPlayer.play("show_chat")
			chat_visible = true
