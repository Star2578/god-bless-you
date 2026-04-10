extends RayCast3D

@onready var play_char : PlayerCharacter = $"../../../../PlayerCharacter"
@onready var hold_pos = %Camera/HoldPos
var held_object: RigidBody3D = null

func _physics_process(delta):
	input_management()

	if held_object:
		# Move the object toward the HoldPos using velocity
		# This gives it that "Garry's Mod" weight/delay
		var target_vel = (hold_pos.global_position - held_object.global_position) * 20.0
		held_object.linear_velocity = target_vel
		
		# Keep it from spinning wildly
		held_object.angular_velocity = Vector3.ZERO

func input_management():
	if Input.is_action_just_pressed(play_char.interact_action):
		interact_with()

func interact_with():
	var collide = get_collider()

	if collide and collide is Interactable:
		var x = collide as Interactable
		
		if x.pick3d:
			print("pick3d")
			pick_up(x.rigid_body)
		else:
			print("interact")
			x.interact()

func pick_up(body: RigidBody3D):
	print("pickup")
	print(body)
	held_object = body
	held_object.gravity_scale = 0.0 # Make it float
	# We use layers to stop it from colliding with the player while held
	held_object.set_collision_layer_value(1, false)

func release_object():
	if held_object:
		held_object.gravity_scale = 1.0
		held_object.set_collision_layer_value(1, true)
		held_object = null
