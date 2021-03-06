extends Area2D

export(Vector2) var teleport_to = Vector2()
export(String, "up", "right", "down", "left") var direction = "left"

func _on_Portal_body_entered(body):
	if body is KinematicBody2D:
		body.pass_through_door()
		teleport_to = get_node("Position2D").global_position
		body.position = teleport_to
		body.direction = direction
		body._set_direction(direction)
		body.get_node("Camera2D").smoothing_enabled = false
		body.get_node("Camera2D").force_update_scroll()
		body.get_node("Camera2D").smoothing_enabled = true
