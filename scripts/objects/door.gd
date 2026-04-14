extends Interactable

@onready var anim: AnimationPlayer = %AnimationPlayer
@onready var sfx: AudioStreamPlayer3D = %AudioStreamPlayer3D
var is_open = false

func interact():
	print("DOOR!")
	sfx.play()
	if not is_open:
		is_open = true
		anim.play("open", -1, 1, false)
	else:
		is_open = false
		anim.play("open", -1, -1, true)
		
	
