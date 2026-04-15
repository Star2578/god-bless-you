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

		var static_body:StaticBody3D = owner.find_children("*","StaticBody3D")[0]
		if static_body:
			static_body.set_collision_layer_value(1,false)
			await get_tree().create_timer(1.0).timeout
			static_body.set_collision_layer_value(1,true)



