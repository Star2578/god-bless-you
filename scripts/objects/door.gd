extends Interactable

@onready var anim: AnimationPlayer = %AnimationPlayer
@onready var sfx: AudioStreamPlayer3D = %AudioStreamPlayer3D
var is_open = false

func _ready() -> void:
	super()


func interact():
	print("DOOR!")
	sfx.play()
	if not is_open:
		is_open = true
		anim.play("open", -1, 1, false)
	else:
		is_open = false
		anim.play("open", -1, -1, true)

func _on_collide_with_door(body:Node3D):
	# auto open if npc collide
	if body.is_in_group("NPC") and not is_open:
		sfx.play()
		is_open = true
		anim.play("open", -1, 1, false)
