extends RayCast3D

@export var throw_force: float = 15.0
@export var break_distance: float = 5.0 # Distance before the object drops

@onready var play_char : PlayerCharacter = $"../../../../PlayerCharacter"
@onready var hold_pos = %Camera/HoldPos
var held_object: RigidBody3D = null

func _physics_process(delta):
	input_management()

	if held_object:
		var distance = hold_pos.global_position.distance_to(held_object.global_position)
		
		if distance > break_distance:
			release_object()
			return
		
		var target_vel = (hold_pos.global_position - held_object.global_position) * 20.0
		held_object.linear_velocity = target_vel
		
		# Keep it from spinning wildly
		held_object.angular_velocity = Vector3.ZERO

func input_management():
	if Input.is_action_just_pressed(play_char.interact_prim_action):
		interact_with()
	if Input.is_action_just_pressed(play_char.interact_m1_action):
		print("m1")
		if held_object:
			throw()
	if Input.is_action_just_pressed(play_char.interact_m2_action):
		print("m2")
		if held_object:
			release_object()

func interact_with():
	var collide = get_collider()

	if collide and collide is Interactable:
		var x = collide as Interactable
		
		if x.pick3d:
			if held_object:
				release_object()
			
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
	# held_object.set_collision_layer_value(1, false)

func throw():
	held_object.gravity_scale = 1.0
	held_object.set_collision_layer_value(1, true)
	
	var throw_dir = -play_char.cam.global_basis.z
	
	held_object.apply_central_impulse(throw_dir * throw_force * held_object.mass)
	if held_object is Explosive:
		held_object.was_thrown = true
	
	held_object = null
	print("Object thrown!")

func release_object():
	held_object.gravity_scale = 1.0
	held_object.set_collision_layer_value(1, true)
	held_object = null
