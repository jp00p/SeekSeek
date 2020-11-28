tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/GetCoords.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)

func _input(event):
	var scene_root = get_tree().get_edited_scene_root()
	var mouse_coords = get_viewport().get_mouse_position()
	dock.text = str(mouse_coords)

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()
