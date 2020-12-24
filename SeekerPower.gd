extends Panel

var background
var icon_image
var skill_name
var hotkey
var cooldown
var skill_key

func _ready():
	skill_key = hotkey-1
	var icon_text = hotkey
	if hotkey == 1:
		icon_text = "Space"
	$Background.texture = load("res://sprites/skills/"+str(background))
	$Icon.texture = load("res://sprites/skills/"+str(icon_image))
	$Hotkey.text = str(icon_text)
	$CooldownTimer.wait_time = cooldown
	
func _process(delta):
	if !$CooldownTimer.is_stopped() and $CooldownTimer.time_left > 0:
		$CooldownOverlay.value = (float($CooldownTimer.time_left/float(cooldown))*100)
		
func start_cooldown():
	$CooldownTimer.start()
	Globals.seeker_skills[skill_key].cooldown_active = true

func _on_CooldownTimer_timeout():
	Globals.seeker_skills[skill_key].cooldown_active = false
	$AnimationPlayer.play("skill_ready")
