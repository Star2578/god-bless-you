extends CharacterBody3D


const SPEED = 5.0

@onready var nav_agent_3d : NavigationAgent3D = $NavigationAgent3D

var next_target_position: Vector3
var frame_since_path_calc:int = 0

func _ready() -> void:
	nav_agent_3d.target_position = Vector3(14,0.3,-4.8)

func _process(delta) -> void:
	if frame_since_path_calc >= 10:
		next_target_position = nav_agent_3d.get_next_path_position()
		frame_since_path_calc = 0
	else:
		frame_since_path_calc +=1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta


	add_velocity_toward_next_path()

	move_and_slide()

	# var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# if direction:
	# 	velocity.x = direction.x * SPEED
	# 	velocity.z = direction.z * SPEED
	# else:
	# 	velocity.x = move_toward(velocity.x, 0, SPEED)
	# 	velocity.z = move_toward(velocity.z, 0, SPEED)

func add_velocity_toward_next_path():
	if nav_agent_3d.is_navigation_finished():
		return
	var pos_diff = self.next_target_position - self.global_position
	var dir = pos_diff.normalized()

	self.velocity.x = dir.x * SPEED
	self.velocity.z = dir.z * SPEED

func _on_navigation_agent_3d_link_reached(details: Dictionary) -> void:
	print(details)
	var dir:Vector3 = (details.link_exit_position - details.position).normalized()
	self.velocity.x = dir.x * SPEED
	self.velocity.z = dir.z * SPEED

func _on_navigation_agent_3d_navigation_finished() -> void:
	self.velocity = Vector3.ZERO