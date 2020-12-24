extends CanvasLayer


# give a letter rank to seeker (how few items made it in, how quickly they won)
# give awards to some players:
 # most items
 # most running
 # least items
 # closest calls
 # 

func _ready():
	$Control.set_visible(false)

func declare_winner(winning_team):
	$Control.set_visible(true)
	$Control/VBoxContainer/Winner.text = str(winning_team) + " wins!"
