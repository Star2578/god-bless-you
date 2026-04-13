extends CharacterBody3D
# class_name NPC

@export_group("NPC Parameters")

@export var hp:int = 10

@export var move_speed: float = 2.0
@export var idle_wait_time: float = 2.0

enum State { IDLE, START_ROAMING, ROAMING, UNCONSCIOUS ,LAY_DOWN, STANDING_UP }
var state = State.IDLE

var path_node: Node3D
var current_target: Marker3D
var _idle_timer: float = 0.0


@export_group("Active Ragdoll Parameters")

# @export_range(0.0, 1.0) var physics_interpolation: float = 0.5
@export var physics_skeleton: Skeleton3D
@export var animated_skeleton: Skeleton3D
@export var character_collision : CollisionShape3D # a hitbox to activate ragdoll

@export var linear_spring_stiffness: float = 1200.0
@export var linear_spring_damping: float = 40.0
@export var max_linear_force: float = 9999.0
@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0


var physical_bone_sim: PhysicalBoneSimulator3D
var physics_bones
var hip_bone: PhysicalBone3D

@onready var hitbox_manager = $Hitboxes

var _teleport_pending: bool = false
var _pending_ragdoll_position: Vector3

var _delta: float
var contact_timer:float = 0.0
var contact_interval:float = 5 # time before character revert from ragdoll
var contact_counter:int = 0 # hit count before turn fully ragdoll

var recovery_timer:float = 0.0
const RECOVERY_DELAY:float = 5.0 # time it take for npc to get up from unconscious state


func _ready() -> void:
	path_node = get_tree().root.find_child("NPCPath", true, false)

	for child in physics_skeleton.get_children():
		if child is PhysicalBoneSimulator3D:
			physical_bone_sim = child
	physics_bones = physical_bone_sim.get_children().filter(
		func(x): return x is PhysicalBone3D
	)

	for b:PhysicalBone3D in physics_bones:
		b.add_collision_exception_with(self)
		if "hips" in b.name.to_lower():
			hip_bone = b



func _process(delta: float) -> void:
	self._delta = delta
	DebugDraw3D.draw_text(global_position + (Vector3.UP * 4.0),State.find_key(self.state),72)

	match state:
		State.IDLE:
			# Count down timer, no await in _process
			_idle_timer += delta
			if _idle_timer >= idle_wait_time:
				_idle_timer = 0.0
				state = State.START_ROAMING

		State.START_ROAMING:
			var child_count = path_node.get_child_count()
			if child_count == 0:
				return
			# Pick a random target different from the current one
			var rand_node: Marker3D = current_target
			while rand_node == current_target:
				rand_node = path_node.get_child(randi_range(0, child_count - 1))
			current_target = rand_node
			state = State.ROAMING

		State.ROAMING:
			if current_target == null:
				state = State.IDLE

		# When character turn fully ragdoll
		State.UNCONSCIOUS:
			recovery_timer -= delta

			if recovery_timer <= 0.0:
				self.velocity = Vector3.ZERO
				self.state = State.STANDING_UP

				# physics_skeleton.physical_bones_stop_simulation()
				# deactivate_ragdoll()
				sync_ragdoll_position()
				physics_skeleton.skeleton_updated.connect(_on_skeleton_updated)
				# physics_skeleton.skeleton_updated.connect(_on_skeleton_updated)
				# physics_skeleton.physical_bones_start_simulation()



func _physics_process(delta: float) -> void:
	# cancel external force
	self.velocity.x = 0.0
	self.velocity.z = 0.0


	if self._teleport_pending:
		_teleport_pending = false
		global_position = self._pending_ragdoll_position
		velocity = Vector3.ZERO
		return

	if self.state == State.UNCONSCIOUS:
		velocity = Vector3.ZERO
		return



	if not is_on_floor():
		self.velocity.y += get_gravity().y * delta

	if self.state == State.ROAMING:
		var pos_diff: Vector3 = (current_target.global_position - global_transform.origin)
		if Vector3(pos_diff.x , 0.0 ,pos_diff.z).length() < 0.1 :
			self.state = State.IDLE

		var target_vel = pos_diff.normalized() * self.move_speed
		self.velocity.x = target_vel.x
		self.velocity.z = target_vel.z

		if pos_diff.length_squared() > 0.001:
			look_at(global_position - Vector3(target_vel.x,0.0 , target_vel.z), Vector3.UP)

	move_and_slide()

	# return to normal animation after time
	if self.contact_timer <= 0.0 and not self.is_dead():
		if self.is_ragdoll_enabled():
			deactivate_ragdoll()
			self.contact_counter = 0
	else:
		self.contact_timer -= delta


func hookes_law(
	displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float
) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)


func _on_skeleton_updated() -> void:
	# rotate the physical bones toward the animated bones rotations using hookes law
	var delta := get_physics_process_delta_time()

	for b:PhysicalBone3D in physics_bones:
		var bone_id = b.get_bone_id()


		var target_transform: Transform3D = animated_skeleton.global_transform * animated_skeleton.get_bone_global_pose(bone_id)
		var current_transform: Transform3D = physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(bone_id)

		var position_difference: Vector3 = target_transform.origin - current_transform.origin

		if position_difference.length_squared() > 1.0:
			b.global_position = target_transform.origin
			b.linear_velocity = Vector3.ZERO
		else:
			var force: Vector3 = hookes_law(position_difference, b.linear_velocity, linear_spring_stiffness, linear_spring_damping)
			force = force.limit_length(max_linear_force)
			b.linear_velocity += (force * delta)

		var rot_delta := (target_transform.basis.get_rotation_quaternion() * current_transform.basis.get_rotation_quaternion().inverse()).normalized()
		if rot_delta.w < 0:
			rot_delta = Quaternion(-rot_delta.x, -rot_delta.y, -rot_delta.z, -rot_delta.w)
		var rot_angle := rot_delta.get_angle()
		var rot_axis := rot_delta.get_axis()
		var angular_vel := rot_axis * rot_angle

		var torque = hookes_law(angular_vel, b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		torque = torque.limit_length(max_angular_force)
		b.angular_velocity += torque * delta


func take_damage(damage:int):
	self.hp = max(self.hp - damage , 0)

	self.contact_timer = self.contact_interval

	# track continuous hit
	if self.contact_timer > 0.0:
		self.contact_counter += 1

	if self.is_dead() or self.contact_counter > 5:
		# goes fully ragdoll
		self.state = State.UNCONSCIOUS
		self.recovery_timer = self.RECOVERY_DELAY
		self.activate_ragdoll(false,true)
	else:
		self.activate_ragdoll(true,true)

func activate_ragdoll(with_active:bool , revert_pose:bool):

	if self.is_ragdoll_enabled():
		# active ragdoll -> fully ragdoll
		if not with_active and self.is_active_ragdoll():
			physics_skeleton.skeleton_updated.disconnect(_on_skeleton_updated)
		return



	# start with current animation pose
	if revert_pose:
		for b:PhysicalBone3D in physics_bones:
			var b_id := b.get_bone_id()
			var pose := animated_skeleton.get_bone_global_pose(b_id)
			physics_skeleton.set_bone_global_pose(b_id , pose)

	if with_active:
		physics_skeleton.skeleton_updated.connect(_on_skeleton_updated)
		physical_bone_sim.physical_bones_start_simulation()
		animated_skeleton.visible = false
		physics_skeleton.visible = true
	else:
		physical_bone_sim.physical_bones_start_simulation()
		animated_skeleton.visible = false
		physics_skeleton.visible = true

func deactivate_ragdoll():
	if self.is_active_ragdoll():
		physics_skeleton.skeleton_updated.disconnect(_on_skeleton_updated)

	physical_bone_sim.physical_bones_stop_simulation()
	self.character_collision.disabled = false
	animated_skeleton.visible = true
	physics_skeleton.visible = false

func sync_ragdoll_position():
	# move real node position to current ragdoll position
	var space_state := get_world_3d().direct_space_state
	var raycast_query := PhysicsRayQueryParameters3D.create(hip_bone.global_position + (Vector3.UP * 0.2), hip_bone.global_position + (Vector3.DOWN * 10),1 , [self])
	var floor_collision := space_state.intersect_ray(raycast_query)
	if floor_collision:
		_pending_ragdoll_position  = floor_collision.position + (Vector3.UP * 0.01)
	else:
		_pending_ragdoll_position  = hip_bone.global_position + (Vector3.UP * 0.1)
	_teleport_pending = true

func is_ragdoll_enabled()->bool:
	return physical_bone_sim.is_simulating_physics()

func is_active_ragdoll()->bool:
	return physics_skeleton.skeleton_updated.is_connected(_on_skeleton_updated)

func is_dead():
	if self.hp == 0:
		return true
	return false


func _hitbox_hit(body:Node):
	print(body.name)
	# if body.is_in_group("NPC"):
	# 	print(body)
	# 	print("HIT")
		# print("HIT")
		# body.take_damage(1)
