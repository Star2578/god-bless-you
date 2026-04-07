# class_name InterpolatedSkeletonModifier3D extends SkeletonModifier3D

# @export_range(0.0, 1.0) var physics_interpolation: float = 0.5

# @export var physics_skeleton: Skeleton3D
# @export var animated_skeleton: Skeleton3D

# @export_group("Active Ragdoll Parameters")
# @export var linear_spring_stiffness: float = 1200.0
# @export var linear_spring_damping: float = 40.0
# @export var max_linear_force: float = 9999.0

# @export var angular_spring_stiffness: float = 4000.0
# @export var angular_spring_damping: float = 80.0
# @export var max_angular_force: float = 9999.0

# var physical_bone_sim:PhysicalBoneSimulator3D
# var physics_bones

# var _delta: float = 1.0 / 60.0
# var _last_parent_transform:Transform3D


# func _ready() -> void:
# 	print("Ragdoll basis: ", physics_skeleton.global_transform.basis.get_euler())
# 	print("Target basis: ", animated_skeleton.global_transform.basis.get_euler())

# 	_last_parent_transform = (owner as Node3D).global_transform

# 	for child in self.physics_skeleton.get_children():
# 		if child is PhysicalBoneSimulator3D:
# 			physical_bone_sim = child
# 	physics_bones = self.physical_bone_sim.get_children().filter(
# 		func(x): return x is PhysicalBone3D
# 	)
# 	self.physics_skeleton.skeleton_updated.connect(self._on_skeleton_updated)
# 	# self.physics_skeleton.skeleton_updated.connect(self._on_physics_skeleton_updated)


# 	# for b in physics_bones:
# 	# 	var bone_name: String = physics_skeleton.get_bone_name(b.get_bone_id()).to_lower()
# 	# 	# Foot and lower leg bones should not collide with floor
# 	# 	if "Foot" in bone_name or "toe" in bone_name or "ankle" in bone_name:
# 	# 		b.collision_mask = 0  # collide with nothing
# 	# 		b.collision_layer = 0

# 	self.physical_bone_sim.physical_bones_start_simulation()

# func _process(delta: float) -> void:
# 	# _on_physics_skeleton_updated()
# 	return


# func _physics_process(delta):
# 	self._delta = delta


# func _on_physics_skeleton_updated():
# 	for i in range(0, self.get_skeleton().get_bone_count()):
# 		var animated_transform: Transform3D = (
# 			animated_skeleton.global_transform * animated_skeleton.get_bone_global_pose(i)
# 		)
# 		var physics_transform: Transform3D = (
# 			physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(i)
# 		)
# 		(
# 			self
# 			. get_skeleton()
# 			. set_bone_global_pose(
# 				i,
# 				(
# 					global_transform.affine_inverse()
# 					* (animated_transform.interpolate_with(
# 						physics_transform,
# 						physics_interpolation
# 					))
# 				)
# 			)
# 		)


# func _on_skeleton_updated() -> void:
# 	for b in physics_bones:
# 		var bone_id = b.get_bone_id()

# 		var target_transform: Transform3D = (
# 			animated_skeleton.global_transform * animated_skeleton.get_bone_global_pose(bone_id)
# 		)
# 		var current_transform: Transform3D = (
# 			physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(bone_id)
# 		)

# 		var rotation_difference: Basis = target_transform.basis * current_transform.basis.inverse()
# 		var position_difference: Vector3 = target_transform.origin - current_transform.origin

# 		var has_rotated: bool = rotation_difference.get_euler().length_squared() > 0.00001
# 		# if position_difference.length_squared() > 2.0:
# 		# 	# Smoothly blend toward target
# 		# 	b.global_position = b.global_position.lerp(target_transform.origin, 0.3)
# 		# 	b.linear_velocity = Vector3.ZERO  # Kill runaway velocity
# 		if true:
# 			var force: Vector3 = hookes_law(
# 				position_difference,
# 				b.linear_velocity,
# 				linear_spring_stiffness,
# 				linear_spring_damping
# 			)
# 			force = force.limit_length(max_linear_force)
# 			var max_delta_v = position_difference / self._delta
# 			b.linear_velocity += (force * self._delta).limit_length(max_delta_v.length())

# 		# print(b.linear_velocity)

# 		var torque = hookes_law(
# 			rotation_difference.get_euler(),
# 			b.angular_velocity,
# 			angular_spring_stiffness,
# 			angular_spring_damping
# 		)
# 		torque = torque.limit_length(max_angular_force)
# 		b.angular_velocity += torque * self._delta

# 		# if has_rotated:
# 			# b.global_basis = b.global_basis.orthonormalized()
# func hookes_law(
# 	displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float
# ) -> Vector3:
# 	return (stiffness * displacement) - (damping * current_velocity)

class_name InterpolatedSkeletonModifier3D extends SkeletonModifier3D

@export_range(0.0, 1.0) var physics_interpolation: float = 0.5
@export var physics_skeleton: Skeleton3D
@export var animated_skeleton: Skeleton3D

@export_group("Active Ragdoll Parameters")
@export var linear_spring_stiffness: float = 1200.0
@export var linear_spring_damping: float = 40.0
@export var max_linear_force: float = 9999.0
@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0

var physical_bone_sim: PhysicalBoneSimulator3D
var physics_bones
var _delta: float = 1.0 / 60.0
var _last_parent_transform: Transform3D

func _ready() -> void:
	_last_parent_transform = (owner as Node3D).global_transform

	for child in physics_skeleton.get_children():
		if child is PhysicalBoneSimulator3D:
			physical_bone_sim = child

	physics_bones = physical_bone_sim.get_children().filter(
		func(x): return x is PhysicalBone3D
	)

	physics_skeleton.skeleton_updated.connect(_on_skeleton_updated)
	physical_bone_sim.physical_bones_start_simulation()

func _physics_process(delta: float) -> void:
	_delta = delta
	_sync_bones_to_parent_movement()
	_on_physics_skeleton_updated()

func _sync_bones_to_parent_movement() -> void:
	var current_parent_transform: Transform3D = (owner as Node3D).global_transform
	var position_delta: Vector3 = current_parent_transform.origin - _last_parent_transform.origin
	var rotation_delta: Basis = current_parent_transform.basis * _last_parent_transform.basis.inverse()

	var has_moved: bool = position_delta.length_squared() > 0.00001
	var has_rotated: bool = rotation_delta.get_euler().length_squared() > 0.00001

	if has_moved or has_rotated:
		for b in physics_bones:
			var relative_pos: Vector3 = b.global_position - _last_parent_transform.origin
			b.global_position = current_parent_transform.origin + rotation_delta * relative_pos
			if has_rotated:
				b.global_basis = (rotation_delta * b.global_basis).orthonormalized()

	_last_parent_transform = current_parent_transform

func _on_physics_skeleton_updated() -> void:
	for i in range(get_skeleton().get_bone_count()):
		var animated_transform: Transform3D = (
			animated_skeleton.global_transform * animated_skeleton.get_bone_global_pose(i)
		)
		var physics_transform: Transform3D = (
			physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(i)
		)
		get_skeleton().set_bone_global_pose(
			i,
			global_transform.affine_inverse() * animated_transform.interpolate_with(
				physics_transform, physics_interpolation
			)
		)

func _on_skeleton_updated() -> void:
	var skel_basis_inv: Basis = physics_skeleton.global_transform.basis.inverse()
	var target_skel_basis_inv: Basis = animated_skeleton.global_transform.basis.inverse()

	for b in physics_bones:
		var bone_id = b.get_bone_id()

		var target_transform: Transform3D = (
			animated_skeleton.global_transform * animated_skeleton.get_bone_global_pose(bone_id)
		)
		var current_transform: Transform3D = (
			physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(bone_id)
		)

		# Strip skeleton rotation — fixes world space leak
		var target_bone_basis: Basis = target_skel_basis_inv * target_transform.basis
		var current_bone_basis: Basis = skel_basis_inv * current_transform.basis
		var rotation_difference: Basis = target_bone_basis * current_bone_basis.inverse()

		var position_difference: Vector3 = target_transform.origin - current_transform.origin

		# Position spring
		var force: Vector3 = hookes_law(
			position_difference,
			b.linear_velocity,
			linear_spring_stiffness,
			linear_spring_damping
		)
		force = force.limit_length(max_linear_force)
		var max_delta_v: Vector3 = position_difference / _delta
		b.linear_velocity += (force * _delta).limit_length(max_delta_v.length())

		# Rotation spring — local space in, world space out
		var euler: Vector3 = rotation_difference.get_euler()
		euler.x = wrapf(euler.x, -PI, PI)
		euler.y = wrapf(euler.y, -PI, PI)
		euler.z = wrapf(euler.z, -PI, PI)

		var local_torque: Vector3 = hookes_law(
			euler,
			skel_basis_inv * b.angular_velocity,
			angular_spring_stiffness,
			angular_spring_damping
		)
		local_torque = local_torque.limit_length(max_angular_force)
		var world_torque: Vector3 = physics_skeleton.global_transform.basis * local_torque
		b.angular_velocity += world_torque * _delta

func hookes_law(
	displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float
) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)
