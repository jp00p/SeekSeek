extends Control

var buttons = [false, false, false]

func _check_complete():
	for result in buttons:
		if result == false:
			return
	queue_free()	

func _on_CheckButton_pressed():
	buttons[0] = true
	_check_complete()

func _on_CheckButton2_pressed():
	buttons[1] = true
	_check_complete()

func _on_CheckButton3_pressed():
	buttons[2] = true
	_check_complete()
