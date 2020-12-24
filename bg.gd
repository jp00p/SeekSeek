extends TextureRect

var t = 0.0
var speed = 1000
func _process(delta):
	t += delta
	#get_material().set_shader_param("in_Time", t)
	#$TextureRect.get_material().set_shader_param("in_Time", t/100)
