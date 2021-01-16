extends MarginContainer

func _ready():
	$MuteButton.set_pressed(Globals.sound_muted)

func _on_MuteButton_toggled(button_pressed):
	Globals.sound_muted = button_pressed
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), Globals.sound_muted)
