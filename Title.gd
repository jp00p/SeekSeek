extends Control

signal title_start
signal show_help

func _on_Button_pressed():
	$WOW.play()
	$CenterContainer/VBoxContainer/AnimationPlayer.play("intro")
	yield($CenterContainer/VBoxContainer/AnimationPlayer, "animation_finished")
	emit_signal("title_start")


func _on_Help_pressed():
	emit_signal("show_help")
