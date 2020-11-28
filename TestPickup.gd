extends Node2D

func _on_Area2D_area_entered(area):
	pass

func _on_Area2D_body_entered(body):
	if body.has_method("_gain_coin"):
		body._gain_coin()
		queue_free()
