extends CanvasLayer

onready var chat_display = $Chat/ChatText
var chat_visible = false

func _process(delta):
	pass

func _on_ChatSend_pressed():
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
	var p = get_tree().get_root().get_node("Level1/YSort/"+str(id))
	p.can_move = false

func _on_ChatInput_focus_exited():
	$Chat.modulate.a = 0.33
	var id = get_tree().get_network_unique_id()
	var p = get_tree().get_root().get_node("Level1/YSort/"+str(id))
	p.can_move = true

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		$Chat/ChatControl/ChatInput.text = ""
		$Chat/ChatControl/ChatInput.release_focus()
	if event.is_action_pressed("ui_accept"):
		_on_ChatSend_pressed()
	if Input.is_action_just_pressed("chat") and !$Chat/ChatControl/ChatInput.has_focus():
		if chat_visible:
			$Chat/AnimationPlayer.play_backwards("show_chat")
			chat_visible = false
		else:
			$Chat/AnimationPlayer.play("show_chat")
			chat_visible = true
